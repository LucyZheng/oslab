extrn	_disp_pos
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



public _showhello
_showhello proc
	push ax
	mov ah, 0
	int 33
	pop ax
	ret
_showhello endp

public _showtimeint
_showtimeint proc
	push ax
	mov ah, 1
	int 33
	pop ax
	ret
_showtimeint endp

public _showdateint
_showdateint proc
	push ax
	mov ah, 2
	int 33
	pop ax
	ret
_showdateint endp

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