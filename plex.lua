#!/usr/bin/lua5.3
-----------------------------------------------------------------------------
-- PL/0 Lexer module
-- Name: plex
-- Author: Kahsolt
-- Time: 2016-12-10
-- Version: 1.3
-- Lua Ver: 5.3
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Declare module & import dependencies
-----------------------------------------------------------------------------
plex = {}				-- 模块名
local _M = plex			-- 临时模块名
dofile('plenv.lua')		-- 执行全局参数设定
require 'plerr'

-----------------------------------------------------------------------------
-- Private variables & functions
-----------------------------------------------------------------------------
local input = ''	-- Current char
local inputs = ''	-- Current buffer

-- Judger
local function isEOF()		return input==nil	end
local function isNL()		return input=='\n'	end
local function isNonsense()	return input=='\0' or input==' ' or input=='' or input=='\t' or input=='\r' or input=='\n' end
local function isLetter()	return input and ('A'<=input and input<='Z' or 'a'<=input and input<='z') end
local function isDigit()	return input and ('0'<=input and input<='9') end
local function isAdd()		return input=='+'	end
local function isSub()		return input=='-'	end
local function isMul()		return input=='*'	end
local function isDiv()		return input=='/'	end
local function isMod()		return input=='%'	end
local function isPwr()		return input=='^'	end
local function isEqu()		return input=='='	end
local function isLes()		return input=='<'	end
local function isGrt()		return input=='>'	end
local function isPeriod()	return input=='.'	end
local function isComma()	return input==','	end
local function isSemiColon()return input==';'	end
local function isColon()	return input==':'	end
local function isQuote()	return input=="'"	end
local function isLrdbr()	return input=='('	end
local function isRrdbr()	return input==')'	end
local function isLagbr()	return input=='<'	end
local function isRagbr()	return input=='>'	end
local function isLclbr()	return input=='{'	end
local function isRclbr()	return input=='}'	end
local isDot		= isPeriod
local isStar	= isMul

-- Tools
local function chkReserved()
	if ReservedWord[inputs:upper()] then
		return TokenType[inputs:upper()]
	end
end
local function readInput()
	input=FileIn:read(1)			-- EOF returns nil as well
	-- print('Cur_Line'..Cur_Line)
	if input=='\n' then
		-- print('inputs='..inputs)
		Cur_Line=Cur_Line+1			-- compatible with Windows & Linux
		Cur_Column=0
	else
		Cur_Column=Cur_Column+1
	end
end
local function initInput()		-- Pre-Read: keep head char of the next token in 'input'
	while not isEOF() and isNonsense() do readInput() end
end
local function nextInput()		-- Admit & read next
	inputs = inputs..input
	readInput()
end
local function initInputs()		-- Clear the old buffer info
	inputs = ''
	Token = {type=TokenType.BAD}
end
local function err(id)
	plerr.what('Plex',id)
end

-----------------------------------------------------------------------------
-- Pulic variables & functions
-----------------------------------------------------------------------------
function _M.init(fin)
	if not fin then fin=FileInName
	else FileInName=fin end
	FileIn = io.open(fin, "r")
	Cur_Line = 1
	Cur_Column = 0
	if not FileIn then
		err(101)
		return false
	end
	initInput()
	return true
end
function _M.isFin()
	return input==nil
end
function _M.nextToken()
	initInputs()	-- Clear old buffer info
	if isEOF() then	return nil end

	-- [[REM: now 'input' is already the head char of the token to extract]] --
	-- [[REM: after extract this token successfully, set 'input' to the next char]] --
	-- print("[Head Char:] '"..input.."'")		-- current token head char
	if isLetter() then			-- ID
		while isLetter() or isDigit() do nextInput() end
		Token.type = chkReserved() or TokenType.ID
		Token.value = inputs
	elseif isDigit() then		-- NUM	-- unsigned INT
		while isDigit() do nextInput() end
		if tonumber(inputs) > INT_MAX then
			err(201)
		else
			Token.type=TokenType.NUM
			Token.value=tonumber(inputs)
		end
	elseif isAdd()		then Token.type,_=TokenType.ADD,readInput()			-- '+'
	elseif isSub()		then Token.type,_=TokenType.SUB,readInput()			-- '-'
	elseif isMul()		then Token.type,_=TokenType.MUL,readInput()			-- '*'
	elseif isDiv() 		then Token.type,_=TokenType.DIV,readInput()			-- '/'
	elseif isMod() 		then Token.type,_=TokenType.MOD,readInput()			-- '%'	
	elseif isPwr() 		then Token.type,_=TokenType.PWR,readInput()			-- '^'
	elseif isEqu()		then Token.type,_=TokenType.EQU,readInput()			-- '='
	elseif isLrdbr()	then Token.type,_=TokenType.LRDBR,readInput()		-- '('
	elseif isRrdbr()	then Token.type,_=TokenType.RRDBR,readInput()		-- ')'
	elseif isPeriod()	then Token.type,_=TokenType.PERIOD,readInput()		-- '.'
	elseif isComma()	then Token.type,_=TokenType.COMMA,readInput()		-- ','
	elseif isSemiColon()then Token.type,_=TokenType.SEMICOLON,readInput()	-- ';'
	elseif isColon() then
		nextInput()
		if isEqu() then
			Token.type=TokenType.ASSIGN	-- ':='
			readInput()
		else
			err(211)
		end
	elseif isLagbr() then
		nextInput()
		if isEqu() then
			Token.type=TokenType.ELT		-- '<='
			readInput()
		elseif isRagbr() then
			Token.type=TokenType.NEQ		-- '<>'
			readInput()
		else
			Token.type=TokenType.LES		-- '<'
		end
	elseif isRagbr() then
		nextInput()
		if isEqu() then
			Token.type=TokenType.EGT		-- '>='
			readInput()
		else
			Token.type=TokenType.GRT		-- '>'
		end
	elseif isLclbr() then
		readInput()
		if isStar() then					-- '{*' skip multiline comments
			repeat
				repeat readInput() until isStar() or isEOF()
				repeat readInput()
					if isRclbr() then
						readInput()
						initInput()
						return _M.nextToken()	-- Get the next
					end
				until isStar() or isEOF()
			until not isStar() or isEOF()
		else 								-- '{' skip inline comment
			if isRclbr() then
				readInput()
				initInput()
				return _M.nextToken()
			else
				repeat readInput() until isRclbr() or isNL() or isEOF()
				if isRclbr() then
					readInput()
					initInput()
					return _M.nextToken()
				else
					err(291)
				end
			end
		end	
	else
		readInput()
		err(200)
		initInput()
		return _M.nextToken()	-- Get the next
	end

	initInput()		-- Prepare for the next token
	return Token
end

-----------------------------------------------------------------------------
-- Debug functions
-----------------------------------------------------------------------------
function _M.test(fin)
	_M.init(fin)
	print("<Type>\t<Value>")
	while true do
		t=_M.nextToken()
		if not t then break end
		print(t.type or '',t.value or '')
	end
end

-----------------------------------------------------------------------------
return _M
