--
-- actions/vstudio/vs2010.lua
-- Add support for the Visual Studio 2010 project formats.
-- Copyright (c) 2009-2014 Jason Perkins and the Premake project
--

	premake.vstudio.vs2010 = {}

	local p = premake
	local vs2010 = p.vstudio.vs2010
	local vstudio = p.vstudio
	local project = p.project
	local tree = p.tree


---
-- Map Premake tokens to the corresponding Visual Studio variables.
---

	vstudio.pathVars = {
		["cfg.objdir"] = "$(IntDir)",
		["prj.location"] = "$(ProjectDir)",
		["sln.location"] = "$(SolutionDir)",
		["cfg.buildtarget.directory"] = "$(TargetDir)",
		["cfg.buildtarget.name"] = "$(TargetFileName)",
		["cfg.buildtarget.basename"] = "$(TargetName)",
	}



---
-- Identify the type of project being exported and hand it off
-- the right generator.
---

	function vs2010.generateProject(prj)
		p.eol("\r\n")
		p.indent("  ")
		p.escaper(vs2010.esc)

		if premake.project.isdotnet(prj) then
			premake.generate(prj, ".csproj", vstudio.cs2005.generate)
			premake.generate(prj, ".csproj.user", vstudio.cs2005.generateUser)
		elseif premake.project.iscpp(prj) then
			premake.generate(prj, ".vcxproj", vstudio.vc2010.generate)

			-- Skip generation of empty user files
			local user = p.capture(function() vstudio.vc2010.generateUser(prj) end)
			if #user > 0 then
				p.generate(prj, ".vcxproj.user", function() p.outln(user) end)
			end

			-- Only generate a filters file if the source tree actually has subfolders
			if tree.hasbranches(project.getsourcetree(prj)) then
				premake.generate(prj, ".vcxproj.filters", vstudio.vc2010.generateFilters)
			end
		end
	end



---
-- Generate the .props, .targets, and .xml files for custom rules.
---

	function vs2010.generateRule(rule)
		p.eol("\r\n")
		p.indent("  ")
		p.escaper(vs2010.esc)

		p.generate(rule, ".props", vs2010.rules.props.generate)
		p.generate(rule, ".targets", vs2010.rules.targets.generate)
		p.generate(rule, ".xml", vs2010.rules.xml.generate)
	end



--
-- The VS 2010 standard for XML escaping in generated project files.
--

	function vs2010.esc(value)
		value = value:gsub('&',  "&amp;")
		value = value:gsub('<',  "&lt;")
		value = value:gsub('>',  "&gt;")
		return value
	end



---
-- Define the Visual Studio 2010 export action.
---

	newaction {
		-- Metadata for the command line and help system

		trigger     = "vs2010",
		shortname   = "Visual Studio 2010",
		description = "Generate Visual Studio 2010 project files",

		-- Visual Studio always uses Windows path and naming conventions

		os = "windows",

		-- The capabilities of this action

		valid_kinds     = { "ConsoleApp", "WindowedApp", "StaticLib", "SharedLib", "Makefile", "None" },
		valid_languages = { "C", "C++", "C#" },
		valid_tools     = {
			cc     = { "msc"   },
			dotnet = { "msnet" },
		},

		-- Solution and project generation logic

		onSolution = vstudio.vs2005.generateSolution,
		onProject  = vstudio.vs2010.generateProject,
		onRule = vstudio.vs2010.generateRule,

		onCleanSolution = vstudio.cleanSolution,
		onCleanProject  = vstudio.cleanProject,
		onCleanTarget   = vstudio.cleanTarget,

		pathVars        = vstudio.pathVars,

		-- This stuff is specific to the Visual Studio exporters

		vstudio = {
			csprojSchemaVersion = "2.0",
			productVersion      = "8.0.30703",
			solutionVersion     = "11",
			versionName         = "2010",
			targetFramework     = "4.0",
			toolsVersion        = "4.0",
		}
	}
