#!/usr/bin/lua5.3
-----------------------------------------------------------------------------
-- PL/0 Common Environmntal Data & Structure
-- Name: plenv
-- Author: Kahsolt
-- Time: 2016-12-19
-- Version: 1.6
-- Lua Ver: 5.3
-----------------------------------------------------------------------------

-- Meta-Info Definition
TokenType={
	BAD=0,									-- Unknown Char
	ID=100,									-- Identifier
	CONST=101, VAR=102,						-- Announcer
	NUM=111, STR=112,						-- Datatype - supports float and string
	BEGIN=201, END=202,						-- Reserved Words <Block Structure>
	PROCEDURE=211, CALL=212,
	IF=221,	THEN=222, ELSE=223,
	WHILE=231, DO=232, REPEAT=233, UNTIL=234,
	ASSIGN=301,								-- Linker
	PERIOD=311,	COMMA=312, SEMICOLON=313,	-- Separator
	LRDBR=321, RRDBR=322,					-- Combiner
	ADD=401, SUB=402, MUL=403, DIV=404,		-- Arithmetic Operator
	MOD=405, PWR=406,
	NOT=411, AND=412,  OR=413,	 			-- Logic Operator
	EQU=421, NEQ=422, ELT=423, EGT=424,		-- Comparation Operator
	LES=425, GRT=426,
	READ=501, WRITE=502,					-- Inner Function
	ODD=511,
}
ReservedWord={								-- Subset of TokenType
	CONST='', VAR='',						-- key makes sense while value is useless
	BEGIN='', END='',
	PROCEDURE='', CALL='',
	IF='',	THEN='', ELSE='',
	WHILE='', DO='', REPEAT='', UNTIL='',
	READ='', WRITE='', ODD='',
}
PCode={
	HLT=100,	-- Machine Stop
	INT=101,	-- Data Stacktop move up
	LIT=102,	-- Load const to stacktop
	LOD=103,	-- Load var to stacktop
	CAL=201,	-- Call address
	JMP=202,	-- Goto address
	JPC=203,	-- Goto address with condition=false (fact is JNE)
	STO=301,	-- Store stacktop to var
	OPR=401,	-- Do calculation
	RED=501,	-- Readin var
	WRT=502,	-- Writeout stacktop
}
ErrorMessage={
	-- [[Fatal Logical Error]] --
	['100']='Mystical Fatal Error..',
	['101']='Cannot open input file',
	['102']='Cannot open output file',
	-- [[Lexing Error]] --
	['200']='Unkown character',
	['201']='Number too big as UINT32',
	['202']='Bad float number',
	['203']='String missing right quote \'\'\'',
	['211']='Assignment missing equal \'=\'',
	['291']='Comment missing right curl bracket\'}\'',
	-- [[Parsing Error]] --
	['300']='Error Parser Function Call',
	['301']='Missing "."',
	['302']='Missing ";"',
	['303']='Missing "="',
	['304']='Missing "END"',
	['305']='Missing ":="',
	['306']='Missing "THEN"',
	['307']='Missing "DO"',
	['308']='Missing "WHILE"',
	['309']='Missing "UNTIL"',
	['310']='Missing "("',
	['311']='Missing ")"',
	['312']='Missing or Bad Statement',
	['313']='Missing an Identifier',
	['314']='Missing Relation Operator',
	['315']='Missing or Bad Expression',
	['316']='Missing a Number',
	['317']='Missing or Bad Condition',
	-- [[Semantical Error]] --
	['401']='Identifier not declared',
	['402']='Identifier re-declared',
	['403']='Cannot assign a nein-Var',
	['404']='Cannot call a nein-Procedure',
	['405']='Cannot be a Procedure',
	['406']='Definition "=" is required rather than Assignment ":="',
	['407']='Cannot read a nein-Var',
	['408']='Cannot write a Procedure',
	['409']='UNPARSED text in the end',
	-- [[PCode Error]] --
	['500']='Unknow PCmd',
}
INT_MAX	 = 4294967295	-- UINT32

-- Default Const
FileInName	= 'p.pas'	-- default file-in name
PL0_FileIn	= ''
PL0_FileOut	= ''
PL0_Address	= 3			-- 3 seems to be a co-incidence

-- Mode Switch
PL0_Debug		= false		-- debug flag
PL0_FoldConst	= true		-- [NOT recommended!] const fold to optmize algbra expressions

-- Status Const
FileIn	 = PL0_FileIn		-- Input file
FileOut  = PL0_FileOut		-- Output file
-- Status Var
Namespace	= {}	-- Current symbol names
					-- Looks like: {["1"]={name='const1',type='CONST',value=3},["2"]={name='proc_var1',type='PROCEDURE'|'VAR',layer=0,address=5}}
Address=PL0_Address	-- init Name Address in Namespacer
Layer		= 0		-- be-Carved the current layer
Cur_Line	= 1		-- Cursor line of source file
Cur_Column	= 0		-- Cursor column of source file
Cur_Count	= 0		-- Cursor of destination codeset
Error_Count	= 0		-- Current Error Count
CodeSet		= {}	-- Output PCode
					-- {['1']={pcmd='JMP',layerdiff=1,x=25}}
-- Temp Var
Token = {}			-- Current tmp token:
					-- Looks like: {type='ID', value='aVar'} {type='NUM', value=12345}

-- Debug Function
function pl0Status()
	print("PL/0 compiler Status:")
	print("=====================")
	print("Fin =\t"..FileIn)
	print("Loc =\t"..Cur_Line..':'..Cur_Column)
	print("Token =\t"..Token.type..':'..Token.value)
	print("Fout =\t"..FileOut)
	print("Cmd_N =\t"..Cur_Count)
	print()
end