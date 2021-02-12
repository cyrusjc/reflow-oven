$MODLP51

org 0000H
   ljmp MainProgram
   
org 0x000B
	ljmp Timer0_ISR

org 0x0013
	ljmp setting_up

org 0x0023
	ljmp serial_int
org 0x002B
	ljmp Timer2_ISR
	


CLK  EQU 22118400
BAUD equ 115200
BRG_VAL equ (0x100-(CLK/(16*BAUD)))
TIMER0_RELOAD_L DATA 0xf2
TIMER1_RELOAD_L DATA 0xf3
TIMER0_RELOAD_H DATA 0xf4
TIMER1_RELOAD_H DATA 0xf5

TIMER0_RATE   EQU 4096     ; 2048Hz squarewave (peak amplitude of CEM-1203 speaker)
TIMER0_RELOAD EQU ((65536-(CLK/TIMER0_RATE)))
TIMER2_RATE   EQU 1000     ; 1000Hz, for a timer tick of 1ms
TIMER2_RELOAD EQU ((65536-(CLK/TIMER2_RATE)))
;----------------------------------------
extra_starts_at EQU 0xEC
;-------------------------------------------
CSEG
CE_ADC EQU P2.0
MY_MOSI EQU P2.1
MY_MISO EQU P2.2
MY_SCLK EQU P2.3 
BOOT_BUTTON   equ P4.5
SOUND_OUT     equ P3.7
dseg at 0x30
signal: ds 1
x:   ds 4
y:   ds 4
bcd: ds 5
Result: ds 2
temp_volt: ds 2
Count1ms:     ds 2 
alarm_temp: ds 1
alarm_temp_temp: ds 1
temperature: ds 1
temppppp:ds 1
time_mod: ds 1
BSEG
mf: dbit 1
half_seconds_flag: dbit 1
beep_flag: dbit 1
on_off: dbit 1
$NOLIST
$include(math32.inc)
$LIST

LCD_RS equ P1.1
LCD_RW equ P1.2
LCD_E  equ P1.3
LCD_D4 equ P3.2
LCD_D5 equ P3.6
LCD_D6 equ P3.4
LCD_D7 equ P3.5
add_alarm equ P0.2
sub_alarm equ P0.4
exit equ P2.7
off equ P2.4
$NOLIST
$include(LCD_4bit.inc)
$LIST

Blank: db '   ', 0
space: db ' ', 0
initial: db 'Alarm Temp at:', 0
cc: db 'C', 0
on: db 'on', 0
off_str: db 'off', 0
;---------------------------------;
; Routine to initialize the ISR   ;
; for timer 0                     ;
;---------------------------------;


serial_int:
	push acc
	push psw
	push AR1
	push AR2
	push AR3
	Push AR4
	push AR5
	Push AR6
	Push AR7	
	mov r7, x
	mov r5, x+1 
	mov R2, bcd
	mov R3, bcd+1
	mov R4, bcd+2
	mov R6, bcd+3
	mov R1, bcd+4
	
	jnb RI, done
	clr RI
	mov signal, sbuf
	;hex_ascii(signal)    ;got from online, could be wrong 
	;mov signal, a

	;mov a, signal
	hex_ascii(low(signal))
	da a
	mov temppppp, a
	hex_ascii(high(signal))
	da a
	mov temppppp+1, a
	
	
	;mov a, signal
	;cjne a, #0xff, lcd_signal
	;sjmp done
;lcd_signal:
	
	;da a 
	;mov temppppp, a
	;lcall hex2bcd
done:
	;mov bcd, R2
	;mov bcd+1, R3
	;mov bcd+2, R4
	;mov bcd+3, R6
	;mov bcd+4, R1
	
	mov x, R7
	mov x+1, R5 
	pop AR7
	pop AR6
	pop AR5
	pop AR4
	pop AR3
	pop AR2
	pop AR1
	pop psw
	pop acc
	reti
Timer0_Init:
	mov a, TMOD
	anl a, #0xf0 ; Clear the bits for timer 0
	orl a, #0x01 ; Configure timer 0 as 16-timer
	mov TMOD, a
	mov TH0, #high(TIMER0_RELOAD)
	mov TL0, #low(TIMER0_RELOAD)
	; Set autoreload value
	mov TIMER0_RELOAD_H, #high(TIMER0_RELOAD)
	mov TIMER0_RELOAD_L, #low(TIMER0_RELOAD)
	; Enable the timer and interrupts
    setb ET0  ; Enable timer 0 interrupt
    setb TR0  ; Start timer 0
	ret

;---------------------------------;
; ISR for timer 0.  Set to execute;
; every 1/4096Hz to generate a    ;
; 2048 Hz square wave at pin P3.7 ;
;---------------------------------;
Timer0_ISR:
	;clr TF0  ; According to the data sheet this is done for us already.
	cpl SOUND_OUT ; Connect speaker to P3.7!
	reti

;---------------------------------;
; Routine to initialize the ISR   ;
; for timer 2                     ;
;---------------------------------;
Timer2_Init:
	mov T2CON, #0 ; Stop timer/counter.  Autoreload mode.
	mov TH2, #high(TIMER2_RELOAD)
	mov TL2, #low(TIMER2_RELOAD)
	; Set the reload value
	mov RCAP2H, #high(TIMER2_RELOAD)
	mov RCAP2L, #low(TIMER2_RELOAD)
	; Init One millisecond interrupt counter.  It is a 16-bit variable made with two 8-bit parts
	clr a
	mov Count1ms+0, a
	mov Count1ms+1, a
	; Enable the timer and interrupts
    setb ET2  ; Enable timer 2 interrupt
    setb TR2  ; Enable timer 2
	ret
	
Timer2_ISR:
	clr TF2  ; Timer 2 doesn't clear TF2 automatically. Do it in ISR
	
	; The two registers used in the ISR must be saved in the stack
	push acc
	push psw
	
	;jnb beep_flag, inc_count
	;clr beep_flag
	; Increment the 16-bit one mili second counter
	
	
	
	
	
inc_count:
	inc Count1ms+0    ; Increment the low 8-bits first
	mov a, Count1ms+0 ; If the low 8-bits overflow, then increment high 8-bits
	jnz Inc_Done
	inc Count1ms+1
Inc_Done:
	; Check if half second has passed
	mov a, Count1ms+0
	cjne a, #low(500), Timer2_ISR_done ; Warning: this instruction changes the carry flag!
	mov a, Count1ms+1
	cjne a, #high(500), Timer2_ISR_done
	
	; 500 milliseconds have passed.  Set a flag so the main program knows
	setb half_seconds_flag ; Let the main program know half second had passed
	mov a, alarm_temp
	add a, #0x99
	da a
	subb a, bcd
	jnc clear
	jnb on_off, clear
	cpl TR0 ; Enable/disable timer/counter 0. This line creates a beep-silence-beep-silence sound.
	; Reset to zero the milli-seconds counter, it is a 16-bit variable
	setb beep_flag
clear:
	;jb beep_flag, clra
	;clr TR0
clra:
	clr a
	mov Count1ms+0, a
	mov Count1ms+1, a
	
Timer2_ISR_done:
	pop psw
	pop acc
	reti
	
INI_SPI:
setb MY_MISO ; Make MISO an input pin
clr MY_SCLK ; Mode 0,0 default
ret
DO_SPI_G:
mov R1, #0 ; Received byte stored in R1
mov R2, #8 ; Loop counter (8-bits)
DO_SPI_G_LOOP:
mov a, R0 ; Byte to write is in R0
rlc a ; Carry flag has bit to write
mov R0, a
mov MY_MOSI, c
setb MY_SCLK ; Transmit
mov c, MY_MISO ; Read received bit
mov a, R1 ; Save received bit in R1
rlc a
mov R1, a
clr MY_SCLK
djnz R2, DO_SPI_G_LOOP
ret

; Configure the serial port and baud rate
InitSerialPort:
    ; Since the reset button bounces, we need to wait a bit before
    ; sending messages, otherwise we risk displaying gibberish!
    mov R1, #222
    mov R0, #166
    djnz R0, $   ; 3 cycles->3*45.21123ns*166=22.51519us
    djnz R1, $-4 ; 22.51519us*222=4.998ms
    ; Now we can proceed with the configuration
	orl	PCON,#0x80
	mov	SCON,#0x52
	mov	BDRCON,#0x00
	mov	BRL,#BRG_VAL
	mov	BDRCON,#0x1E ; BDRCON=BRR|TBCK|RBCK|SPD;
    ret

; Send a character using the serial port
putchar:
    jnb TI, putchar
    clr TI
    mov SBUF, a
    ret

; Send a constant-zero-terminated string using the serial port
SendString:
    clr A
    movc A, @A+DPTR
    jz SendStringDone
    lcall putchar
    inc DPTR
    sjmp SendString
SendStringDone:
    ret
 
new_line:
    DB  '\r', '\n', 0

MainProgram:


    mov SP, #7FH ; Set the stack pointer to the begining of idata
    
    ;--------------setting timer-----------------------
    lcall Timer0_Init
    lcall Timer2_Init
    ; In case you decide to use the pins of P0, configure the port in bidirectional mode:
    mov P0M0, #0
    mov P0M1, #0
    setb EA   ; Enable Global interrupts
    lcall LCD_4BIT
    
    setb EX1
    clr TCON.2
    clr ES ; cleared es
    ; For convenience a few handy macros are included in 'LCD_4bit.inc':
	;setb TR2
	setb TR2
	clr TR0
    setb half_seconds_flag
	setb on_off
	mov a, #0h
	da a
	mov temppppp, a
    ;--------------------------------------------------
    setb CE_ADC
    lcall InitSerialPort
    lcall INI_SPI
    
    mov alarm_temp, #30h
    ;Set_Cursor(1, 1)
	;Send_Constant_String(#initial)
	;Set_Cursor(2, 1)
	;Display_BCD(alarm_temp)
	;Set_Cursor(2, 4)
	;Send_Constant_String(#cc)
    
Forever:
	Set_Cursor(2, 8)
	Display_BCD(#temppppp)

begin:
	;clr CE_ADC
	;mov R0, #00000001B ; Start bit:1
	;lcall DO_SPI_G
	;mov R0, #10000000B ; Single ended, read  0
	;lcall DO_SPI_G
	;mov a, R1 ; R1 contains bits 8 and 9
	;anl a, #00000011B ; We need only the two least significant bits
	;mov Result+1, a ; Save result high.
	;mov R0, #55H ; It doesn't matter what we transmit...
	;lcall DO_SPI_G
	;mov Result, R1 ; R1 contains bits 0 to 7. Save result low.
	;setb CE_ADC
	;--------------------------------------------------------
	;clr CE_ADC
	;mov R0, #00000001B ; Start bit:1
	;lcall DO_SPI_G
	;mov R0, #10000000B ; Single ended, read  1
	;lcall DO_SPI_G
	;mov a, R1 ; R1 contains bits 8 and 9
	;anl a, #00000011B ; We need only the two least significant bits
	;mov temp_volt+1, a ; Save result high.
	;mov R0, #55H ; It doesn't matter what we transmit...
	;lcall DO_SPI_G
	;mov temp_volt, R1 ; R1 contains bits 0 to 7. Save result low.
	;--------------------------------------------------------
	;setb CE_ADC
	;lcall getchar
	Read_ADC_Channel(0)
	
	da a
	mov temppppp, a
	lcall wait
	;lcall print_data
	lcall temperature_call
	mov DPTR, #new_line
    lcall SendString
    
loop_a:
	jnb half_seconds_flag, Forever_jmp
loop_b:
    clr half_seconds_flag ; We clear this flag in the main loop, but it is set in the ISR for timer 2
Forever_jmp:
	ljmp Forever
	
    

    
    sjmp $ ; This is equivalent to 'forever: sjmp forever'
temperature_call:
	mov x+0, Result
	mov x+1, Result+1
	mov x+2, #0  
	mov x+3, #0

	Load_y(410)
	lcall mul32
	Load_y(1023)
	lcall div32
	
;	Load_y(1000000)
;	lcall mul32
	Load_y(150)
	lcall mul32
;
;	Load_y(8200)
;	lcall div32
;

;	Load_y(100)
;	lcall div32

	
	Load_y(2200)
	lcall add32
	
	
	load_y(100)
	lcall div32
	
	
	lcall hex2bcd
;	Send_BCD(bcd+3)
;	Send_BCD(bcd+2)
	Send_BCD(bcd+1)
	Send_BCD(bcd)



	ret   
print_data:
	mov x+0, Result
	mov x+1, Result+1
	mov x+2, #0h
	mov x+3, #0h

	Load_y(410)
	lcall mul32
	Load_y(1023)
	lcall div32
	Load_y(273)
	lcall sub32
	
	lcall hex2bcd
	Send_BCD(bcd)

    ret
    
    
wait:
	push AR0
	push AR1
	push AR2
	mov R2, #100
L33: mov R1, #250
L22: mov R0, #166
L11: djnz R0, L11 ; 3 cycles->3*45.21123ns*166=22.51519us
 	djnz R1, L22 ; 22.51519us*250=5.629ms
 	djnz R2, L33 ; 5.629ms*89=0.5s (approximately)
 	
 	pop AR2
 	pop AR1
 	pop AR0
 	
 	ret
 	
 	
setting_up:
	push acc
	push psw
start:
	jb add_alarm, sub_sub  ; if the 'BOOT' button is not pressed skip
	Wait_Milli_Seconds(#50)	; Debounce delay.  This macro is also in 'LCD_4bit.inc'
	jb add_alarm, sub_sub  ; if the 'BOOT' button is not pressed skip
	jnb add_alarm, $
	mov a, alarm_temp
	cjne a, #99h, not_full
	mov a, #0h
	sjmp full
not_full:
	add a, #0x01
full:
	da a
	mov alarm_temp, a
	sjmp display
	
	
sub_sub:
    jb sub_alarm, display  ; if the 'BOOT' button is not pressed skip
	Wait_Milli_Seconds(#50)	; Debounce delay.  This macro is also in 'LCD_4bit.inc'
	jb sub_alarm, display  ; if the 'BOOT' button is not pressed skip
	jnb sub_alarm, $
	mov a, alarm_temp
	cjne a, #0h, not_zero
	mov a, #99h
	sjmp zero
not_zero:
	add a, #0x99
zero:
	da a
	mov alarm_temp, a
	
	
display:
	;mov a, alarm_temp
	;da a
	;mov alarm_temp_temp, a
	Set_Cursor(2, 1)
	Send_Constant_String(#Blank)	
	Set_Cursor(2, 1)     ; the place in the LCD where we want the BCD counter value
	Display_BCD(alarm_temp)
	Wait_Milli_Seconds(#100)
	jb exit, start  ; if the 'BOOT' button is not pressed skip
	Wait_Milli_Seconds(#50)	; Debounce delay.  This macro is also in 'LCD_4bit.inc'
	jb exit, start_jmp  ; if the 'BOOT' button is not pressed skip
	jnb exit, $

	sjmp return
	
start_jmp:
ljmp start

return:
	pop psw 
	pop acc
reti




ASCIItoHEX:
	setb	ACC.5				; Strip case, lower case ascii 
	subb	a,#0x57				; value a - f will not carry
	jnc	ASCIIDone			; if not carry then we have converted the nibble
	add	a,#0x27				; Convert back to 0 - 9
ASCIIDone:
	ret
	
	
	
getchar:
	jnb RI, getchar
	clr RI
	mov a, SBUF
	ret
	

 	
END

GeString:
	mov R3, #buffer
GSLoop:
	lcall getchar
	push acc
	clr c
	subb a, #10H
	pop acc
	jc GSDone
	MOV @R0, A
	inc R3
	SJMP GSLoop
GSDone:
	clr a
	mov @R0, a
	ret