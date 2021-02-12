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
testinf equ p2.5
;----------------------------------------
extra_starts_at EQU 0xEC
;-------------------------------------------
CSEG
CE_ADC EQU P2.0
MY_MOSI EQU P2.1
MY_MISO EQU P2.2
MY_SCLK EQU P2.3 
SEGA equ P0.3
SEGB equ P0.5
SEGC equ P0.7
SEGD equ P4.4
SEGE equ P4.5
SEGF equ P0.4
SEGG equ P0.6
SEGP equ P2.7
CA1  equ P0.2
CA2  equ P0.0
CA3  equ P0.1
oven EQU P2.6
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
temperature: ds 2
temperature1: ds 2
temppppp:ds 1
time_mod: ds 1
Disp1:  ds 1 
Disp2:  ds 1
Disp3:  ds 1
state:  ds 1
statepvm: ds 1
x_counter: ds 1
count1s: ds 1
pwm: ds 1
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
HEX_7SEG: DB 0xC0, 0xF9, 0xA4, 0xB0, 0x99, 0x92, 0x82, 0xF8, 0x80, 0x90	
;---------------------------------;
; Routine to initialize the ISR   ;
; for timer 0                     ;
;---------------------------------;


serial_int:
	jnb RI, done
	clr RI
	;mov signal, sbuf
	;hex_ascii(signal)    ;got from online, could be wrong 
	;cjne a, #0x01, done
	cpl testinf 

done:

	
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
	mov Count1s, a
	mov Count1s, a
	; Enable the timer and interrupts
    setb ET2  ; Enable timer 2 interrupt
    setb TR2  ; Enable timer 2
	ret
; Pattern to load passed in accumulator
load_segments:
	mov c, acc.0
	mov SEGA, c
	mov c, acc.1
	mov SEGB, c
	mov c, acc.2
	mov SEGC, c
	mov c, acc.3
	mov SEGD, c
	mov c, acc.4
	mov SEGE, c
	mov c, acc.5
	mov SEGF, c
	mov c, acc.6
	mov SEGG, c
	mov c, acc.7
	mov SEGP, c
	ret
Timer2_ISR:
	clr TF2  ; Timer 2 doesn't clear TF2 automatically. Do it in ISR
	
	; The two registers used in the ISR must be saved in the stack
	push acc
	push psw
	
	;jnb beep_flag, inc_count
	;clr beep_flag
	; Increment the 16-bit one mili second counter
	
;;;  State machine for 7-segment displays starts here
	; Turn all displays off
	setb CA1
	setb CA2
	setb CA3

	mov a, state
state0:
	cjne a, #0, state1
	mov a, disp1
	lcall load_segments
	clr CA1
	inc state
	sjmp state_done
state1:
	cjne a, #1, state2
	mov a, disp2
	lcall load_segments
	clr CA2
	inc state
	sjmp state_done
state2:
	cjne a, #2, state_reset
	mov a, disp3
	lcall load_segments
	clr CA3
	mov state, #0
	sjmp state_done
state_reset:
	mov state, #0
state_done:
;;;  State machine for 7-segment displays ends here	
	
	
	inc x_counter
	clr c
	mov a, x_counter
	subb a, pwm
	jnc jmp_yo_mama
	setb oven ;switched arleady
	sjmp inc_count
jmp_yo_mama:

	clr oven ;switched already
	sjmp inc_count
inc_count:
	inc Count1ms+0    ; Increment the low 8-bits first
	mov a, Count1ms+0 ; If the low 8-bits overflow, then increment high 8-bits
	jnz Inc_Done
	inc Count1ms+1
Inc_Done:
	; Check if half second has passed
	mov a, Count1ms+0
	
	cjne a, #low(1000), timerjump ; Warning: this instruction changes the carry flag!
	mov a, Count1ms+1
	cjne a, #high(1000), timerjump
	sjmp jumpioverjump
timerjump:
	ljmp timer2_isr_done
jumpioverjump:	
	
	
	
	; 500 milliseconds have passed.  Set a flag so the main program knows4
	setb half_seconds_flag ; Let the main program know half second had passed
	mov a, count1s
	add a, #0x01
	da a
	mov count1s, a
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
	
;state machine control	
    
	
	
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
      mov AUXR, #00010001B 
    setb EA   ; Enable Global interrupts
    lcall LCD_4BIT
    setb ES
    setb EX1
    clr TCON.2
    clr ES ; cleared es
    ; For convenience a few handy macros are included in 'LCD_4bit.inc':
	;setb TR2
	setb TR2
	clr TR0
    setb half_seconds_flag
	setb on_off
	mov p1m1, #0
	mov a, #0h
	da a
	mov temppppp, a
	mov x_counter, #0x0
    ;--------------------------------------------------
    setb CE_ADC
    lcall InitSerialPort
    lcall INI_SPI
    mov state, #0
    mov alarm_temp, #30h
    ;Set_Cursor(1, 1)
	;Send_Constant_String(#initial)
	;Set_Cursor(2, 1)
	;Display_BCD(alarm_temp)
	;Set_Cursor(2, 4)
	;Send_Constant_String(#cc)

mov state, #0
mov statepvm, #0

	
	; After initialization the program stays in this 'forever' loop
	
Forever:
	Set_Cursor(2, 8)
	Display_BCD(#temppppp)

	set_Cursor(1,2)
	Display_BCD(statepvm)
	set_Cursor(1,4)
	Display_BCD(count1s)
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
	mov dptr, #HEX_7SEG
	
	mov a, temperature
	anl a, #0x0f
	movc a, @a+dptr
	mov disp1, a
	
	mov a, temperature
	swap a
	anl a, #0x0f
	movc a, @a+dptr
	mov disp2, a

	mov a,temperature+1

	anl a, #0x0f
	movc a, @a+dptr
	mov disp3, a
	mov DPTR, #new_line
    lcall SendString

    
loop_a:
	jnb half_seconds_flag, Forever_jmp

loop_b:
    clr half_seconds_flag ; We clear this flag in the main loop, but it is set in the ISR for timer 2
    mov a, statepvm
    sjmp statepvm0
Forever_jmp:
	ljmp Forever
	
statepvm0:
	cjne a, #0, statepvm1
	mov pwm, #0 
	jb off, statepvm0_done
	jnb off, $ ;wait for key release
	mov statepvm, #1
statepvm0_done:
ljmp ffjmp
statepvm1:
	cjne a, #1, statepvm2
	mov pwm, #255; 100% power
;	mov count1s, #0
;	mov a, #150 ;temp at 70 ;see what happens
	clr c
;	subb a, temperature1
	
	clr mf
	
	load_x(150)
	mov y, low(temperature1)
	mov y+1, high(temperature1+1)
	mov y+2, #0
	mov y+3, #0
	lcall x_gt_y
	jb mf, statepvm1_done
	
;	jnc statepvm1_done
	mov statepvm, #2
statepvm1_done:
	sjmp ffjmp
statepvm2:
	cjne a,#2,statepvm3
	clr c	
	mov pwm, #10
	mov a, #60
	da a
	subb a, count1s  ;tier
	jnc statepvm2_done
;	sjmp stage2done
 	;fix this later
;	mov a, temperature1
;	subb a, #80
;	jnc DontAbbort
;	sjmp ffjmp
;DontAbbort:	
;	mov a,#96
;	clr c
;	subb a,count1s
;	jnc statepvm2_done
stage2done:
	mov statepvm, #3
statepvm2_done:
	sjmp ffjmp
statepvm3:	
	cjne a, #3, statepvm4
	mov pwm, #255; 100% power
	mov count1s, #0
	clr mf
	
	load_x(220)
	mov y, low(temperature1)
	mov y+1, high(temperature1+1)
	mov y+2, #0
	mov y+3, #0
	lcall x_gt_y
	jb mf, statepvm3_done 
	;mov a,  #high(190);see what happens ???? some temperature 120? around there
	;cjne a, temperature1+1, statepvm3_done
	;mov a, #low(190)
	;cjne a , temperature1, statepvm3_done
	mov statepvm, #4
statepvm3_done: 
	sjmp ffjmp
statepvm4:
	cjne a,#4, statepvm5
	
	mov pwm,#10
	mov a,#0x45
	da a
	clr c
	subb a, count1s
	jnc statepvm4_done
	mov statepvm, #5
statepvm4_done:
	sjmp ffjmp
statepvm5: 
	cjne a,#5, state_abort
	mov pwm, #0
	mov a, #0x60
	da a
	mov count1s,#0h
	clr c 
	subb a,temperature1
	jc statepvm5_done
	mov statepvm,#0
statepvm5_done:
	sjmp ffjmp
	
state_abort:
	mov pwm, #0
	mov statepvm, #0
ffjmp:
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
	mov temperature1+0, x+0
	mov temperature1+1, x+1
	lcall hex2bcd
mov temperature, bcd
mov temperature+1, bcd+1


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