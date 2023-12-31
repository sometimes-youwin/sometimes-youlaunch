extends PopupInterface

@onready
var app_info: ScrollContainer = %AppInfo
@onready
var _status: RichTextLabel = %Status

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	%Accept.pressed.connect(func() -> void:
		var r: Launchable = app_info.build()
		
		var errors := r.check()
		if not errors.is_empty():
			_status.clear()
			for i in errors:
				_status.append_text("{0}\n".format([i]))
			return
		
		finished.emit(r)
	)
	%Cancel.pressed.connect(func() -> void:
		finished.emit()
	)

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#
