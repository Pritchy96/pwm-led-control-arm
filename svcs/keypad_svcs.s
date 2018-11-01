;----------------------------------------------------------------------------------
;  Keypad SVC Table Handler
;  T. Pritchard
;  Created: February 2017
;  Last Updated: 11 May 2017
;
;  Handles all external keypad related SVC instructions.
;  Checks bits 0-1 of R0 in order to get the instruction code for this subset.
;
;  Known Bugs: None.
;----------------------------------------------------------------------------------

keypad_area              EQU     &20000000
keypad_data              EQU     &2
keypad_control           EQU     &3     ;Offsets kept within sub-tables in order to aid modularity.
keypad_wait_time         EQU     &0F    ;Time to wait before allowing another key press.

;----------------------------------------------------------------------------------
;  Selects the instruction specific to this table
;  R0 = SVC selector
;----------------------------------------------------------------------------------
keypad_svcs
        CMP R0, #&00                    ;get button states.
        BLEQ init_keypad

        CMP R0, #&01
        BLEQ read_keypad

                                        ;If no valid code found, should probably error.
        B svc_return                    ;End of SVC call, return to user program.

;----------------------------------------------------------------------------------
;  Sets up keypad, mostly using the control register
;  Registers:
;  R0 = Keypad area for offsetting
;  R1 = Loading and Storing keypad control.
;----------------------------------------------------------------------------------
init_keypad
        MOV  R0, #keypad_area
        LDRB  R1, [R0, #keypad_control]
        BIC R1, R1, #&E0                ;Clear bit 5-7
        ORR R1, R1, #&0F                ;Set rows (0-3) to be inputs.
        STRB R1, [R0, #keypad_control]

        MOV PC, LR                      ;Return back to the table so we can drop back into user program.

;----------------------------------------------------------------------------------
;  Checks to see if we want to display a digit.
;  Registers:
;  R0 = Last keyboard key pressed,
;  R2 = Loaded keyboard data
;  R4 = Index offset, not used in this method.
;  R12, svc return, used in this method only if there is nothing pressed.
;----------------------------------------------------------------------------------
handle_interrupt
        LDR R0, keypad_last_key
        CMP R0, R2                      ;Is this the same key as was pressed last time?
        BNE convert_keypad_char         ;A new key has been pressed, display it reguardless of wait timer.


        LDR R0, keypad_timer
        MOV  R1, #timer_interval
        ADD R0, R0, R1                  ;Add how long we have waited..

        MOV  R1, #keypad_wait_time
        CMP R0, R1
        BGT convert_keypad_char         ;We've waited long enough since the last keypress, display it.

        ADR R1, keypad_timer
        STR R0, [R1]

        MOV R1, #0
        ADRL R0, keypad_storage
        STRB R1, [R0, #0]
        MOV PC, LR


;----------------------------------------------------------------------------------
;  Checks to see if a digit is pressed in.
;  Registers:
;  R0 = Holds keyboard location for offsetting.
;  R1 = Storing keyboard data.
;  R2 = Loaded keyboard data
;  R3 = Bit cleared to check for high columns.
;  R4 = Index offset.
;  R12, svc return, used in this method only if there is nothing pressed.
;----------------------------------------------------------------------------------
read_keypad
        MOV  R0, #keypad_area
        MOV R4, #0

        LDRB  R1, [R0, #keypad_data]
        BIC R1, R1, #&E0                ;Clear bit 5-7
        ORR R1, R1, #&80                ;Set column 7 high
        STRB R1, [R0, #keypad_data]     ;Store this back so we can read whether a row is high.
        LDRB  R2, [R0, #keypad_data]    ;Load it back, to check rows.

        BIC R2, R2, #&10                ;We don't care about bit 4?
        BIC R3, R2, #&F0                ;Remove all data that isn't whether a key is down or not (but keep it in R1)
        CMP R3, #0                      ;Do checking to see whether any row is high here.
        BNE handle_interrupt

        ADD R4, R4, #4                  ;We're on the next column so offset the jump table index.
        BIC R1, R1, #&E0                ;Clear bit 5-7
        ORR R1, R1, #&40                ;Set Column 6 high
        STRB R1, [R0, #keypad_data]     ;Store this back so we can read whether a row is high.
        LDRB  R2, [R0, #keypad_data]    ;Load it back, to check rows.

        BIC R2, R2, #&10                ;We don't care about bit 4?
        BIC R3, R2, #&F0                ;Remove all data that isn't whether a key is down or not (but keep it in R1)
        CMP R3, #0                      ;Do checking to see whether any row is high here.
        BNE handle_interrupt

        ADD R4, R4, #4                  ;We're on the next column so offset the jump table index.
        BIC R1, R1, #&E0                ;Clear bit 5-7
        ORR R1, R1, #&20                ;Set Column 5 high
        STRB R1, [R0, #keypad_data]     ;Store this back so we can read whether a row is high.
        LDRB  R2, [R0, #keypad_data]    ;Load it back, to check rows.

        BIC R2, R2, #&10                ;We don't care about bit 4?
        BIC R3, R2, #&F0                ;Remove all data that isn't whether a key is down or not (but keep it in R1)
        CMP R3, #0                      ;Do checking to see whether any row is high here.
        BNE handle_interrupt

        BIC R1, R1, #&E0                ;Clear bit 5-7
        STRB R1, [R0, #keypad_data]     ;Store this back.

        MOV R0, #0
        ADR R1, keypad_last_key
        STR R0, [R1]                    ;Nothing is being displayed, so unset key down.

        MOV R12, #0                     ;Nothing pressed, return 0.
        MOV PC, LR                      ;Return back to the table so we can drop back into user program.


;----------------------------------------------------------------------------------
;  Converts the matrix position of the keypad to an index in the keypad_table
;  Registers:
;  R0 = Clear keypad timer, row data for checking what is high.
;  R1 = Storing keyboard data.
;  R2 = Loaded keyboard data
;  R4 = Index offset.
;----------------------------------------------------------------------------------
convert_keypad_char
        MOV R0, #0
        ADR R1, keypad_timer
        STR R0, [R1]                    ;We've displayed something, restart the bouncing timer.

        ADR R1, keypad_last_key
        STR R2, [R1]                    ;Save the last displayed key,

        BIC R0, R2, #&F0                ;Remove all data that isn't row related.

        TEQ R0, #&1
        BEQ return_key

        ADD R4, R4, #1                 ;Add one to index.
        TEQ R0, #&2                    ;Check if high
        BEQ return_key                 ;If it is, index is now at the right position in table.

        ADD R4, R4, #1
        TEQ R0, #&4
        BEQ return_key

        ADD R4, R4, #1
        B return_key                    ;No need to test, it must be this


;----------------------------------------------------------------------------------
;  Simply returns the value of keypad_table[R4].
;  Registers:
;  R0 = Load keypad table address.
;  R1 = keypad value, ready to be saved.
;  R2 = Area in memory of the keypad storage.
;----------------------------------------------------------------------------------
return_key
        ADR R0, keypad_table
        LDRB R1, [R0, R4]
        ADRL R0, keypad_storage
        STRB R1, [R0, #0]
        MOV PC, LR


keypad_table    DEFB    &31, &34, &37, &2A, &32, &35, &38, &30, &33, &36, &39, &23
keypad_timer    DEFW    &0
keypad_last_key DEFW    &0
