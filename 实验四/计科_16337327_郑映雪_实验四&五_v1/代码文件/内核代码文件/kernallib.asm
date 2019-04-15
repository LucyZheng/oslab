
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                              klib.asm
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


; 导入全局变量
extrn	_disp_pos
extrn   _showTime:near
extrn   _showDate:near
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
	
	mov ah,0eh 	    ; 功能号
	mov bl,0 		
	int 10h 		; 调用10H号中断
	mov ah,0
	ret
_getChar endp


;读入字符串，返回读入的字符串的个数
public _strlen
_strlen proc
	push bp
	push cx
	push dx
	push bx
	mov bp, sp
	xor dx,dx
	mov ax, offset [bp+10] ;传参中，参数的地址存入堆栈中，但前面push了4个寄存器，故使bp+10，下同。
	mov bx,ax ;bx存储参数的地址
now: 
	mov ah,0
	int 16h ;调用16h中断，输入字符
 
	cmp al,13
	je exit ;回车即结束长度统计
	cmp al,8
	jne save ;退格就不会计入长度
 
	mov ax, 0
	cmp dx, ax
	je first
	jmp back

first:
	push bx
	push dx
	
	mov bh,0 ;显示第0页的信息
	mov ah,3
	int 10h  ;此处调用功能号为03h的10h号中断，读取光标信息，行和列分别保存在 dh和dl中
	
	mov bh,0 ;在光标处显示空格，即可以让光标仿照真正的shell一样在后面
	mov ah,2
	int 10h  
	mov bh,0
	mov al,' '
	mov bl,07h 
	mov cx,1
	mov ah,9
	pop dx
	pop bx
	jmp next

save:
	mov byte ptr [bx],al
	push bx
	push dx
showch@: ; 显示键入字符
	mov ah,0eh 	    
	mov bl,0 		
	int 10h 		
	mov ah,0
	pop dx
	pop bx
	inc bx
	inc dx
next:
	jmp now
exit:
	mov ax,dx ;调用函数的返回值储存在ax中
	mov sp, bp
	pop bx
	pop dx
	pop cx
	pop bp
	ret
_strlen endp


;退格时存储空格字符在光标处
back proc
	sub bx,1
	sub dx,1
	push bx
	push dx
	mov bh,0
	mov ah,3
	int 10h
	sub dl,1
	mov bh,0
	mov ah,2
	int 10h
	mov bh,0
	mov al,' '	
	mov bl,7 
	mov cx,1 
	mov ah,9  ;9号功能的10h号中断作用是在当前光标处显示字符
	int 10h 
	pop dx
	pop bx
	jmp next
back endp



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

public _getDate
_getdate proc
	push bp
	push bx
	push cx
	push dx
	push ax
	push di
	mov bp,sp
	;mov ah,2ah;cx,dh,dl中分别年月日
	;int 21h
	mov ah, 4h
	int 1ah
	mov ax, [bp + 14]
	mov bx, ax
	mov [bx], cx
	mov ax, [bp + 16]
	mov bx, ax
	mov [bx], dh
	mov ax, [bp + 18]
	mov bx, ax
	mov [bx], dl
	mov sp, bp
	pop di
	pop ax
	pop dx
	pop cx
	pop bx
	pop bp
	ret
_getdate endp


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

; 含键盘中断的运行子程序
public _run 
_run proc
   push ax
    push bx
    push cx
    push dx
	push es
	push ds

	xor ax,ax
	mov es,ax
	push word ptr es:[9*4]                  ;将9h中断入栈，再出栈保存在数据中
	pop word ptr ds:[0]
	push word ptr es:[9*4+2]
	pop word ptr ds:[2]

	mov word ptr es:[24h],offset keyboard		; 设置键盘中断向量的偏移地址
	mov ax,cs 
	mov word ptr es:[26h],ax

	push bp
	push ax
	mov bp, sp  
	mov ax, [bp+20] 
	push ax
	mov ax, [bp + 18]
	push ax
	call _load ;读软盘或硬盘上的若干物理扇区到内存的ES:BX处：
	pop ax
	pop ax
	mov ax, 7e00h
	call ax
	
	xor ax,ax
	mov es,ax
	push word ptr ds:[0]                     ;将存有原中断的数据入栈再出栈到出栈保存到原中断地址
	pop word ptr es:[9*4]
	push word ptr ds:[2]
	pop word ptr es:[9*4+2]
	int 9h
	
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
_run endp


public _load
_load proc					
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
_load endp

keyboard:
    push ax
    push bx
    push cx
    push dx
	push bp

print:
	push ax
	push es
	mov ax,0B800h
	mov es,ax
	mov ah, 0Fh
	mov al, 'O'
	mov word ptr es:[((12*80+40)*2)],ax
	mov al, 'U'
	mov word ptr es:[((12*80+41)*2)],ax
	mov al, 'C'
	mov word ptr es:[((12*80+42)*2)],ax
	mov al, 'H'
	mov word ptr es:[((12*80+43)*2)],ax
	mov al, '!'
	mov word ptr es:[((12*80+44)*2)],ax
	
	; 延迟微小的时间再让ouch消失
    mov cx,delayTime      
deloop:
	mov word ptr ds:[t],cx          
	mov cx,delayTime
	loop1:loop loop1 
	mov cx,word ptr ds:[t]          
	loop deloop

	
	mov al, ' '
	mov word ptr es:[((12*80+40)*2)],ax
	mov al, ' '
	mov word ptr es:[((12*80+41)*2)],ax
	mov al, ' '
	mov word ptr es:[((12*80+42)*2)],ax
	mov al, ' '
	mov word ptr es:[((12*80+43)*2)],ax
	mov al, ' '
	mov word ptr es:[((12*80+44)*2)],ax
	
	pop es
	pop ax
    
	in al,60h	;清除键盘数据锁存器，以便下次还可以触发
	mov al,20h					    ; AL = EOI
	out 20h,al						; 发送EOI到主8529A
	out 0A0h,al					    ; 发送EOI到从8529A

	pop bp
	pop dx
	pop cx
	pop bx
	pop ax
	iret							; 从中断返回

	delayTime equ 3000   ;延迟时间
	t dw 0

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


;	时钟中断程序
public setMyClock 
setMyClock proc
	push ax	
	mov ax, 8  ;安装8号中断
	push ax
	mov ax, offset MyClock
	push ax
	call _setNewInt  ;调用安装中断的函数安装中断
	pop ax
	pop ax
	pop ax
	ret

MyClock:	
	push ax
	push es
	jmp MyClockBegin
	charA equ 1
	charB equ 2
	charC equ 3
	charD equ 4
	chx dw charA
	delay equ 5					; 计时器延迟计数
	count dw delay				;计时器计数变量，初值=delay


MyClockBegin:
	dec word ptr [count]				; 递减计数变
	jnz endd@						; >0：跳转
	mov word ptr [count], delay			; 重置计数变量=初值delay
	call showChar
	jmp endd@

showChar:
	mov	ax,0B800h				; 文本窗口显存起始地址
	mov	es,ax					; GS = B800h
	mov ax, 1
	mov di, (24*80+79)*2 		;右下角
	cmp ax, word ptr[chx]		
	jz show1
	mov ax, 2
	cmp ax, word ptr[chx]
	jz show2
	mov ax, 3
	cmp ax, word ptr[chx]
	jz show3
	mov ax, 4
	cmp ax, word ptr[chx]
	jz show4	
show1:							;轮流显示“LOVE”
	mov ah,0FAh
	mov al, 'L'
	mov word ptr es:[di], ax
	mov word ptr [chx], 2
	ret
show2:                          
	mov ah,0E8h
	mov al, 'O'
	mov word ptr es:[di], ax
	mov word ptr [chx], 3
	ret
show3:                          
    mov ah,0A1h
	mov al, 'V'
	mov word ptr es:[di], ax
	mov word ptr [chx], 4
	ret
show4:                          
    mov ah,09Eh
	mov al, 'E'
	mov word ptr es:[di], ax
	mov word ptr [chx], 1
	ret
endd@:						; 从中断返回
	pop es
	pop ax
	mov al,20h					; AL = EOI
	out 20h,al						; 发送EOI到主8529A
	out 0A0h,al					; 发送EOI到从8529A
	iret
	

setMyClock endp



; 设置34号中断
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


;33号中断：系统调用
public setint33
setint33 proc
	push ax
	push es
	mov ax, cs
	push ax
	mov ax, 33
	push ax
	mov ax, offset int33
	push ax
	call _setNewInt
	pop ax
	pop ax
	pop ax
	pop es
	pop ax
	ret

int33:
	push bp
	push bx
	push cx
	push dx
	push es
	push ds	
	cmp ah, 0                ;根据功能号实现对应的功能
	je int330
	cmp ah, 1
	je int331
	cmp ah, 2
	je int332
int330:				;0号功能：在屏幕中间显示"HELLO"
	push es
	push ax	           
	mov ax, 0b800h                   
	mov es,ax
	mov di, (80*13+38)*2
	mov ah, 0ah
	mov al, 'H'
	mov word ptr es:[di], ax
	mov ah, 0Bh
	mov al, 'E'
	mov word ptr es:[di+2], ax
	mov ah, 0Ch
	mov al, 'L'
	mov word ptr es:[di+4], ax
	mov ah, 0Dh
	mov al, 'L'
	mov word ptr es:[di+6], ax
	mov ah, 0eh
	mov al, 'O'
	mov word ptr es:[di+8], ax
	pop ax
	pop es
	jmp int33end

int331:               ;1号功能，在屏幕下方显示当前时间
	mov bh,0          ;读光标位置，(dh,dl) = (行，列)
 	mov ah,3
 	int 10h				
	push dx           ;保存光标位置
	mov dh, 24
	mov dl, 38       ;设置光标位置(dh,dl) = (24，38)
 	mov bh,0
 	mov ah,2
 	int 10h
 	call _showTime    ;调用C文件中的函数，在屏幕下方显示当前的时间
 	pop dx
 	mov bh,0          ;恢复光标位置(dh,dl)
 	mov ah,2
 	int 10h
	jmp int33end

int332:		;2号功能，在屏幕偏上方显示时间
	mov bh,0          ;读光标位置，(dh,dl) = (行，列)
 	mov ah,3
 	int 10h				
	push dx           ;保存光标位置
	mov dh, 12
	mov dl, 38       ;设置光标位置(dh,dl) = (12，38)
 	mov bh,0
 	mov ah,2
 	int 10h
 	call _showDate    ;调用C文件中的函数，在屏幕下方显示当前的时间
 	pop dx
 	mov bh,0          ;恢复光标位置(dh,dl)
 	mov ah,2
 	int 10h
	jmp int33end

int33end:
	pop ds
	pop es
	pop dx
	pop cx
	pop bx
	pop bp
	iret
setint33 endp
