extern int strlen(char *str);
extern void printchar(char ch);
extern void showhello();
extern void showtimeint();
extern void showdateint();
extern void cls();
char a[100];
int n;
int flag;
int _disp_pos=0;
void printf(char *ch){
	while (*ch != '\0'){
		printchar(*ch);
		ch++;
	}
}
int i =0;
int strcmp(char str1[], char str2[], int len1, int len2) /*实现两个字符串的比较*/
{
	if(len1 < len2) return 0;
	for(i = 0; i < len2; i++)
		if(str1[i] != str2[i]) return 0;
	return 1;
}
void main()
{
	while(1){
		printf("\r\n");
		printf("Input 0/1/2 to get the system call\r\n");	
		printf("0: show 'hello' \r\n1: show the current time\r\n2: show the current date\r\n");
		printf(">> ");
		n=0;
		n = strlen(a);
		if (strcmp(a,"0",n,1)) flag=0;
		else if (strcmp(a,"1",n,1)) flag=1;
		else if (strcmp(a,"2",n,1)) flag=2;
		else {
			printf("\r\nWrong input,please input 0~2");
		}
		switch (flag)
		{
			case 0:
				showhello();
				printf("\r\n");
				break;
			case 1:
				showtimeint();
				printf("\r\n");
				break;
			case 2:
				showdateint();
				printf("\r\n");
				break;
		}
	}
}	