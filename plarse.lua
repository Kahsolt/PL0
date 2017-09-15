#!/usr/bin/lua5.3
-----------------------------------------------------------------------------
-- PL/0 Parser module
-- Name: plarse
-- Author: Kahsolt
-- Time: 2016-12-19
-- Version: 2.1
-- Lua Ver: 5.3
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Declare module & import dependencies
-----------------------------------------------------------------------------
plarse = {}			-- 模块名
local _M = plarse	-- 临时模块名
dofile('plenv.lua')	-- 引入模块
require 'plex'
require 'plame'
require 'plerr'
require 'plode'

-----------------------------------------------------------------------------
-- Private variables & functions
-----------------------------------------------------------------------------
local parseProgram, parseSubProgram, parseStatemant

-- Tools
local function testToken(type)		-- test only
	return Token.type==TokenType[type]
end
local function absorbToken(type)	-- test, if match then get next token
	if Token.type==TokenType[type] then
		plex.nextToken()
		return true
	else
		return false
	end
end
local function getTokenValue(type)
	if type=='ID' and testToken('ID') or type=='NUM' and testToken('NUM') then
		t=Token.value			-- get the ID Name or Num Value
		plex.nextToken()
		return t
	else
		return false
	end
end
local function err(id)
	plerr.what('Plarse',id)
end

-- Local Debug
local function dbg(func)
	if PL0_Debug then print('[Func] '..func..'\t\t[Token] '..(Token.type or '<NK>')..'\t'..(Token.value or '<Symbol>')) end
end

-- Parsers
function parseProgram()			-- ﻿<程序> ::= <分程序>.
	dbg('Program')
	INT_VAR=0
	parseSubProgram(0,nil)		-- init Layer=0, MAIN procedure is ananymous so use nil
	if not absorbToken('PERIOD') then
		err(301)
	end
	if not plex.isFin() then
		err(409)
		return false
	end
	return true
end
function parseSubProgram(layer,proc_name)	-- <分程序> ::= {<常量说明部分>}{变量说明部分>}{<过程说明部分>}<语句>
	dbg('SubProgram')
	local parseDeclareConst, parseDeclareVar, parseDeclareProcedure
	function parseDeclareConst()		-- <常量说明部分> ::= const<标识符>=<无符号整数>{,<标识符>=<无符号整数>};
		dbg('DeclareConst')
		if not absorbToken('CONST') then err(300) return false end
		if testToken('ID') then
			repeat
				local _name=getTokenValue('ID')
				if not plame.setName(_name,'CONST') then err(402) end
				if testToken('EQU') or testToken('ASSIGN') then	-- # AUTO-CORRECTION
					if absorbToken('ASSIGN') then err(406)
					else absorbToken('EQU') end
					if testToken('NUM') then
						local _value=getTokenValue('NUM')
						plame.setValue(_name,_value)
					else err(316) end
				else err(303) return false end
				if absorbToken('SEMICOLON') then return true
				elseif not absorbToken('COMMA') then err(302) return false end
			until not testToken('ID')
			err(302)
			return false
		else err(313) return false end
	end
	function parseDeclareVar()			-- <变量说明部分>::= var<标识符>{,<标识符>};
		dbg('DeclareVar')
		if not absorbToken('VAR') then err(300) return false end
		if testToken('ID') then
			repeat
				local _name=getTokenValue('ID')
				if PL0_Debug then print('_name='.._name) end
				if not plame.setName(_name,'VAR') then err(402) end
				INT_VAR=INT_VAR+1
				if absorbToken('SEMICOLON') then return true
				elseif not absorbToken('COMMA') then err(302) return false end
			until not testToken('ID')
			err(302)
			return false
		else err(313) return false end
	end
	function parseDeclareProcedure()	-- <过程说明部分> ::= procedure<标识符>;<分程序>;
		dbg('DeclareProcedure')
		if not absorbToken('PROCEDURE') then err(300) return false end
		if testToken('ID') then
			local _name=getTokenValue('ID')
			if not plame.setName(_name,'PROCEDURE') then err(402) return false
			else
				if absorbToken('SEMICOLON') then
					if parseSubProgram(layer+1,_name) then	-- layer increase when entering subprogram
						if absorbToken('SEMICOLON') then
							return true
						end
						err(302)
						return false
					else return false end
				else err(302) return false end
			end
		else err(313) return false end
	end

	local int_var=INT_VAR			-- used by PCODE.INT, create a new segment, INT_VAR is the globally VAR count
	Address=PL0_Address
	local _layer_save=Layer
	Layer=layer 						-- Carve current layer to global

	local _entry = Cur_Count			-- Carve Procedure Entry
	plode.write(PCode.JMP,0,0)			-- <Right> [*] to skip to statement segment, address 0 here IS modified later

	plame.setAddress(proc_name,_entry)	-- set for CAL to procedure head

	while testToken('CONST') or testToken('VAR') or testToken('PROCEDURE') do		-- order is not important
		if testToken('CONST') then parseDeclareConst() end
		if testToken('VAR') then parseDeclareVar() end
		if testToken('PROCEDURE') then parseDeclareProcedure() end
	end
	plame.setAddress(proc_name,Cur_Count)			-- <Right> back-fill PROCEDURE.address in Namespace, set for PCode
	plode.fillAddress(_entry,Cur_Count)				-- {RENEW it to the Code Block} back-fill JMP pcmd [*] above
	plode.write(PCode.INT,0,PL0_Address+INT_VAR-int_var)	-- count VAR - pcmd

	local _ret=parseStatemant()
	plode.write(PCode.OPR,0,0)			-- 0 = return

	Layer=_layer_save					-- re-Carve previous layer
	INT_VAR=int_var 					-- re-Carve INT
	return _ret
end
function parseStatemant()		-- <语句> ::= <赋值语句>|<条件语句>|<当型循环语句>|<过程调用语句>|<读语句>|<写语句>|<复合语句>|<重复语句>|<空>
	dbg('Statemant')
	local parseExpression, parseTerm, parseFactor, parseCondition
	local parseStatemantCompoud, parseStatemantAssign, parseStatemantIf, parseStatemantWhile, parseStatemantRepeat, parseStatemantCall, parseStatemantRead, parseStatemantWrite
	function parseExpression(notBase)			-- <表达式> ::= [+|-]<项>{(+|-)<项>}
		dbg('Expression')
		if absorbToken('SUB') then plode.write(PCode.OPR,0,1)		-- 1 = oppsite
		else absorbToken('ADD') end
		local _fold_addsub = false
		local _a = parseTerm()
		if _a then
			local _op
			while testToken('ADD') or testToken('SUB') do
				if absorbToken('ADD') then _op='+'
				elseif absorbToken('SUB') then _op='-' end
				local _b = parseTerm()
				if PL0_Debug then print('_a='..tostring(_a)..'\t_b='..tostring(_b)) end
				if PL0_FoldConst==true then
					if type(_a)=='number' and type(_b)=='number' then		-- PL0_FoldConst success!
						_fold_addsub = true
						if _op=='+' then _a = _a+_b
						elseif _op=='-' then _a = _a-_b
						else err(100) end
					else
						if type(_a)=='number' then plode.write(PCode.LIT,0,_a) end		-- PL0_FoldConst failed, write up
						if type(_b)=='number' then plode.write(PCode.LIT,0,_b) end		-- PL0_FoldConst failed, write up
						if _op=='+' then plode.write(PCode.OPR,0,2)		-- 2 = addition
						elseif _op=='-' then plode.write(PCode.OPR,0,3)		-- 3 = substraction
						else err(100) end
					end
				else
					if _op=='+' then plode.write(PCode.OPR,0,2)		-- 2 = addition
					elseif _op=='-' then plode.write(PCode.OPR,0,3)		-- 3 = substraction
					else err(100) end
				end
			end
			if PL0_Debug then print('_ret_addsub='..tostring(_a)) end
			if _fold_addsub==true then	
				if notBase==true then
					return _a
				else
					plode.write(PCode.LIT,0,_a)	-- got the Expr Base
					return true
				end
			else
				if notBase==true then
					return _a
				else
					return true
				end
			end
		else return false end
	end
	function parseTerm()				-- <项> ::= <因子>{(*|/)<因子>}
		dbg('Term')
		local _fold_muldiv = false
		local _x=parseFactor()
		if _x then
			local _op
			while testToken('MUL') or testToken('DIV')  do
				if absorbToken('MUL') then _op='*'
				elseif absorbToken('DIV') then _op='/' end
				local _y=parseFactor()
				if PL0_Debug then  print('_x='..tostring(_x)..'\t_y='..tostring(_y)) end
				if PL0_FoldConst==true then
					if type(_x)=='number' and type(_y)=='number' then		-- PL0_FoldConst success!
						_fold_muldiv = true
						if _op=='*' then _x = _x*_y
						elseif _op=='/' then _x = math.floor(_x/_y)	-- omit DIVIDE 0 ERROR...
						else err(100) end
					else
						if type(_x)=='number' then plode.write(PCode.LIT,0,_x) end		-- PL0_FoldConst failed, write up
						if type(_y)=='number' then plode.write(PCode.LIT,0,_y) end		-- PL0_FoldConst failed, write up
						if _op=='*' then plode.write(PCode.OPR,0,4)			-- 4 = multiple
						elseif _op=='/' then plode.write(PCode.OPR,0,5)		-- 5 = division
						else err(100) end
					end
				else
					if _op=='*' then plode.write(PCode.OPR,0,4)			-- 4 = multiple
					elseif _op=='/' then plode.write(PCode.OPR,0,5)		-- 5 = division
					else err(100) end
				end
			end
			if _fold_muldiv==true then
				if PL0_Debug then print('_ret_muldiv='..tostring(_x)) end
				return _x
			else
				return _x 	-- whether after const fold
			end
		else
			return false
		end
	end
	function parseFactor()				-- <因子> ::= <标识符>|<数>|'('<表达式>')‘
		dbg('Factor')
		if testToken('ID') then
			local _name=getTokenValue('ID')
			if plame.isConst(_name) then
				if PL0_FoldConst==true then
					return plame.getValue(_name)
				else
					plode.write(PCode.LIT,0,plame.getValue(_name))
					return true
				end
			elseif plame.isVar(_name) then
				plode.write(PCode.LOD,Layer-plame.getLayer(_name),plame.getAddress(_name))
				return true
			else err(405) return false end
		elseif testToken('NUM') then
			local _val=getTokenValue('NUM')
			if PL0_FoldConst==true then
				return _val
			else
				plode.write(PCode.LIT,0,_val)
				return true
			end
		elseif absorbToken('LRDBR') then
			local _inner_expr = parseExpression(true)
			if absorbToken('RRDBR') then
				return _inner_expr
			else err(311) return false end
		else return false end
	end
	function parseCondition()			-- <条件> ::= <表达式><关系运算符><表达式>|odd<表达式>
		dbg('Condition')
		if absorbToken('ODD') then
			if 	parseExpression() then
				plode.write(PCode.OPR,0,6)	-- 6 = if odd
				return true
			else err(315) return false end
		elseif parseExpression() then
			local _relop
			if absorbToken('EQU') then _relop='EQU'
			elseif absorbToken('NEQ') then _relop='NEQ'
			elseif absorbToken('LES') then _relop='LES'
			elseif absorbToken('ELT') then _relop='ELT'
			elseif absorbToken('GRT') then _relop='GRT'
			elseif absorbToken('EGT') then _relop='EGT'
			else err(314) return false end
			if parseExpression() then
				if _relop=='EQU' then plode.write(PCode.OPR,0,8)	-- 8 = EQU
				elseif _relop=='NEQ' then plode.write(PCode.OPR,0,9)	-- 9 = NEQ
				elseif _relop=='LES' then plode.write(PCode.OPR,0,10)	-- 10 = LES
				elseif _relop=='ELT' then plode.write(PCode.OPR,0,13)	-- 13 = ELT
				elseif _relop=='GRT' then plode.write(PCode.OPR,0,12)	-- 12 = GRT
				elseif _relop=='EGT' then plode.write(PCode.OPR,0,11)	-- 11 = EGT
				else err(100) return false end
				return true
			else err(315) return false end
		else err(317) return false end
	end
	function parseStatemantCompoud()	-- <复合语句> ::= begin<语句>{;<语句>}end
		dbg('StatemantCompoud')
		if not absorbToken('BEGIN') then err(300) return false end
		if absorbToken('END') then return true end	-- Support Nil Statement
		if parseStatemant() then
			while absorbToken('SEMICOLON') do
				if absorbToken('END') then
					return true
				elseif not parseStatemant() then return false end
			end
			if absorbToken('END') then
				return true
			else err(304) return false end
		else err(312) return false end
	end
	function parseStatemantAssign()		-- <赋值语句> ::= <标识符>:=<表达式>
		dbg('StatemantAssign')
		if not testToken('ID') then err(313) return false end
		local _name=getTokenValue('ID')
		if not plame.getIndex(_name) then err(401) return false
		elseif not plame.isVar(_name) then err(403) return false
		else
			if absorbToken('ASSIGN') then
				if not parseExpression() then err(315) return false end 
				plode.write(PCode.STO,Layer-plame.getLayer(_name),plame.getAddress(_name))
				return true
			else err(305) return false end
		end	
	end
	function parseStatemantIf()			-- <条件语句> ::= if<条件>then<语句>[else<语句>]
		dbg('StatemantIf')
		if not absorbToken('IF') then err(300) return false end
		if parseCondition() then
			if absorbToken('THEN') then
				local _if = Cur_Count
				plode.write(PCode.JPC,0,0)	-- infact it is JNE
				if parseStatemant() then
					if absorbToken('ELSE') then
						local _else = Cur_Count
						plode.write(PCode.JMP,0,0)
						plode.fillAddress(_if,Cur_Count)
						if parseStatemant() then
							plode.fillAddress(_else,Cur_Count)
							return true
						end
					else
						plode.fillAddress(_if,Cur_Count)
					end
					return true
				else err(312) return false end
			else err(306) return false end
		else return false end
	end
	function parseStatemantWhile()		-- <当型循环语句> ::= while<条件>do<语句>
		dbg('StatemantWhile')
		if not absorbToken('WHILE') then err(300) return false end
		local _start = Cur_Count
		if parseCondition() then
			local _end = Cur_Count
			plode.write(PCode.JPC,0,0)
			if absorbToken('DO') then
				if parseStatemant() then
					plode.write(PCode.JMP,0,_start)
					-- print('Modify PCode line:'.._end)
					plode.fillAddress(_end,Cur_Count)
					return true
				end
			else err(307) return false end
		else return false end
	end
	function parseStatemantRepeat()		-- <重复语句> ::= repeat<语句>{;<语句>}until<条件>
		dbg('StatemantRepeat')
		if not absorbToken('REPEAT') then err(300) return false end
		local _start = Cur_Count
		if parseStatemant() then
			while absorbToken('SEMICOLON') do
				if not parseStatemant() then return false end
			end
			if absorbToken('UNTIL') then
				if parseCondition() then
					plode.write(PCode.JPC,0,_start)
					return true
				end
			else err(309) return false end
		else err(312) return false end
	end
	function parseStatemantCall()		-- <过程调用语句> ::= call<标识符>
		dbg('StatemantCall')
		if not absorbToken('CALL') then err(300) return false end
		if testToken('ID') then
			local _name=getTokenValue('ID')
			if not plame.getIndex(_name) then err(401) return false
			elseif not plame.isProc(_name) then err(404) return false
			else
				-- print('CAL '.._name..'ADDR: '..(plame.getAddress(_name)or '<NO>'))
				plode.write(PCode.CAL,Layer-plame.getLayer(_name),plame.getAddress(_name))
				return true
			end
		else err(313) return false end
	end
	function parseStatemantRead()		-- <读语句> ::= read'('<标识符>{,<标识符>}')‘
		dbg('StatemantRead')
		if not absorbToken('READ') then err(300) return false end
		if absorbToken('LRDBR') then
			if testToken('ID') then
				repeat
					local _name=getTokenValue('ID')
					if not plame.getIndex(_name) then err(401) return false
					elseif not plame.isVar(_name) then err(407) return false
					else
						plode.write(PCode.RED,Layer-plame.getLayer(_name),plame.getAddress(_name))
					end
					if absorbToken('RRDBR') then return true
					else absorbToken('COMMA') end
				until not testToken('ID')
				err(311)
				return false
			else err(313) return false end
		else err(310) return false end
	end
	function parseStatemantWrite()		-- <写语句> ::= write'('<标识符>{,<标识符>}')‘
		dbg('StatemantWrite')
		if not absorbToken('WRITE') then err(300) return false end
		if absorbToken('LRDBR') then
			if testToken('ID') or testToken('NUM') then
				repeat
					if testToken('ID') then
						local _name=getTokenValue('ID')
						if not plame.getIndex(_name) then err(401) return false
						elseif plame.isProc(_name) then err(408) return false
						elseif plame.isConst(_name) then
							plode.write(PCode.LIT,0,plame.getValue(_name))
							plode.write(PCode.WRT,0,0)
						else
							plode.write(PCode.LOD,Layer-plame.getLayer(_name),plame.getAddress(_name))
							plode.write(PCode.WRT,0,0)
						end
					else
						local _num = getTokenValue('NUM')
						plode.write(PCode.LIT,0,_num)
						plode.write(PCode.WRT,0,0)
					end
					if absorbToken('RRDBR') then return true
					else absorbToken('COMMA') end
				until not testToken('ID') and not testToken('NUM')
				err(311)
				return false
			else err(313) return false end
		else err(310) return false end
	end

	if testToken('BEGIN') then return parseStatemantCompoud()
	elseif testToken('ID') then return parseStatemantAssign()
	elseif testToken('IF') then return parseStatemantIf()
	elseif testToken('WHILE') then return parseStatemantWhile()
	elseif testToken('DO') then return parseStatemantWhile()
	elseif testToken('REPEAT') then return parseStatemantRepeat()
	elseif testToken('CALL') then return parseStatemantCall()
	elseif testToken('READ') then return parseStatemantRead()
	elseif testToken('WRITE') then return parseStatemantWrite()
	elseif absorbToken('SEMICOLON') then return true	-- Null Statement
	else return false end
end

-----------------------------------------------------------------------------
-- Pulic variables & functions
-----------------------------------------------------------------------------
function _M.init(fin)
	plex.init(fin)
	plerr.init()
	plame.init()
	plode.init()
end
function _M.startParse(fin)
	_M.init(fin)
	plex.nextToken()		-- Pre-read a token
	parseProgram()
	if Error_Count==0 then plode.output() end
	plode.test()
	plerr.info()
end

-----------------------------------------------------------------------------
-- Debug functions
-----------------------------------------------------------------------------
function _M.test(fin)
	PL0_Debug=true
	_M.startParse(fin)
	plame.test()
end

-----------------------------------------------------------------------------
return _M
