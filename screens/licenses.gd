extends PopupInterface

const APP_LICENSE := "res://LICENSE"
const APP_LICENSE_NAME := "LICENSE_sometimes-youlaunch"
const LICENSE_DIR := "res://licenses"
const TREE_COL: int = 0
const ALL_ITEM := "All"

var _pages := {}

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _init() -> void:
	ready.connect(func() -> void:
		await get_tree().physics_frame
		await get_tree().physics_frame
		set("split_offset", get_viewport().size.x * 0.2)
	)

func _ready() -> void:
	var tree: Tree = %Tree
	var licenses := %Licenses
	
	var root := tree.create_item()
	tree.item_selected.connect(func() -> void:
		_show_page(tree.get_selected().get_text(TREE_COL))
	)
	var all_item: TreeItem = tree.create_item(root)
	all_item.set_text(TREE_COL, ALL_ITEM)
	
	var app_license := FileAccess.open(APP_LICENSE, FileAccess.READ)
	if app_license == null:
		printerr("Unable to read app license, this is a bug!")
		return
	
	var app_license_page := _create_page(tree, APP_LICENSE_NAME, app_license.get_as_text())
	if app_license_page == null:
		printerr("Unable to create app license page, this is a bug!")
		return
	
	_pages[APP_LICENSE_NAME] = app_license_page
	licenses.add_child(app_license_page)
	
	var dir := DirAccess.open(LICENSE_DIR)
	if dir == null:
		printerr("Unable to open {0}, this is a bug!".format([LICENSE_DIR]))
		return
	
	dir.list_dir_begin()
	
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if _pages.has(file_name):
			printerr("Found duplicate file for {0} somehow, skipping".format([file_name]))
			file_name = dir.get_next()
			continue
		
		var file_path := "{0}/{1}".format([LICENSE_DIR, file_name])
		var file := FileAccess.open(file_path, FileAccess.READ)
		if file == null:
			printerr("Unable to open license file at {0}, skipping".format([file_path]))
			file_name = dir.get_next()
			continue
		
		var page := _create_page(tree, file_name, file.get_as_text())
		if page == null:
			printerr("Unable to create page for {0}, this is a bug!".format([file_path]))
			file_name = dir.get_next()
			continue
		
		_pages[file_name] = page
		licenses.add_child(page)
		
		file_name = dir.get_next()
	
	if _pages.size() < 1:
		printerr("No license pages created, this is a bug!")
		return
	
	tree.set_selected(all_item, TREE_COL)

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

static func _create_page(tree: Tree, page_name: String, page_text: String) -> Control:
	var item: TreeItem = tree.create_item(tree.get_root())
	item.set_text(TREE_COL, page_name)
	
	var page := RichTextLabel.new()
	page.bbcode_enabled = true
	page.text = page_text
	page.name = page_name
	page.fit_content = true
	page.selection_enabled = true
	
	return page

func _show_page(text: String) -> void:
	if text == ALL_ITEM:
		for i in _pages.values():
			i.show()
	else:
		for i in _pages.values():
			i.hide()
		
		_pages[text].show()

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#
