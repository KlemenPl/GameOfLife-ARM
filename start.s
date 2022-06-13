.equ PMC_BASE,  0xFFFFFC00  /* (PMC) Base Address */
.equ CKGR_MOR,	0x20        /* (CKGR) Main Oscillator Register */
.equ CKGR_PLLAR,0x28        /* (CKGR) PLL A Register */
.equ PMC_MCKR,  0x30        /* (PMC) Master Clock Register */
.equ PMC_SR,	  0x68        /* (PMC) Status Register */

.equ PIOA_BASE, 0xFFFFF400 /* Zacetek registrov za vrata A - PIOA */
.equ PIOB_BASE, 0xFFFFF600 /* Zacetek registrov za vrata B - PIOB */
.equ PIOC_BASE, 0xFFFFF800 /* Zacetek registrov za vrata C - PIOC */
.equ PIO_PER,   0x00 /* Odmiki... */
.equ PIO_PDR,   0x04
.equ PIO_PSR,   0x08
.equ PIO_OER,   0x10
.equ PIO_ODR,   0x14
.equ PIO_OSR,   0x18
.equ PIO_SODR,  0x30
.equ PIO_CODR,  0x34
.equ PIO_PDSR,  0x3c
.equ PIO_PUER,  0x64

.equ PMC_BASE, 	0xFFFFFC00	/* Power Management Controller */
							/* Base Address */
.equ PMC_PCER, 	0x10  		/* Peripheral Clock Enable Register */

.equ TC0_BASE, 	0xFFFA0000	/* TC0 Channel Base Address */
.equ TC_CCR,  	0x00  		/* TC0 Channel Control Register */
.equ TC_CMR, 	0x04	  	/* TC0 Channel Mode Register*/
.equ TC_CV,    	0x10		/* TC0 Counter Value */
.equ TC_RA,    	0x14		/* TC0 Register A */
.equ TC_RB,    	0x18		/* TC0 Register B */
.equ TC_RC,    	0x1C		/* TC0 Register C */
.equ TC_SR,    	0x20		/* TC0 Status Register */
.equ TC_IER,   	0x24		/* TC0 Interrupt Enable Register*/
.equ TC_IDR,   	0x28		/* TC0 Interrupt Disable Register */
.equ TC_IMR,  	0x2C		/* TC0 Interrupt Mask Register */

.equ DBGU_BASE, 0xFFFFF200 /* Debug Unit Base Address */
.equ DBGU_CR,   0x00  /* DBGU Control Register */
.equ DBGU_MR,   0x04   /* DBGU Mode Register*/
.equ DBGU_IER,  0x08 /* DBGU Interrupt Enable Register*/
.equ DBGU_IDR,  0x0C /* DBGU Interrupt Disable Register */
.equ DBGU_IMR,  0x10 /* DBGU Interrupt Mask Register */
.equ DBGU_SR,   0x14 /* DBGU Status Register */
.equ DBGU_RHR,  0x18 /* DBGU Receive Holding Register */
.equ DBGU_THR,  0x1C /* DBGU Transmit Holding Register */
.equ DBGU_BRGR, 0x20 /* DBGU Baud Rate Generator Register */

.equ IO_LOW,    0x0
.equ IO_HIGH,   0x1

.equ LED_PIO_BASE,      PIOB_BASE 
.equ LED_SIZE_X,        0x8
.equ LED_SIZE_Y,        0x6
.equ GAME_LEN,          48
.equ GAME_STEP,         600 @ Each game step is around 600 ms

@ Macros:

/*********************************
 * sudiv:
 * Performs software unsigned
 * division. (Dividing by 0 is
 * undefined behaviour).
 * 
 * rd: quotient (output)
 * rn: divident (input)
 * rn: divisor  (input)
 * rt: temporary
 ********************************/
 .macro sudiv   rd, rn, rm, rt
        mov     \rt, \rn
        mov     \rd, #0
1:
        cmp     \rt, \rm        @ while rt >= rm
        subhs   \rt, \rt, \rm
        addhs   \rd, \rd, #1
        bhi     1b
 .endm


 /*********************************
 * sumod:
 * Performs software unsigned
 * modulo.
 * 
 * r0: remainder (output)
 * r1: divident  (input)
 * r2: divisor   (input)
 ********************************/
.macro  sumod    rd, rn, rm
        mov     \rd, \rn
1:
        cmp     \rd, \rm        @ while rd >= rm
        subhs   \rd, \rd, \rm
        bhs     1b
 .endm

LED_X: .byte 6, 7, 8, 9, 16, 17, 18, 19
LED_Y: .byte 0, 1, 2, 3, 4, 5
.space 2

GEN_STR:        .asciz "Generation: "
.space 3
FINISH_STR:     .asciz "Finished."
.space 2

BUTTON_PIN: .byte 10
.space 3
BEEPER_PIN: .byte 11
.space 3
VCC_PIN:    .byte 21
.space 3

RNG:        .word  12345

GAME0:      .space 48
GAME1:      .space 48

.align


.text
.code 32

.global _error
_error:
        b _error

.global	_start
_start:

        /* 
        select system mode
        CPSR[4:0]	Mode
        --------------
        10000	  User
        10001	  FIQ
        10010	  IRQ
        10011	  SVC
        10111	  Abort
        11011	  Undef
        11111	  System
        */

        mrs     r0,   cpsr
        bic     r0,   r0, #0x1F   /* clear mode flags */
        orr     r0,   r0, #0xDF   /* set supervisor mode + DISABLE IRQ, FIQ*/
        msr     cpsr, r0

        /* init stack */
        ldr     sp, _Lstack_end

        /* setup system clocks */
        ldr     r1, =PMC_BASE

        ldr     r0, = 0x0F01
        str     r0, [r1,#CKGR_MOR]

osc_lp:
        ldr   r0, [r1,#PMC_SR]
        tst   r0, #0x01
        beq   osc_lp

        mov   r0, #0x01
        str   r0, [r1,#PMC_MCKR]

        ldr   r0, =0x2000bf00 | ( 124 << 16) | 12  /* 18,432 MHz * 125 / 12 */
        str   r0, [r1,#CKGR_PLLAR]

pll_lp:
        ldr   r0, [r1,#PMC_SR]
        tst   r0, #0x02
        beq   pll_lp

        /* MCK = PCK/4 */
        ldr   r0, =0x0202
        str   r0, [r1,#PMC_MCKR]

mck_lp:
        ldr   r0, [r1,#PMC_SR]
        tst   r0, #0x08
        beq   mck_lp

        /* Enable caches */
        mrc   p15, 0, r0, c1, c0, 0
        orr   r0, r0, #(0x1 <<12)
        orr   r0, r0, #(0x1 <<2)
        mcr   p15, 0, r0, c1, c0, 0


.global _main
/* main program */
_main:

        /* user code here */
        @ bl      INIT_IO


        bl      INIT_TC0
        bl      INIT_TTY

        @ Initialize onboard LED
        mov     r0, #1
        ldr     r1, =PIOC_BASE
        mov     r2, #1
        bl      INIT_OUT_PIN

        @ Enable clock for PIO port B
        ldr     r1, =PMC_BASE
        mov     r2, #0b1000
        str     r2, [r1, #PMC_PCER]

        @ Initialize button        
        ldr     r1, =LED_PIO_BASE
        ldrb    r2, BUTTON_PIN
        bl      INIT_IN_PIN

        @ Initialize BEEPER
        mov     r0, #0
        ldrb    r2, BEEPER_PIN
        bl      INIT_OUT_PIN

        @ Initialize VCC+
        mov     r0, #1 @ Always on
        ldrb    r2, VCC_PIN
        bl      INIT_OUT_PIN

        @ Initialize LED x pins
        mov     r0, #1
        adr     r3, LED_X
        mov     r4, #0
led_init_x:
        ldrb    r2, [r3, r4]
        bl      INIT_OUT_PIN
        add     r4, r4, #1
        cmp     r4, #LED_SIZE_X
        blt     led_init_x

        @ Initialize LED y pins
        mov     r0, #0
        adr     r3, LED_Y
        mov     r4, #0
led_init_y:
        ldrb    r2, [r3, r4]
        bl      INIT_OUT_PIN
        add     r4, r4, #1
        cmp     r4, #LED_SIZE_Y
        blt     led_init_y

MAIN_LOOP:
        @ Wait until user presses a button    
        mov     r3, #0
        mov     r9, #0 @ Generation counter
user_btn_wait:
        ldr     r1, =LED_PIO_BASE
        ldr     r2, BUTTON_PIN 
        add     r3, r3, #1

        bl      DIGITAL_READ

        ldr     r1, =PIOC_BASE
        mov     r2, #1
        bl      DIGITAL_WRITE

        mov     r4, r0
        @ Wait 10 ms
        mov     r0, #10
        bl      DELAY

        cmp     r4, #0
        beq     user_btn_wait

        @ Seed RNG
        mov     r0, r3
        bl      SEED_RANDOM

        @ Initialize boards
        adr     r11, GAME0 @ FrontBuffer
        adr     r12, GAME1 @ BackBuffer

        mov     r0, #0
        mov     r1, #0
clear_bb:
        strb    r0, [r12, r1]
        add     r1, r1, #1
        cmp     r1, #GAME_LEN
        blt     clear_bb

        mov     r1, #0
seed_fb:
        bl      RANDOM
        and     r0, r0, #0b1
        strb    r0, [r11, r1]

        add     r1, r1, #1
        cmp     r1, #GAME_LEN
        blt seed_fb

        @ Simulate game
loop:
        @ Count active cells
        mov     r3, #0 @ i count
        mov     r4, #0 @ active count
loop_count:
        ldrb    r0, [r11, r3]

        cmp     r0, #0
        addne   r4, r4, #1

        add     r3, r3, #1
        cmp     r3, #GAME_LEN
        blt     loop_count

        cmp     r4, #0
        bne     loop_continue

        ldr     r0, =400
        bl      DELAY

        @ adr     r0, FINISH_STR
        @ bl      SERIAL_PRINT_STR
        @ mov     r0, #'\n'
        @ bl      TTY_PUTC

        @ Reset if every cell is dead
        @ Buf firt notify user
        mov     r3, #6  @ Repeat counter
loop_notify:
        mov     r4, #0  @ Cell counter
loop_notify_inner:
        @ Negate cell state
        ldrb    r5, [r11, r4]
        eor     r5, r5, #0b1
        strb    r5, [r11, r4]

        add     r4, r4, #1
        cmp     r4, #GAME_LEN
        blt     loop_notify_inner

        mov     r0, r5
        ldr     r1, =LED_PIO_BASE
        ldrb    r2, BEEPER_PIN
        bl      DIGITAL_WRITE

        mov     r0, r11
        ldr     r1, =125000
        ldr     r2, =200        

        bl      DRAW_MATRIX

        subs    r3, r3, #1
        bne     loop_notify

        b       MAIN_LOOP
loop_continue:

        mov     r0, r11
        ldr     r1, =220000     @ Each iter will last around 220ms.
        ldr     r2, =650        @ ns
        bl      DRAW_MATRIX

        @ Print generation number
        @ adr     r0, GEN_STR
        @ bl      SERIAL_PRINT_STR
        @ add     r9, r9, #1
        @ mov     r0, r9
        @ bl      SERIAL_PRINT_UINT
        @ mov     r0, #'\n'
        @ bl      TTY_PUTC
        
        @ Clear back buffer
        mov     r2, #0
        mov     r0, #0
loop_clear_bf:
        strb    r0, [r12, r2]
        add     r2, r2, #1
        cmp     r2, #GAME_LEN
        blt     loop_clear_bf

        @ Step the game
        mov     r2, #0 @ count
loop_step:
        @ Count neigbours
        mov     r1, r11
        bl      COUNT_NEIGHBOURS

        ldrb    r3, [r1, r2] @ Current cell alive?
        cmp     r3, #0
        beq     step_dead
        @ Alive cell checks
        cmp     r0, #2
        beq     step_setalive
        cmp     r0, #3
        beq     step_setalive
        b       step_setdead
step_dead:
        @ Dead cell checks
        cmp     r0, #3
        beq     step_setalive
        b       step_setdead       
step_setalive:
        mov     r0, #1
        b       step_end
step_setdead:
        mov     r0, #0
step_end:
        strb    r0, [r12, r2]

        add     r2, r2, #1
        cmp     r2, #GAME_LEN
        blt     loop_step

        @ Check, if user pressed a button
        ldr     r1, =LED_PIO_BASE
        ldr     r2, BUTTON_PIN 
        bl      DIGITAL_READ
        cmp     r0, #1
        beq     MAIN_LOOP

        @ Swap buffers
        eor     r11, r11, r12
        eor     r12, r12, r11
        eor     r11, r11, r12
        
        b       loop

/*********************************
 * DRAW_MATRIX
 * Draws matrix.
 *
 * r0: addr to the LED state
 * r1: frame time (in ns)
 * r2: individual LED time (in ns)
 ********************************/
 DRAW_MATRIX:
        stmfd   r13!, {r0-r7, lr}
        mov     r4, r0 @ Addr
        mov     r5, r1 @ Frame time counter
        mov     r6, r2 @ Individual LED time
        mov     r7, #GAME_LEN @ Previous cell
        
        ldr     r1, =LED_PIO_BASE
DRAW_MATRIX_loop:
        mov     r3, #0 @ Count
DRAW_MATRIX_inner_loop:
        ldrb    r0, [r4, r3]
        cmp     r0, #0
        @ Skip innactive cells
        addeq   r3, r3, #1
        beq     DRAW_MATRIX_inner_loop
        cmp     r3, #GAME_LEN
        bge     DRAW_MATRIX_inner_end

        @ Turn off previous cell
        cmp     r7, #GAME_LEN
        movne   r0, #0
        movne   r2, r7
        blne    SET_CELL_STATE

        @ Turn on current active cell
        mov     r0, #1
        mov     r2, r3 
        bl      SET_CELL_STATE

        @ Sleep
        mov     r0, r6
        bl      DELAY_NS
        sub     r5, r5, r6

        mov     r7, r3
        add     r3, r3, #1
        cmp     r3, #GAME_LEN
        blt     DRAW_MATRIX_inner_loop
DRAW_MATRIX_inner_end:

        mov     r0, r6
        bl      DELAY_NS
        sub     r5, r5, r6

        @ Turn off prev cell
        cmp     r7, #GAME_LEN
        movne   r0, #0
        movne   r2, r7
        blne    SET_CELL_STATE

        cmp     r5, #0
        bgt     DRAW_MATRIX_loop
       
        ldmfd   r13!, {r0-r7, pc}


/*********************************
 * IS_ACTIVE
 * Checks if cell is active.
 *
 * r0: += 1 if active
 * r1: addr
 * r2: X pos
 * r3: Y pos
 ********************************/
IS_ACTIVE:
        stmfd   r13!, {r2-r5, lr}
        cmp     r2, #0
        blt     IS_ACTIVE_end
        cmp     r2, #LED_SIZE_X
        bge     IS_ACTIVE_end

        cmp     r3, #0
        blt     IS_ACTIVE_end
        cmp     r3, #LED_SIZE_Y
        bge     IS_ACTIVE_end

        @ Calculate idx
        mov     r5, #LED_SIZE_X
        mul     r4, r3, r5
        add     r4, r4, r2

        ldrb    r2, [r1, r4]
        cmp     r2, #0
        beq     IS_ACTIVE_end

        add     r0, r0, #1
IS_ACTIVE_end:        
        ldmfd   r13!, {r2-r5, pc}

/*********************************
 * COUNT_NEIGHBOURS
 * Counts active neigbours.
 *
 * r0: count (output)
 * r1: adr   (input)
 * r2: idx   (input)
 ********************************/
 COUNT_NEIGHBOURS:
        stmfd   r13!, {r2-r4, lr}
        mov     r0, #0

        @ Get Y
        sudiv   r3, r2, #LED_SIZE_X, r4
        @ Get X
        sumod   r2, r2, #LED_SIZE_X

        @ X:r2
        @ Y:r3

        @ ...
        @ ?x.
        @ ...
        sub     r2, r2, #1
        bl      IS_ACTIVE

        @ ...
        @ .x?
        @ ...
        add     r2, r2, #2
        bl      IS_ACTIVE

        @ ..?
        @ .x.
        @ ...
        sub     r3, r3, #1
        bl      IS_ACTIVE

        @ .?.
        @ .x.
        @ ...
        sub     r2, r2, #1
        bl      IS_ACTIVE

        @ ?..
        @ .x.
        @ ...
        sub     r2, r2, #1
        bl      IS_ACTIVE

        @ ...
        @ .x.
        @ ?..
        add     r3, r3, #2
        bl      IS_ACTIVE

        @ ...
        @ .x.
        @ .?.
        add     r2, r2, #1
        bl      IS_ACTIVE

        @ ...
        @ .x.
        @ ..?
        add     r2, r2, #1
        bl      IS_ACTIVE

        ldmfd   r13!, {r2-r4, pc}

/*********************************
 * SET_CELL_STATE:
 * Sets cell state for LED matrix.
 *
 * r0: state (0/1)
 * r1: BASE
 * r2: cell index
 *********************************/
 SET_CELL_STATE:
        stmfd   r13!, {r2-r4, lr}
        mov     r3, r2

        @ Set X row
        sumod   r2, r2, #LED_SIZE_X
        ldr     r4, =LED_X
        ldrb    r2, [r4, r2]
        mov     r4, r0
        eor     r0, r0, #0b1
        bl      DIGITAL_WRITE

        mov     r0, r4
        @ Set Y row
        sudiv   r2, r3, #LED_SIZE_X, r4
        ldr     r4, =LED_Y
        ldrb    r2, [r4, r2]
        bl      DIGITAL_WRITE

        ldmfd   r13!, {r2-r4, pc}

/*********************************
 * RANDOM:
 * Calculates pseudo-random 
 * number and writes it to r0
 * using linear congruential 
 * generator method.
 *
 * r0: output random number
 ********************************/
 RANDOM:
        stmfd   r13!, {r1,r2, lr}
        ldr     r0, RNG

        ldr     r1, =16807
        mov     r2, r0
        mul     r0, r2, r1

        ldr     r2, =12345
        add     r0, r0, r2

        ldr     r2, =2147483647
        sumod   r0, r0, r2

        str     r0, RNG
        ldmfd   r13!, {r1,r2, pc}

/*********************************
 * SEED_RANDOM:
 * Seeds RNG.
 *
 * r0: input seed
 ********************************/
 SEED_RANDOM:
        stmfd   r13!, {r1,r2, lr}
        ldr     r1, RNG
        add     r1, r1, #1
        add     r1, r1, r0
        mov     r2, r1
        mul     r1, r2, r0
        str     r1, RNG        
        ldmfd   r13!, {r1,r2, pc}

/*********************************
 * SERIAL_PRINT_STR
 * Prints string to TTY.
 *
 * r0: addr to null terminated
 * string.
 *********************************/
SERIAL_PRINT_STR:
        stmfd   r13!, {r0,r1, lr}
        mov     r1, r0
SERIAL_PRINT_STR_loop:
        ldrb    r0, [r1, #0]
        cmp     r0, #0
        beq     SERIAL_PRINT_STR_end
        bl      TTY_PUTC
        add     r1, r1, #1
        b       SERIAL_PRINT_STR_loop
SERIAL_PRINT_STR_end:    
        ldmfd   r13!, {r0,r1, pc}

 /*********************************
 * SERIAL_PRINT_UINT
 * Prints unsigned integer to TTY.
 *
 * r0: integer value
 *********************************/
 SERIAL_PRINT_UINT:
        stmfd   r13!, {r0-r4, lr}
        @ Reverse number
        mov     r1, #0  @ Reversed
        mov     r3, #0  @ Len counter
        mov     r4, #10 @ Radix
SERIAL_PRINT_UINT_rev:
        @ r1 *= 10
        mov     r2, r1
        mul     r1, r2, r4
        @ r1 += r0 % 10
        sumod   r2, r1, #10
        add     r1, r1, r4
        @ r0 /= 10
        sudiv   r0, r0, r4, r2
        cmp     r0, #0
        bne     SERIAL_PRINT_UINT_rev

        @ Print reversed number
SERIAL_PRINT_UINT_loop_rev:
        sumod   r0, r1, r4
        cmp     r0, #0
        blne    TTY_PUTC

        mov     r0, r1
        sudiv   r1, r0, r4, r2
        cmp     r1, #0
        bne     SERIAL_PRINT_UINT_loop_rev

        @ Print trailing zeros
        mov     r0, #'0'
SERIAL_PRINT_UINT_loop_zeros:
        cmp     r3, #0
        blne    TTY_PUTC
        subs    r3, r3, #1
        bne     SERIAL_PRINT_UINT_loop_zeros

        ldmfd   r13!, {r0-r4, pc}

/*********************************
 * TTY_GETC:
 * Saves typed character from tty
 * to r0.
 ********************************/
TTY_GETC:
        stmfd   r13!, {r1, lr}
        ldr     r1, =DBGU_BASE
TTY_GETC_LP:
        ldr     r0, [r1, #DBGU_SR]
        tst     r0, #0b1
        beq     TTY_GETC_LP
        ldr     r0, [r1, #DBGU_RHR]
        ldmfd   r13!, {r1, pc}

/*********************************
 * TTY_PUTS:
 * Writes character stored in r0
 * to tty output.
 ********************************/
TTY_PUTC:
        stmfd   r13!, {r1,r2, lr}
        ldr     r1, =DBGU_BASE
TTY_PUTC_LP:
        ldr     r2, [r1, #DBGU_SR]
        tst     r2, #(1 << 1)
        beq     TTY_PUTC_LP
        str     r0, [r1, #DBGU_THR]
        ldmfd   r13!, {r1,r2, pc}


/*********************************
 * DIGITAL_WRITE:
 * Sets pin to either HIGH or LOW
 * state.
 *
 * r0: state (0/1)
 * r1: BASE (PIOA, PIOB, PIOC)
 * r2: PIN
 ********************************/
DIGITAL_WRITE:
        stmfd   r13!, {r0,r3, lr}

        cmp     r0, #0
        ldreq   r0, =PIO_CODR @ LOW
        ldrne   r0, =PIO_SODR @ HIGH

        mov     r3, #1
        lsl     r3, r3, r2

        str     r3, [r1, r0]
        
        ldmfd   r13!, {r0,r3, pc} 

/*********************************
 * DIGITAL_READ:
 * Reads either HIGH or LOW
 * state on the pin.
 *
 * r0: output (0/1)
 * r1: BASE (PIOA, PIOB, PIOC)
 * r2: PIN
 ********************************/
DIGITAL_READ:
        stmfd   r13!, {r3, lr}

        ldr     r0, [r1, #PIO_PDSR]

        mov     r3, #1
        lsl     r3, r3, r2
        and     r0, r0, r3

        cmp     r0, #0
        moveq   r0, #0 @ LOW
        movne   r0, #1 @ HIGH

        ldmfd   r13!, {r3, pc}


/*********************************
 * INIT_IN_PIN:
 * Initializes pin for digital 
 * read. Must be called before trying 
 * to read from the pin.
 *
 * r1: BASE (PIOA, PIOB, PIOC)
 * r2: PIN
 ********************************/
INIT_IN_PIN:
        stmfd   r13!, {r3, lr}
        mov     r3, #1
        lsl     r3, r3, r2

        @ Input
        str     r3, [r1, #PIO_PUER]  @ Enable pullup
        str     r3, [r1, #PIO_PER]   @ Configure pin as input
        str     r3, [r1, #PIO_ODR]   @ .

        ldmfd   r13!, {r3, pc}

/*********************************
 * INIT_OUT_PIN:
 * Initializes pin for digital 
 * write. Must be called before 
 * trying to write to the pin.
 *
 * r0: initial state (0/1)
 * r1: BASE (PIOA, PIOB, PIOC)
 * r2: PIN
 ********************************/
INIT_OUT_PIN:
        stmfd   r13!, {r3, lr}
        mov     r3, #1
        lsl     r3, r3, r2

        @ Output
        str     r3, [r1, #PIO_PER]
        str     r3, [r1, #PIO_OER]  @ Enable output
        
        cmp     r0, #0
        streq   r3, [r1, #PIO_CODR] @ Write LOW
        strne   r3, [r1, #PIO_SODR] @ Write HIGH

        ldmfd   r13!, {r3, pc}

/*********************************
 * DELAY_NS:
 * Delays for r0 ns (blocking).
 *
 * r0: input ns
 ********************************/
DELAY_NS:
        stmfd   r13!, {r0,r1, lr}
DELAY_NS_l0:
        mov     r1, #48 @ 48000 for whole ms
DELAY_NS_l1:
        subs    r1, r1, #1
        bne     DELAY_NS_l1

        subs    r0, r0, #1
        bne     DELAY_NS_l0
        ldmfd   r13!, {r0,r1, pc}

DELAY:
        stmfd   r13!, {r0-r2, lr}
        ldr     r2, =TC0_BASE
DELAY_loop:
        ldr     r1, [r2, #TC_SR]
        tst     r1, #1 << 4
        beq     DELAY_loop
        subs    r0, r0, #1
        bne     DELAY_loop
        ldmfd   r13!, {r0-r2, pc}

INIT_TC0:
        stmfd   r13!, {r1-r3, lr}
        @Omogoci urin signal
        ldr     r1, =PMC_BASE
        mov     r2, #1 << 17
        str     r2, [r1, #PMC_PCER]
        @ Izberi ferkvenco urinega signala
        ldr     r1, =TC0_BASE
        ldr     r2, =0b110 << 13 @ WAVE, WAVESEL
        add     r2, r2, #0b011
        str     r2, [r1, #TC_CMR]
        @ Zapisi zgornjo mejo (375) v TC_RC
        ldr     r2, =375
        str     r2, [r1, #TC_RC]
        @ Omogoci uro, sprozi stevec
        mov     r2, #0b0101
        str     r2, [r1, #TC_CCR]

        ldmfd   r13!, {r1-r3, pc}

INIT_TTY:
        stmfd   r13!, {r0,r1, lr}
        ldr     r0, =DBGU_BASE
        mov     r1, #156        @  BR=19200
        str     r1, [r0, #DBGU_BRGR]
        ldr     r1, =(1 << 11)
        ldr     r2, =(0b10 << 14)  @ Local Loopback Mode (instead of Normal)
        add     r1, r1, r2
        str     r1, [r0, #DBGU_MR]
        ldr     r1, =0b1010000
        str     r1, [r0, #DBGU_CR]
        ldmfd   r13!, {r0,r1, pc}

/* end user code */

_wait_for_ever:
  b _wait_for_ever

/* constants */

_Lstack_end:
  .long __STACK_END__

.end

