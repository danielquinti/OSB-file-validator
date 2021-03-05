%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>

void check_file(char const*,int,int);
void check_sample(char const*);
void warning(char const*);
void yyerror (char const *);
int yylex();
extern int yylineno;
int warn=0;
%}

%union{
	char const*valString;
	int valInt;
	double valDouble;
}
%token PROLOG
%token COMMENT
%token <valString> FILEPATH
%token LAYER
%token SNAPPING
%token F_COMMAND
%token MX_COMMAND
%token MY_COMMAND
%token M_COMMAND
%token V_COMMAND
%token S_COMMAND
%token C_COMMAND
%token L_COMMAND
%token R_COMMAND
%token P_COMMAND
%token T_COMMAND
%token NL

%token V_TOKEN

%token H_PARAM
%token A_PARAM

%token <valDouble> DOUBLE
%token <valInt> INT
%token HEX
%token COMMA

%token LOOP_TYPE
%token TRIGGER_TYPE
%token ANIM_TYPE
%token SPRITE_TYPE
%token SAMPLE_TYPE
%token DEDENT
%token INDENT
%type <valInt> command command_list_1 common_params easing command_list_element
%type <valDouble>number

%start S
%%

S: cm1 prolog NL content

prolog:{yyerror("Missing prolog");}
| PROLOG

content:
|element_list

element_list:element_list element
|element
|error{yyerror("Incorrect object declaration");}


element: COMMENT NL
	|object

object: sprite_image_decl NL command_list
|anim_image_decl NL command_list
|sample_decl NL


sprite_image_decl: SPRITE_TYPE COMMA LAYER COMMA SNAPPING COMMA FILEPATH COMMA number COMMA number {check_file($7,-1,0);}
anim_image_decl:   ANIM_TYPE   COMMA LAYER COMMA SNAPPING COMMA FILEPATH COMMA number COMMA number COMMA INT COMMA INT COMMA LOOP_TYPE {check_file($7,$13,1);
	if ($13<=0) yyerror("Frame count must be 1 or higher");
	if ($15<0) yyerror("Delay between frames must be positive");}
sample_decl: SAMPLE_TYPE COMMA INT COMMA INT COMMA FILEPATH COMMA volume{if (($5<0)||($5>3))yyerror("Invalid layer id"); check_sample($7);}


volume:
	| INT {if (($1<0)||($1>100)) yyerror("Volume value must be between 0 and 100");}
	| error  {yyerror("Incorrect volume format");}


cm1: 
	| COMMENT
	;

command_list: INDENT command_list_1 DEDENT 


command_list_1: command_list_1 command_list_element{
						if (!($2>=$1) && (warn)){
							warning("Command timestamps out of order");
							printf("%d\n",$1);
							printf("%d\n",$2);
							}
						$$=$2;}
	| command_list_element{$$=$1;}

command_list_element: COMMENT {yyerror("Comments are not allowed within command lists");}
|command {$$=$1;}
|error {yyerror("This command is not well formed");}

number: INT {$$=(double)$1;}
	| DOUBLE {$$=$1;}
	| error  {yyerror("Incorrect number format");}

color: INT{if (($1<0)||($1>255)) yyerror("Color value out of range: must be between 0 and 255");}
	|HEX

parameter: V_TOKEN
	|H_PARAM
	|A_PARAM

command: F_COMMAND common_params COMMA number NL
			{if (($4<0)||($4>1)) yyerror("Opacity out of range, must be between 0 and 1"); else
			$$=$2;}
	|F_COMMAND  common_params COMMA number COMMA number NL
		{if (($4<0)||($4>1)||($6<0)||($6>1)) yyerror("Opacity out of range:must be between 0 and 1"); else
			$$=$2;}
	|M_COMMAND  common_params COMMA number COMMA number COMMA number COMMA number NL{$$=$2;}
	|M_COMMAND  common_params COMMA number COMMA number NL{$$=$2;}
	|MX_COMMAND common_params COMMA number COMMA number NL{$$=$2;}
	|MX_COMMAND common_params COMMA number NL{$$=$2;}
	|MY_COMMAND common_params COMMA number COMMA number NL{$$=$2;}
	|MY_COMMAND common_params COMMA number NL{$$=$2;}
	|S_COMMAND  common_params COMMA number NL{$$=$2;}
	|S_COMMAND  common_params COMMA number COMMA number NL{$$=$2;}
	|V_TOKEN    common_params COMMA number COMMA number COMMA number COMMA number NL{$$=$2;}
	|V_TOKEN    common_params COMMA number COMMA number NL{$$=$2;}
	|R_COMMAND  common_params COMMA number NL{$$=$2;}
	|R_COMMAND  common_params COMMA number COMMA number NL{$$=$2;}
	|C_COMMAND  common_params COMMA color COMMA color COMMA color NL{$$=$2;} 
	|C_COMMAND  common_params COMMA color COMMA color COMMA color COMMA color COMMA color COMMA color NL{$$=$2;}
	|P_COMMAND  common_params COMMA parameter NL{$$=$2;}
	|L_COMMAND  COMMA INT COMMA INT NL command_list {if ($5<0) yyerror("Number of loop iterations must be positive");$$=$3;}
	|T_COMMAND  COMMA TRIGGER_TYPE COMMA INT COMMA INT NL command_list{if ($5>$7) yyerror("Wrong interval for command: start after finish");else $$=$5;}

easing: INT {if (($1<0)||($1>34)) yyerror("Invalid easing value, must be between 0 and 34"); else $$=$1;}

common_params: COMMA easing COMMA INT COMMA {$$=$4;}
	|COMMA easing COMMA INT COMMA INT {if ($4>$6) yyerror("Wrong interval for command, start after finish");else $$=$4;}

%%
int main(int argc, char *argv[]) {
extern FILE *yyin;

	switch (argc) {
		case 1:	yyin=stdin;
			yyparse();
			printf("Storyboard validation finished without errors.\n");
			break;
		case 2: yyin = fopen(argv[1], "r");
			if (yyin == NULL) {
				printf("ERROR: Could not open file.\n");
			}
			else {
				yyparse();
				fclose(yyin);
				printf("Storyboard validation finished without errors.\n");
			}
			break;
		case 3: yyin = fopen(argv[1], "r");
			warn=atoi(argv[2]);
			if (yyin == NULL) {
				printf("ERROR: Could not open file.\n");
			}
			else {
				yyparse();
				fclose(yyin);
				printf("Storyboard validation finished without errors.\n");
			}
			break;
		default: printf("ERROR: Too many arguments.\nSyntax: %s [fichero_entrada]\n\n", argv[0]);
	}
	return 0;
}
	
void yyerror (char const*message) { 	
if (strcmp("syntax error",message)){
	char errstring [512]="Syntax error at line ";
	char number[10];
	sprintf(number, "%d", yylineno);
	strcat(errstring,number);
	strcat(errstring,": ");	
	fprintf (stderr, "%s%s.\n", errstring,message);
	yyclearin;
	exit(0);
	}
	};

void warning (char const*message) { 	
char errstring [512]="Warning at line ";
	char number[10];
	sprintf(number, "%d", yylineno);
	strcat(errstring,number);
	strcat(errstring,": ");	
	fprintf (stderr, "%s%s.\n", errstring,message);};

void asset_error(char const*errmsg){
	char errstring [512]="Asset error at line ";
	char number[10];
	sprintf(number, "%d", yylineno);
	strcat(errstring,number);
	strcat(errstring,": ");	
	fprintf (stderr, "%s%s.\n", errstring,errmsg);
	yyclearin;
	exit(0);	
}

void check_file(char const*filename,int iters,int anim){
	FILE *fd;
	char aux[512]="";
	char iternumber[512];
	char *offset;
	char extension [30];
	char *flnm=(char*)filename;
	//trim extension
	offset=strchr(flnm,'.');
	strcpy(extension,offset);
	if ((strcmp(extension,".jpg")&&strcmp(extension,".png"))&&strcmp(extension,".jpeg"))
			asset_error("Animation and Sprite objects only support jpeg,png and jpg files.");
	*offset='\0';
	if (anim){
		for (int i=0;i<iters;i++){
			//save the number
			sprintf(iternumber,"%d",i);

			//put it all together
			strcat(aux,"./");
			strcat(aux,flnm);
			strcat(aux,iternumber);
			strcat(aux,extension);

			fd=fopen(aux,"r");
			strcpy(aux,"");
			if (fd==NULL) asset_error(strerror(errno));
			else fclose(fd);
		}
	}
	else {
		strcat(aux,"./");
		strcat(aux,flnm);
		strcat(aux,extension);
		fd=fopen(aux,"r");
		strcpy(aux,"");
		if (fd==NULL) asset_error(strerror(errno));
		else fclose(fd);
		}
	}
void check_sample(char const*filename){
	FILE *fd;
	char aux[512]="";
	char iternumber[512];
	char *offset;
	char extension [30];
	char *flnm=(char*)filename;
	//trim extension
	offset=strchr(flnm,'.');
	strcpy(extension,offset);
	if ((strcmp(extension,".mp3")&&strcmp(extension,".wav"))&&strcmp(extension,".ogg"))
			asset_error("Sample objects only support wav,mp3 and ogg files");
	*offset='\0';
	strcat(aux,"./");
	strcat(aux,flnm);
	strcat(aux,extension);
	fd=fopen(aux,"r");
	strcpy(aux,"");
	if (fd==NULL) asset_error(strerror(errno));
	else fclose(fd);
	}

