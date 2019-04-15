
typedef enum PCB_STATUS{PCB_READY, PCB_EXIT, PCB_RUNNING, PCB_BLOCKED} PCB_STATUS;

typedef struct Register{
	int ss;
	int gs;
	int fs;
	int es;
	int ds;
	int di;
	int si;
	int sp;
	int bp;
	int bx;
	int dx;
	int cx;
	int ax;
	int ip;
	int cs;
	int flags;
} Register;

typedef struct PCB{
	Register regs;
	PCB_STATUS status;
	int ID;
} PCB;

int MAX_PCB_NUMBER = 8;

PCB PCB_LIST[8];

PCB *current_process_PCB_ptr;

int first_time;
int kernal_mode = 1;
int process_number = 0;
int current_seg = 0x1000;

int current_process_number = 0;

PCB *get_current_process_PCB() {
	return &PCB_LIST[current_process_number];
}

void save_PCB(int ax, int bx, int cx, int dx, int sp, int bp, int si, int di, int ds, int es, int fs, int gs, int ss, int ip, int cs, int flags) {
	current_process_PCB_ptr = get_current_process_PCB();
	
	current_process_PCB_ptr->regs.ss = ss;
	current_process_PCB_ptr->regs.gs = gs;
	current_process_PCB_ptr->regs.fs = fs;
	current_process_PCB_ptr->regs.es = es;
	current_process_PCB_ptr->regs.ds = ds;
	current_process_PCB_ptr->regs.di = di;
	current_process_PCB_ptr->regs.si = si;
	current_process_PCB_ptr->regs.sp = sp;
	current_process_PCB_ptr->regs.bp = bp;
	current_process_PCB_ptr->regs.bx = bx;
	current_process_PCB_ptr->regs.dx = dx;
	current_process_PCB_ptr->regs.cx = cx;
	current_process_PCB_ptr->regs.ax = ax;
	current_process_PCB_ptr->regs.ip = ip;
	current_process_PCB_ptr->regs.cs = cs;
	current_process_PCB_ptr->regs.flags = flags;
}

void schedule() {
	if (current_process_PCB_ptr->status == PCB_READY) {
		first_time = 1;
		current_process_PCB_ptr->status = PCB_RUNNING;
		return;
	}
	current_process_PCB_ptr->status = PCB_BLOCKED;
	current_process_number++;
	if (current_process_number >= process_number) current_process_number = 1;
	current_process_PCB_ptr = get_current_process_PCB();
	if (current_process_PCB_ptr->status == PCB_READY) first_time = 1;
	current_process_PCB_ptr->status = PCB_RUNNING;
	return;
}

void PCB_initial(PCB *ptr, int process_ID, int seg) {
	ptr->ID = process_ID;
	ptr->status = PCB_READY;
	ptr->regs.gs = 0x0B800;
	ptr->regs.es = seg;
	ptr->regs.ds = seg;
	ptr->regs.fs = seg;
	ptr->regs.ss = seg;
	ptr->regs.cs = seg;
	ptr->regs.di = 0;
	ptr->regs.si = 0;
	ptr->regs.bp = 0;
	ptr->regs.sp = 0x0100 - 4;
	ptr->regs.bx = 0;
	ptr->regs.ax = 0;
	ptr->regs.cx = 0;
	ptr->regs.dx = 0;
	ptr->regs.ip = 0x0100;
	ptr->regs.flags = 512;
}

void create_new_PCB() {
	if (process_number > MAX_PCB_NUMBER) return;
	PCB_initial(&PCB_LIST[process_number], process_number, current_seg);
	process_number++;
	current_seg += 0x1000;
}

void initial_PCB_settings() {
	process_number = 0;
	current_process_number = 0;
	current_seg = 0x1000;
}

extern void cls();
extern void printchar(char ch);
extern void run(int num, int first);
extern void getime(int *hour, int *minute, int *second);
int disp_pos = 0;
char input;

char sector_number = 11;

void printf(char *ch){
	while (*ch != '\0'){
		printchar(*ch);
		ch++;
	}
}

void help(){
	printf("help   --- for help\r\n");
	printf("dir    --- to get the information of programs\r\n");
	printf("time   --- to get current time\r\n");
	printf("r abcd --- to choose user program a, b, c, d to run together\r\n");
	printf("cls    --- to clear the screen\r\n");
}
void dir(){
	printf("\r\nNo.    space                 description\r\n\r\n\r\n");
	printf("1      512KB      The letter moves in the first quadrant.\r\n");
	printf("2      512KB      The letter moves in the second quadrant.\r\n");
	printf("3      512KB      The letter moves in the third quadrant.\r\n");
	printf("4      512KB      The letter moves in the forth quadrant.\r\n");
	
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

int strcmp(char str1[], char str2[], int len1, int len2) /*实现两个字符串的比较*/
{
	int i = 0;
	if(len1 < len2) return 0;
	for(i = 0; i < len2; i++)
		if(str1[i] != str2[i]) return 0;
	return 1;
}

int strlenn(char *str) {
	int i = 0;
	while(*(str++)) i++;
	return i;
}

void get_input(char *ptr, int length) {
	int count = 0;
	if (length == 0) {
		return;
	}
	else {
		getChar();
		while (input != 13) {
			printChar(input);
			ptr[count++] = input;
			if (count == length) {
				ptr[count] = '\0';
				printf("\n\r");
				return;
			}
			getChar();
		}
		ptr[count] = '\0';
		printf("\n\r");
		return;
	}
}

void create_process(char *comm) {
	int i, sum = 0, flagg = 0;
	for (i = 2; i < strlenn(comm); ++i) {
		if (comm[i] == ' ' || comm[i] >= 'a' && comm[i] <= 'd') continue;
		else {
			printf("  invalid program number: ");
			printChar(comm[i]);
			printf("\n\n\r");
			return;
		}
	}
	for (i = 2; i < strlenn(comm); ++i) {
		if (comm[i] != ' ') flagg = 1;
	}
	if (flagg == 0) {
		printf("  invalid input\n\n\r");
		return;
	}
	sector_number = 11;
	run_process();
	for (i = 2; i < strlenn(comm) && sum < MAX_PCB_NUMBER; ++i) {
		if (comm[i] == ' ') continue;
		sum++;
		sector_number = comm[i] - 'a' + 11;
		run_process(sector_number, current_seg);
	}
	kernal_mode = 0;
}

void cmain(){
	initial_PCB_settings();
	kernal_mode = 1;
	printf("  \r\n");
	printf("Welcome to Zheng Yingxue's os\r\nYou can input 'help' to get the help\r\n");
	for (;;){
		int n = 0;    
		char tmp[100]; 
		printf(">>");
		get_input(tmp, 100);
		n = strlenn(tmp);
		printf("\r\n");
		if(strcmp(tmp,"help",n,4)) help(); /*进入帮助界面*/
		else if (tmp[0] == 'g' && tmp[1] == 'o') {
			cls();
			create_process(tmp);
			continue;
		}
		else if(strcmp(tmp,"time",n,4)){	/*显示当前时间*/
			printf("It's ");
				showTime();
		}
		else if (strcmp(tmp,"dir",n,3)) dir(); /*显示用户程序信息*/
		else if (strcmp(tmp,"cls",n,3)) cls(); /*清屏*/
		else if (strcmp(tmp,"int",n,3)){
			cls();
			runint(1,15);
		}
		else  
			printf("Wrong input.");		
		printf("\r\n");
		printf("\r\n");
	}
}
