\ StarFire-Forth - SPI RAM driver for 23LCV1024 1Mbit RAM chip
\ Copyright (C) 2021 Rob Probin
\ 
\ MIT license
\ See LICENSE for the details

-SPIRAM
marker -SPIRAM
decimal ram

\ SRAM_CS -> LATAbits.LATA3
\ SRAM_CS_TRIS -> _TRISA3

$0240 constant SPI1STAT
$0242 constant SPI1CON1
$0244 constant SPI1CON2
$0248 constant SPI1BUF

\ Bits of SPI1STAT
$0001 constant mSPIRBF

\ Bits of SPI1CON1
$0x0040 constant mCKE
$0x0080 constant mCKP

1 3 lshift constant _SRAM_CS

( f -- )
: SRAM_CS   \ set the CS line to a particular state
    _SRAM_CS LATA out!
;

: init_spiram
    TRISA _SRAM_CS mclr \ set pin 31 for output to allow control of SRAM CS  (output = 0)
    1 SRAM_CS         \ CS is active low, so disable

    \ spi pin setup
    RPINR20 = 0xFF07; \ SPI1 Data Input, SPI IN, RP7, pin 43   
    RPOR4 = 0x0708;   \ function 8 = SPI1 Clock Output, SPI CLK RP8 (lower byte), pin 44)
                      \ function 7 = SPI1 Data Output, SPI OUT, RP9 (upper byte), pin 1

    \ setup the SPI peripheral
    0 SPI1STAT !      \ disable the SPI module (just in case)

    \ SFR Name Addr Bit 15 Bit 14 Bit 13 Bit 12 Bit 11 Bit 10 Bit 9 Bit 8 Bit 7 Bit 6 Bit 5 Bit 4 Bit 3 Bit 2 Bit 1 Bit 0
    \ SPI1CON1   0242   —      —       —   DISSCK DISSDO MODE16  SMP    CKE  SSEN CKP   MSTEN ----SPRE<2:0>----  PPRE<1:0>  Reset Value = 0000
    \  SPI1CON1 = 0x0161;    \ FRAMEN = 0, SPIFSD = 0, DISSDO = 0, MODE16 = 0; SMP = 0; CKP = 1; CKE = 1; SSEN = 0; MSTEN = 1; SPRE = 0b000, PPRE = 0b01
    $057B SPI1CON1 !        \ SPIFSD = 0, DISSDO = 0, MODE16 = 1; SMP = 0; CKP = 1; CKE = 1; SSEN = 0; MSTEN = 1; SPRE = 0b110, PPRE = 0b11
    \ SPI1CON1 = 0x0573;     \             SPIFSD = 0, DISSDO = 0, MODE16 = 1; SMP = 0; CKP = 1; CKE = 1; SSEN = 0; MSTEN = 1; SPRE = 0b110, PPRE = 0b11

    \ main clock is 23 MHz (/2 of Fosc)
    \ SPI Peripheral clock is /2 = 12MHz.

    \ 111 = Secondary prescale 1:1
    \ 110 = Secondary prescale 2:1     <<<-- will give 12 MHz (with primary set at 1:1). However logic analyser is 20 Msps
    \ 101 = 3:1
    \ 100 = 4:1
    \ 011 = 5:1
    \ 010 = 6:1
    \ 001 = 7:1
    \ 000 = Secondary prescale 8:1

    \ 11 = Primary prescale 1:1
    \ 10 = Primary prescale 4:1
    \ 01 = Primary prescale 16:1
    \ 00 = Primary prescale 64:1
    \ SMP: SPIx Data Input Sample Phase bit Master mode:
    \          0 = Input data sampled at middle of data output time 
    \ CKE: SPIx Clock Edge Select bit(1) 
    \          1 = Serial output data changes on transition from active clock state to Idle clock state (see bit 6) 
    \ CKP: Clock Polarity Select bit 
    \          0 = Idle state for clock is a low level; active state is a high level 
    SPI1CON1 mCKE mset
    SPI1CON1 mCKP mclr
    $8000 SPI1STAT ! \ enable the SPI module 
;


( -- u )
: _SPI_wait_read_buf

    begin SPI1STAT mSPIRBF mtst until \ wait for the data to be read
    SPI1BUF @
;

( uaddr -- )
: start_SPI_write
    0 SRAM_CS                   \ lower the slave select line
    \ pause required here? 25ns required, instruction time = 43ns. Should be ok :-)
    
    SPI1BUF @ drop                 \ dummy read of the SPI1BUF register to clear the SPIRBF flag
    dup $8000 and if $0201 else $0200 then   \ instruction 0x02 is write, plus top bit of 128K address
    SPI1BUF !                      \ write the data out to the SPI peripheral

    _SPI_wait_read_buf drop
    
    1 lshift SPI1BUF !              \ emulate 16 bit address

    \ the second part of the address is now being sent out, while the function returns
;

( n16 -- )
: SPI_write
    _SPI_wait_read_buf drop 
    SPI1BUF !
;


( addr -- )
: start_SPI_read
    0 SRAM_CS    \ lower the slave select line
    \ pause required here? 25ns required, instruction time = 43ns. Should be ok :-)
    
    SPI1BUF @ drop             \ dummy read of the SPI1BUF register to clear the SPIRBF flag
    dup $8000 and if $0301 else $0300 then        \ instruction 0x03 is read, plus top bit of 128K address
    SPI1BUF !                   \ write the data out to the SPI peripheral
    _SPI_wait_read_buf drop
    
    1 lshift SPI1BUF !          \ emulate 16 bit address
    _SPI_wait_read_buf drop
;

( -- n16 )
: SPI_read
    0 SPI1BUF !          \ dummy value
    _SPI_wait_read_buf
;


( -- )
: end_SPI_read
    \ Need to wait over 1 bit after . At 12MHz this is 83ns.
    \ At 6MHz this is 176ns (used for logic analyser)
    \ Instructions are 43ns. 
    \ asm("repeat #5");      //200ns delay
    \ asm("nop");
    \ actual delay is much longer because of call overhead

    1 SRAM_CS     \ raise the slave select line    
;

( -- )
: end_SPI_write
    _SPI_wait_read_buf drop     \ for write we need to wait for it to clocked out

    \ same delay notes as SPI_finish_read
    1 SRAM_CS
;



