
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                              klib.asm
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
extern  macro %1    ;统一用extern导入外部标识符
	extrn %1
endm

; 导入全局变量
extern _input:near
extrn _cmain:near
extrn	_disp_pos:near
extern _create_new_PCB:near
extern _kernal_mode:near
extern _process_number:near
extern _current_process_number:near
extern _first_time:near
extern _save_PCB:near
extern _schedule:near
extern _get_current_process_PCB:near
extern _sector_number:near
extern _current_seg:near

back_time dw 1

;**************************************************
;* 内核库过程版本信息                             *
;**************************************************

;************ *****************************
; *SCOPY@                               *
;****************** ***********************
; 实参为局部字符串带初始化异常问题的补钉程序
public SCOPY@
SCOPY@ proc 
		arg_0 = dword ptr 6
		arg_4 = dword ptr 0ah
		push bp
		mov bp,sp
		push si
		push di
		push ds
		lds si,[bp+arg_0]
		les di,[bp+arg_4]
		cld
		shr cx,1
		rep movsw
		adc cx,cx
		rep movsb
		pop ds
		pop di
		pop si
		pop bp
		retf 8
SCOPY@ endp

;清屏
public _cls
_cls proc 
        push ax
        push bx
        push cx
        push dx	
		mov	ax, 600h	; AH = 6,  AL = 0
		mov	bx, 700h	; 黑底白字(BL = 7)
		mov	cx, 0		; 左上角: (0, 0)
		mov	dx, 184fh	; 右下角: (24, 79)
		int	10h		; 显示中断
		
		mov dx,0	;调用功能号为2的10h号中断，每次清屏后重新设置光标位置为（0,0）
        mov bx,0    
        mov ah,2
        int 10h
		
		pop dx
		pop cx
		pop bx
		pop ax
        mov word ptr [_disp_pos],0
		ret
_cls endp


; 字符输出，此处采用上一个实验中使用过的功能号为0eh的10h号中断
public _printchar
_printchar proc 
	push bp
	mov bp,sp
	mov al,[bp+4]  ;传参的参数地址存入堆栈中，但由于push了BP寄存器，所以要+4而不是+2
	mov bl,0
	mov ah,0eh
	int 10h
	mov sp,bp
	pop bp
	ret
_printchar endp


; 读一个字符
public _getChar
_getChar proc
	mov ah,0
	int 16h
	mov byte ptr [_input], al
	ret
_getChar endp


;系统时间
public _gettime
_gettime proc
	push bp
	push bx
	push cx
	push dx
	push ax
	push di
	mov bp,sp
	mov ah, 2h
	int 1ah
	mov ax, [bp + 14] ;传参中，参数的地址按序存入堆栈中，但是由于之前push的寄存器占了12byte，故要使bp+14，以下同理
	mov bx, ax
	mov [bx], ch  
	mov ax, [bp + 16]
	mov bx, ax
	mov [bx], cl
	mov ax, [bp + 18]
	mov bx, ax
	mov [bx], dh
	mov sp, bp
	pop di
	pop ax
	pop dx
	pop cx
	pop bx
	pop bp
	ret
_gettime endp


;=========================================================================
;					void _run_process()
;=========================================================================
public _run_process
_run_process proc
	push es
	
	mov ax, word ptr [_current_seg]
	mov es, ax
	mov bx, 100h
	mov ah, 2
	mov al, 1
	mov dl, 0
	mov dh, 0
	mov ch, 0
	mov cl, byte ptr [_sector_number]
	int 13h
	
	call _create_new_PCB
	
	pop es
	ret
_run_process endp


public _runint   ;不含键盘中断的运行用户程序
_runint proc
   push ax
    push bx
    push cx
    push dx
	push es
	push ds

	push bp
	push ax
	mov bp, sp  
	mov ax, [bp+20] 
	push ax
	mov ax, [bp + 18]
	push ax
	call _load1 ;读软盘或硬盘上的若干物理扇区到内存的ES:BX处：
	pop ax
	pop ax
	mov ax, 7e00h
	call ax
	
	
	mov sp, bp
	pop ax
	pop bp
	
	pop ax
	mov ds,ax
	pop ax
	mov es,ax
	pop dx
	pop cx
	pop bx
	pop ax
	ret						
_runint endp


public _load1
_load1 proc					
	push bp
	push ax
	push bx
	push cx
	push dx
	mov bp, sp  
	mov ax, cs
	mov es,ax       
	mov ax, 7e00h   
	mov bx, ax;      
	mov ah,2                
	mov al,[bp+12]                
	mov dl,0                 
	mov dh,0                
	mov ch,0                 
	mov cl,[bp+14]          
	int 13H 				
	mov sp, bp
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret						
_load1 endp

;=========================================================================
;					void _set_timer()
;=========================================================================
public _set_timer
_set_timer proc
	push ax
	mov al, 36h
	out 43h, al
	mov ax, 11931		;频率为100Hz
	out 40h, al
	mov al, ah
	out 40h, al
	pop ax
	ret
_set_timer endp


;=========================================================================
;					void _set_clock()
;=========================================================================
public _set_clock
_set_clock proc
	push es
	call near ptr _set_timer
	xor ax, ax
	mov es, ax
	mov word ptr es:[20h], offset Timer
	mov word ptr es:[22h], cs
	pop es
	ret
_set_clock endp



;****************************
; 时钟中断程序              *
;****************************
Timer:
	cmp word ptr [_kernal_mode], 1
	jne process_timer
	jmp kernal_timer
	
process_timer:
	.386
	push ss
	push gs
	push fs
	push es
	push ds
	.8086
	push di
	push si
	push bp
	push sp
	push dx
	push cx
	push bx
	push ax
	
	cmp word ptr [back_time], 0
	jnz time_to_go
	mov word ptr [back_time], 1
	mov word ptr [_kernal_mode], 1
	push 512
	push 800h
	push 100h
	iret
	
time_to_go:
	inc word ptr [back_time]
	mov ax, cs
	mov ds, ax
	mov es, ax
	call _save_PCB
	call _schedule
	
store_PCB:
	mov ax, cs
	mov ds, ax
	call _get_current_process_PCB
	mov si, ax
	mov ss, word ptr ds:[si]
	mov sp, word ptr ds:[si+2*7]
	cmp word ptr [_first_time], 1
	jnz next_time
	mov word ptr [_first_time], 0
	jmp start_PCB
	
next_time:
	add sp, 11*2						
	
start_PCB:
	mov ax, 0
	push word ptr ds:[si+2*15]
	push word ptr ds:[si+2*14]
	push word ptr ds:[si+2*13]
	
	mov ax, word ptr ds:[si+2*12]
	mov cx, word ptr ds:[si+2*11]
	mov dx, word ptr ds:[si+2*10]
	mov bx, word ptr ds:[si+2*9]
	mov bp, word ptr ds:[si+2*8]
	mov di, word ptr ds:[si+2*5]
	mov es, word ptr ds:[si+2*3]
	.386
	mov fs, word ptr ds:[si+2*2]
	mov gs, word ptr ds:[si+2*1]
	.8086
	push word ptr ds:[si+2*4]
	push word ptr ds:[si+2*6]
	pop si
	pop ds
	
process_timer_end:
	push ax
	mov al, 20h
	out 20h, al
	out 0A0h, al
	pop ax
	iret
	
kernal_timer:
    push es
	push ds
	
	dec byte ptr es:[cccount]		    ;递减计数变量
	jnz fin								; >0 跳转
	inc byte ptr es:[tmp]				;自增tmp
	cmp byte ptr es:[tmp], 1			;根据tmp选择显示内容
	jz ch1								;1显示‘/’
	cmp byte ptr es:[tmp], 2			;2显示‘|’
	jz ch2
	cmp byte ptr es:[tmp], 3			;3显示‘\’
	jz ch3
	cmp byte ptr es:[tmp], 4			;4显示‘-’
	jz ch4
	
ch1:
	mov bl, '/'
	jmp showch
	
ch2:
	mov bl, '|'
	jmp showch
	
ch3:
    mov bl, '\'
	jmp showch
	
ch4:
	mov byte ptr es:[tmp],0
	mov bl, '-'
	jmp showch
	
showch:
	.386
	push gs
	mov	ax,0B800h				; 文本窗口显存起始地址
	mov	gs,ax					; GS = B800h
	mov ah,0Fh
	mov al,bl
	mov word[gs:((80 * 24 + 78) * 2)], ax
	pop gs    
	.8086
	mov byte ptr es:[cccount],8
	
fin:
	mov al,20h					        ; AL = EOI
	out 20h,al						    ; 发送EOI到主8529A
	out 0A0h,al					        ; 发送EOI到从8529A
	
	pop ds
	pop es                              ; 恢复寄存器信息
	iret		
	
	cccount db 8					     ; 计时器计数变量，初值=8
	tmp db 0

public _setNewInt  ;安装中断向量的函数
_setNewInt proc
	push bp
	push ax
	push es
	mov bp, sp  
	mov ax, 0
	mov es, ax  ;将段地址设置为0000h
	mov al, 4
	mov bl, [bp+10]  
	mul bl   ;中断序号*4的处理
	mov di, ax
	mov ax, [bp+8]
	mov word ptr es:[di], ax ; 设置中断向量的偏移地址
	add di, 2
	mov word ptr es:[di], cs; 设置中断向量的段地址
	mov sp, bp
	pop es
	pop ax
	pop bp
	ret
_setNewInt endp
	
public setint34
setint34 proc
	push ax
	push es
	mov ax, 34
	push ax
	mov ax, offset int34
	push ax
	call _setNewInt  ;安装34号向量
	pop ax
	pop ax
	pop es
	pop ax
	ret

int34:
	push bp
	push ax
	push bx
	push cx
	push dx
	push es
	push ds
	mov ax, 0b800h                    ;显示'INT34'
	mov es,ax
	mov di, (80*1+0)*2
	mov ah, 0Fh
	mov al, 'I'
	mov word ptr es:[di], ax
	mov al, 'N'
	mov word ptr es:[di+2], ax
	mov al, 'T'
	mov word ptr es:[di+4], ax
	mov al, '3'
	mov word ptr es:[di+6], ax
	mov al, '4'
	mov word ptr es:[di+8], ax
	
	mov ax,cs 
	mov ds,ax
	mov es,ax
	mov ss,ax
	mov ah,13h 
	mov al,1 
	mov bl,0ah 
	mov bh,0 
	mov dh,6 
	mov dl, 0
	mov bp,offset str1 
	mov cx,23 
	int 10h ; 调用10H号中断显示字符


	pop ds
	pop es
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	iret

str1 db "The experiment is hard!"
setint34 endp


; 设置35号中断
public setint35
setint35 proc
	push ax
	push es
	mov ax, 35
	push ax
	mov ax, offset int35
	push ax
	call _setNewInt
	pop ax
	pop ax
	pop es
	pop ax
	ret

int35:
	push bp
	push ax
	push bx
	push cx
	push dx
	push es
	push ds
	
	mov ax, 0b800h                    ;显示'INT35'
	mov es,ax
	mov di, (80*1+40)*2
	mov ah, 0Fh
	mov al, 'I'
	mov word ptr es:[di], ax
	mov al, 'N'
	mov word ptr es:[di+2], ax
	mov al, 'T'
	mov word ptr es:[di+4], ax
	mov al, '3'
	mov word ptr es:[di+6], ax
	mov al, '5'
	mov word ptr es:[di+8], ax

	mov ax,cs 
	mov ds,ax
	mov es,ax
	mov ss,ax

	mov ah,13h 
	mov al,1 
	mov bl,0bh 
	mov bh,0 
	mov dh,6 
	mov dl, 40
	mov bp,offset str2 
	mov cx,23 
	int 10h 
	
	pop ds
	pop es 
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	iret
int35end:
setint35 endp
str2 db "But I will try my best!"


; 设置36号中断
public setint36
setint36 proc
	push ax
	push es
	mov ax, 36
	push ax
	mov ax, offset int36
	push ax
	call _setNewInt 
	pop ax
	pop ax
	pop es
	pop ax
	ret

int36:
	push bp
	push ax
	push bx
	push cx
	push dx
	push es
	push ds
	
	mov ax, 0b800h                 ;显示'INT36'
	mov es,ax
	mov di, (80*13+0)*2
	mov ah, 0Fh
	mov al, 'I'
	mov word ptr es:[di], ax
	mov al, 'N'
	mov word ptr es:[di+2], ax
	mov al, 'T'
	mov word ptr es:[di+4], ax
	mov al, '3'
	mov word ptr es:[di+6], ax
	mov al, '6'
	mov word ptr es:[di+8], ax

	mov ax,cs 
	mov ds,ax
	mov es,ax
	mov ss,ax

	mov ah,13h
	mov al,1 
	mov bl,0ch 
	mov bh,0
	mov dh,19 
	mov dl, 0
	mov bp,offset str3 
	mov cx,37 
	int 10h 
	
	pop ds
	pop es
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	iret
int36end:
setint36 endp
str3 db "I will finish it before the deadline!"


; 设置37号中断
public setint37
setint37 proc
	push ax
	push es
	mov ax, 37
	push ax
	mov ax, offset int37
	push ax
	call _setNewInt
	pop ax
	pop ax
	pop es
	pop ax
	ret

int37:
	push bp
	push ax
	push bx
	push cx
	push dx
	push es
	push ds
	
	mov ax, 0b800h                 ;显示'INT37'
	mov es,ax
	mov di, (80*13+40)*2
	mov ah, 0Fh
	mov al, 'I'
	mov word ptr es:[di], ax
	mov al, 'N'
	mov word ptr es:[di+2], ax
	mov al, 'T'
	mov word ptr es:[di+4], ax
	mov al, '3'
	mov word ptr es:[di+6], ax
	mov al, '7'
	mov word ptr es:[di+8], ax

	mov ax,cs 
	mov ds,ax
	mov es,ax
	mov ss,ax

	mov ah,13h 
	mov al,1
	mov bl,0dh 
	mov bh,0 
	mov dh,19 
	mov dl, 40
	mov bp,offset str4 
	mov cx,22 
	int 10h 
	pop ds
	pop es
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	iret
int37end:
setint37 endp
str4 db "Zheng Yingxue 16337327"
