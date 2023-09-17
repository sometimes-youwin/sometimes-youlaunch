extends VBoxContainer

## Start button pressed.
signal started(data: Launchable)
## Data edited successfully.
signal saved(data: Launchable)
## Delete button pressed.
signal deleted(data: Launchable)

const EDIT_TEXT := "Edit"
const SAVE_TEXT := "Save"

const DELETE_TEXT := "Delete"
const CONFIRM_TEXT := "Confirm"
var _delete_confirmed := false

@onready
var _edit_button: Button = %Edit
@onready
var _cancel_button: Button = %Cancel
@onready
var _delete_button: Button = %Delete

@onready
var _status: RichTextLabel = %Status
@onready
var app_info: ScrollContainer = %AppInfo
@onready
var last_used: RichTextLabel = %LastUsed
@onready
var times_used: RichTextLabel = %TimesUsed

var _is_editing := false :
	set(v):
		_is_editing = v
		app_info.set_editable(_is_editing)
		if _is_editing: # Edit pressed
			_edit_button.text = SAVE_TEXT
			_cancel_button.show()
			_status.show()
		else: # Save pressed
			_edit_button.text = EDIT_TEXT
			_cancel_button.hide()
			_status.hide()

## Needed in order to rollback changes when cancelling an edit.
var _before_state: Launchable = null

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	%Start.pressed.connect(func() -> void:
		started.emit(app_info.build())
	)
	_cancel_button.pressed.connect(func() -> void:
		_is_editing = false
		
		if _before_state != null:
			app_info.init_from_launchable(_before_state)
		_before_state = null
	)
	_edit_button.pressed.connect(func() -> void:
		_is_editing = not _is_editing
		if _is_editing: # Edit pressed
			_before_state = app_info.build()
		else: # Save pressed
			saved.emit(app_info.build())
			_before_state = null
	)
	_delete_button.pressed.connect(func() -> void:
		if not _delete_confirmed:
			_delete_confirmed = true
			_delete_button.text = CONFIRM_TEXT
		else:
			deleted.emit(app_info.build())
	)
	_delete_button.mouse_exited.connect(func() -> void:
		_delete_confirmed = false
		_delete_button.text = DELETE_TEXT
	)
	visibility_changed.connect(func() -> void:
		if not visible:
			_cancel_button.pressed.emit()
	)
	
	app_info.set_editable(false)
	_status.hide()
	_cancel_button.hide()

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#
