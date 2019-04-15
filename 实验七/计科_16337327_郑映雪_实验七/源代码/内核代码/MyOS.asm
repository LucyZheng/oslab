.8086
_TEXT segment byte public 'CODE'
assume cs:_TEXT
DGROUP group _TEXT,_DATA,_BSS
org 100h

start:
		xor ax, ax
		mov es, ax		
		mov word ptr es:[33*4], offset int_21h
		mov word ptr es:[33*4+2], cs		
		call _set_clock	
		mov ax,cs
		mov ds,ax
		mov es,ax
		mov ss,ax
		mov sp,100h
		call near ptr _cmain

    	jmp $	
		
		include kliba.asm

_TEXT ends

_DATA segment word public 'DATA'

_DATA ends

_BSS	segment word public 'BSS'
_BSS ends

end start