org  7c00h		; BIOS将把引导扇区加载到0:7C00处，并开始执行
Start:
mov	ax, cs	; 置其他段寄存器值与CS相同
mov	ds, ax	; 数据段
LoadKernal:
;读软盘或硬盘上的kernal到内存的ES:BX处：
mov ax, _seg  ;段地址 ; 存放数据的内存基地址
mov es,ax           ;设置段地址（不能直接mov es,段地址）
mov bx, _offset  ;偏移地址; 存放数据的内存偏移地址
mov ah,2                ; 功能号
mov al, 9        ;扇区数
mov dl,0          ;驱动器号 ; 软盘为0，硬盘和U盘为80H
mov dh,0          ;磁头号 ; 起始编号为0
mov ch,0          ;柱面号 ; 起始编号为0
mov cl,2           ;起始扇区号 ; 起始编号为1
int 13H 

jmp _seg : _offset
jmp $           

_offset  equ 100h
_seg    equ 800h   
times 510-($-$$)	db	0	
	db 	55h, 0aah				
