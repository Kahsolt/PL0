#!/usr/bin/lua5.3
-----------------------------------------------------------------------------
-- PL/0 Symbol-Name Table module
-- Name: plame
-- Author: Kahsolt
-- Time: 2016-12-15
-- Version: 1.3
-- Lua Ver: 5.3
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Declare module & import dependencies
-----------------------------------------------------------------------------
plame = {}			-- 模块名
local _M = plame	-- 临时模块名
dofile('plenv.lua')	-- 执行全局参数设定

-----------------------------------------------------------------------------
-- Private variables & functions
-----------------------------------------------------------------------------
local function existName(name)
	for i=#Namespace,1,-1 do
		if Namespace[i].name==name then
			return true
		end
	end
	return nil
end

-----------------------------------------------------------------------------
-- Pulic variables & functions
-----------------------------------------------------------------------------
function _M.init()
	Address=PL0_Address
	Namespace={}		-- {['idx_i']={name,type,value,address,layer}}
end
function _M.getIndex(name)		-- search from the tail
	local _layer = Layer
	local PL0_SepearteLayer = true
	for i=#Namespace,1,-1 do
		if PL0_SepearteLayer then
			if Namespace[i].layer <= _layer then	-- upper layers can be seen
				_layer = Namespace[i].layer
			else 									-- cannot access other vars in the same absolute or deeper layer
				while 1>=1 and Namespace[i].layer~=_layer do
					i=i-1
				end
			end
		end
		if Namespace[i].name==name then
			return i
		end
	end
	return nil
end
function _M.isConst(name)
	return Namespace[_M.getIndex(name)] and Namespace[_M.getIndex(name)].type=='CONST'
end
function _M.isVar(name)
	return Namespace[_M.getIndex(name)] and Namespace[_M.getIndex(name)].type=='VAR'
end
function _M.isProc(name)
	return Namespace[_M.getIndex(name)] and Namespace[_M.getIndex(name)].type=='PROCEDURE'
end
function _M.getValue(name)
	return Namespace[_M.getIndex(name)] and Namespace[_M.getIndex(name)].value
end
function _M.getAddress(name)
	return Namespace[_M.getIndex(name)] and Namespace[_M.getIndex(name)].address
end
function _M.getLayer(name)
	return Namespace[_M.getIndex(name)] and Namespace[_M.getIndex(name)].layer
end
function _M.setName(name,type)			-- type='CONST'|'VAR'|'PROCEDURE'
	if type=='CONST' and existName(name) then
		return false
	elseif (type=='VAR' or type=='PROCEDURE') and existName(name) and _M.getName(name).layer==Layer and _M.getName(name).address==Address then
		return false
	else
		local _idx = 1		-- start from 1
		while Namespace[_idx] do _idx=_idx+1 end	-- get a availabe index
		Namespace[_idx]={}
		Namespace[_idx].name=name
		Namespace[_idx].type=type
		if type=='VAR' then
			Namespace[_idx].layer=Layer
			Namespace[_idx].address=Address
			Address=Address+1
		elseif type=='PROCEDURE' then
			Namespace[_idx].layer=Layer
			-- Namespace[_idx].address is Waited for the back-fill
		elseif type=='CONST' then
			Namespace[_idx].layer=Layer
		end
		return true
	end
end
function _M.setValue(name,value)		-- used by CONST DEFINITION
	if not Namespace[_M.getIndex(name)] then
		return false
	else
		Namespace[_M.getIndex(name)].value=value
		return true
	end
end
function _M.setAddress(name,address)	-- used by PROCEDURE BACK-FILL
	if not Namespace[_M.getIndex(name)] then
		return false
	else
		Namespace[_M.getIndex(name)].address=address
		return true
	end
end

-----------------------------------------------------------------------------
-- Debug functions
-----------------------------------------------------------------------------
function _M.test()
	print('================')
	print('Namespace Table:')
	print('================')
	print('ID\tname\tvalue\tlayer\taddress\ttype')
	for i=1,#Namespace do
		print(i..'\t'..(Namespace[i].name or '')..'\t'..(Namespace[i].value or '')..'\t'..(Namespace[i].layer or '')..'\t'..(Namespace[i].address or '')..'\t'..(Namespace[i].type or ''))
	end
	print()
end

-----------------------------------------------------------------------------
return _M
