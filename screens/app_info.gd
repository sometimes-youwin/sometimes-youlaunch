class_name AppInfo
extends ScrollContainer

const LAUNCHABLE_TYPE := {
	SIMPLE = "Simple",
	COMPOSITE = "Composite"
}

@onready
var _launchable_name: LineEdit = %Name
var launchable_name: String :
	get:
		return _launchable_name.text
	set(v):
		_launchable_name.text = v
@onready
var _description: TextEdit = %Description
var description: String :
	get:
		return _description.text
	set(v):
		_description.text = v

@onready
var _path_input: LineEdit = %PathInput
@onready
var _path_button: Button = %PathButton
var path: String :
	get:
		return _path_input.text
	set(v):
		_path_input.text = v

@onready
var _launchable_type: OptionButton = %LaunchableType
@onready
var _launchable_type_description: RichTextLabel = %LaunchableTypeDescription
var launchable_type: String :
	get:
		return _launchable_type.get_item_text(_launchable_type.get_item_index(_launchable_type.get_selected_id()))
	set(v):
		for i in _launchable_type.item_count:
			if _launchable_type.get_item_text(i) == v:
				_launchable_type.get_popup().index_pressed.emit(i)
				break

@onready
var _sublauncher_container: HBoxContainer = %SublauncherContainer
@onready
var _sublauncher: OptionButton = %Sublauncher
var sublaunchable: Launchable = null :
	get:
		return sublaunchable
	set(v):
		sublaunchable = v
		for i in _sublauncher.item_count:
			if _sublauncher.get_item_text(i) == v.name:
				_sublauncher.select(i)
				break

@onready
var _command: LineEdit = %Command
var command: String :
	get:
		return _command.text
	set(v):
		_command.text = v

var default_search_path := ""

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	_path_button.pressed.connect(func() -> void:
		var fd := FileDialogUtil.create_file_dialog(
			FileDialog.FILE_MODE_OPEN_FILE, default_search_path)
		
		add_child(fd)
		fd.popup_centered_ratio()
		
		var path = await fd.close_requested
		if not path is String:
			return
		
		_launchable_name.text = path.get_file()
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

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

## Initialize all fields from a given [Launchable] or [Sublaunchable].
func init_from_launchable(launchable: Launchable) -> void:
	launchable_name = launchable.name
	description = launchable.description
	path = launchable.path
	command = launchable.command
	if launchable is Sublaunchable:
		sublaunchable = launchable.launchable
		launchable_type = AppInfo.LAUNCHABLE_TYPE.COMPOSITE

## Initialize the launchables drop down with information from the [Metadata].
func init_from_metadata(metadata: Metadata) -> void:
	default_search_path = metadata.default_search_path
	
	for i in metadata.launchables:
		_sublauncher.add_item(i.name)
	if _sublauncher.item_count < 1:
		_sublauncher.add_item("No launchers available")
	var sublauncher_popup := _sublauncher.get_popup()
	sublauncher_popup.index_pressed.connect(func(idx: int) -> void:
		if metadata.launchables.size() > 0:
			sublaunchable = metadata.launchables[idx]
	)
	_sublauncher.select(0)
	sublauncher_popup.index_pressed.emit(0)

## Enable or disable editing of fields.
func set_editable(state: bool) -> void:
	_launchable_name.editable = state
	
	_description.editable = state
	
	_path_input.editable = state
	_path_button.disabled = not state
	
	_launchable_type.disabled = not state
	
	_sublauncher.disabled = not state
	
	_command.editable = state

## Build a [Launchable] or [Sublaunchable] from fields.
func build() -> Launchable:
	var r: Launchable = null
	
	match launchable_type:
		LAUNCHABLE_TYPE.SIMPLE:
			r = Launchable.new()
		LAUNCHABLE_TYPE.COMPOSITE:
			r = Sublaunchable.new()
			r.launchable = sublaunchable
		
	r.name = launchable_name
	r.description = description
	r.path = path
	r.command = command
	
	return r
