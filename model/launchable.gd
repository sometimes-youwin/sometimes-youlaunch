class_name Launchable
extends Resource

## A file that can be launched.
##
## A file that can be launched. Additional args can be used via [member command].
## [codeblock]
## "{path} --quiet"
## [/codeblock]

## Error messaging for [code]Launchable[/code]s.
const LaunchableError := {
	EMPTY_NAME = "Name is missing",
	PATH_DOES_NOT_EXIST = "Path does not exist: {0}",
	MISSING_FORMAT_KEY = "Command does not contain the expected format key: {{0}}"
}

## The key used when formatting the [member command].
const PATH_KEY := "path"

## The name of the [code]Launchable[/code]. Must be distinct.
@export
var name := ""
## The description of the [code]Launchable[/code].
@export
var description := ""

## The path to the file.
@export
var path := ""
## If defined, the [member path] with be executed according to this string. [br]
## [br]
## Format args are used like:
## [codeblock]
## "{path} --quiet"
## [/codeblock]
@export
var command := ""

## The amount of times this [code]Launchable[/code] has been used.
@export
var use_count: int = 0

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

## Check if the [code]Launchable[/code] is valid. Errors are returned in an
## [Array].
func check() -> Array[String]:
	var r: Array[String] = []
	
	if name.is_empty():
		r.push_back(LaunchableError.EMPTY_NAME)
	
	if not FileAccess.file_exists(path):
		r.push_back(LaunchableError.PATH_DOES_NOT_EXIST.format([path]))
	
	if not command.is_empty():
		if not command.contains("{{0}}".format([PATH_KEY])):
			r.push_back(LaunchableError.MISSING_FORMAT_KEY.format([PATH_KEY]))
	
	return r

## Get the formatted command from this [code]Launchable[/code]. If the command is not valid,
## an error code will be returned. Otherwise, the [String] command will be returned.
func to_command() -> Variant:
	if not check().is_empty():
		return ERR_INVALID_DATA
	
	return command.format({
		path = path
	})

## Create a [code]Launchable[/code] from a [Sublaunchable].
static func from_sublaunchable(sublaunchable: Sublaunchable) -> Launchable:
	var r := Launchable.new()
	
	r.name = sublaunchable.name
	r.description = sublaunchable.name
	r.path = sublaunchable.path
	r.command = sublaunchable.command
	
	return r
