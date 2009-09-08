#!/usr/bin/env lua5.1
package.path = "?.lua;../?.lua;" .. package.path

-- Basic variables (global vars are in upper case)
require "tools.config"
local util = require "tools.util"

-- Local scope
local string = require "tools.split"
local platforms = require "tools.platforms"
local myplat = platforms[TEC_SYSNAME]

--- Retrieves the release information
function getrelease()
	-- Identifying the release by 2 ways:
	-- 1. if the svn command is available
	local url,tag
	if os.execute("which svn >/dev/null") == 0 then
		url = myplat.exec("cd "..SVNDIR.." && env LANG=C svn info |grep URL")
		url = url:match("URL:%s*(.+)([%p%c%s]+)$")
		print("[ DEBUG ] Generating release information: Parsing the URL '".. url .."'")
	end
	-- 2. or if the config already provides it
	url = url or SVNURL

	url,tag = url:match("(.+)/(.+)$")
	if tag and tag == "trunk" and os.execute("which svn >/dev/null") == 0 then
		local rev = myplat.exec("cd "..SVNDIR.." && env LANG=C svn info|grep Rev:")
		rev = rev:match(".*Rev:%s*(%w+).*$")
		if rev then
			tag = "OB_HEAD_r"..rev
		end
		print("[ DEBUG ] Generating release information: Parsing the Revision '".. rev.."'")
	end
	-- when ...openbus/trunk ; url = ...openbus and tag = OB_r27387 ??
	-- when ...openbus/branches/OB_v1_10_2008_12_12 ; url = ...openbus/branches and tag = OB_v1_10..

	print("[ WARNING ] Using the following release information to create packages: "..tag)
	return assert(tag)
end

--- Packs in a tarball named by profile
function pack(arch,profile)
	-- Overwriting some global variables with arch values
	-- Using 'tools.config.changePlatform' global function
	local PKGDIR = changePlatform(arch)

	local tarball_files = ""
	local metadata_files = ""
	-- Adds file contents to a big string
	local function add(f)
		if f then
			local str = f:read("*a"):gsub("\n"," "):gsub("${TEC_UNAME}",arch)
			tarball_files = tarball_files .. str
			f:close()
		end
	end
	local function addmetadata(filename)
		if io.open(filename,"r") then
			metadata_files = metadata_files .." ".. filename
		end
	end

	local _,name = profile:match("(.*)/(.*)") --extracts name "dir/name.profile"
	name = name or profile                    --could nil only if "name.profile"
	name = name:gsub(".profile","")           --deletes the suffix ".profile"

	print "----------------------------------------------------------------------"
	print("[ INFO ] Generating the tarball for arch:".. arch .." profile:".. name)
	local file = assert(io.open(profile,"r") or 
			io.open(name..".profile","r") or 
			io.open(DEPLOYDIR .."/profiles/".. name,"r") or 
			io.open(DEPLOYDIR .."/profiles/".. name ..".profile","r"))

	-- Listing packages from profile description
	local l = file:lines()
	repeat
		p = l()
		if p then
			addmetadata(PKGDIR.."/"..p..".template")
			addmetadata(PKGDIR.."/"..p..".files")
			addmetadata(PKGDIR.."/"..p..".links")
			-- including filenames inside of *.files
			add(io.open(PKGDIR.."/"..p..".files","r"))
			-- including link's name inside of *.links
			add(io.open(PKGDIR.."/"..p..".links","r"))
		end
	until (p == nil)

	-- Creates a metadata.tar.gz and include it in tarball_files
	-- Tip: the installation actually is inside of INSTALL.TOP !
	local release = getrelease()
	local metadata_dirname = "metadata-"..release.."-"..name
	assert(os.execute(myplat.cmd.mkdir .. TMPDIR .."/"..metadata_dirname) == 0)
	assert(os.execute(myplat.cmd.install .. metadata_files .." "..TMPDIR.."/"..metadata_dirname) == 0)
	assert(os.execute("cd ".. TMPDIR .." && tar -cf - ".. metadata_dirname .." |gzip > ".. metadata_dirname ..".tar.gz") == 0)
	assert(os.execute("mv ".. TMPDIR .."/".. metadata_dirname ..".tar.gz ".. INSTALL.TOP) == 0)
	assert(os.execute(myplat.cmd.rm .. TMPDIR) == 0)
	tarball_files = tarball_files .." ".. metadata_dirname..".tar.gz "

	-- Call the 'tar' command
	local excludefile = os.tmpname()
	local tar_cmd = "cd ".. INSTALL.TOP .." && "
	tar_cmd = tar_cmd .. "find . -name .svn -type d |sed \"s#^./##\" >"..excludefile.." && tar cfX - "..excludefile.." "
	tar_cmd = tar_cmd .. tarball_files
	tar_cmd = tar_cmd .. "|gzip > "..DOWNLOADDIR.."/openbus-".. release .."-"..name.."-".. arch .. ".tar.gz "
	assert(os.execute(tar_cmd) == 0, "Cannot execute the command \n"..tar_cmd..
	                  "\n, ensure that 'tar' command has --exclude option!")

	-- Cleans the temporary excludefile
	os.remove(excludefile)
	print "[ INFO ] Done!"
	print "----------------------------------------------------------------------"
end

--------------------------------------------------------------------------------
-- Main code -------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Parsing arguments
local arguments = util.parse_args(arg,[[
	--help                   : show this help
	--verbose                : turn ON the VERBOSE mode (show the system commands)
	--profile=filename       : use the 'filename' as input for profile with the
	                           list of packages to packaging
	--arch=tecmake_arch      : specifies the arch based on tecmake way. Use 'all'
	                           to pack all supported architectures
 NOTES:
 	The prefix '--' is optional in all options.
	So '--help' or '-help' or yet 'help' all are the same option.]])

-- Overloading the os.execute to dummy verbose
if arguments["verbose"] or arguments["v"] then
	util.verbose(1)
end

assert(arguments["profile"],"Missing argument --profile!")
assert(arguments["arch"] or TEC_UNAME,"Missing argument --arch and not found TEC_UNAME env!")
arguments["arch"] = arguments["arch"] or TEC_UNAME

if arguments["arch"] ~= "all" then
	pack(arguments["arch"],arguments["profile"])
else
	-- making for all
	for _,arch in ipairs(SUPPORTED_ARCH) do
		pack(arch,arguments["profile"])
	end
end