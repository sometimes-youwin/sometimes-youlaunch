extends PopupInterface

const HARD_RESET_TEXT := "Hard Reset"
const HARD_RESET_CONFIRM := "Confirm"

@onready
var _default_search_path_input: LineEdit = %DefaultSearchPathInput
@onready
var _default_search_path_button: Button = %DefaultSearchPathButton

var metadata: Metadata = null

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	var hard_reset: Button = %HardReset
	hard_reset.pressed.connect(func() -> void:
		if hard_reset.text == HARD_RESET_TEXT:
			hard_reset.text = HARD_RESET_CONFIRM
			hard_reset.modulate = Color.RED
		else:
			metadata.reset()
			metadata.save()
			finished.emit()
	)
	hard_reset.mouse_exited.connect(func() -> void:
		hard_reset.text = HARD_RESET_TEXT
		hard_reset.modulate = Color.WHITE
	)
	
	_default_search_path_input.text = metadata.default_search_path
	_default_search_path_input.text_changed.connect(func(text: String) -> void:
		metadata.default_search_path = text
	)
	_default_search_path_button.pressed.connect(func() -> void:
		var fd := FileDialogUtil.create_file_dialog(
			FileDialog.FILE_MODE_OPEN_DIR, metadata.default_search_path)
		
		add_child(fd)
		fd.popup_centered_ratio()
		
		var path: Variant = await fd.close_requested
		if not path is String:
			return
		
		_default_search_path_input.text = path
		_default_search_path_input.text_changed.emit(path)
	)

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

