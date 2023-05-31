\ Basic Utilities
\ Taken from FlashForth
\ 
\ See FlashForth for the details
\ FlashForth is licensed according to the GNU General Public License*

-baseutil
marker -baseutil
decimal ram

\ MCU without eeprom
: .free
  decimal
  cr ." Flash:" flash hi here - u. ." bytes"
  cr ." Ram:" ram hi here - u. ." bytes"
;


