;程序源代码（myos1.asm）
org  7c00h		; BIOS将把引导扇区加载到0:7C00h处，并开始执行
OffSetOfUserPrg1 equ 8100h
OffSetOfUserPrg2 equ 8300h
OffSetOfUserPrg3 equ 8500h
OffSetOfUserPrg4 equ 8700h
OffSetOfUserPrg5 equ 8900h
Start:
	mov ax,0B800h
	mov es,ax
	
	call clear   ;调取清屏模块进行清屏
	
	mov	ax, cs	       ; 置其他段寄存器值与CS相同
	mov	ds, ax	       ; 数据段
	mov	bp, Message		 ; BP=当前串的偏移地址
	mov	ax, ds		 ; ES:BP = 串地址
	mov	es, ax		 ; 置ES=DS
	mov	cx, MessageLength  ; CX = 串长
	mov	ax, 1301h		 ; AH = 13h（功能号）、AL = 01h（光标置于串尾）
	mov	bx, 0007h		 ; 页号为0(BH = 0) 黑底白字(BL = 07h)
    mov dh, 0		       ; 行号=0
	mov	dl, 0			 ; 列号=0
	int	10h			 ; BIOS的10h功能：显示一行字符
	
	
	mov ah,00h
	int 16h		
	mov ah, 0eh                 
    mov bl, 0                   
    int 10h 	;读取键盘输入
	
	cmp al,'a'
	jl Start 
	cmp al,'e'
	jg Start    ;如果输入的字符是除了a~e（注意是小写）以外的字符，就回到开头，继续等待输入
	push ax
	sub al,'a'   ;以输入的字符减去a的ASCII码并存储，以转到正确的程序
	mov byte[x],al
	pop ax
	
	mov	ax, cs	       ; 置其他段寄存器值与CS相同
	mov	ds, ax	       ; 数据段
	mov	bp, m2		 ; BP=当前串的偏移地址
	mov	ax, ds		 ; ES:BP = 串地址
	mov	es, ax		 ; 置ES=DS
	mov	cx, ml  ; CX = 串长（=9）
	mov	ax, 1301h		 ; AH = 13h（功能号）、AL = 01h（光标置于串尾）
	mov	bx, 0007h		 ; 页号为0(BH = 0) 黑底白字(BL = 07h)
      mov dh, 24		       ; 行号=0
	mov	dl, 0			 ; 列号=0
	int	10h	
LoadnEx:

	  
     ;读软盘或硬盘上的若干物理扇区到内存的ES:BX处：
      mov ax,cs                ;段地址 ; 存放数据的内存基地址
      mov es,ax                ;设置段地址（不能直接mov es,段地址）

      mov ah,2                 ; 功能号
      mov al,1                 ;扇区数
      mov dl,0                 ;驱动器号 ; 软盘为0，硬盘和U盘为80H
      mov dh,0                 ;磁头号 ; 起始编号为0
      mov ch,0                 ;柱面号 ; 起始编号为0
	  add byte[x],2			;根据前面输入计算出x的值，以这个值来判断应该读取第几扇区
      mov cl,byte[x]                 
	  cmp cl,2		;根据前面输入计算出x的值，以这个值来判断应该跳转到哪个子程序
	  jz j1
	  cmp cl,3
	  jz j2
	  cmp cl,4
	  jz j3
	  cmp cl,5
	  jz j4
	  cmp cl,6
	  jz j5
j1:
      mov bx, OffSetOfUserPrg1  
      int 13H ;                  
      jmp OffSetOfUserPrg1
j2:
      mov bx, OffSetOfUserPrg2  
      int 13H ;                
      jmp OffSetOfUserPrg2
j3:
      mov bx, OffSetOfUserPrg3  
      int 13H ;                
      jmp OffSetOfUserPrg3
j4:   
	  mov bx, OffSetOfUserPrg4
      int 13H ;                
      jmp OffSetOfUserPrg4
j5:
      mov bx, OffSetOfUserPrg5  
      int 13H ;                  
      jmp OffSetOfUserPrg5

clear:	;清屏模块
	mov si,0
	mov cx,80*25  ;逐个将屏幕上每个字符ASCII码置零。用cx计数。
	mov dx,0
clear1:
	mov [es:si],dx  ;逐个置零
	add si,2  
	loop clear1 ;
	ret
	
data:
	x db 0
m2 db 'Press q(lower-case) to quit and return.'
ml equ ($-m2)

Message:
      db '  Please input a-e:'


MessageLength  equ ($-Message)
      times 510-($-$$) db 0
      db 0x55,0xaa

