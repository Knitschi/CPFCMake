# This file contains helper functions that improve the GoogleTestAdapter support of CPF projects.

include_guard(GLOBAL)


#-----------------------------------------------------------
# Documentation in APIDocs.dox
#
function(cpfGenerateGoogleTestAdapterSettingsFile packages)
	
	# Locations
	set(settingsFileName "${CMAKE_BINARY_DIR}/${PROJECT_NAME}.gta.runsettings")

	# Opening sections
	set(settingsFileContent "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n\
<RunSettings>\n\
	<GoogleTestAdapterSettings>\n\
		<SolutionSettings>\n\
			<Settings/>\n\
		</SolutionSettings>\n\
		<ProjectSettings>\n\
"
	)

	# Add one command line parameter section for each test executable.
	foreach(package ${packages})
		if(TARGET ${package})
			get_property(testTarget TARGET ${package} PROPERTY INTERFACE_CPF_TESTS_SUBTARGET)
			if(testTarget)
				get_property(testExeArguments TARGET ${testTarget} PROPERTY VS_DEBUGGER_COMMAND_ARGUMENTS)
				if(testExeArguments)
					cpfGetConfigurations(configs)
					foreach(config ${configs})

						cpfGetTestExeSettingStartTag(startTag ${testTarget} ${config})
						string(APPEND settingsFileContent "\t\t\t${startTag}\n")
						string(APPEND settingsFileContent "\t\t\t\t<AdditionalTestExecutionParam>${testExeArguments}</AdditionalTestExecutionParam>\n")
						string(APPEND settingsFileContent "\t\t\t</Settings>\n")

					endforeach()
				endif()
			endif()
		endif()

	endforeach()

	# Close sections
	set(settingsFileContentEnd " \t\t</ProjectSettings>\n\
	</GoogleTestAdapterSettings>\n\
</RunSettings>\n\
"	
	)

	string(APPEND settingsFileContent ${settingsFileContentEnd})

	file(WRITE ${settingsFileName} ${settingsFileContent})

endfunction()

#-----------------------------------------------------------
#
function( cpfGetTestExeSettingStartTag startTagOut testExeTarget config)

	cpfGetTargetOutputFileName( testExe ${testExeTarget} ${config})
	set(${startTagOut} "<Settings ProjectRegex=\"${testExe}\">" PARENT_SCOPE)

endfunction()

