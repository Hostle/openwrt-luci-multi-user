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

s:tab("user",  translate("User Settings"))
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

o = s:taboption("user", Flag, "status_menu", translate("Enable Status Menus"))
o.rmempty = true
o.disabled ="iptables routes syslog dmesg processes realtime" 
o.enabled = "nil"

status_subs = s:taboption("status", MultiValue, "status_subs", translate("Status Menus"))
status_subs.rmempty = true
status_subs:depends("status_menu", "nil")
status_subs:value("iptables", "Firewall")
status_subs:value("routes", "Routes")
status_subs:value("syslog", "System Log") 
status_subs:value("dmesg", "Kernel Log")
status_subs:value("processes", "Processes")
status_subs:value("realtime", "Realtime Graphs")

o = s:taboption("user", Flag, "system_menu", translate("Enable System Menus"))
o.rmempty = true 
o.disabled = "system" 
o.enabled = "admins"

system_subs = s:taboption("system", MultiValue, "system_subs", translate("System Menus"))
system_subs.rmempty = true
system_subs:depends("system_menu", "admins")
system_subs:value("system_tab", "System")
system_subs:value("packages", "Software")
system_subs:value("startup", "Startup")
system_subs:value("crontab", "Scheduled Tasks")
system_subs:value("leds", "LED Configuration")
system_subs:value("flashops", "Backup / Flash Firmware")
system_subs:value("reboot", "Reboot")

o = s:taboption("user", Flag, "network_menu", translate("Enable Network Menu"))
o.rmempty = true 
o.disabled ="network" 
o.enabled = "nil"

network_subs = s:taboption("network", MultiValue, "network_subs", translate("Network Menus"))
network_subs.rmempty = true
network_subs:depends("network_menu", "nil")
network_subs:value("network_tab", "Interfaces")
network_subs:value("wireless", "Wifi")
network_subs:value("vlan", "Switch")
network_subs:value("dhcp", "DHCP and DNS")
network_subs:value("hosts", "Hostnames")
network_subs:value("netroutes", "Static Routes")
network_subs:value("firewall", "FireWall")
network_subs:value("diagnostics", "Diagnostics")

return m
