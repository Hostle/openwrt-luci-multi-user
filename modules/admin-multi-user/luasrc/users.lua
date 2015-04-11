-- luci/openwrt multi user implementation V1 --
-- users.lua by Hostle 12/12/2014 --

module("luci.users", package.seeall)

--## General dependents ##--
require "luci.sys"

--## Add/Remove User files and dependants ##--
local fs = require "nixio.fs"
local passwd = "/etc/passwd"
local passwd2 = "/etc/passwd-"
local shadow = "/etc/shadow"
local shadow2 = "/etc/shadow-"
local groupy = "/etc/group"
local users_file = "/etc/config/users"
local homedir

--## global User buffers ##--
local ui_users = {}
local ui_usernames = {}
local sys_usernames = {}
local valid_users = {}

--## debugging ##--
local debug = 0
local logfile = "/tmp/users.log"

--## users model boiler plate ##--
users = {}
users.prototype = { name = "new user", user_group = "default", shell = "none", menu_items = "none" }
users.metatable = { __index = users.prototype }

function users:new(user)
	setmetatable(users, users.metatable)
	return user
end



--## login function to provide valid usernames, used by dispatcher,index and serviceclt ##--
function login()
   local users = assert(io.open("/etc/passwd", "r"))
   local i = 1

   for line in users:lines() do
    if line and line ~= "" then
      line = line:sub(1, line:find(":")-1)
       if line ~= "daemon" and line ~= "network" and line ~= "nobody" then
        valid_users[i] = line
        i = i + 1
      end
    end
   end
   users:close()
  return valid_users
end

--########################################### File parsing fuctions ########################################--

--## load user tmp buffer (tbuf) into ui_usernames buffer ##--
function process_ui_user(tbuf)
  local nbuf = {}
  local user = users:new()
  local line = ""
  local menu_items = ""

	for k,v in pairs(tbuf) do
	  if v:find("option name") then
	   name = v:sub(v:find("option")+13, -2)
	   nbuf["name"]= name
	   --print("USER ="..nbuf["name"])
	  end
	  if v:find("user_group") then
	   user_group = v:sub(v:find("option")+19,-2)
	   nbuf["user_group"]=user_group
	   --print("GROUP="..nbuf["user_group"])
	  end
	  if v:find("shell") then
	   shell = v:sub(v:find("option")+14,-2)
	   nbuf["shell"]=shell
	   --print("SHELL="..nbuf["shell"])
	  end
	  --[[if v:find("menu_items") then
	   menu_items = v:sub(v:find("option")+19,-2)
	   nbuf["menu_items"]=menu_items
	   --print("MENUS="..nbuf["menu_items"])
	  end]]--
	   if v:find("status_menu") then
	   status_menu = v:sub(v:find("option")+20,-2)
	   nbuf["status_menu"]=status_menu
	   --print("STATUS MENUS="..nbuf["status_menu"])
	  end
	   if v:find("system_menu") then
	   system_menu = v:sub(v:find("option")+20,-2)
	   nbuf["system_menu"]=system_menu
	   --print("STATUS MENUS="..nbuf["system_menu"])
	  end
	   if v:find("network_menu") then
	   network_menu = v:sub(v:find("option")+21,-2)
	   nbuf["network_menu"]=network_menu
	   --print("STATUS MENUS="..nbuf["network_menu"])
	  end
	   if v:find("status_subs") then
	   status_subs = v:sub(v:find("option")+20,-2)
	   nbuf["status_subs"]=status_subs
	   --print("STATUS SUBS="..nbuf["status_subs"])
	  end
	   if v:find("system_subs") then
	   system_subs = v:sub(v:find("option")+20,-2)
	   nbuf["system_subs"]=system_subs
	   --print("SYSTEM SUBS="..nbuf["system_subs"])
	  end
	   if v:find("network_subs") then
	   network_subs = v:sub(v:find("option")+21,-2)
	   nbuf["network_subs"]=network_subs 
	   --print("NETWORK SUBS="..nbuf["network_subs"])
	  end
	end
	if nbuf.status_menu and nbuf.status_menu ~= "nil" then
	menu_items =  menu_items .. " " .. nbuf.status_menu
	end
	if nbuf.system_menu and nbuf.system_menu ~= "nil" then
	menu_items =  menu_items .. " " .. nbuf.system_menu
	end
	if nbuf.network_menu and nbuf.network_menu ~= "nil" then
	menu_items =  menu_items .. " " .. nbuf.network_menu
	end
	if nbuf.network_subs then
	menu_items = menu_items .. " " .. nbuf.network_subs
	end
	if nbuf.system_subs then
	menu_items = menu_items .. " " .. nbuf.system_subs
	end
	if nbuf.status_subs then
	menu_items = menu_items .. " " .. nbuf.status_subs
	end
        nbuf.menu_items = menu_items:sub(2,-1)
	--print(nbuf.menu_items)

	user = users:new({ name = nbuf.name, user_group = nbuf.user_group, shell = nbuf.shell, 
			           menu_items = nbuf.menu_items })

	ui_users[user.name] = { user_group = nbuf.user_group, shell = nbuf.shell, 
				            menu_items = nbuf.menu_items }  --## add user and info to ui_users buffer

	ui_usernames[#ui_usernames+1]=user.name --## keep track of ui_usernames
end

--## seperate users from "/etc/config/users" file and add to temp buffer (tbuf) ##--
function load_ui_user_file()
  local file = io.open(users_file, "r")
  local buf = {}
  local buft = {}
  local i = 1

	for line in file:lines() do
	  if line ~= nil then
	   buf[i]=line
	   i = i + 1
	  end
	end
	file:close()
	for i=1, #buf do
	  if buf[i]:find("config user") then
	   j = 1
	   repeat
	   buft[j]= buf[i+j]
	   j = j + 1
	   until buf[j] ==  ""
	   process_ui_user(buft) --## send user to be added to ui_users 
	  end
	end
end

--## function to load users from "/etc/passwd" file into sys_usernames buffer ##--
function load_sys_user_file()
  local file = assert(io.open(passwd, "r"))
  local line = ""
  local i = 1

	for line in file:lines() do
	  if line and line ~= "" then
	   line = line:sub(1, line:find(":")-1)
	    if line ~= "root" and line ~= "daemon" and line ~= "network" and line ~= "nobody" and line ~= "ftp" then
	     sys_usernames[i] = line
	     i = i + 1
		  end
	  end
	end
  file:close()
end

--## function to find new users and add them to the system (checks if shell has changed too) ##--
function add_users()
  local x = 1

	repeat
	  for i,v in pairs(ui_usernames) do
		tmp_name = v
		for j,k in pairs(sys_usernames) do
		  if tmp_name == k then is_user = true end
		end
		if is_user then 
		  if ui_users[tmp_name].shell == "1" then 
		    check_shell(tmp_name,true)
		  else
		    check_shell(tmp_name,false)
		  end 
		end
		if not is_user then 
		  create_user(tmp_name,ui_users[tmp_name].shell,ui_users[tmp_name].user_group) 
		end
		is_user = false
		x = x + 1
	  end
	until x > #ui_usernames
end

--## function to find deleted users and remove them from the system ##--
function del_users()
  local tmp_name
  local x = 1

	repeat
	  for i,v in pairs(sys_usernames) do
	    tmp_name = v
	    for j,k in pairs(ui_usernames) do
	      if tmp_name == k then 
		      is_user = true 
		    end
	    end
	    if not is_user then 
		    remove_user(tmp_name) 
		  end
	    is_user = false
	    x = x + 1
	  end
	until x > #sys_usernames
end

--## function to add user to system ##--
function create_user(user,shell,group)
	if shell == '1' then 
	  shell = "/bin/ash" 
	else 
	  shell = "/bin/false" 
	end
	  check_user(user, group, shell)
	  setpasswd(user)
end

--## function to remove user from system ##--
function remove_user(user)
	delete_user(user)
end

--## function to check if user gets ssh access (shell or not) ##--
function check_shell(user,has_shell)
	 local file = assert(io.open(passwd, "r"))
	 local line = ""
	 local shell
	 local i = 1
	 local buf = {}

	   for line in file:lines() do
	    if line and line ~= "" then
	     buf[i]=line
	     if line:find(user) then
              shell = line:sub(line:find(":/bin/")+1,-1)
	     end
             i = i + 1
	    end
           end
	   file:close()
	   if has_shell and shell ~= "/bin/ash" then
	    for i = 1, #buf do
	     if buf[i]:find(user) then
              buf[i]=buf[i]:gsub("/bin/false", "/bin/ash")
             end
	    end
   	   elseif not has_shell and shell ~= "/bin/false" then
   	    for i = 1, #buf do
	     if buf[i]:find(user) then
              buf[i]=buf[i]:gsub("/bin/ash", "/bin/false")
             end
	    end
	   end
	   file = assert(io.open(passwd, "w+"))
	   for k,v in pairs(buf) do
            file:write(v.."\n")
	   end
	   file:close()
end

--## function used by dispatcher to remove specified menus from index tree ##--
--## Called by disatcher to determine what menus should be visible ##-- 
function hide_menus(user,menus)
	  if user == nil then return end
	  local x = 1
	  load_ui_user_file()
	  local h_menus = ui_users[user].menu_items

	  for token in string.gmatch(h_menus, "[^%s]+") do
      	      menus[x]=token
	      x = x + 1
	  end
	  return(menus)
end

--## function to set default password for new users ##--
--## duplicate of luci set password only a default password is set(openwrt)
function setpasswd(username,password)
	if not password then password = "openwrt" end
		password = password:gsub("'", [['"'"']])


	if username then
		username = username:gsub("'", [['"'"']])
	end

	return os.execute(
		"(echo '" .. password .. "'; sleep 1; echo '" .. password .. "') | " ..
		"passwd '" .. username .. "' >/dev/null 2>&1"
	)
end

--####################################### Ulitlity functions ###############################################--

--## function to check if user exists ##--
function checkit(val, file)
 if not file then file = io.open(passwd, "r")
  for line in file:lines() do
   if line:find(val) then file:close() return false end
  end
 end
  return true
end

--## function to check if file exists ##--
--## can be replaced with nixio file access ##-- 
local function exists(name)
    if type(name)~="string" then return false end
    return os.rename(name,name) and true or false
end

--## function to check if path is a file ##--
local function isFile(name)
    if type(name)~="string" then return false end
    if not exists(name) then return false end
    local f = io.open(name)
    if f then
        f:close()
        return true
    end
    return false
end

--## function to check if path is a directory ##--
local function isDir(name)
    return (exists(name) and not isFile(name))
end

--## function to get next available uid ##--
function get_uid(group)
  local file = assert(io.open(passwd, "r"))
  local t = {}
  local i = 1
  local pat_uid

  if group == "admin" then
    pat_uid = ":1%d%d%d:1%d%d%d:"
  elseif group == "user" then
    pat_uid = ":2%d%d%d:2%d%d%d:"
  else
    if(debug > 0) then print("Error { User Group Doesn't Exists !! }") end
    fs.writefile("/tmp/multi.stderr", "Error { User Group Doesn't Exists !! }")
  end

  for line in file:lines() do
    if line:match(pat_uid) then
      line = line:match(pat_uid)
 			uid = line:sub(2,5)
 			t[i] = uid
  	  i = i + 1
    end
  end
  file:close()

  if #t < 1 then
   if group == "admin" then t[1]=1000 else t[1]=2000 end
  end
  table.sort(t)
  uid = t[#t] + 1 or 0
 return uid
end

--############################################### Add User Functions ######################################--


--## functio to prepare users home dir ##--
function create_homedir(name)
    local home = "/home/"
    local homedir = home .. name
  return homedir
end

--## function add user to passwds ##--
function add_passwd(name,uid,shell,homdir)
  local file = assert(io.open(passwd, "a"))
  local nuser = "\n"..name..":x:"..uid..":"..uid..":"..name..":"..homedir..":"..shell
  local nuser2 = "\n"..name..":*:"..uid..":"..uid..":"..name..":"..homedir..":"..shell

	if checkit(name, file) then
      file:write(nuser)
	  file:close()
	  file = assert(io.open(passwd2, "a"))
	  file:write(nuser2)
	  file:close()
  else
	  if(debug > 0) then print("Error { User Already Exists !! }") end
	  fs.writefile("/tmp/multi.stderr", "Error { User Already Exist !! }")
	 return 1
  end
end

--## function add user to shadows ##--
function add_shadow(name)
  local file = assert(io.open(shadow, "a"))
  local shad = "\n"..name..":*:11647:0:99999:7:::"

	if checkit(name, file) then
	  file:write(shad)
	  file:close()
	  file = assert(io.open(shadow2, "a"))
	  file:write(shad)
	  file:close()
    else
	  if(debug > 0) then print("Error { User Already Exists !! }") end
	  fs.writefile("/tmp/multi.stderr", "Error { User Already Exists !! }")
	 return 1
  end
end

--## function to add user to group ##--
function add_group(name,uid)
  local grp = "\n"..name..":x:"..uid..":"..name
  local file = assert(io.open(groupy, "a"))

	if checkit(name, file) then
	  file:write(grp)
	  file:close()
	else
	  if(debug > 0) then print("Error { User Already Exists !! }") end
	  fs.writefile("/tmp/multi.stderr", "Error { User Already Exists !! }")
	 return 1
	end
end

--## make the users home directory and set permissions to (755) ##--
function make_home_dirs(homedir)
	local home = "/home"

	if not isDir(home) then
	  fs.mkdir(home, 755)
	end

   if not isDir(homedir) then
      fs.mkdir(homedir, 755)
   end

	local cmd = "find "..homedir.." -print | xargs chown "..name..":"..name
	os.execute(cmd)
end

--## function to check if user is valid ##--
function check_user(name, group, shell)
	if not checkit(name) then
      if(debug > 0) then print("Error { User Already Exists !! }") end
      fs.writefile("/tmp/multi.stderr", "Error { User Already Exists !! }")
	 return 1
	elseif not name and pass and uid and shell then
      if(debug > 0) then print("Error { Not Enough Parameters !! }") end
      fs.writefile("/tmp/multi.stderr", "Error { Not Enough Parameters !! }")
	 return 1
	else
	 add_user(name, group, shell)
  end
end

--## function to add user to the system  ##--
function add_user(name, group, shell)
	local uid = get_uid(group)
	homedir = create_homedir(name)

	add_passwd(name,uid,shell,homedir)
	add_shadow(name)
	add_group(name,uid)
	make_home_dirs(homedir)
end


--################################### Remove User functions ###########################################--

--## function load file into buffer ##--
function load_file(name, buf)
  local i = 1
  local file = io.open(name, "r")

	for line in file:lines() do
	  buf[i] = line
	  if debug > 0 then print(buf[i]) end
	  i = i + 1
	end
	file:close()
	return(buf)
end

--## function to remove user from buffer ##--
function rem_user(user, buf)
	for i,v in pairs(buf) do
	  if v:find(user) then
	    table.remove(buf,i)
	  end
	end
	return(buf)
end

--## function to write buffer back to file ##--
function write_file(name, buf)
  local file = io.open(name, "w")

  for i,v in pairs(buf) do
		if debug > 0 then print(v) end
    if(i < #buf) then
	    file:write(v.."\n")
	  else
	    file:write(v)
	  end
	end
	file:close()
end

--## function remove user from the system ##--
function delete_user(user)
  local buf = { ["passwd"] = {}, ["shadow"] = {}, ["group"] = {} }

	--## load files into indexed buffers ##--
	load_file(passwd, buf.passwd)
	load_file(shadow, buf.shadow)
	load_file(groupy, buf.group)

	--## remove user from buffers ##--
	rem_user(user, buf.passwd)
	rem_user(user, buf.shadow)
	rem_user(user, buf.group)

	--## write edited buffers back to the files ##--
	write_file(passwd, buf.passwd)
	write_file(passwd2, buf.passwd)
	write_file(shadow, buf.shadow)
	write_file(shadow2, buf.shadow)
	write_file(groupy, buf.group)
	luci.sys.call("rm /home/"..user.."/*")
	fs.rmdir("/home/"..user)
end
