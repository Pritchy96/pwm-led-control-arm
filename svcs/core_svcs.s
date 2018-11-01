;----------------------------------------------------------------------------------
;  Core System SVC Table Handler
;  T. Pritchard
;  Created: February 2017
;  Last Updated: 22 March 2017
;
;  Handles all core system SVC instructions.
;  Checks bits 0-1 of R0 in order to get the instruction code for this subset.
;
;  Known Bugs: None.
;----------------------------------------------------------------------------------

;----------------------------------------------------------------------------------
;  Selects the instruction specific to this table
;
;  Register usage.
;  R0 = Sub table SVC selector.
;----------------------------------------------------------------------------------
core_svcs
        ;CMP R0, #&00           ;reset program execution.
        ;B reset                ;TODO: This will never work!
        CMP R0, #&01            ;halt program execution (endless loop in supervisor mode.)
        BLEQ halt
;        CMP R0, #&02
;        BLEQ set_irq_enable
;        CMP R0, #03
;        BLEQ set_fiq_enable

                                ;If no valid code found, should probably error.
        B svc_return            ;End of SVC call, return to user program.


;These are currently not used as the concept of user disabling interrupts makes me feel vaguely uneasy.
;----------------------------------------------------------------------------------
;  Sets the IRQ enable bit (7) in the CPSR to R11 (SVC param)
;
;  Register usage.
;  R0 = Load/Save CPSR.
;----------------------------------------------------------------------------------
;set_irq_enable
;        MRS R0, CPSR
;        BIC R0, R0, #&40
;        ORR R0, R0, #&40        ;TODO: these only disable, not enable!
;        MSR CPSR_c, R0
;        MOV PC, LR              ;Move back to sending method.

;----------------------------------------------------------------------------------
;  Sets the FIQ enable bit (6) in the CPSR to R11 (SVC param)
;
;  Register usage.
;  R0 = Load/Save CPSR.
;----------------------------------------------------------------------------------
;set_fiq_enable
;        MRS R0, CPSR
;        BIC R0, R0, #&20
;        ORR R0, R0, #&20
;        MSR CPSR_c, R0
;        MOV PC, LR              ;Move back to sending method.
