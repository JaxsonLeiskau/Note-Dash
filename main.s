	AREA    FinalProject, CODE, READONLY
        EXPORT  __main

; GPIO and LCD definitions
RS          EQU     0x20    
RW          EQU     0x40    
EN          EQU     0x80    
GPIOA_BASE  EQU     0x40020000
GPIOC_BASE  EQU     0x40020800
GPIOA_IDR   EQU     0x40020010  

__main  PROC
        ; Enable GPIOA and GPIOC clocks
        LDR     r0, =0x40023830
        MOV     r1, #0x00000005
        STR     r1, [r0]   
        ; Configure PA0 and PA1 as inputs
        LDR     r0, =GPIOA_BASE       
        ; Read current MODER value
        LDR     r1, [r0, #0x00]
        ; Clear bits 0-3 (PA0, PA1) to make them inputs
        BIC     r1, r1, #0x0000000F
        ; Set bits for PA5, PA6, PA7 as outputs (LCD control)
        BIC     r1, r1, #0x0000FC00     ; Clear PA5-PA7 bits first
        ORR     r1, r1, #0x00005400     ; Set PA5, PA6, PA7 as outputs
        ; Keep PA13, PA14 in alt function mode
        ORR     r1, r1, #0x28000000
        STR     r1, [r0, #0x00]     
        ; Enable pull-up resistors on PA0 and PA1
        LDR     r1, [r0, #0x0C]     
        BIC     r1, r1, #0x0000000F ; Clear bits 0-3
        ORR     r1, r1, #0x00000005 ; Set pull-up (01 01)
        STR     r1, [r0, #0x0C]      
        ; Configure GPIOC for LCD data
        LDR     r1, =GPIOC_BASE
        LDR     r2, =0x00015555
        STR     r2, [r1, #0x00]      
        LTORG                          
        ; initialize LCD 
        BL      LCDInitCommands       
        ; Load GPIO addresses for LCD usage
        LDR     r0, =GPIOA_BASE
        LDR     r1, =GPIOC_BASE     
        ; Note
        MOV     r2, #0x80       
        BL      LCDCommand
        MOV     r3, #'N'
        BL      LCDData
        MOV     r3, #'o'
        BL      LCDData
        MOV     r3, #'t'
        BL      LCDData
        MOV     r3, #'e'
        BL      LCDData       
        ; Dash
        MOV     r2, #0xC0       
        BL      LCDCommand
        MOV     r3, #'D'
        BL      LCDData
        MOV     r3, #'a'
        BL      LCDData
        MOV     r3, #'s'
        BL      LCDData
        MOV     r3, #'h'
        BL      LCDData

WaitForSensor
        ; Read sensors from PA0 and PA1
        LDR     r2, =GPIOA_IDR
        LDR     r3, [r2]            
        AND     r4, r3, #0x01       ; r4 = sensor 1 
        AND     r5, r3, #0x02       ; r5 = sensor 2       
        ; Check if BOTH sensors are tripped
        CMP     r4, #0
        BNE     WaitForSensor       
        CMP     r5, #0
        BNE     WaitForSensor       
        B       SensorTripped       
        LTORG                       

SensorTripped
        LDR     r2, =GPIOA_IDR
WaitRelease
        LDR     r3, [r2]
        AND     r4, r3, #0x03       
        CMP     r4, #0x03           
        BNE     WaitRelease                
        BL      ShortDelay      
        ; Reload GPIO addresses before clearing
        LDR     r0, =GPIOA_BASE
        LDR     r1, =GPIOC_BASE      
        ; clear the display
        MOV     r2, #0x01
        BL      LCDCommand
        BL      ShortDelay
        B       StartAnimation
StartAnimation
        ; Value 0-15 = active position, 16 = inactive
        MOV     r8, #16         
        MOV     r9, #16         
        MOV     r10, #16        
        MOV     r11, #16        
        MOV     r7, #16         
        MOV     r6, #16             
        ; Tile row assignments (0 = top row, 1 = bottom row)
        LDR     r4, =TileRows
        MOV     r5, #0
        STRB    r5, [r4, #0]   
        MOV     r5, #1
        STRB    r5, [r4, #1]    
        MOV     r5, #0
        STRB    r5, [r4, #2]    
        MOV     r5, #1
        STRB    r5, [r4, #3]    
        MOV     r5, #0
        STRB    r5, [r4, #4]    
        MOV     r5, #1
        STRB    r5, [r4, #5]           
        ; Initialize seed 
        LDR     r4, =RandomSeed
        MOV     r5, #0xACE1     ; Initial seed value
        STR     r5, [r4]     
        MOV     r12, #0         ; Frame counter     
        LTORG                  
GameLoop
        ;Load GPIO addresses at start of every frame
        LDR     r0, =GPIOA_BASE
        LDR     r1, =GPIOC_BASE      
        ; Clear display
        MOV     r2, #0x01
        BL      LCDCommand
        BL      ShortDelay      
        ; Draw hit zone indicators
        MOV     r2, #0x80       
        ADD     r2, r2, #12     
        BL      LCDCommand
        MOV     r3, #'|'        
        BL      LCDData       
        MOV     r2, #0xC0       
        ADD     r2, r2, #12     
        BL      LCDCommand
        MOV     r3, #'|'        
        BL      LCDData      
        ; Increment frame counter
        ADD     r12, r12, #1      
        ; Check spawn condition
        CMP     r12, #3
        BLT     NoSpawn       
        MOV     r12, #0
        ; Get random number to decide which tile to spawn
        BL      GetRandom       
        AND     r0, r0, #0x07    
        ; Map 0-7 to tile indices 0-5
        CMP     r0, #6
        SUBGE   r0, r0, #6            
        ; Now r0 contains 0-5, try to spawn that tile
        CMP     r0, #0
        BNE     TryTile2
        CMP     r8, #16
        MOVEQ   r8, #0
        BEQ     NoSpawn
        
TryTile2
        CMP     r0, #1
        BNE     TryTile3
        CMP     r9, #16
        MOVEQ   r9, #0
        BEQ     NoSpawn
        
TryTile3
        CMP     r0, #2
        BNE     TryTile4
        CMP     r10, #16
        MOVEQ   r10, #0
        BEQ     NoSpawn
        
TryTile4
        CMP     r0, #3
        BNE     TryTile5
        CMP     r11, #16
        MOVEQ   r11, #0
        BEQ     NoSpawn
        
TryTile5
        CMP     r0, #4
        BNE     TryTile6
        CMP     r7, #16
        MOVEQ   r7, #0
        BEQ     NoSpawn
        
TryTile6
        CMP     r0, #5
        BNE     NoSpawn
        CMP     r6, #16
        MOVEQ   r6, #0
        
NoSpawn      
        ; Draw all active tiles 
        CMP     r8, #16
        BGE     SkipDraw1
        LDR     r4, =TileRows
        LDRB    r5, [r4, #0]    ; Get row for tile 1
        CMP     r5, #0
        MOVEQ   r2, #0x80       
        MOVNE   r2, #0xC0       
        ADD     r2, r2, r8      
        BL      LCDCommand
        MOV     r3, #'*'      
        BL      LCDData
SkipDraw1
        ; Draw Tile 2
        CMP     r9, #16
        BGE     SkipDraw2
        LDR     r4, =TileRows
        LDRB    r5, [r4, #1]
        CMP     r5, #0
        MOVEQ   r2, #0x80
        MOVNE   r2, #0xC0
        ADD     r2, r2, r9
        BL      LCDCommand
        MOV     r3, #'*'
        BL      LCDData
SkipDraw2      
        ; Draw Tile 3
        CMP     r10, #16
        BGE     SkipDraw3
        LDR     r4, =TileRows
        LDRB    r5, [r4, #2]
        CMP     r5, #0
        MOVEQ   r2, #0x80
        MOVNE   r2, #0xC0
        ADD     r2, r2, r10
        BL      LCDCommand
        MOV     r3, #'*'
        BL      LCDData
SkipDraw3      
        ; Draw Tile 4
        CMP     r11, #16
        BGE     SkipDraw4
        LDR     r4, =TileRows
        LDRB    r5, [r4, #3]
        CMP     r5, #0
        MOVEQ   r2, #0x80
        MOVNE   r2, #0xC0
        ADD     r2, r2, r11
        BL      LCDCommand
        MOV     r3, #'*'
        BL      LCDData
SkipDraw4      
        ; Draw Tile 5
        CMP     r7, #16
        BGE     SkipDraw5
        LDR     r4, =TileRows
        LDRB    r5, [r4, #4]
        CMP     r5, #0
        MOVEQ   r2, #0x80
        MOVNE   r2, #0xC0
        ADD     r2, r2, r7
        BL      LCDCommand
        MOV     r3, #'*'
        BL      LCDData
SkipDraw5      
        ; Draw Tile 6
        CMP     r6, #16
        BGE     SkipDraw6
        LDR     r4, =TileRows
        LDRB    r5, [r4, #5]
        CMP     r5, #0
        MOVEQ   r2, #0x80
        MOVNE   r2, #0xC0
        ADD     r2, r2, r6
        BL      LCDCommand
        MOV     r3, #'*'
        BL      LCDData
SkipDraw6
        BL      LongDelay
        ; Read sensors for hit detection
        LDR     r2, =GPIOA_IDR
        LDR     r3, [r2]
        AND     r4, r3, #0x01       
        AND     r5, r3, #0x02       
        LSR     r5, r5, #1              
        ; Check Tile 1 at position 12
        CMP     r8, #12
        BNE     CheckTile2
        LDR     r2, =TileRows
        LDRB    r3, [r2, #0]
        CMP     r3, #0              ;
        BNE     CheckTile2
        ; Tile 1 at position 12 on top row - check PA0
        CMP     r4, #1              
        MOVEQ   r8, #16                   
CheckTile2
        ; Check Tile 2 at position 12 
        CMP     r9, #12
        BNE     CheckTile3
        LDR     r2, =TileRows
        LDRB    r3, [r2, #1]
        CMP     r3, #1              
        BNE     CheckTile3
        CMP     r5, #1              
        MOVEQ   r9, #16                
CheckTile3
        ; Check Tile 3 at position 12
        CMP     r10, #12
        BNE     CheckTile4
        LDR     r2, =TileRows
        LDRB    r3, [r2, #2]
        CMP     r3, #0            
        BNE     CheckTile4
        CMP     r4, #1             
        MOVEQ   r10, #16                   
CheckTile4
        ; Check Tile 4 at position 12
        CMP     r11, #12
        BNE     CheckTile5
        LDR     r2, =TileRows
        LDRB    r3, [r2, #3]
        CMP     r3, #1             
        BNE     CheckTile5
        CMP     r5, #1             
        MOVEQ   r11, #16           
        
CheckTile5
        ; Check Tile 5 at position 12
        CMP     r7, #12
        BNE     CheckTile6
        LDR     r2, =TileRows
        LDRB    r3, [r2, #4]
        CMP     r3, #0              
        BNE     CheckTile6
        CMP     r4, #1              
        MOVEQ   r7, #16                   
CheckTile6
        ; Check Tile 6 at position 12 
        CMP     r6, #12
        BNE     UpdatePositions
        LDR     r2, =TileRows
        LDRB    r3, [r2, #5]
        CMP     r3, #1              
        BNE     UpdatePositions
        CMP     r5, #1            
        MOVEQ   r6, #16               
UpdatePositions
        ;Update tile positions
        CMP     r8, #16        
        BGE     SkipMove1
        ADD     r8, r8, #1     
        CMP     r8, #16        
        BEQ.W   GameOver      
SkipMove1      
        CMP     r9, #16
        BGE     SkipMove2
        ADD     r9, r9, #1
        CMP     r9, #16
        BEQ.W   GameOver        
SkipMove2     
        CMP     r10, #16
        BGE     SkipMove3
        ADD     r10, r10, #1
        CMP     r10, #16
        BEQ.W   GameOver      
SkipMove3
        CMP     r11, #16
        BGE     SkipMove4
        ADD     r11, r11, #1
        CMP     r11, #16
        BEQ.W   GameOver      
SkipMove4       
        CMP     r7, #16
        BGE     SkipMove5
        ADD     r7, r7, #1
        CMP     r7, #16
        BEQ.W   GameOver       
SkipMove5      
        CMP     r6, #16
        BGE     SkipMove6
        ADD     r6, r6, #1
        CMP     r6, #16
        BEQ.W   GameOver
SkipMove6      
        B       GameLoop        ; Repeat forever    
        LTORG 

; RANDOM NUMBER GENERATOR
GetRandom   FUNCTION
        PUSH    {r1, r2, r3, LR}       
        LDR     r1, =RandomSeed
        LDR     r0, [r1]        ; Load current seed        
        ; New bit = bit0 XOR bit2 XOR bit3 XOR bit5
        MOV     r2, r0
        AND     r2, r2, #0x01   ; bit 0    
        MOV     r3, r0
        LSR     r3, r3, #2
        AND     r3, r3, #0x01   ; bit 2
        EOR     r2, r2, r3  
        MOV     r3, r0
        LSR     r3, r3, #3
        AND     r3, r3, #0x01   ; bit 3
        EOR     r2, r2, r3       
        MOV     r3, r0
        LSR     r3, r3, #5
        AND     r3, r3, #0x01   ; bit 5
        EOR     r2, r2, r3     
        ; Shift right and insert new bit at position 15
        LSR     r0, r0, #1
        LSL     r2, r2, #15
        ORR     r0, r0, r2    
        ; Store new seed
        STR     r0, [r1]      
        POP     {r1, r2, r3, LR}
        BX      LR
        ENDP

; GAME OVER SCREEN
GameOver
        ; Reload GPIO addresses
        LDR     r0, =GPIOA_BASE
        LDR     r1, =GPIOC_BASE       
        ; Clear display
        MOV     r2, #0x01
        BL      LCDCommand
        BL      ShortDelay       
        ; Game Over
        MOV     r2, #0x80
        BL      LCDCommand
        MOV     r3, #'G'
        BL      LCDData
        MOV     r3, #'a'
        BL      LCDData
        MOV     r3, #'m'
        BL      LCDData
        MOV     r3, #'e'
        BL      LCDData
        MOV     r3, #' '
        BL      LCDData
        MOV     r3, #'O'
        BL      LCDData
        MOV     r3, #'v'
        BL      LCDData
        MOV     r3, #'e'
        BL      LCDData
        MOV     r3, #'r'
        BL      LCDData     
        ; Press Reset
        MOV     r2, #0xC0
        BL      LCDCommand
        MOV     r3, #'P'
        BL      LCDData
        MOV     r3, #'r'
        BL      LCDData
        MOV     r3, #'e'
        BL      LCDData
        MOV     r3, #'s'
        BL      LCDData
        MOV     r3, #'s'
        BL      LCDData
        MOV     r3, #' '
        BL      LCDData
        MOV     r3, #'R'
        BL      LCDData
        MOV     r3, #'e'
        BL      LCDData
        MOV     r3, #'s'
        BL      LCDData
        MOV     r3, #'e'
        BL      LCDData
        MOV     r3, #'t'
        BL      LCDData
GameOverLoop
        B       GameOverLoop    ; Repeat Forever
        ENDP

; LCD INITIALIZATION 
LCDInitCommands FUNCTION
        LDR     r0, =GPIOA_BASE
        LDR     r1, =GPIOC_BASE       
        PUSH    {LR}
        MOV     r2, #0x38
        BL      LCDCommand        
        MOV     r2, #0x0C
        BL      LCDCommand        
        MOV     r2, #0x01
        BL      LCDCommand        
        MOV     r2, #0x06
        BL      LCDCommand       
        POP     {LR}
        BX      LR
        ENDP
        LTORG                  

; LCD COMMAND
LCDCommand  FUNCTION
        STRB    r2, [r1, #0x14]
        MOV     r2, #0x00
        ORR     r2, r2, #EN
        STRB    r2, [r0, #0x14]
        PUSH    {LR}
        BL      delay
        
        MOV     r2, #0x00
        STRB    r2, [r0, #0x14]
        POP     {LR}
        BX      LR
        ENDP

; LCD DATA
LCDData     FUNCTION
        STRB    r3, [r1, #0x14]
        MOV     r3, #0x00
        ORR     r3, r3, #EN
        ORR     r3, r3, #RS
        STRB    r3, [r0, #0x14]
        PUSH    {LR}
        BL      delay
        
        MOV     r3, #0x00
        ORR     r3, r3, #RS
        STRB    r3, [r0, #0x14]
        POP     {LR}
        BX      LR
        ENDP

; DELAY FUNCTIONS
delay       FUNCTION
        MOV     r5, #50
loop1       MOV     r4, #0xFF
loop2       SUBS    r4, r4, #1
        BNE     loop2
        SUBS    r5, r5, #1
        BNE     loop1
        BX      LR
        ENDP
ShortDelay  FUNCTION
        PUSH    {r4, r5, LR}
        MOV     r6, #5
delayloop1  BL      delay
        SUBS    r6, r6, #1
        BNE     delayloop1
        POP     {r4, r5, LR}
        BX      LR
        ENDP
LongDelay   FUNCTION
        PUSH    {r4, r5, LR}
        MOV     r6, #150        ; Increased for slower movement
delayloop2  BL      delay
        SUBS    r6, r6, #1
        BNE     delayloop2
        POP     {r4, r5, LR}
        BX      LR
        ENDP
; Data section for tile row assignments and random seed
        AREA    MYDATA, DATA, READWRITE
TileRows    SPACE   6               ; Storage for 6 tile row assignments
RandomSeed  SPACE   4               ; Storage for LFSR random seed
        
        END
