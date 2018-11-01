;----------------------------------------------------------------------------------
;  Interrupt Handler
;  T. Pritchard
;  Created: March 2017
;  Last Updated: 11 May 2017
;
;  Handles all interrupt calls.
;
;  Known Bugs: None.
;
;  Register usage:
;  R0-R6: Pushed and used for handling stuff.
;----------------------------------------------------------------------------------


fiq_handler                     ;This is never actually branched to, but eh, formatting
        PUSH {R0 - R6, LR}
        ;do FIQ stuff here.
        b interrupt_return

;----------------------------------------------------------------------------------
;  Handles any IRQ interrupt.
;  Registers:
;  R0 = Port area
;  R1 = interrupt bits
;  R2 = interrupt enable (probably not needed)
;----------------------------------------------------------------------------------
irq_handler
        PUSH {R0 - R6, LR}
        MOV   R0, #port_area    ;For accessing IO

        LDRB R1, [R0, #&18]     ;Interrupt bits
        LDRB R2, [R0, #&1C]     ;Interrupt enable

        AND R1, R1, R2          ;We only care about any given bit if both the enable and the interrupt bit is high.

        CMP R1, #1              ;TODO: Use TST/jump table.
        BLEQ timer_interrupt

        B interrupt_return

;----------------------------------------------------------------------------------
;  Handles a timer interrupt, checking for keyboard output, and prints it to the LCD.
;  Registers:
;  R0 = Port area
;  R1 = load and store timer wait time.
;  R2 = interrupt enable (probably not needed)
;----------------------------------------------------------------------------------
timer_interrupt
        MOV   R0, #port_area    ;For accessing IO

        LDRB R1, [R0, #&8]      ;Get timer compare register.
        ADD R1, R1, #&3
        STRB R1, [R0, #&C]      ;Set timer compare register to a smaller value.

        SVC &0401               ;Get keyboard output (R12)


        MOV PC, LR;

;----------------------------------------------------------------------------------
;  Called by all SVC instructions to pop registers and return to the program.
;----------------------------------------------------------------------------------
interrupt_return
        POP {R0 - R6, LR}

        SUBS PC, LR, #4         ;Return to the user program.
