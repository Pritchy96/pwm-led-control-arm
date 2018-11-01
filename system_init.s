;----------------------------------------------------------------------------------
;  System Initialiser
;  T. Pritchard
;  Created: February 2017
;  Last Updated: 11 May 2017
;
;  This file initialises both the supervisor and user modes. It then changes to
;  user mode and branches to the user program included in user_program.s
;
;  Known Bugs: None.
;
;----------------------------------------------------------------------------------

org 0                               ;Exception 'vector' table.
reset
        B init                      ;Reset
        B halt                      ;Undefined?
        B svc_handler               ;SVC Handler
        B halt                      ;Prefetch Abort
        B halt                      ;Data Abort
        NOP                         ;Unused
        B irq_handler               ;IRQ
        B fiq_handler               ;FIQ (We don't branch here, we just go straight into the FIQ below)
        include interrupt_handler.s ;Include here so we can handle FIQ's quickly, no branching (code is dumped straight here.)

                                    ;I/O offsets are kept within each SVC handler to aid modularity.
port_area       EQU     &10000000   ;All I/O addresses are offset from this value.
fpga_area       EQU     &20000000   ;All fpga I/O addresses are offset from this value.
keypad_storage  EQU     &10000
timer_interval  EQU     &03
ALIGN

;----------------------------------------------------------------------------------
;  Initialises all stacks, then branches to user program.
;  Register Usage:
;  R0: port area
;  R1: interrupt enabling, clearing interrupt bits
;----------------------------------------------------------------------------------
init
        ADRL  SP, sup_stack     ;Start in Sup mode, allocate supervisor stack.

        MOV  R0, #port_area     ;For accessing IO
        LDRB  R1, [R0, #&1C]
        ORR R1, R1, #&61        ;Set button and timer interupt enable.
        STRB  R1, [R0, #&1C]

        LDRB R1, [R0, #&18]     ;Clear the Interrupt bits
        BIC R1, R1, #&FF

        STRB R1, [R0, #&18]
        BL init_stacks

        MRS R0, CPSR            ;Change to user mode, begin user program.
        BIC R0, R0, #&1F
        ORR R0, R0, #&10
        MSR CPSR_c, R0
        NOP

        B begin_user_program

halt
        B halt                  ;End user program.


;----------------------------------------------------------------------------------
;  Initialises all stacks.
;  Register Usage:
;  R0: load/store original CPSR.
;  R1: copy of CPSR to modify it to change modes.
;----------------------------------------------------------------------------------
init_stacks
        MRS R0, CPSR

        ADRL  SP, sup_stack

        MOV R1, R0              ;Copy CPSR so we can modify it.
        BIC R1, R1, #&1F        ;Clear mode bits
        ORR R1, R1, #&1F        ;Set mode bits to system
        MSR CPSR_c, R1
        NOP
        ADRL  SP, usr_stack

        MOV R1, R0              ;Copy CPSR so we can modify it.
        BIC R1, R1, #&1F        ;Clear mode bits
        ORR R1, R1, #&12        ;Set mode bits to IRQ
        MSR CPSR_c, R1
        NOP
        ADRL  SP, irq_stack

        MOV R1, R0              ;Copy CPSR so we can modify it.
        BIC R1, R1, #&1F        ;Clear mode bits
        ORR R1, R1, #&11        ;Set mode bits to IRQ
        MSR CPSR_c, R1
        NOP
        ADRL SP, fiq_stack

        BIC R0, R0, #&C0        ;Enable interrupts (low enable).

        MSR CPSR_C, R0          ;Return to super mode.
        NOP

        MOV PC, LR              ;Return to the sys,


include user_program.s
include svc_handler.s

sup_stack EQU &20000            ;Stack memory allocation (supervisor).
usr_stack EQU &21000
irq_stack EQU &22000
fiq_stack EQU &23000
