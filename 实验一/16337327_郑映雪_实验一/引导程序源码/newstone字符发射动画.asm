; 程序源代码（stone.asm）
; 本程序在文本方式显示器上从左边射出一个*号,以45度向右下运动，撞到边框后反射,如此类推.
;  凌应标 2014/3
;   NASM汇编格式
    Dn_Rt equ 1                  ;D-Down,U-Up,R-right,L-Left
    Up_Rt equ 2                  ;
    Up_Lt equ 3                  ;
    Dn_Lt equ 4                  ;
    delay equ 50000					; 计时器延迟计数,用于控制画框的速度
    ddelay equ 400					; 计时器延迟计数,用于控制画框的速度

    org 07c00h					
start:
	 mov ax,0xB800
     mov es,ax
     mov byte [es:0],'Z'
     mov byte [es:1],7
	 mov byte [es:2],'h'
     mov byte [es:3],7
	 mov byte [es:4],'e'
     mov byte [es:5],7
	 mov byte [es:6],'n'
     mov byte [es:7],7
	 mov byte [es:8],'g'
     mov byte [es:9],7
	 mov byte [es:10],'Y'
     mov byte [es:11],7
	 mov byte [es:12],'X'
     mov byte [es:13],7
	;xor ax,ax					; AX = 0   程序加载到0000：100h才能正确执行
      mov ax,cs
	mov es,ax					; ES = 0
	mov ds,ax					; DS = CS
	mov es,ax					; ES = CS
	mov	ax,0B800h				; 文本窗口显存起始地址
	mov	gs,ax					; GS = B800h
    mov byte[char],'*' 
	mov byte[co],0FAh           ;颜色初始化
	
loop1:
	dec word[count]				; 递减计数变量
	jnz loop1					; >0：跳转;
	mov word[count],delay
	dec word[dcount]				; 递减计数变量
    jnz loop1
	mov word[count],delay
	mov word[dcount],ddelay
;实际上是把delay赋值给count里的地址，ddelay赋值给dcount的地址，两层循环，起到延时的作用。

;下段是为了判断字符初始时应该从哪个方向射入
mov al,1
cmp al,byte[rdul]
jz  DnRt
mov al,2
cmp al,byte[rdul]
jz  UpRt
mov al,3
cmp al,byte[rdul]
jz  UpLt
mov al,4
cmp al,byte[rdul]
jz  DnLt
jmp $	

DnRt:;从左下往右上运动，没有碰到两边就输出，否则反射
	inc word[x]
	inc word[y]
	mov bx,word[x]
	mov ax,25
	sub ax,bx
    jz  dr2ur
	mov bx,word[y]
	mov ax,80
	sub ax,bx
    jz  dr2dl
	jmp show
dr2ur:;碰到右边界反射
	  mov byte[co],09Ah;碰到边界后改变颜色
      mov word[x],23
      mov byte[rdul],Up_Rt	
      jmp show
dr2dl:;碰到上边界反射
	  mov byte[co],0FAh ;碰到边界后改变颜色
      mov word[y],78
      mov byte[rdul],Dn_Lt	
      jmp show

UpRt:  ;从右下往左上运动
	dec word[x]
	inc word[y]
	mov bx,word[y]
	mov ax,80
	sub ax,bx
      jz  ur2ul
	mov bx,word[x]
	mov ax,-1
	sub ax,bx
      jz  ur2dr
	jmp show
ur2ul: ;碰到上边界反射
	  mov byte[co],0F9h ;碰到边界后改变颜色
      mov word[y],78
      mov byte[rdul],Up_Lt	
      jmp show
ur2dr: ;碰到左边界反射
      mov byte[co],0EFh ;碰到边界后改变颜色
      mov word[x],1
      mov byte[rdul],Dn_Rt	
      jmp show

	
;以下两个操作同以上两个操作
UpLt:
	dec word[x]
	dec word[y]
	mov bx,word[x]
	mov ax,-1
	sub ax,bx
    jz  ul2dl
	mov bx,word[y]
	mov ax,-1
	sub ax,bx
    jz  ul2ur
	jmp show

ul2dl:
	  mov byte[co],0Fh  ;碰到边界后改变颜色
      mov word[x],1
      mov byte[rdul],Dn_Lt	
      jmp show
ul2ur:
	  mov byte[co],09Eh ;碰到边界后改变颜色
      mov word[y],1
      mov byte[rdul],Up_Rt	
      jmp show

	
	
DnLt:
	inc word[x]
	dec word[y]
	mov bx,word[y]
	mov ax,-1
	sub ax,bx
      jz  dl2dr
	mov bx,word[x]
	mov ax,25
	sub ax,bx
      jz  dl2ul
	jmp show

dl2dr:
	  mov byte[co],0A1h  ;碰到边界后改变颜色
      mov word[y],1
      mov byte[rdul],Dn_Rt	
      jmp show
	
dl2ul:
	  mov byte[co],0F5h  ;碰到边界后改变颜色
      mov word[x],23
      mov byte[rdul],Up_Lt	
      jmp show
	
show:	
    xor ax,ax                 ; 计算显存地址
    mov ax,word[x]
	mov bx,80
	mul bx
	add ax,word[y]
	mov bx,2
	mul bx
	mov bp,ax
	mov ah,[co]			 ;将当前的颜色赋值到ah以显示颜色
	mov al,byte[char]			;  AL = 显示字符值（默认值为20h=空格符）
	mov word[gs:bp],ax  		;  显示字符的ASCII码值
	jmp loop1
end:
    jmp $                   ; 停止画框，无限循环 
	
datadef:	
    count dw delay
    dcount dw ddelay
    rdul db Dn_Rt         ; 向右下运动
    x    dw 7
    y    dw 0
    char db '*'
	co db 07h ;定义颜色变量co，并在每次碰撞后都产生变化
