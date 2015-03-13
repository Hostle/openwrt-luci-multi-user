--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2011 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

--[[
LuCI - Lua Configuration Interface
$Id: users.lua 12/12/2014 by Hostle
]]--

m = Map("users", translate("User Configuration"), translate("Add / Remove or Edit Users."))


local groups_path = "/etc/group"
local groups = {"admin", "user"}
local nw = require "luci.dispatcher"
local usw = require "luci.users"

local menu = {}
local menu = nw.index_list(menu)

m.on_after_commit = function()
			usw.load_ui_user_file()
			usw.load_sys_user_file()
			usw.add_users()
			usw.del_users()			
		    end

s = m:section(TypedSection, "user", "")
s.anonymous = true
s.addremove = true

function s.parse(self, ...)
	TypedSection.parse(self, ...)
end


name = s:option(Value, "name", translate("User Name"))

user_group = s:option(ListValue, "user_group", translate("User Group"))
for k, v in ipairs(groups) do
	user_group:value(v)
end

s:option(Flag, "shell", translate("Allow SSH Access")).rmempty = false 

menu_items = s:option(MultiValue, "menu_items", translate("Hidden Menu Items"))
for k, v in ipairs(menu) do
	menu_items:value(v)
end

return m
