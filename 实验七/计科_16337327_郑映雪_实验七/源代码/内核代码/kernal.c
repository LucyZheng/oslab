#include "PCB.h"

extern void getChar();
extern void cls();
extern void printChar();
extern void run_process();

char input, sector_number, sector_size;

void print(char *str) {
	while(*str != '\0') {
		printChar(*str);
		str++;
	}
}

void getline(char *ptr, int length) {
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
				print("\n\r");
				return;
			}
			getChar();
		}
		ptr[count] = '\0';
		print("\n\r");
		return;
	}
}

int strcmp(char *str1, char *str2) {
	while ((*str1) && (*str2)) {
		if (*str1 != *str2) {
			if (*str1 < *str2) return -1;
			return 1;
		}
		++str1;
		++str2;
	}
	return (*str1) - (*str2);
}

int strlen(char *str) {
	int i = 0;
	while(*(str++)) i++;
	return i;
}

int substr(char *src, char *sstr, int pos, int len) {
	int i = pos;
	for (; i < pos + len; ++i) {
		sstr[i - pos] = src[i];
	}
	sstr[pos + len] = '\0';
	return 1;
}


void dir() {
	print("This program has only one userprogram.\n\r");
}

void help() {
	print("cls     -- clean the screen\n\r");
	print("dir     -- show the information of programs\n\r");
	print("test    -- test Multi-process cooperation\n\r");
	print("r       -- run user programs like r 1234\n\r");
	print("help    -- show all the supported shell commands\n\n\r");
}

void create_process(char *comm) {
	int i, sum = 0, flag = 0;
	for (i = 1; i < strlen(comm); ++i) {
		if (comm[i] == ' ' || comm[i] >= '1' && comm[i] <= '4') continue;
		else {
			print("invalid program number: ");
			printChar(comm[i]);
			print("\n\n\r");
			return;
		}
	}
	for (i = 1; i < strlen(comm); ++i) {
		if (comm[i] != ' ') flag = 1;
	}
	if (flag == 0) {
		print("invalid input\n\n\r");
		return;
	}
	for (i = 1; i < strlen(comm) && sum < MAX_PCB_NUMBER; ++i) {
		if (comm[i] == ' ') continue;
		sum++;
		sector_number = comm[i] - '0' + 10;
		sector_size = 1;
		run_process();
	}
	PCB_initial(&PCB_LIST[0], 1, 0x1000);
	kernal_mode = 0;
}

cmain() {
	initial_PCB_settings();
	cls();
	print("Welcome to ZhengYingXue's OS!\n\r");
	print("You can input 'help' to get the help.\n\r");
	kernal_mode = 1;
	for (;;) {
		char commands[100];
		print(">>");
		getline(commands, 100);
		if (strcmp(commands, "help") == 0) help();
		else if (strcmp(commands, "cls") == 0) cls();
		else if (strcmp(commands, "dir") == 0) dir();
		else if (commands[0] == 'r') create_process(commands);
		else if (strcmp(commands, "test") == 0) {
			cls();
			sector_number = 15;
			sector_size = 2;
			run_process();
			kernal_mode = 0;	
		}
		else if (commands[0] == '\0') continue;
		else print("Wrong input.\r\n");
	}
}