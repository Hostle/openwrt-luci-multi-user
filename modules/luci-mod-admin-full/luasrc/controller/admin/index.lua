-- Copyright 2008 Steven Barth <steven@midlink.org>
-- Licensed to the public under the Apache License 2.0.

--[[ multi-user support added by Hostle 12/12/14 ]]--

module("luci.controller.admin.index", package.seeall)

function index()
--## Multi User ##--
local fs = require "nixio.fs"
local valid_users = {}

--## load system users into tbl ##--
  if fs.stat("/usr/lib/lua/luci/users.lua") then
    local usw = require "luci.users"
    valid_users = usw.login()
  else
--## no multi user so root is only valid user ##--
    valid_users = { "root" }
  end

	local root = node()
	if not root.target then
		root.target = alias("admin")
		root.index = true
	end
	local page   = node("admin")
	page.target  = firstchild() 
	page.title   = _("Administration")
	page.order   = 10
	page.sysauth = valid_users
	page.sysauth_authenticator = "htmlauth"
	page.ucidata = true
	page.index = true

	-- Empty services menu to be populated by addons
	entry({"admin", "services"}, firstchild(), _("Services"), 40).index = true

	entry({"admin", "logout"}, call("action_logout"), _("Logout"), 90)
end

function action_logout()
	local dsp = require "luci.dispatcher"
	local utl = require "luci.util"
	local sid = dsp.context.authsession

	if sid then
		utl.ubus("session", "destroy", { ubus_rpc_session = sid })

		dsp.context.urltoken.stok = nil

		luci.http.header("Set-Cookie", "sysauth=%s; expires=%s; path=%s/" %{
			sid, 'Thu, 01 Jan 1970 01:00:00 GMT', dsp.build_url()
		})
	end

	luci.http.redirect(luci.dispatcher.build_url())
end
