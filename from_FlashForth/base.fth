\ Basic Utilities
\ Taken from FlashForth
\ 
\ See FlashForth for the details
\ FlashForth is licensed according to the GNU General Public License*

-baseutil
marker -baseutil
decimal ram

\ From free.fs
: unused hi here - 1+ ;
\ MCU without eeprom
: .free
  decimal
  cr ." Flash:" flash unused u. ." bytes"
  cr ." Ram:" ram unused u. ." bytes"
;


