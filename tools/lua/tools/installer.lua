#!/usr/bin/env lua5.1
package.path = "?.lua;../?.lua;" .. package.path

require "tools.config"
local util = require "tools.util"
local platforms = require "tools.platforms"
local myplat = platforms[TEC_SYSNAME]
--[[
  USO:
  1. gera um arquivo de template da configuracao com as respostas
  2. salva esse arquivo para o admin poder reusar
  3. faz a configuração real no openbus (substituindo valores em core/conf/*.lua)
  4. fazer a configuração a partir de um arquivo de input considerando que
     o admin já tem esse 'arquivo' com as respostas
]]

CONFIG = "[ CONFIGURE ] "
INSTALL = "[ INSTALL ] "
ERROR = "[ ERROR ] "

-- Configures with user interation
function wizard(template, save)
	local function parser(_,t)
		-- for a complex type delegates to __call metamethod
		if t.type == "list" then
			t.check(t, save)
		-- for a simple data asks and retrieves the answer
		else
			print(CONFIG,"Property name: ".. t.name)
			print(CONFIG,t.msg)
			io.write("> ")
			local var = io.read("*l")
			if t.type == "number" then
				var = tonumber(var)
			end
			assert(type(var) == t.type, "ERROR: Invalid configuration value, should be '".. t.type.."'")
			save[t.name] = var
		end
	end
	-- call the parse for all fields in template table
	table.foreach(template,parser)
end

-- Checks consistency between two configuration tables
function checker(template, cfg)
	local missing = {}
	for _, t in ipairs(template) do
		-- if missing configuration marks in the missing table
		if not cfg[t.name] then
			table.insert(missing, t.name)
		elseif (type(cfg[t.name]) ~= t.type) and 
		  (type(cfg[t.name]) ~= "table" or t.type ~= "list") then
			return false , "Invalid type on definition of '"..t.name.."'"
		end
	end
	-- returns a table with the missing configuration
	if #missing > 0 then
		return false, "Missing some definitions", missing
	end
	-- it's all right and no missing
	return true
end

-- Simple get to index by name
function getFieldByName(tbl, name)
	for i, t in ipairs(tbl) do
		if t.name == name then
			return t
		end
	end
	return nil
end

-- Launcher for the wizard that accepts an old configuration table
function launchWizard(template, cfg, reconfig_flag)
	assert(type(template) == "table")
	if cfg then
		if reconfig_flag then
			-- Force the user fill the installPath again (he could have change it)
			cfg.installPath = nil
		end
		-- Checks the consistency of the previous configuration
		local ok, errmsg, missing = checker(template.messages,cfg)
		if not ok then
			print(CONFIG,errmsg.. ", please complete the following properties:")
	--~ print("Sua configuração está incompleta, por favor complete os items:")
			local missing_msg = {}
			table.foreach(missing, function(i,v)
				print("  ",v)
				table.insert(missing_msg,getFieldByName(template.messages,v))
			end)
			-- Retrieves the missing configuration from user interation
			wizard(missing_msg,cfg)
		else
			print(CONFIG,"Thanks, your configuration is valid and was accepted!")
		end
	else
		cfg = {}
		wizard(template.messages,cfg)
	end
	return cfg
end

-- Loads a template table from a filename
function loadTemplate(tmplname)
	assert(type(tmplname) == "string")
	assert(not _G.messages and not _G.configure_action,
		"ERROR: Possible BUG = Lua global environment already "..
		"has _G.messages or _G.configure_action !")
	assert(loadfile(tmplname),
		 "ERROR: Cannot import the configuration template '"..tmplname.."'.")()

	local template = {
		messages = _G.messages,
		configure_action = _G.configure_action,
	}
	_G.messages = nil
	_G.configure_action = nil

	-- We assume that template contains a 'messages' table
	assert(type(template.messages) == "table",
				 "ERROR: Invalid template. Table 'messages' not found inside it.")
	if template.configure_action then
		assert(type(template.configure_action) == "function",
				 "ERROR: Invalid template. Function 'configure_action' not found inside it.")
	end

	return template
end

function parseTemplate(filename, config)
	-- parses the template
	local tmpl_table = loadTemplate(filename)
	-- launch the wizard to ask what it needs to user
	local config = launchWizard(tmpl_table, config)
	-- if all right then take a custom action (if exists)
	if not tmpl_table.configure_action then
		print(CONFIG, "WARNING: Template '"..filename.."' has no action.")
	else
		-- Takes the action planned by developer
		assert(tmpl_table.configure_action(config, TMPDIR, util), "ERROR: Custom action"..
				" from template '"..filename.."' has failed!")
	end
	return config
end

--------------------------------------------------------------------------------
-- Main code -------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Parsing arguments
local arguments = util.parse_args(arg,[[
	--help                   : show this help
	--config=filename        : use 'filename' to import a previous configuration
	--package=filename       : package 'filename' to unpack, configure and install
	--template=filename      : use 'filename' as input for answers
	
 NOTES:
	If you give '--package' so the '--template' will be discard !
	The '--template' is useful in manual reconfiguration only !

 	The prefix '--' is optional in all options.
	So '--help' or '-help' or yet 'help' all are the same option.

 EXAMPLES:
	]].. arg[0].. [[ --package=myOpenBus.tar.gz --config=myPrevious.answers ]])

-- Setting verbose level if requested
if arguments["verbose"] or arguments["v"] then
	util.verbose(1)
end

-- Cache variables
-- ATTENTION: config as 'nil' is important if none previous conf is given
local template, config

if arguments.config then
	print(CONFIG,"Input configuration file given, checking it for updates!")
	local dump = assert(io.open(arguments.config,"r"),
	                    "ERROR: Opening file '"..arguments.config.."'."):read("*a")

	assert(loadstring("fromconsole = "..dump), "ERROR: Invalid syntax of file")()
	assert(type(fromconsole) == "table", "ERROR: Configuration should be a table")
	config = fromconsole
	fromconsole = nil
end

-- Loading configuration from template file provided or from default
if arguments.template then
	config = assert(parseTemplate(arguments.template,config), "ERROR: Failed parsing template '"..arguments.template.."'.")	
else
	config = assert(parseTemplate(DEFAULT_TEMPLATE,config), "ERROR: Failed parsing template '"..DEFAULT_TEMPLATE.."'.")	
end

-- When no package is given assumes reconfiguration
if arguments.package then
	if arguments.package:match(".*openbus.*tar.gz$") then
		-- Starting the extraction of the package
		print(INSTALL, "Unpacking in a temporary dir '"..TMPDIR.."'...")
		assert(os.execute(myplat.cmd.mkdir .. TMPDIR) == 0)
		
		-- Trying extract the metadata.tar.gz from package
		print(INSTALL, "Extracting metadata.")
		local _,release,profile,arch = arguments.package:match("(.*)openbus%-(.+)%-(.+)%-(.+).tar.gz$")
		extract_cmd = myplat.cmd.install..arguments.package.." ".. TMPDIR .."/tempinstall.tar.gz;"
		extract_cmd = extract_cmd .. " cd "..TMPDIR.." ; gzip -c -d tempinstall.tar.gz | "
		extract_cmd = extract_cmd .. "tar -xf - metadata-"..release.."-"..profile..".tar.gz && "
		extract_cmd = extract_cmd .. "gzip -c -d metadata-"..release.."-"..profile..".tar.gz |"
		extract_cmd = extract_cmd .. "tar -xf -"
		assert(os.execute(extract_cmd) == 0, "ERROR: '".. arguments.package .."'"..
					 " is not a valid package! Please contact the administrator!")

		-- Unpacking the openbus-<<release>>_plat.tar.gz package
		-- Grant to user's configure_action functions that could operate over an
		-- instalation tree and at the end all files will be copied to real path
		assert(os.execute("cd "..TMPDIR.."; gzip -c -d tempinstall.tar.gz|tar -xf -") == 0)
		assert(os.remove(TMPDIR.."/tempinstall.tar.gz"))
		print(INSTALL, "Unpack DONE.")

		-- Verifying the openbus libraries consistency for this system
		print(INSTALL, "Searching missing dependencies...")
		local libchecker = require "tools.checklibdeps"
		local ok, msg = libchecker:start(TMPDIR)
		if not ok then error(msg.."\n '"..arguments.package.."'"..
		               " has missing dependencies! Please contact the administrator!")
		else print(INSTALL,msg) end

		print(CONFIG, "Configuring the package based on package metadata")
		local metadata_dirname = "metadata-"..release.."-"..profile
		-- Configure main step, using all .template of this package metadata
		local files = myplat.exec(myplat.cmd.ls .. TMPDIR .."/".. metadata_dirname)
		local nexttmpl = files:gmatch("%S+.template")
		local tmplname, template
		tmplname = nexttmpl()
		-- For each template ...
		while type(tmplname) == "string" do
			-- parse the template
			local filename = TMPDIR.."/"..metadata_dirname.."/"..tmplname
			config = assert(parseTemplate(filename, config), "ERROR: Failed parsing template '"..filename.."'.")
			-- go to next template!
			tmplname = nexttmpl()
		end
		-- Removing metadata files to clean the temporary tree
		-- Maybe it's important for futher actions like uninstall or pos-install checks
		assert(os.execute(myplat.cmd.rm .. TMPDIR .."/".. metadata_dirname) == 0)
		-- Moving the temporary tree to real tree (given by user)
		assert(os.execute(myplat.cmd.mkdir .. config.installPath) == 0,
					 "ERROR: The installation path is invalid or you cannot write there!")
		assert(os.execute(myplat.cmd.install .. TMPDIR .."/* ".. config.installPath) == 0)
		assert(os.execute(myplat.cmd.rm .. TMPDIR) == 0)
	else
		print(INSTALL,"Do nothing. You MUST provide a valid package filename "..
					"'openbus-<release>-<profile>-<plat>.tar.gz' to install the OpenBus.")
		print(INSTALL,"Please check --help for more instructions.")
		os.exit(0)
	end
else
	--TODO: reconfiguration isn't implemented yet!
	error("ERROR: Mandatory argument --package was not provided. Aborting!")
end

print(CONFIG, "Configure DONE.")

print(INSTALL,"You MUST set in your profile the sytem variable OPENBUS_HOME as:")
print("\t csh shell      : setenv OPENBUS_HOME \""..config.installPath.."\"")
print("\t ksh/bash shell : export OPENBUS_HOME=\""..config.installPath.."\"")
--~ print("\t windows shell  : set OPENBUS_HOME=\""..config.installPath.."\"")

-- Persisting the answers to future interactions
util.serialize_table("/tmp/latest.answers",config)
print(INSTALL,"Saving your answers at '/tmp/latest.answers' please backup it if you need.")

print(INSTALL,"Installation DONE!")