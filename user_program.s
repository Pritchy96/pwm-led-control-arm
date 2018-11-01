;----------------------------------------------------------------------------------
;  Stopwatch Program
;  T. Pritchard
;  Created: February 2017
;  Last Updated: 11 May 2017
;
;  This is the main file for the user program. It intialises the keypad and then
;
;  Keypad Values 0-9 select LEDs, * decreases the LED brightness, and # increases it.
;  0 turns off all LED's, 9 selects them all.
;
;  Known Bugs: None.
;
;  Register usage.
;  R0  = Port Area.
;  R1  = Keypad Value.
;  R2  = LED Selection.
;  R3  = LED Brightness.
;  R11 = SVC parameter.
;  R12 = SVC return.
;----------------------------------------------------------------------------------

;----------------------------------------------------------------------------------
;  Initialises Backlight then branches into the main program loop.
;----------------------------------------------------------------------------------
begin_user_program
        MOV  R0, #port_area             ;KEEP R0 = port area for duration.
        SVC &0400                       ;Initialise keypad.
        B main_loop


;----------------------------------------------------------------------------------
;  The main program loop. Updates the PWM value of the LED, polls the keypad storage
;  and calls SVC instructions to set the relevant LED values.
;----------------------------------------------------------------------------------
main_loop
        MOV R11, R2                     ;Put LED selection in SVC parameter (R11)
        SVC &0500                       ;Update LED PWM.

        MOV R1, #keypad_storage         ;Get keypad value.
        LDRB R1, [R1, #0]

        CMP R1, #0
        BEQ main_loop                   ;Skip if nothing is held down.

        CMP R1, #&23                    ;&23 = * key
                BEQ inc_brightness

        CMP R1, #&2A                    ;&2A = # key
                BEQ dec_brightness

        SUB R1, R1, #&30                ;Convert to 1-8
        ADR R0, led_table               ;Convert from binary to a one hot representation for the LEDs
        LDRB R2, [R0, R1]

        B main_loop

;----------------------------------------------------------------------------------
;  Increment the PWM threshold value, ensure it won't overflow (0-FF), and then
;  SVC call to send the new value to the PWM generator.
;----------------------------------------------------------------------------------
inc_brightness
        ADD R3, R3, #&1

        CMP R3, #&FF
        MOVGT R3, #&FF                  ;We don't want to go > 255 and overflow the pwm generator.

        MOV R11, R3                     ;Put the PWM threshold value in the svc parameter.
        SVC &0501                       ;Set the threshold.
        B main_loop                     ;Go back to loop.

;----------------------------------------------------------------------------------
;  Decrement the PWM threshold value, ensure it won't underflow (0-FF), and then
;  SVC call to send the new value to the PWM generator.
;----------------------------------------------------------------------------------
dec_brightness
        SUB R3, R3, #&1

        CMP R3, #&0
        MOVLT  R3, #&0                  ;Ensure we don't underflow the PWM generator.

        MOV R11, R3                     ;Put the PWM threshold value in the svc parameter.
        SVC &0501                       ;Set the threshold.
        B main_loop                     ;Go back to loop.


led_table    DEFB    0, 4, 64, 2, 32, 1, 16, 8, 128, &FF        ;Maps 0-9 to the LED one hot representation we need.

ALIGN
