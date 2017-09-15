#!/usr/bin/lua5.3
-----------------------------------------------------------------------------
-- PL/0 Compiler
-- Name: pl0c
-- Author: Kahsolt
-- Time: 2016-12-21
-- Version: 1.1
-- Lua Ver: 5.3
-----------------------------------------------------------------------------
require 'plarse'


if #arg ~= 1 then
	print('Usage: pl0c.lua <fpath>')
	os.exit()
else
	plarse.startParse(arg[1])
end
