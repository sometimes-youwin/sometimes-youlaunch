extends CanvasLayer

const AddDialogue: PackedScene = preload("res://screens/add_dialogue.tscn")
const LaunchInfo: PackedScene = preload("res://screens/launch_info.tscn")
const LandingPage: PackedScene = preload("res://screens/landing_page.tscn")
const Settings: PackedScene = preload("res://screens/settings.tscn")
const Licenses: PackedScene = preload("res://screens/licenses.tscn")

const LANDING_PAGE_NAME := "Home"
const NAME_COL: int = 0
@onready
var _tree: Tree = %Tree
@onready
var _page_container: ScrollContainer = %Pages
## Page names to page nodes.
var _pages := {}
## Page names to [TreeItem]s. Useful for deleting pages.
var _tree_items := {}
## The current displayed page.
var _current_page: Control = null

@onready
var _landing_page: VBoxContainer = %LandingPage

var _metadata := Metadata.create()

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	$VBoxContainer/HSplitContainer.split_offset = get_viewport().size.x * 0.2
	
	var root := _tree.create_item()
	_tree.item_selected.connect(func() -> void:
		_change_page(_tree.get_selected().get_text(NAME_COL))
	)
	var landing_page_item := _tree.create_item(root)
	landing_page_item.set_text(NAME_COL, LANDING_PAGE_NAME)
	_pages[LANDING_PAGE_NAME] = _landing_page
	_tree_items[LANDING_PAGE_NAME] = landing_page_item
	_tree.set_selected(landing_page_item, NAME_COL)
	
	for i in _metadata.launchables:
		_create_launchable_page(i)
	
	%Add.pressed.connect(func() -> void:
		var gui := AddDialogue.instantiate()
		var popup := PopupWindow.new("Add App", gui)
		
		add_child(popup)
		popup.popup_centered_ratio(0.5)
		gui.app_info.init_from_metadata(_metadata)
		
		var data: Launchable = await popup.close_requested
		if data == null:
			return
		if not data is Launchable and not data is Sublaunchable:
			printerr("Received unexpected item from AddDialogue: {0}".format([data]))
			return
		
		_metadata.launchables.push_back(data)
		_create_launchable_page(data)
	)
	%StopAll.pressed.connect(_landing_page.kill_all)
	%Licenses.pressed.connect(func() -> void:
		var gui := Licenses.instantiate()
		var popup := PopupWindow.new("Licenses", gui)
		
		add_child(popup)
		popup.popup_centered_ratio(0.5)
	)
	%Settings.pressed.connect(func() -> void:
		var gui := Settings.instantiate()
		gui.metadata = _metadata
		var popup := PopupWindow.new("Settings", gui)
		
		add_child(popup)
		popup.popup_centered_ratio(0.5)
		
		await popup.close_requested
		
		# Hard reset
		if _metadata.launchables.size() != _pages.size():
			get_tree().reload_current_scene()
	)

func _exit_tree() -> void:
	if _metadata.save() != OK:
		printerr("Unable to save metadata")

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

## Create a new page for a [Launchable].
func _create_launchable_page(data: Launchable) -> Control:
	var item := _tree.create_item(_tree.get_root())
	item.set_text(NAME_COL, data.name)
	
	var page := LaunchInfo.instantiate()
	var init_page := func(launchable: Launchable) -> void:
		page.last_used.text = launchable.readable_last_used_datetime()
		page.times_used.text = str(launchable.use_count)
	
	page.started.connect(_start)
	page.saved.connect(func(data: Launchable) -> void:
		_metadata.update_launchable(data)
		
		init_page.call(data)
	)
	page.deleted.connect(_delete)
	_page_container.add_child(page)
	
	init_page.call(data)
	
	var app_info: Control = page.app_info
	app_info.init_from_launchable(data)
	app_info.init_from_metadata(_metadata)
	
	_pages[data.name] = page
	_tree_items[data.name] = item
	page.hide()
	
	return page

func _remove_launchable_page(data: Launchable) -> Error:
	if not _tree_items.has(data.name):
		printerr("_tree_items does not have {0}".format([data.name]))
		return ERR_DOES_NOT_EXIST
	if not _pages.has(data.name):
		printerr("_pages does not have {0}".format([data.name]))
		return ERR_DOES_NOT_EXIST
	
	_tree_items[data.name].free()
	_tree_items.erase(data.name)
	
	_pages[data.name].queue_free()
	_pages.erase(data.name)
	
	return OK

## Change the current page to another page.
func _change_page(page_name: String) -> void:
	if _current_page != null:
		_current_page.hide()
	
	_current_page = _pages[page_name]
	_current_page.show()

## Start a given launchable.
func _start(data: Launchable) -> void:
	var found := _metadata.find_match(data)
	if found == null:
		printerr("No matching Launchable found for {0}".format([data.name]))
		return
	
	var command: Variant = found.to_command()
	if not command is String:
		printerr("Failed to get command for {0}".format([found.name]))
		return
	
	var split_command := Array(command.split(" "))
	var pid := OS.create_process(split_command.pop_front(), split_command)
	if pid < 0:
		printerr("Failed to start {0}".format([found.name]))
		return
	
	_landing_page.add_running_app(found.name, pid)
	
	found.timestamp()
	found.use_count += 1
	_metadata.update_launchable(found)
	
	if not _pages.has(found.name):
		printerr("_pages does not contain {0}, this is a bug!".format([found.name]))
		return
	var page: Control = _pages[found.name]
	page.last_used.text = found.readable_last_used_datetime()
	page.times_used.text = str(found.use_count)
	
	# We only need to change the tree item order. Pages are shown one at a time, so it
	# does not really matter if they are in order
	if not _tree_items.has(found.name):
		printerr("_tree_items does not contain {0}, this is a bug!".format([found.name]))
		return
	if not _tree_items.has(LANDING_PAGE_NAME):
		printerr("_tree_items does not contain {0}, this is a bug!".format([LANDING_PAGE_NAME]))
		return
	_tree_items[found.name].move_after(_tree_items[LANDING_PAGE_NAME])

## Delete a given launchable.
func _delete(data: Launchable) -> void:
	if _remove_launchable_page(data) != OK:
		printerr("Unable to remove page for {0}, aborting delete".format([data.name]))
		return
	
	var found := _metadata.find_match(data)
	if found == null:
		printerr("Unable to find match for Launchable {0}, aborting delete".format([data.name]))
		return
	
	_metadata.launchables.erase(found)
	
	_metadata.save()

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#
