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

  .org $8000

reset:
  ; initialize the stack pointer
  ldx #$ff        ; first stack address
  txs             ; load X-Register to stack pointer
  cli

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
  ldx #0
send_msg:
  lda startup_message,x
  beq done
  jsr send_char
  inx
  jmp send_msg
done:
  
  ; loop to get user input
rx_wait:
  lda ACIA_STATUS
  and #%00001000  ; check rx buffer status flag
  beq rx_wait     ; loop if rx buffer empty

  lda ACIA_DATA
  jsr print_char
  jsr send_char
  jmp rx_wait

startup_message: .asciiz "Welcome to Flip-6502"

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

