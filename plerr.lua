#!/usr/bin/lua5.3
-----------------------------------------------------------------------------
-- PL/0 Error module
-- Name: plerr
-- Author: Kahsolt
-- Time: 2016-12-12
-- Version: 1.1
-- Lua Ver: 5.3
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Declare module & import dependencies
-----------------------------------------------------------------------------
plerr = {}			-- 模块名
local _M = plerr	-- 临时模块名

-----------------------------------------------------------------------------
-- Pulic variables & functions
-----------------------------------------------------------------------------
function _M.init()
	Error_Count=0
end
function _M.info()
	if Error_Count==0 then
		print('\n[Plerr Message]: No Error')
	else
		print('\n[Plerr Message]: Total Error Count = '..Error_Count..'\n')
	end
end
function _M.what(src,id)
	Error_Count=Error_Count+1
	if tonumber(id) < 200 then		-- Fatal Error
		print('<<'..src..' Fatal Error>>: '..ErrorMessage[tostring(id)])
		os.exit()
	else
		print('['..src..' Error]: #'..Cur_Line..':'..Cur_Column..' => '..ErrorMessage[tostring(id)])
	end
end

-----------------------------------------------------------------------------
return _M
