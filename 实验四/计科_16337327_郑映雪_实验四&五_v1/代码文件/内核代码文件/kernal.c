extern int strlen(char *str);
extern void cls();
extern void printchar(char ch);
extern void run(int num, int first);
extern void runint(int num1, int first1);
extern void getime(int *hour, int *minute, int *second);
extern void getdate(int *year, int *month, int *day);
int disp_pos = 0;
char tmp[100] = {'\0'}; 
int n = 0;    
int flag = 0;

void printf(char *ch){
	while (*ch != '\0'){
		printchar(*ch);
		ch++;
	}
}

void help(){
	printf("help  --- for help\r\n");
	printf("dir   --- to get the information of programs\r\n");
	printf("time  --- to get current time\r\n");
	printf("run   --- to choose user programs to run\r\n");
	printf("run a --- instantly run program a.(you can input 'run a' or 'run b' or 'run c' or 'run d')\r\n");
	printf("cls   --- to clear the screen\r\n");
}
void dir(){
	printf("\r\nNo.    space                 description\r\n\r\n\r\n");
	printf("1      512KB      The letter moves in the first quadrant.\r\n");
	printf("2      512KB      The letter moves in the second quadrant.\r\n");
	printf("3      512KB      Int 34~37\r\n");
	printf("4      512KB      System calls\r\n");
	
}
void todec(int BCD){ 
	
	int n1 = 4096;
	int n2 = 0;
	char num1[6] = {'\0'};
	int index = 0;
	if(BCD == 0){ 
		printf("00");
		return;
	}
	while(BCD < n1) n1/=16;
	while(n1 > 0){ /*BCD码转为十进制*/
		n2 = BCD/n1;
		num1[index] = n2 + '0';
		index++;
		BCD %= n1;
		n1/=16;
	}
	if (index == 1) {  /*当某个单位为个位数时，在前面补上一个0，使它看上去更像真实的时钟*/
		num1[1] = num1[0];
		num1[0] = '0';
	}
	
	printf(num1);
}

void  showDate(){
	int year = 0;
	int month = 0;
	int day = 0;
	getDate(&year, &month, &day);/*获取时间*/

	/*显示获取的年月日*/
	todec(year);
	printchar('-');
	todec(month);
	printchar('-');
	todec(day);
}

void showTime(){
	int hour = 0;
	int minute = 0;
	int second = 0;
	gettime(&hour, &minute, &second); 
	todec(hour); /*int 1ah 返回的时分秒为BCD码格式，必须转为十进制*/
	printchar(':');
	todec(minute);
	printchar(':');
	todec(second);
	printf(" now!");
}

int i = 0;

int strcmp(char str1[], char str2[], int len1, int len2) /*实现两个字符串的比较*/
{
	if(len1 < len2) return 0;
	for(i = 0; i < len2; i++)
		if(str1[i] != str2[i]) return 0;
	return 1;
}

void cmain(){
	printf("  \r\n");
	printf("Welcome to Zheng Yingxue's os\r\nYou can input 'help' to get the help\r\n");
	for (;;){
		printf(">>");
		n = 0;
		n = strlen(tmp);
		printf("\r\n");
		if(strcmp(tmp,"help",n,4)) flag = 1; /*进入帮助界面*/
		else if(strcmp(tmp,"time",n,4)) flag = 2;  /*显示当前时间*/
		else if(strcmp(tmp,"run",n,3) && !strcmp(tmp,"run ",n,4) && !strcmp(tmp,"runint",n,6))flag = 3; /*进入运行子界面时运行程序*/
		else if(strcmp(tmp,"run ",n,4)) flag = 4; /*直接运行某程序*/
		else if (strcmp(tmp,"dir",n,3))flag = 5; /*显示用户程序信息*/
		else if (strcmp(tmp,"cls",n,3)) flag = 6; /*清屏*/
		else flag = 7;		
		
		switch (flag){
			case 1:{
				help();
				break;
			}
			case 2:{
				printf("It's ");
				showTime();
				break;
			}
			case 3:{
				printf("please input 'run a' /'run b' / 'run c' / 'run d'");
				printf("\r\n");
				printf("You can input 'exit' to return.\r\n");
				while(1){
					printf("pro>>"); /*进入子界面*/
					n = strlen(tmp);
					if(strcmp(tmp,"exit",n,4) == 1) break;
					else if(strcmp(tmp, "run ",n,4) == 1){
						int qflag = 0;
						for(i = 4; i < n; i++)
							if(tmp[i]<'a' || tmp[i] > 'd'){ /*对输入错误的处理输出*/
								printf("Please input run a~d.");
								qflag = 1;
								break;
							}
						if(qflag == 0)
						for(i = 4; i < 7; i++){
							switch(tmp[i]){
								case 'a':
									cls();
									run(2,12); /*调用run函数，传参为给用户程序分配的扇区数和放置用户程序的扇区，下同*/
									break;
								case 'b':
									cls();
									run(2,14);
									break;
								case 'c':
									cls();
									run(1,16);
									break;
								case 'd':
									cls();
									runint(1,17);
						
							}
						}
					}
					else printf("\r\nWrong input.");
				printf("\r\n");
				printf("\r\n");
				}
				break;
			}
			case 4:{
				int qflag = 0;
				for(i = 4; i < n; i++)
					if(tmp[i]<'a' || tmp[i] > 'd'){
						printf("Please input run a~d.");
						qflag = 1;
						break;
					}
				if(qflag == 0)
					for(i = 4; i < 7; i++){
						switch(tmp[i]){
								case 'a':
									cls();
									run(2,12);
									break;
								case 'b':
									cls();
									run(2,14);
									break;
								case 'c':
									cls();
									run(1,16);
									break;
								case 'd':
									cls();
									runint(1,17);			
									break;
						}
					}
					break;
									
			}
			case 5:{
				dir ();
				break;
			}
			case 6:{
				cls();
				break;
			}
			default : printf("Wrong input.");
		}
		printf("\r\n");
		printf("\r\n");
	}
}
