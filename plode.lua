#!/usr/bin/lua5.3
-----------------------------------------------------------------------------
-- PL/0 P-Code Generator module
-- Name: plode
-- Author: Kahsolt
-- Time: 2016-12-18
-- Version: 1.5
-- Lua Ver: 5.3
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Declare module & import dependencies
-----------------------------------------------------------------------------
plode = {}				-- 模块名
local _M = plode		-- 临时模块名
dofile('plenv.lua')		-- 执行全局参数设定
require 'plerr'

-----------------------------------------------------------------------------
-- Private variables & functions
-----------------------------------------------------------------------------
-- Tools
local function toPCode(pcmd)
	for k,v in pairs(PCode) do
		if v==pcmd then
			return tostring(k)
		end
	end
end
local function err(id)
	plerr.what('Plerr',id)
end

-----------------------------------------------------------------------------
-- Pulic variables & functions
-----------------------------------------------------------------------------
function _M.init(fout)
	if not fout then
		fout=FileInName:sub(1,#FileInName-4)..'.pcd'
	end
	FileOut = io.open(fout, "w")
	Address = PL0_Address
	Cur_Count = 0
	if not FileOut then
		err(102)
		return false
	end
	return true
end
function _M.fillAddress(index,address)
	if CodeSet[index] then
		CodeSet[index].x=address
		return true
	else
		return false
	end
end
function _M.count()
	return Cur_Count
end
function _M.write(pcmd,layerdiff,x)
	CodeSet[Cur_Count]={}
	CodeSet[Cur_Count].pcmd=toPCode(pcmd)		-- convert to 3 Letter OP
	if not CodeSet[Cur_Count].pcmd then
		err(500)
	end
	CodeSet[Cur_Count].layerdiff=layerdiff
	CodeSet[Cur_Count].x=x
	Cur_Count=Cur_Count+1		-- start from 0 to Cur_Count
end
function _M.output()
	for i=0,Cur_Count-1 do
		FileOut:write(CodeSet[i].pcmd..' '..CodeSet[i].layerdiff..' '..tostring(CodeSet[i].x)..'\n')
	end
end

-----------------------------------------------------------------------------
-- Debug functions
-----------------------------------------------------------------------------
function _M.status()
	print("PCoder Status:")
	print("Line\t=\t"..Cur_Line)
	print("Token\t=\t"..Token.type.."\t"..Token.value)
	print()
end
function _M.test()
	for i=0,Cur_Count-1 do
		print('['..i..']\t'..(CodeSet[i].pcmd or '<BAD>')..' '..(CodeSet[i].layerdiff or '<BAD>')..' '..(tostring(CodeSet[i].x) or '<BAD>'))
	end
end

-----------------------------------------------------------------------------
return _M
