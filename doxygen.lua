---
-- doxygen/doxygen.lua
---

local p = premake
p.modules.doxygen = {}

local m = p.modules.doxygen
m._VERSION = p._VERSION

-----------------------------------

local DOXYFILE_FIELD_TEXT_VALUE = {
	"PROJECT_BRIEF",
	"PROJECT_NAME"
}

local DOXYFILE_FIELD_TABLE_VALUE = {
	"ABBREVIATE_BRIEF",
	"STRIP_FROM_PATH",
	"STRIP_FROM_INC_PATH",
	"ALIASES",
	"TCL_SUBST",
	"EXTENSION_MAPPING",
	"ENABLED_SECTIONS",
	"FILE_VERSION_FILTER",
	"CITE_BIB_FILES",
	"INPUT",
	"FILE_PATTERNS",
	"EXCLUDE",
	"EXCLUDE_PATTERNS",
	"EXCLUDE_SYMBOLS",
	"EXAMPLE_PATH",
	"EXAMPLE_PATTERNS",
	"IMAGE_PATH",
	"INPUT_FILTER",
	"FILTER_PATTERNS",
	"FILTER_SOURCE_PATTERN",
	"CLANG_OPTIONS",
	"IGNORE_PREFIX",
	"HTML_EXTRA_FILES",
	"QHP_CUST_FILTER_ATTRS",
	"QHP_SECT_FILTER_ATTRS",
	"MATHJAX_EXTENSIONS",
	"EXTRA_SEARCH_MAPPINGS",
	"EXTRA_PACKAGES",
	"LATEX_EXTRA_STYLESHEET",
	"LATEX_EXTRA_FILES",
	"INCLUDE_PATH",
	"INCLUDE_FILE_PATTERNS",
	"PREDEFINED",
	"TAGFILES",
	"DOTFILE_DIRS",
	"MSCFILE_DIRS",
	"DIAFILE_DIRS"
}

local this = {}

function this.getcommonpath (paths)
	if #paths == 1 then return paths[1] end
	local match = false
	local parts = {}
	for i, part in ipairs (paths) do
		table.insert (parts, part)
	end
	
	while (not match)
	do
		match = true
		local reference
		for _, part in pairs (parts)
		do
			if reference == nil then reference = part end
			if part ~= reference then
				match = false
				break
			end 
		end
		
		if match then return reference end
			
		for i,part in ipairs (parts) do
			parts[i] = path.getdirectory (part)
		end
	end
	
	return nil
end

function this.append (ctx, key, value)
	if type(ctx.settings[key]) ~= "table" then
		if type(ctx.settings[key]) == nil then
			ctx.settings[key] = {}
		else
			ctx.settings[key] = { ctx.settings[key] }
		end
	end
	
	if type(value) == "table" then
		for _, v in ipairs(value) do
			if (not table.contains(ctx.settings[key])) then
				table.insert (ctx.settings[key], v)
			end
		end
	elseif (not table.contains(ctx.settings[key], value)) then
		table.insert (ctx.settings[key], value)
	end
end

function this.set (ctx, key, value)
	ctx.settings[key] = value
end

function this.assign  (ctx, key, value)
	key = string.upper(string.gsub(key, "%s+", "_"))
	if table.contains (DOXYFILE_FIELD_TABLE_VALUE, key) then
		this.append (ctx, key, value)
	else
		this.set (ctx, key, iif(
			table.contains (DOXYFILE_FIELD_TEXT_VALUE, key),
			premake.quoted(tostring(value)),
			value
		))
	end
end

function this.generate (ctx)
	for k, v in pairs (ctx.settings)
	do
		if type (v) == "boolean"
		then
			v = iif (v, "YES", "NO")
		elseif type (v) == "table"
		then
			v = table.implode (v, "", "", " \\\n\t")
		end
		
		if #v > 0
		then
			p.w (k .. " = " .. v)
		end
	end
end

function this.onWorkspace (wks)
	if type(wks.doxygen) == "boolean"
		and wks.doxygen == false
	then
		return
	end
	
	local ctx = {
		workspace = wks,
		settings = {},
		location = wks.location or path.getdirectory (_MAIN_SCRIPT),
		filename = wks.name 
	}

	local targetdirs = {}
	for cfg in p.workspace.eachconfig (wks) do
		table.foreachi (cfg.includedirs, function (d)
			this.append (ctx, "INCLUDE_PATH", d) 
		end)
		table.foreachi (cfg.sysincludedirs, function (d)
			this.append (ctx, "EXCLUDE", d) 
		end)
		table.insert (targetdirs, cfg.targetdir or cfg.location)
	end
	
	local targetdir = this.getcommonpath(targetdirs) or ctx.location
	
	this.set (ctx, "PROJECT_NAME", wks.name)
	this.set (ctx, "OUTPUT_DIRECTORY", targetdir)
	
	for k, v in pairs (wks.doxyfile) do
		this.assign (ctx, k, v)
	end
	
	for prj in p.workspace.eachproject (wks) do
		this.onProject (prj, ctx) 
	end
	
	p.generate(ctx, ".doxyfile", this.generate)
end

function this.onProject (prj, ctx)
	if type(prj.doxygen) == "boolean"
		and prj.doxygen == false
	then
		return
	end
	
	for cfg in p.project.eachconfig (prj)
	do
		table.foreachi (cfg.includedirs, function(d)
			this.append (ctx, "INCLUDE_PATH", d)
		end)
		table.foreachi (cfg.files, function (f)
				if (p.languages.isc(cfg.language) or p.languages.iscpp(cfg.language))
					and not(path.iscppheader (f)) then return end
				if p.languages.iscsharp(cfg.language) 
					and not string.endswith (f, ".cs") then return end
					
				this.append (ctx, "INPUT", f)
		end)
	end
	
	for k, v in pairs (prj.doxyfile) do
		this.assign (ctx, k, v)
	end
end

p.api.register {
	name = "doxygen",
	scope = "project",
	kind = "boolean",
}

p.api.register {
	name = "doxyfile",
	scope = "config",
	kind = "keyed:mixed"
}
	
newaction {
	trigger     = "doxygen",
	shortname   = "Doxygen",
	description = "Generate Doxygen configuration file",
	valid_languages = { "C", "C++", "C#" },
	valid_kinds     = { "ConsoleApp", "WindowedApp", "StaticLib", "SharedLib" },

	onWorkspace = this.onWorkspace,
}


return m