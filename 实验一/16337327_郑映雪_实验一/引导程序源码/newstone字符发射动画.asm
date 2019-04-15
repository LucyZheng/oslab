; ����Դ���루stone.asm��
; ���������ı���ʽ��ʾ���ϴ�������һ��*��,��45���������˶���ײ���߿����,�������.
;  ��Ӧ�� 2014/3
;   NASM����ʽ
    Dn_Rt equ 1                  ;D-Down,U-Up,R-right,L-Left
    Up_Rt equ 2                  ;
    Up_Lt equ 3                  ;
    Dn_Lt equ 4                  ;
    delay equ 50000					; ��ʱ���ӳټ���,���ڿ��ƻ�����ٶ�
    ddelay equ 400					; ��ʱ���ӳټ���,���ڿ��ƻ�����ٶ�

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
	;xor ax,ax					; AX = 0   ������ص�0000��100h������ȷִ��
      mov ax,cs
	mov es,ax					; ES = 0
	mov ds,ax					; DS = CS
	mov es,ax					; ES = CS
	mov	ax,0B800h				; �ı������Դ���ʼ��ַ
	mov	gs,ax					; GS = B800h
    mov byte[char],'*' 
	mov byte[co],0FAh           ;��ɫ��ʼ��
	
loop1:
	dec word[count]				; �ݼ���������
	jnz loop1					; >0����ת;
	mov word[count],delay
	dec word[dcount]				; �ݼ���������
    jnz loop1
	mov word[count],delay
	mov word[dcount],ddelay
;ʵ�����ǰ�delay��ֵ��count��ĵ�ַ��ddelay��ֵ��dcount�ĵ�ַ������ѭ��������ʱ�����á�

;�¶���Ϊ���ж��ַ���ʼʱӦ�ô��ĸ���������
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

DnRt:;�������������˶���û���������߾������������
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
dr2ur:;�����ұ߽練��
	  mov byte[co],09Ah;�����߽��ı���ɫ
      mov word[x],23
      mov byte[rdul],Up_Rt	
      jmp show
dr2dl:;�����ϱ߽練��
	  mov byte[co],0FAh ;�����߽��ı���ɫ
      mov word[y],78
      mov byte[rdul],Dn_Lt	
      jmp show

UpRt:  ;�������������˶�
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
ur2ul: ;�����ϱ߽練��
	  mov byte[co],0F9h ;�����߽��ı���ɫ
      mov word[y],78
      mov byte[rdul],Up_Lt	
      jmp show
ur2dr: ;������߽練��
      mov byte[co],0EFh ;�����߽��ı���ɫ
      mov word[x],1
      mov byte[rdul],Dn_Rt	
      jmp show

	
;������������ͬ������������
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
	  mov byte[co],0Fh  ;�����߽��ı���ɫ
      mov word[x],1
      mov byte[rdul],Dn_Lt	
      jmp show
ul2ur:
	  mov byte[co],09Eh ;�����߽��ı���ɫ
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
	  mov byte[co],0A1h  ;�����߽��ı���ɫ
      mov word[y],1
      mov byte[rdul],Dn_Rt	
      jmp show
	
dl2ul:
	  mov byte[co],0F5h  ;�����߽��ı���ɫ
      mov word[x],23
      mov byte[rdul],Up_Lt	
      jmp show
	
show:	
    xor ax,ax                 ; �����Դ��ַ
    mov ax,word[x]
	mov bx,80
	mul bx
	add ax,word[y]
	mov bx,2
	mul bx
	mov bp,ax
	mov ah,[co]			 ;����ǰ����ɫ��ֵ��ah����ʾ��ɫ
	mov al,byte[char]			;  AL = ��ʾ�ַ�ֵ��Ĭ��ֵΪ20h=�ո����
	mov word[gs:bp],ax  		;  ��ʾ�ַ���ASCII��ֵ
	jmp loop1
end:
    jmp $                   ; ֹͣ��������ѭ�� 
	
datadef:	
    count dw delay
    dcount dw ddelay
    rdul db Dn_Rt         ; �������˶�
    x    dw 7
    y    dw 0
    char db '*'
	co db 07h ;������ɫ����co������ÿ����ײ�󶼲����仯
