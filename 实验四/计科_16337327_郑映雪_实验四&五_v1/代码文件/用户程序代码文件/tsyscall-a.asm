.8086
_TEXT segment byte public 'CODE'
DGROUP group _TEXT,_DATA,_BSS
       assume cs:_TEXT
extrn _main:near
extrn _Message:near
org 100h

start:
	mov  ax,  cs
	mov  ds,  ax           ; DS = CS
	mov  es,  ax           ; ES = CS
	mov  ss,  ax           ; SS = cs
	mov  sp, 100h
	call _main
	ret
include tsyscalllib.asm
	
_TEXT ends
;************DATA segment*************
_DATA segment word public 'DATA'
_DATA ends
;*************BSS segment*************
_BSS	segment word public 'BSS'
_BSS ends
;**************end of file***********
end start
