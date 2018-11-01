;----------------------------------------------------------------------------------
;  LED SVC Table Handler
;  T. Pritchard
;  Created: April 2017
;  Last Updated: 11 May 2017
;
;  Handles all LED related SVC instructions.
;  Checks bits 0-1 of R0 in order to get the instruction code for this subset.
;
;  Known Bugs: None.
;
;  Register usage for instruction selection (functions may be different)
;  R0 = Sub table SVC selector.
;  R1 = Port area for offsetting.
;  R2 = Value to push to lcd to switch LCD backlight on.
;  R11 = SVC Parameter.
;
;
;  Register usage for printing methods
;  R0 = Port Area
;  R1 = R11 Stoarge for print_hex_4
;  R2 = General Purpose port register for print_char.
;  R3 = Port A reading (waiting for idle)
;  R11 = SVC Parameter.
;----------------------------------------------------------------------------------

;Offsets kept within sub-tables in order to aid modularity.
led_port  EQU   &0


;----------------------------------------------------------------------------------
;  Selects the instruction specific to this table.
;----------------------------------------------------------------------------------
led_svcs
        CMP  R0, #&00                   ;Send control signal to LCD.
        BLEQ update_led
        CMP  R0, #&01                   ;Send control signal to LCD.
        BLEQ set_brightness
        CMP  R0, #&02                   ;Send control signal to LCD.
        BLEQ get_brightness
                                        ;If no valid code found, should probably error.
        B    svc_return                 ;End of SVC call, return to user program.


;----------------------------------------------------------------------------------
;  updates the value of the LED, on or off.
;----------------------------------------------------------------------------------
update_led
        ;Read in the PWM Value
        MOV R0, #fpga_area
        LDRB R3, [R0, #&4]

        MOV  R1, #port_area             ;For accessing IO
        CMP R3, #&1
        BEQ set_high
        MOV  R2, #&00                   ;Switch on all LED's
        STRB R2, [R1, #led_port]        ;offset to get to LED control section.
        MOV  PC, LR                     ;Move back to sending method.
        set_high
        MOV  R2, R11                    ;Switch on all LED's
        STRB R2, [R1, #led_port]        ;offset to get to LED control section.
        MOV  PC, LR                     ;Move back to sending method.

;----------------------------------------------------------------------------------
;  Store the LED brightness level in memory.
;----------------------------------------------------------------------------------
set_brightness
        MOV R0, #fpga_area
        STRB R11, [R0, #&5]
        MOV  PC, LR                     ;Move back to sending method.

;----------------------------------------------------------------------------------
;  Get the LED brightness level in memory.
;----------------------------------------------------------------------------------
get_brightness
        MOV R0, #fpga_area
        LDRB R12, [R0, #&5]
        MOV  PC, LR                     ;Move back to sending method.
