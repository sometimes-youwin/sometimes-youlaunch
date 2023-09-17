class_name Sublaunchable
extends Launchable

## A file that can only be launched by a [Launchable].
##
## A launchable that is launched by a [Launchable]. [br]
## [member Launchable.command] will use an additional format arg like:
## [codeblock]
## "{command} {path} --quiet"
## [/codeblock]

const SublaunchableError := {
	EMPTY_COMMAND = "A command must be specified for sublaunchables",
	MISSING_LAUNCHABLE = "No launchable specified"
}

## The format key used for the [Launchable] to be used to launch this [code]Sublaunchable[/code].
const COMMAND_KEY := "{command}"

## The [Launchable] to use to launch this [code]Sublaunchable[/code].
@export
var launchable: Launchable = null

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

## Check if the [code]Sublaunchable[/code] is valid. Calls [method Launchable.check] first.
func check() -> Array[String]:
	var r := super.check()
	
	if command.is_empty():
		r.push_back(SublaunchableError.EMPTY_COMMAND)
	else:
		if not command.contains(COMMAND_KEY):
			r.push_back(LaunchableError.MISSING_FORMAT_KEY.format([COMMAND_KEY]))
	
	if launchable == null:
		r.push_back(SublaunchableError.MISSING_LAUNCHABLE)
	
	return r

## Get the formatted command from this [code]Sublaunchable[/code]. If the command is not valid,
## an error code will be returned. Otherwise, the [String] command will be returned.
func to_command() -> Variant:
	if not check().is_empty():
		return ERR_INVALID_DATA
	
	return command.format({
		command = launchable.to_command(),
		path = path
	})

## Create a [code]Sublaunchable[/code] from a [Launchable].
static func from_launchable(launchable: Launchable) -> Sublaunchable:
	var r := Sublaunchable.new()
	
	r.name = launchable.name
	r.description = launchable.description
	r.path = launchable.path
	r.command = launchable.command
	
	return r
