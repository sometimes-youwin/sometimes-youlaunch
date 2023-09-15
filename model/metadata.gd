class_name Metadata
extends Resource

const SAVE_PATH := "user://metadata.tres"

@export
var launchables: Array[Launchable] = []
@export
var sublaunchables: Array[Sublaunchable] = []

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

static func create() -> Metadata:
	var r: Resource = load(SAVE_PATH)
	if r == null or not r is Metadata:
		printerr("Unable to load metadata from {0}, creating new Metadata".format([SAVE_PATH]))
		r = Metadata.new()
	
	return r

func save() -> Error:
	return ResourceSaver.save(self, SAVE_PATH)
