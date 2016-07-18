; PIC16F88 LED nametag
; Version 0.1 Copyright (c) 2016 Jonathan Chapman
; http://www.glitchwrks.com
;
; See LICENSE included in the project root for licensing information.

; PIC16F88 Configuration Bit Settings

#include <p16f88.inc>

 __CONFIG _CONFIG1, _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _WRT_OFF & _CCPMX_RB0 & _CP_OFF
 __CONFIG _CONFIG2, _FCMEN_ON & _IESO_ON

    ORG 0
    goto MAIN

    ORG 8
    goto UPDATE

; Variable declarations
    cblock  0x20
        digitptr                    ; Display address
        eeptr                       ; EEPROM pointer
        eeptr_tmp                   ; Temporary copy of eeptr
        W_temp                      ; Temporary storage for ISR
        S_temp
    endc

DIGITS  EQU     d'8'                ; Number of digits we can write to

MAIN:   movlw   B'00100110'         ; Set up the internal oscillator
        banksel OSCCON
        movwf   OSCCON

        movlw   B'11100000'         ; Set up interrupts and TIMER0
        movwf   INTCON
        movlw   B'00000110'
        movwf   OPTION_REG

        banksel TRISA               ; PORTA, PORTB output
        clrf    TRISA
        clrf    TRISB

        banksel 0
        movlw   B'10000000'         ; Turn of display /WR
        movwf   PORTA

        clrf    eeptr

NOPPER: goto    NOPPER

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; UPDATE - Update the ASCII displays
;
; This routine handles display update and scrolling under the control of TIMER0.
; A NULL-terminated string is read from EEPROM starting at 0x00 and written out
; to the LED display. The EEPROM starting pointer is incremented, and wrapped
; back to 0x00 if we hit the NULL byte. TIMER0 is then reset.
;
; pre:  TIMER0 is configured to cause an interrupt
;       EEPROM contains a NULL-terminated string at 0x00
;       DIGITS is initialized to the number of digits in the display
;       'eeptr' points to the first character in EEPROM to display
; post: Current window of EEPROM string is displayed
;       'eeptr' is incremented or reset to 0x00
;       TIMER0 is re-initialized and its interrupt enabled
;       Interrupts are enabled
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
UPDATE: movwf   W_temp              ; Save W, S
        movf    STATUS, W
        movwf   S_temp

        movf    eeptr, W            ; Save EEPROM pointer
        movwf   eeptr_tmp

        movlw   DIGITS              ; Loop DIGITS - 1 times
        movwf   digitptr
UPDAT1: decf    digitptr
        call    NEXTEE              ; Get next EEPROM character
        call    OUTCHR              ; Display it
        movf    digitptr
        btfss   STATUS, Z           ; charptr == 0 ? done : continue
        goto    UPDAT1
        bsf     PORTA, 6            ; Turn off display blanking

        incf    eeptr_tmp, W        ; Here we actually implement scrolling --
        movwf   eeptr               ; set up eeptr so that we're starting at
        call    EEREAD              ; eeptr++ next time.
        btfsc   STATUS, Z           ; But reset eeptr to 0 if we detect we're
        clrf    eeptr               ; at the end of the string in EEPROM

        clrf    TMR0
        bcf     INTCON, TMR0IF      ; Clear timer interrupt

        movf    W_temp, W           ; Restore W, S
        movf    S_temp, W
        retfie

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; OUTCHR - Output the character in W to the display
;
; pre:  W register contains character to be output
;       'digitptr' contains the display digit to output to
; post: Character is output to display
;       Display /WR line is de-asserted
;       Display blanking turned on (digits off)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
OUTCHR: movwf   PORTB
        movf    digitptr, W
        bsf     W, 7
        movwf   PORTA
        movf    digitptr, W
        movwf   PORTA
        bsf     PORTA, 7
        return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; NEXTEE -- Get the next character from EEPROM
;
; This routine implements a circular array using data EEPROM. When a NULL 0x00
; is found in EEPROM, the character returned will be in the 0th position of the
; EEPROM.
;
; pre:  'eeptr' contains the EEPROM address of the next character to read
;       Data EEPROM contains a NULL-terminated string
; post: Next character from data EEPROM is in W register
;       'eeptr' has been incremented or reset to 0x00
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
NEXTEE: movf    eeptr, W
        call    EEREAD
        btfss   STATUS, Z
        goto    NEXTE1
        clrf    eeptr
        goto    NEXTEE
NEXTE1: incf    eeptr
        return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EEREAD - Read a byte from data EEPROM
;
; pre:  W register contains address of byte to read from EEPROM
; post: W register contains the byte specified
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
EEREAD: 
        banksel EEADR
        movwf   EEADR
        banksel EECON1
        bcf     EECON1, EEPGD
        bsf     EECON1, RD
        banksel EEDATA
        movf    EEDATA, W
        banksel 0
        return

        ; NULL-terminated message string in EEPROM
        org 0x2100
        de "HI, MY NAME IS GLITCH *** ", 0
    end