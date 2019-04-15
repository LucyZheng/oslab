
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                              klib.asm
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


; 导入全局变量
extrn	_disp_pos

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




; 运行子程序
public _run 
_run proc
	push bp
	push ax
	mov bp, sp  
	mov ax, [bp+8] 
	push ax
	mov ax, [bp + 6]
	push ax
	call _load ;读软盘或硬盘上的若干物理扇区到内存的ES:BX处：
	pop ax
	pop ax
	mov ax, 7e00h
	call ax
exits:	
	mov sp, bp
	pop ax
	pop bp
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
