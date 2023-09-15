extends CanvasLayer

const AddDialogue: PackedScene = preload("res://screens/add_dialogue.tscn")

@onready
var _add: Button = %Add
@onready
var _stop_all: Button = %StopAll

const NAME_COL: int = 0
const LAUNCHABLES_TEXT := "Simple"
const SUBLAUNCHABLES_TEXT := "Composite"
@onready
var _tree: Tree = %Tree
var _launchables: TreeItem = null
var _sublaunchables: TreeItem = null
@onready
var _launch_info: PanelContainer = %LaunchInfo
var _pages := {}

var _metadata := Metadata.create()

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	$VBoxContainer/HSplitContainer.split_offset = get_viewport().size.x * 0.2
	
	var root := _tree.create_item()
	_launchables = _tree.create_item(root)
	_launchables.set_text(NAME_COL, LAUNCHABLES_TEXT)
	_sublaunchables = _tree.create_item(root)
	_sublaunchables.set_text(NAME_COL, SUBLAUNCHABLES_TEXT)
	
	for i in _metadata.launchables:
		_create_launchable(i)
	for i in _metadata.sublaunchables:
		_create_sublaunchable(i)
	
	_add.pressed.connect(func() -> void:
		var gui := AddDialogue.instantiate()
		gui.metadata = _metadata
		
		var popup := PopupWindow.new("Add App", gui)
		
		add_child(popup)
		popup.popup_centered_ratio(0.5)
		
		var data: Launchable = await popup.close_requested
		if data == null:
			return
		if not data is Launchable or not data is Sublaunchable:
			printerr("Received unexpected item from AddDialogue: {0}".format([data]))
			return
		
		if data is Sublaunchable:
			_metadata.sublaunchables.push_back(data)
			_create_sublaunchable(data)
		else:
			_metadata.launchables.push_back(data)
			_create_launchable(data)
	)

func _exit_tree() -> void:
	if _metadata.save() != OK:
		printerr("Unable to save metadata")

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

func _create_launchable(data: Launchable) -> void:
	var item := _tree.create_item(_launchables)
	item.set_text(NAME_COL, data.name)

func _create_sublaunchable(data: Sublaunchable) -> void:
	var item := _tree.create_item(_sublaunchables)
	item.set_text(NAME_COL, data.name)

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#
