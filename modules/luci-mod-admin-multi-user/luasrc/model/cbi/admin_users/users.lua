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

local fs = require "nixio.fs"
local groups_path = "/etc/group"
local groups = {"admin", "user"}
local usw = require "luci.users"

local s, o

m.on_after_commit = function()
			usw.load_ui_user_file()
			usw.load_sys_user_file()
			usw.add_users()
			usw.del_users()			
		    end

s = m:section(TypedSection, "user")
s.anonymous = true
s.addremove = true

s:tab("user",  translate("User Setting"))
s:tab("status",  translate("Status Menus"))
s:tab("system",  translate("System Menus"))
s:tab("network",  translate("Network Menus"))

function s.parse(self, ...)
	TypedSection.parse(self, ...)
end


name = s:taboption("user", Value, "name", translate("User Name"))
user_group = s:taboption("user", ListValue, "user_group", translate("User Group"))
for k, v in ipairs(groups) do
	user_group:value(v)
end

o = s:taboption("user", ListValue, "shell", translate("SSH Access"))
o.rmempty = false
o:value("1", "Enabled")
o:value("0", "Disabled")
o.default = "Enabled"

o = s:taboption("user", Flag, "Status_menus", translate("Enable Status Menu"))
o.rmempty = true
o.disabled = "disabled" 
o.enabled = "Status_menus"

status_subs = s:taboption("status", MultiValue, "status_subs", translate("Status Menus"))
status_subs.rmempty = true
status_subs:depends("Status_menus", "Status_menus")
--status_subs:value("Overview", "Overview")
status_subs:value("Firewall", "Firewall")
status_subs:value("Routes", "Routes")
status_subs:value("System_log", "System Log") 
status_subs:value("Kernel_log", "Kernel Log")
status_subs:value("Processes", "Processes")
status_subs:value("Realtime_graphs", "Realtime Graphs")

o = s:taboption("user", Flag, "System_menus", translate("Enable System Menu"))
o.rmempty = true 
o.disabled = "disabled" 
o.enabled = "System_menus"

system_subs = s:taboption("system", MultiValue, "system_subs", translate("System Menus"))
system_subs.rmempty = true
system_subs:depends("System_menus", "System_menus")
system_subs:value("System", "System")
--system_subs:value("Administration", "Administration")
system_subs:value("Software", "Software")
system_subs:value("Startup", "Startup")
system_subs:value("Scheduled_tasks", "Scheduled Tasks")
system_subs:value("Leds", "LED Configuration")
system_subs:value("Firmware", "Backup / Flash Firmware")
system_subs:value("Reboot", "Reboot")

o = s:taboption("user", Flag, "Network_menus", translate("Enable Network Menu"))
o.rmempty = true 
o.disabled = "disabled" 
o.enabled = "Network_menus"

network_subs = s:taboption("network", MultiValue, "network_subs", translate("Network Menus"))
network_subs.rmempty = true
network_subs:depends("Network_menus", "Network_menus")
network_subs:value("Interfaces", "Interfaces")
network_subs:value("Wifi", "Wifi")
network_subs:value("Switch", "Switch")
network_subs:value("Dhcp", "DHCP and DNS")
network_subs:value("Diagnostics", "Diagnostics")

return m
