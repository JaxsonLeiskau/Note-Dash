STM32 NUCLEO-C031C6 LCD Rhythm Game Project

Overview
This project implements a simple rhythm-style reaction game on an STM32 NUCLEO-C031C6
development board using ARM assembly language. The system interfaces with a 16x2 character LCD,
two digital input sensors (or buttons), and a potentiometer. Falling “tiles” are rendered on the LCD, and
the player must trigger the correct sensor when a tile reaches the hit zone. Missing a tile results in a
game over state.

The project demonstrates:
- Direct register-level GPIO configuration
- LCD control in 8-bit parallel mode
- Basic game loop logic and animation
- Input polling and hit detection
- A linear-feedback shift register (LFSR) based pseudo-random number generator
- Timing control using software delay loops
- 
Hardware Requirements
- STM32 NUCLEO-C031C6 development board
- 16x2 HD44780-compatible character LCD (8-bit mode)
- Breadboard and jumper wires
- Two digital input sensors or push buttons (connected to PA0 and PA1)
- Potentiometer (optional, for future expansion or tuning)
- 5V and 3.3V power from the Nucleo board
  
Wiring Summary
- LCD Data Bus: Connected to GPIOC (configured as outputs)
- LCD Control Pins: RS, RW, EN connected to GPIOA
- Sensors / Buttons: Sensor 1 to PA0, Sensor 2 to PA1 (inputs with pull-ups)
- Power: LCD VCC to 5V, LCD GND to GND
  
Software Environment
- Target MCU: STM32C031 (Cortex-M0+)
- Language: ARM Assembly
- Toolchain: Keil MDK, ARM GNU Toolchain, or STM32CubeIDE
- No HAL or CMSIS drivers are used; all peripherals are accessed via memory-mapped registers.
  
Build and Flash Instructions
1. Create a new bare-metal STM32 project in your preferred IDE or toolchain.
2. Add the provided assembly source file to the project.
3. Ensure the linker script matches the STM32C031 memory layout.
4. Build the project.
5. Flash the binary to the NUCLEO-C031C6 board using ST-Link.
6. Power the board and observe the LCD output.
   
Gameplay Description
- On startup, the LCD displays a title screen.
- When both sensors are triggered, the game begins.
- Tiles (*) spawn at the left side of the LCD and move to the right.
- Two rows are used, and tiles are assigned to rows randomly.
- A hit zone is marked with | near the right side of the display.
- The player must press the correct sensor when a tile reaches the hit zone.
- Missing a tile results in a Game Over screen.
  
Code Structure
- Initialization: GPIO setup and LCD initialization
- Main Loop: Frame update, tile spawning, movement, and input checking
- Random Number Generator: 16-bit LFSR for tile selection
- LCD Routines: Command and data write functions
- Delay Routines: Software timing control
- Data Section: Tile row assignments and random seed storage
  
Known Limitations
- Timing is based on software delay loops and is not precise.
- Input is polled, not interrupt-driven.
- The LCD is cleared and redrawn each frame, which may cause flicker.
  
Possible Extensions
- Use hardware timers instead of software delays
- Add score tracking and difficulty scaling
- Use interrupts for input handling
- Add sound feedback using a buzzer
  
License
This project is provided for educational purposes. You may use, modify, and distribute it freely with
attribution.
