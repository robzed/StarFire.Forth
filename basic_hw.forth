\ StarFire-Forth
\ Copyright (C) 2021 Rob Probin
\ 
\ MIT license
\ See LICENSE for the details

-basichw
marker -basichw
decimal ram

$02c0 constant TRISA   \ 1=In, 0=Out
$02c2 constant PORTA   \ read
$02c4 constant LATA    \ output latch

$02c8 constant TRISB
$02ca constant PORTB
$02cc constant LATB

$02d0 constant TRISC
$02d2 constant PORTC
$02d4 constant LATC

1 4 lshift constant PWRLED
1 4 lshift constant RLED
1 3 lshift constant LLED

: out! ( f mask addr -- ) rot if mset else mclr then ;

: pwr_led    ( f -- ) PWRLED LATB out! ;
: right_led  ( f -- ) RLED LATA out! ;
: left_led  ( f -- ) LLED LATC out! ;

\ IR_1        LATAbits.LATA10
\ IR_2        LATAbits.LATA7
\ IR_3        LATBbits.LATB14
\ IR_4        LATBbits.LATB15
\ IR_5        LATAbits.LATA8
\ IR_6        LATAbits.LATA9
\ R_BUT       PORTCbits.RC4
\ L_BUT       PORTCbits.RC5

1 4 lshift constant RBUT
1 5 lshift constant LBUT

: r_but? PORTC @ RBUT and ;
: l_but? PORTC @ LBUT and ;

\ LED1/PWRLED TRIS   _TRISB4
\ LED2/RLED TRIS   _TRISA4
\ LED3/LLED TRIS   _TRISC3

\ R_BUT_TRIS  _TRISC4
\ L_BUT_TRIS  _TRISC5
\ IR_1_TRIS   _TRISA10
\ IR_2_TRIS    _TRISA7
\ IR_3_TRIS   _TRISB14
\ IR_4_TRIS   _TRISB15
\ IR_5_TRIS   _TRISA8
\ IR_6_TRIS   _TRISA9
\ L_PWM       PDC2
\ R_PWM       PDC3

\ These two are handled in SPI_RAM.fth
\ SRAM_CS     LATAbits.LATA3
\ SRAM_CS_TRIS _TRISA3


\ Setup the hardware
\ Zero is output, defaults to 0xFFFF = all inputs
: inithw ( -- )
    RLED TRISA mclr
    PWRLED TRISB mclr
    LLED TRISC mclr
;

: but_test
    do
        r_but? right_led
        l_but? left_led
        r_but? 0= l_but? 0= and pwr_led
    loop
;


