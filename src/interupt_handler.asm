PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003
PCR = $600c
IFR = $600d
IER = $600e

value = $0200 ; 2 bytes
mod10 = $0202 ; 2 bytes
message = $0204 ; 6 bytes
counter = $020a ; 2 bytes

E  = %10000000
RW = %01000000
RS = %00100000

  .org $8000

reset:
  ; initialize the stack pointer
  ldx #$ff        ; first stack address
  txs             ; load X-Register to stack pointer
  cli

  lda #$82
  sta IER
  lda #$00
  sta PCR

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

  lda #0
  sta counter
  sta counter + 1
loop:
  lda #%00000010 ; Cursor at Home
  jsr lcd_instruction

  lda #0
  sta message

  ; store counter to ram
  lda counter
  sta value
  lda counter + 1
  sta counter + 1

divide:
  ; initialize the remainder to zero
  lda #0
  sta mod10
  sta mod10 + 1
  clc
  
  ldx #16
divloop:
  ; rotate quotient and remainder
  rol value
  rol value + 1
  rol mod10
  rol mod10 + 1

  ; a,y = dividend - divisor
  sec
  lda mod10
  sbc #10
  tay ; save low byte in Y
  lda mod10 + 1
  sbc #0
  bcc ignore_result ; branch if dividend < divisor
  sty mod10
  sta mod10 + 1

ignore_result:
  dex
  bne divloop
  rol value ; shift in the last bit of the quotient
  rol value + 1

  lda mod10
  clc
  adc #"0"
  jsr push_char

  ; if value != 0, then continue dividing
  lda value
  ora value + 1
  bne divide ; branch if value not zero

  ldx #0
printStart:
  lda message,x
  beq printEnd
  jsr print_char
  inx
  jmp printStart
printEnd:

  jmp loop

; Add the character in the A register to the beginning of the
; null-terminated string "message"
push_char:
  pha ; push new first char onto stack
  ldy #0

char_loop:
  lda message, y ; get char on string and put into X
  tax
  pla
  sta message, y ; Pull char off stack and add it to the string
  iny
  txa
  pha             ; Push char from string onto stack
  bne char_loop

  pla
  sta message, y  ; Pull the null off the stack and add to the end of the string
  
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
  jsr lcd_wait
  sta PORTB
  lda #0      ; Clear RS/RW/E bits
  sta PORTA
  lda #E      ; Set E bit to send instruction
  sta PORTA
  lda #0      ; Clear RS/RW/E bits
  sta PORTA
  rts

; send character from A register to lcd screen
print_char:
  jsr lcd_wait
  sta PORTB
  lda #RS     ; Set RS; Clear RW/E bits
  sta PORTA
  lda #(RS | E) ; Set E bit to send intruction
  sta PORTA
  lda #RS     ; Set RS; Clear RW/E bits
  sta PORTA
  rts

nmi:
irq:
  inc counter
  bne exit_irq
  inc counter + 1
exit_irq:
  bit PORTA ; clear interupt
  rti

  .org $fffa
  .word nmi
  .word reset
  .word irq
