extends PopupInterface

const LAUNCHABLE_TYPE := {
	SIMPLE = "Simple",
	COMPOSITE = "Composite"
}

@onready
var _name: LineEdit = %Name
@onready
var _description: TextEdit = %Description

@onready
var _path_input: LineEdit = %PathInput
@onready
var _path_button: Button = %PathButton

@onready
var _launchable_type: OptionButton = %LaunchableType
@onready
var _launchable_type_description: RichTextLabel = %LaunchableTypeDescription

@onready
var _sublauncher_container: HBoxContainer = %SublauncherContainer
@onready
var _sublauncher: OptionButton = %Sublauncher
var _sublaunchable: Sublaunchable = null

@onready
var _command: LineEdit = %Command

@onready
var _status: RichTextLabel = %Status

var metadata: Metadata = null

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	if metadata == null:
		printerr("Didn't set metadata, bailing out!")
		finished.emit()
		return
	
	_path_button.pressed.connect(func() -> void:
		var fd := FileDialog.new()
		fd.access = FileDialog.ACCESS_FILESYSTEM
		fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		
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
		
		add_child(fd)
		fd.popup_centered_ratio()
		
		var path = await fd.close_requested
		if not path is String:
			return
		
		_path_input.text = path
	)
	
	for val in LAUNCHABLE_TYPE.values():
		_launchable_type.add_item(val)
	var launchable_popup := _launchable_type.get_popup()
	launchable_popup.index_pressed.connect(func(idx: int) -> void:
		match launchable_popup.get_item_text(idx):
			LAUNCHABLE_TYPE.SIMPLE:
				_launchable_type_description.hide()
				_sublauncher_container.hide()
			LAUNCHABLE_TYPE.COMPOSITE:
				_launchable_type_description.show()
				_sublauncher_container.show()
			_:
				printerr("Unhandled launchable type {0}".format(
					[launchable_popup.get_item_text(idx)]))
	)
	_launchable_type.select(0)
	launchable_popup.index_pressed.emit(0)
	
	for i in metadata.launchables:
		_sublauncher.add_item(i.name)
	if _sublauncher.item_count < 1:
		_sublauncher.add_item("No launchers available")
	var sublauncher_popup := _sublauncher.get_popup()
	sublauncher_popup.index_pressed.connect(func(idx: int) -> void:
		if metadata.launchables.size() > 0:
			_sublaunchable = metadata.launchables[idx]
	)
	_sublauncher.select(0)
	sublauncher_popup.index_pressed.emit(0)
	
	%Accept.pressed.connect(func() -> void:
		var r: Launchable = null
		match _sublauncher.get_item_text(_sublauncher.get_item_index(_sublauncher.get_selected_id())):
			LAUNCHABLE_TYPE.SIMPLE:
				r = Launchable.new()
			LAUNCHABLE_TYPE.COMPOSITE:
				r = Sublaunchable.new()
				r.launchable = _sublaunchable
		
		r.name = _name.text
		r.description = _description.text
		r.path = _path_input.text
		r.command = _command.text
		
		var errors := r.check()
		if not errors.is_empty():
			_status.clear()
			for i in errors:
				_status.append_text("{i}[br]")
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
