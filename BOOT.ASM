; +------------------------------------------------------------+ ;
; | Sample bootsector program for use with the Magic Assembler | ;
; +------------------------------------------------------------+ ;

        mov     ax,07c0
        mov     ds,ax
        xor     bx,bx
        mov     ah,0e
        mov     si,offset(string)
@1      lodsb
        cmp     al,00
        je      @2
        int     10
        jmps    @1
@2      xor     ah,ah
        int     16
        callf   ffff:0000

string  db      'Sorry, this disk is not bootable.' 0a 0d 
        db      'Please insert another disk and press any key to reboot.' 0a 0d 00
