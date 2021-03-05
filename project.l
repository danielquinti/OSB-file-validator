%{
#include <string.h>
#include "project.tab.h"
#include <deque>
#include <math.h>
static std::deque<int> tokenq;
int nspaces=0;

%}
%option noyywrap
%option yylineno
newline \r?\n
prolog "[Events]"
comment (\/\/[^\n\r]*)
comment_block ({comment}{newline})*{comment}
path [^\*\[\]:;\|,]+
filepath "\""{path}"\""
layer Background|Fail|Pass|Foreground
snapping Centre|TopLeft|TopRight|TopCentre|CentreLeft|CentreRight|BottomCentre|BottomLeft|BottomRight
anim_type Animation
sprite_type Sprite
sample_type Sample
f_command F
mx_command MX
my_command MY
m_command M
s_command S 
c_command C
l_command L
r_command R
p_command P
t_command T

v_token V

h_param H
a_param A

loop_type LoopOnce|LoopForever
trigger_type Failing|Passing|HitSome

int -?[0-9]+
double -?[0-9]+"."[0-9]+("E"{int})?
hexvalue [0-9]|[A-F]
hex {hexvalue}{2}
comma ","
spaces {newline}" "*
%%
	if (!tokenq.empty()) {
    int token = tokenq.front();
    tokenq.pop_front();
    return token;
  }
{f_command} {return F_COMMAND;}
{mx_command} {return MX_COMMAND;}
{my_command} {return MY_COMMAND;}
{m_command} {return M_COMMAND;}
{s_command} {return S_COMMAND;}
{c_command} {return C_COMMAND;}
{l_command} {return L_COMMAND;}
{r_command} {return R_COMMAND;}
{p_command} {return P_COMMAND;}
{t_command} {return T_COMMAND;}

{v_token} {return V_TOKEN;}

{h_param} {return H_PARAM;}
{a_param} {return A_PARAM;}

{prolog} {return PROLOG;}
{comment_block} {return COMMENT;}
{filepath} {
	char *str=strdup(yytext);
	++str;
	str[strlen(str)-1] = 0;
	int index=0;
	while (str[index])
		{
			if (str[index]=='\\')
				str[index]='/';
			index++;
		}
	yylval.valString=str;
	return FILEPATH;}
{loop_type} {return LOOP_TYPE;}
{trigger_type} {return TRIGGER_TYPE;}
{anim_type} {return ANIM_TYPE;}
{sprite_type} {return SPRITE_TYPE;}
{sample_type} {return SAMPLE_TYPE;}

{layer} {return LAYER;}
{snapping} {return SNAPPING;}
{double} {
	char *str=strdup(yytext);
	char *offset;
	offset=strchr(str,'E');
	int exp;
	if (offset==NULL) exp=0.0f;
	else {
		char exponent[30];
		strcpy(exponent,offset);
		exp=atof(exponent);
		*offset='\0';
		}
	double base=atof(str);
	yylval.valDouble=base*(pow(10.0f,exp));
	return DOUBLE;}
{int} {yylval.valInt=atoi(strdup(yytext));return INT;}
{hex} {return HEX;}
{comma} {return COMMA;}
{spaces} {
	char const *aux=strdup(yytext);
	int i;
	for (i=0; aux[i]; aux[i]==' ' ? i++ : *aux++);
	//more spaces than counter
	if ((i-nspaces)>0)
		{
		for (int j=(i-nspaces);j!=0;j--){
			tokenq.push_back(INDENT);
		}
		nspaces=i;
		}
	else{
		//less spaces than counter
		if ((i-nspaces)<0){
			for (int j=(i-nspaces);j!=0;j++){
				tokenq.push_back(DEDENT);
			}
			nspaces=i;
		}
		}
	return NL;
	}
" " {fprintf(stderr,"Error at line %d: Spaces are only allowed for indentation.\n",yylineno);exit(0);}
. {fprintf(stderr,"Lexical error at line %d: Unrecognised token \"%s\".\n",yylineno,strdup(yytext));exit(0);}
%%