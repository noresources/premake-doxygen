# Premake doxygen module

`premake-doxygen` provide Doxygen configuration file generation action from Premake scripts.

```
workspace "WorldDominationMasterPlan"
	
	doxyfile {
		project_number = "1.0.0",
		example_path = "examples"
	}
	
	project "Preparation"
		-- All files and includedirs will be added to INPUT settings
		files { ... }	
		inlcudedirs { ... }
		-- sysincludedirs are excluded (EXCLUDE settings)
		sysincludedirs { ... }

	project "SecretPart"
		-- Totally exclude this project
		doxygen "off"
		
	project "Conquer"
		-- Add custom settings
		doxyfile {
			exclude = "details"
		}
```
## Usage

Add the path of this module in your Premake main configuration file

	package.path = "<path-to-module>" .. ";" .. package.path

Run `premake` using the `doxygen` action.
A .doxyfile is generated for each workspace.

Run `doxygen <workspace name>.doxyfile`

