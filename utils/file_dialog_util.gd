class_name FileDialogUtil
extends RefCounted

## Utility for creating [FileDialog]s with an initial search path.

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

## Create a [FileDialog] with an optional [param current_dir]. If no [param current_dir]
## is passed, the user's home directory will be used instead.
static func create_file_dialog(file_mode: FileDialog.FileMode, current_dir: String = "") -> FileDialog:
	var fd := FileDialog.new()
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.file_mode = file_mode
	if current_dir.is_empty():
		match OS.get_name().to_lower():
			"windows", "uwp":
				fd.current_dir = "{0}{1}".format([
					OS.get_environment("HOMEDRIVE"), OS.get_environment("HOMEPATH")])
			"macos", "linux", "freebsd", "netbsd", "openbsd", "bsd":
				fd.current_dir = OS.get_environment("HOME")
	else:
		fd.current_dir = current_dir
	
	fd.close_requested.connect(func(text: String = "") -> void:
		fd.queue_free()
	)
	fd.visibility_changed.connect(func() -> void:
		if not fd.visible:
			fd.close_requested.emit()
	)
	fd.file_selected.connect(func(text: String) -> void:
		fd.close_requested.emit(text)
	)
	# Godot is a bit weird in that it pre-selects a directory instead of allowing for
	# current path
	fd.dir_selected.connect(func(_text: String) -> void:
		fd.close_requested.emit(fd.current_dir)
	)
	
	return fd
