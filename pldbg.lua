#!/usr/bin/lua5.3
-----------------------------------------------------------------------------
-- PL/0 Debugger
-- Name: pldbg
-- Author: Kahsolt
-- Time: 2016-12-20
-- Version: 1.0
-- Lua Ver: 5.3
-----------------------------------------------------------------------------
require 'plarse'

-- for k,v in pairs(_ENV) do print(k,v) end

if #arg ~= 2 then
	print('pldbg.lua l|p <fpath>')
elseif arg[1] == 'l' then
	plex.test(arg[2])
elseif arg[1] == 'p' then
	plarse.test(arg[2])
end
