#include <xc.inc>
Global	Recording, Replay

extrn	LCD_Setup
extrn	Init_piano
extrn	ADC_Setup, Change_Freq
extrn	DAC_Setup, DAC_Int_Hi, Clear_Recording, freq_replay
	
psect	udata_acs   ; reserve data space in access ram
delay_count: ds 1    ; reserve one byte for counter in the delay routine
freq_rollover: ds 1
delay_num:  ds 1
Recording:  ds 1
Replay: ds 1
    	
psect	code, abs	
rst: 	org 0x0
 	goto	setup

int_hi:	
	org	0x0008	; high priority interrpy
	movf	freq_rollover, W, A	; Move freq_rollover to W
	btfsc	Replay, 0, A
	movf	freq_replay, W, A	; Move replay to W if replay mode enabled
	goto	DAC_Int_Hi
	; * Programme FLASH read Setup Code *
setup:	
	bcf	CFGS		; point to Flash program memory  
	bsf	EEPGD		; access Flash program memory
	call	LCD_Setup	
	call	Init_piano
	call	ADC_Setup
	call	DAC_Setup
	setf	TRISC, A    ; all input (control unit for start & stop replay / recording and clear memory) 
	goto	start
	
	; * Main programme **
start: 	
	btfss	Replay, 0, A
	call	Change_Freq		; Stores detected input to W
	movwf	freq_rollover, A	; Move W to freq-rollover
	
	btfsc	PORTC, 0, A      ; If Pin 0 of Port C pressed, set Recording True
	bsf	Recording, 0, A
	
	btfsc	PORTC, 1, A	  ; If Pin 1 of Port C pressed, set Recording False
	bcf	Recording, 0, A
	
	btfsc	PORTC, 2, A      ; If Pin 2 of Port C pressed, Clear Recording
	call	Clear_Recording
	
	btfsc	PORTC, 3, A      ; If Pin 3 of Port C pressed, Set replay True
	call	Replay_Music
	
	btfsc	PORTC, 4, A      ; If Pin 4 of Port C pressed, Set Replay False
	bcf	Replay, 0, A
	

	movlw	0xAA		; Add in some delay to reduce boucing issues
	movwf	delay_num, A

loop:
	movlw	0xFF
	movwf	delay_count, A
	call	delay
	decfsz	delay_num, A
	bra	loop
	
	bra	start
	
	goto	$		; goto current line in code

	; a delay subroutine if you need one, times around loop in delay_count
delay:	decfsz	delay_count, A	; decrement until zero
	bra	delay
	return

Replay_Music:	; Called when RC3 pressed
	bsf	Replay, 0, A
	lfsr	0, 0x200        ; Start memory storage at Bank 2, use FSR0

	return
	
	end	rst