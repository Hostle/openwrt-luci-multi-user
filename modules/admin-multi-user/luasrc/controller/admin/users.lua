
--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2011 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0
]]--

--[[ $Id: users.lua 12/12/2014 by Hostle ]]--

module("luci.controller.admin.users", package.seeall)

function index()
local nw = require "luci.dispatcher"


	local user = nw.get_user()
	if user == "root" then
	  entry({"admin", "users"}, alias("admin", "users", "users"), _("Edit Users"), 55).index = true
	  entry({"admin", "users", "users"}, cbi("admin_users/users"), _("User Options"), 60)
	  entry({"admin", "users", "logout"}, call("action_logout"), _("Logout"), 61)
	end
	if user ~= "root" then
	  name = string.sub(user:upper(),0,1) .. user:sub(2,-1)
	  entry({"admin", "users"}, alias("admin", "users", "passwd"), _(name.."s Options"), 55).index = true
	  entry({"admin", "users", "passwd"}, cbi("admin_users/passwd"), _("Password"), 62)
	  entry({"admin", "users", "logout"}, call("action_logout"), _("Logout"), 63)
	end 
 
end


function action_logout()
local dsp = require "luci.dispatcher"
local sauth = require "luci.sauth"
if dsp.context.authsession then
sauth.kill(dsp.context.authsession)
dsp.context.urltoken.stok = nil
end
luci.http.header("Set-Cookie", "sysauth=; path=" .. dsp.build_url())
luci.http.redirect(luci.dispatcher.build_url())
end

function action_passwd()
	local p1 = luci.http.formvalue("pwd1")
	local p2 = luci.http.formvalue("pwd2")
	local stat = nil

	if p1 or p2 then
		if p1 == p2 then
			stat = luci.sys.user.setpasswd(user, p1)
		else
			stat = 10
		end
	end

	luci.template.render("admin_users/passwd", {stat=stat})
end
