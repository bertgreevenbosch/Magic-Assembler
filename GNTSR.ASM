; +-------------------------------------------------+ ;
; | Sample TSR program for use with Magic Assembler | ;
; +-------------------------------------------------+ ;

        mov     ah,09
        mov     dx,offset(hdtxt)
        int     21
        mov     ax,1100
        mov     cx,000a
        mov     dx,0030
        mov     bx,1010
        mov     bp,offset(data)
        int     10
        mov     ax,3510
        int     21
        mov     rlseg,es
        mov     rlofs,bx
        mov     ax,2510
        mov     dx,offset(therout)
        int     21
        mov     ax,3100
        mov     dx,offset(end)/16+1
        add     dx,0011      
        int     21

therout cmp     ax,0003
        je      @1
        cmp     ax,0083
        je      @1
        pushf
        cs:
        callf   rlofs
        iret
@1      pushf
        cs:
        callf   rlofs
        push    ax
        push    cx
        push    dx
        push    bx
        push    bp
        push    es
        push    cs
        pop     es
        mov     ax,1100
        mov     cx,000a
        mov     dx,0030
        mov     bx,1010
        mov     bp,offset(data)
        pushf
        cs:
        callf   rlofs
        pop     es
        pop     bp
        pop     bx
        pop     dx
        pop     cx
        pop     ax
        iret
    
data    db      00 00 00 00 02 7c ce ce d6 e6 e6 7c 80 00 00 00 ; 0
        db      00 00 00 00 00 78 18 18 18 18 18 7e 00 00 00 00 ; 1
        db      00 00 00 00 00 7c c6 0c 18 30 60 fe 00 00 00 00 ; 2
        db      00 00 00 00 00 7c c6 06 06 1c 06 06 06 c6 7c 00 ; 3
        db      00 00 00 00 00 0c 6c 6c 6c cc cc fe 0c 0c 0c 00 ; 4
        db      00 00 00 00 00 fe c0 c0 c0 fc c6 06 06 c6 7c 00 ; 5
        db      00 00 3c 66 c0 c0 fc c6 c6 c6 c6 7c 00 00 00 00 ; 6
        db      00 00 00 00 00 fe 0c 18 18 30 30 60 60 c0 c0 00 ; 7
        db      00 00 7c c6 c6 c6 7c c6 c6 c6 c6 7c 00 00 00 00 ; 8
        db      00 00 00 00 00 7c c6 c6 c6 c6 7e 06 06 cc 78 00 ; 9
hdtxt   db      'Good Numbers TSR v2.0 - Written by Bert Greevenbosch for Magic Software' 0a 0d
        db      'Public Domain Version' 0a 0d '$'
-
rlofs   dw      ?
rlseg   dw      ?
end
