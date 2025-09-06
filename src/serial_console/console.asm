PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

E  = %10000000
RW = %01000000
RS = %00100000

ACIA_DATA = $5000
ACIA_STATUS = $5001
ACIA_CMD = $5002
ACIA_CTRL = $5003

; ----- argument adresses -----
arg_ptr1 = $0000    ; 2 bytes; lower and upper adress
arg_ptr2 = $0002    ; 2 bytes; lower and upper adresS
; ----- return values -----
rtn_val1 = $0004    ; 2 bytes

; ----- general variable storage -----
user_line = $0200   ; 128 bytes; string the user sends per line
user_start = $0004  ; 2 bytes; start adress
user_end = $0006    ; 2 bytes; end adress
user_curr = $0008   ; 2 bytes
check_byte = $000a
  
; ----- rom start adress -----
  .org $8000

reset:
  ; initialize the stack pointer
  ldx #$ff        ; first stack address
  txs             ; load X-Register to stack pointer
  cli

  lda #$fa
  sta check_byte

  ; set up w65c22
  lda #%11111111  ; Set all pins on port B to output
  sta DDRB

  lda #%11100000  ; Set top 3 pins on port A to output
  sta DDRA

  ; set up display
  lda #%00000001  ; clear display
  jsr lcd_instruction

  lda #%00111000  ; Set 8-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction

  lda #%00001110  ; Display on; cursor on; blink off
  jsr lcd_instruction

  lda #%00000110  ; Increment and shift cursor; don't shift display
  jsr lcd_instruction


  lda #$00
  sta ACIA_STATUS ; soft reset (value not important)
  
  lda #%00011111  ; N-8-1, 19200 baud
  sta ACIA_CTRL

  lda #$0b        ; no parity, no echo, no interrupts
  sta ACIA_CMD

  ; send welcome message
  lda #<startup_message
  sta arg_ptr1
  lda #>startup_message
  sta arg_ptr1 + 1
  jsr send_string

  jsr clr_user_line      ; clear user line buffer

console_new_line: 
  ldx #$00        ; reset character counter

  lda #%00000010 ; Cursor at Home
  jsr lcd_instruction

  ; send console line start
  lda #<console_line_start
  sta arg_ptr1
  lda #>console_line_start
  sta arg_ptr1+1
  jsr send_string
  
  ; loop to get user input
rx_wait:
  lda ACIA_STATUS
  and #%00001000  ; check rx buffer status flag
  beq rx_wait     ; loop if rx buffer empty

  lda ACIA_DATA

  ; check if user send "Enter" / CR / 0x0d
  cmp #$0d
  beq end_of_line           ; no new line -> stay in loop

  sta user_line,x
  jsr print_char
  jsr send_char
  inx
  jmp rx_wait
  

end_of_line:
  lda #$00              
  sta user_line,x       ; null terminate string

  jsr process_user_line
  jmp console_new_line  ; go up to create new line

startup_message: .asciiz "Welcome to Flip-6502"
console_line_start: .byte $0d,$0a, "6504$ ", 0
command_help: .asciiz "help"
answer_help: .byte $0d,$0a, "Basic Memory viewer and manipulator.", $0d, $0a, "Enter address in 00[.00] format. ([] -> optional)", 0

; converts 4bit (nibble) to ascii hex representation
; in A -> out A
NIB_TO_ASC:
  CMP #$0A         ; >= 10 ?
  BCC digit
  CLC
  ADC #$07         ; add 7 so (10..15) becomes (17..22)
digit:
  CLC
  ADC #$30         ; then add '0' -> '0'..'9' or 'A'..'F'
  RTS
  

; ----------------------------------------
; ASCII '0'..'9','A'..'F','a'..'f' -> nibble (0..15)
; In:  A = ASCII
; Out: C = 1 on success, A = nibble 0..15
;      C = 0 on failure, A unchanged/undefined
; ----------------------------------------
ASC_TO_NIB:
  CMP #'0'         ; < '0' ?
  BCC bad
  CMP #':'         ; '0'..'9' ?
  BCC is_digit
  CMP #'A'         ; < 'A' ?
  BCC bad
  CMP #'G'         ; 'A'..'F' ?
  BCC is_upper
  CMP #'a'         ; < 'a' ?
  BCC bad
  CMP #'g'         ; 'a'..'f' ?
  BCS bad
  ; lower-case hex
  SEC
  SBC #'a'-10
  SEC              ; success
  RTS
is_upper:
  SEC
  SBC #'A'-10
  SEC
  RTS
is_digit:
  SEC
  SBC #'0'
  SEC
  RTS
bad:
  CLC              ; failure
  RTS


; sends byte as hex to console
; does not keep a
send_hex:
  pha
  lsr
  lsr
  lsr
  lsr
  jsr NIB_TO_ASC  ; high nibble
  jsr send_char
  pla
  and #$0F        ; keep low nibble
  jsr NIB_TO_ASC
  jsr send_char
  rts


; --- process user line ---
; compares user_line with command_help
; sends answer_help if matched
process_user_line:
  pha
  phy

  ; check for help command
  lda #<command_help  ; load string 1
  sta arg_ptr1
  lda #>command_help
  sta arg_ptr1 + 1
  lda #<user_line     ; load string 2
  sta arg_ptr2
  lda #>user_line
  sta arg_ptr2 + 1
  jsr str_cmp         ; compare
  lda #$01
  cmp rtn_val1
  bne process_user_line_is_hex  ; input can be help or hex

  lda #<answer_help  ; load string 1
  sta arg_ptr1
  lda #>answer_help
  sta arg_ptr1 + 1
  jsr send_string
  jmp process_user_line_done

process_user_line_is_hex:
  ; create 2 byte adress out of 4 hex values
  ; high byte
  lda user_line
  jsr ASC_TO_NIB
  asl
  asl
  asl
  asl
  sta user_start + 1
  lda user_line + 1
  jsr ASC_TO_NIB
  ora user_start + 1
  sta user_start + 1
  sta user_curr + 1
  ; low byte
  lda user_line + 2
  jsr ASC_TO_NIB
  asl
  asl
  asl
  asl
  sta user_start
  lda user_line + 3
  jsr ASC_TO_NIB
  ora user_start
  sta user_start
  sta user_curr
  
  ; check if dot on user_line
  lda user_line + 4
  cmp #"."
  bne process_user_line_single_address

  ; get second address
  lda user_line + 5
  jsr ASC_TO_NIB
  asl
  asl
  asl
  asl
  sta user_end + 1
  lda user_line + 6
  jsr ASC_TO_NIB
  ora user_end + 1
  sta user_end + 1
  ; low byte
  lda user_line + 7
  jsr ASC_TO_NIB
  asl
  asl
  asl
  asl
  sta user_end
  lda user_line + 8
  jsr ASC_TO_NIB
  ora user_end
  sta user_end
  
  jsr send_byte_range
  jmp process_user_line_done

process_user_line_single_address:
  ; load hex from user_start and send to console
  lda #$0d
  jsr send_char
  lda #$0a
  jsr send_char
  lda (user_start)
  jsr send_hex

process_user_line_done:
  ply
  pla
  rts


; expects that user_start and user_end are set
send_byte_range:
  pha
  phy

  lda user_start
  sta user_curr
  ldy #$00
  
send_byte_line:
  ; print current address
  lda #$0d
  jsr send_char
  lda #$0a
  jsr send_char
  lda user_curr + 1
  jsr send_hex
  lda user_curr
  jsr send_hex
  lda #":"
  jsr send_char
  lda #" "
  jsr send_char

send_byte_value:
  ; send address value until current address is divisible by 8
  lda (user_curr),y
  jsr send_hex
  
  inc user_curr     ; zero flag set when overflow
  bne no_wrap
  inc user_curr + 1 
  
  lda user_curr + 1 ; check if higher bit is bigger than user_end
  cmp user_end + 1  ; carry flag when user_curr >= user_end; zero flag when user_curr = user_end; we need c = 1 and z = 0
  beq continue      ; z = 1 -> equal -> in range
  bcs send_byte_range_done ; c = 1 -> equal,bigger -> out of range

no_wrap:
  lda user_curr + 1
  cmp user_end + 1
  bne continue      ; only check lower byte when higher is same
  lda user_curr
  cmp user_end
  beq continue
  bcs send_byte_range_done

continue:
  and #07           ; check if divisible by 8
  beq send_byte_line
  jmp send_byte_value

send_byte_range_done:
  ply
  pla
  rts
  

; expects the two strings at arg_ptr1 and arg_ptr2
; uses rtn_ptr1 to return if the strings are equal 
str_cmp:
  pha
  phy
  ldy #$00

str_cmp_char:
  lda (arg_ptr1),y
  cmp (arg_ptr2),y
  bne str_cmp_not_equal
  ; both the same; now check if both null
  lda (arg_ptr1),y
  ora (arg_ptr2),y  ; return zero if both are zero
  cmp #$00          
  beq str_cmp_equal
  iny
  jmp str_cmp_char

str_cmp_equal:
  lda #$01
  sta rtn_val1
  jmp str_cmp_done

str_cmp_not_equal:
  lda #$00
  sta rtn_val1
  jmp str_cmp_done

str_cmp_done:
  pla
  ply
  rts

; clears the user line
clr_user_line:
  pha
  phx
  ldx #0
clear_loop:
  lda #$00
  sta user_line,x
  inx
  cpx #80     ; 128
  bne clear_loop

  plx
  pla
  rts


; expects the message adress in arg_ptr1
send_string:
  pha
  phy
  ldy #0
send_msg:
  lda (arg_ptr1),y
  beq send_msg_done
  jsr send_char
  iny
  jmp send_msg
send_msg_done:
  ply
  pla
  rts

; expects char in A-Register
send_char:
  sta ACIA_DATA
  pha
tx_wait:
  lda ACIA_STATUS
  and #$10
  beq tx_wait
  jsr tx_delay
  pla
  rts

tx_delay:
  phx
  ldx #100
tx_delay_1:
  dex
  bne tx_delay_1
  plx
  rts

; waits and checks the busy flag of the lcd display
lcd_wait:
  pha
  lda #%00000000    ; Port B input
  sta DDRB
lcdbusy:
  lda #RW
  sta PORTA
  lda #(RW | E)
  sta PORTA
  lda PORTB         ; read busy flag
  and #%10000000    ; keep only busy flag
  bne lcdbusy       ; branch if not zero

  lda #RW
  sta PORTA
  lda #%11111111    ; Port B output
  sta DDRB
  pla
  rts

; send instruction from A register to lcd display
lcd_instruction:
  pha
  jsr lcd_wait
  sta PORTB
  lda #0      ; Clear RS/RW/E bits
  sta PORTA
  lda #E      ; Set E bit to send instruction
  sta PORTA
  lda #0      ; Clear RS/RW/E bits
  sta PORTA
  pla
  rts

; send character from A register to lcd screen
print_char:
  pha
  jsr lcd_wait
  sta PORTB
  lda #RS     ; Set RS; Clear RW/E bits
  sta PORTA
  lda #(RS | E) ; Set E bit to send intruction
  sta PORTA
  lda #RS     ; Set RS; Clear RW/E bits
  sta PORTA
  pla
  rts

  .org $fffc
  .word reset
  .word $0000

