extends CanvasLayer

const HOME_SCREEN := "res://screens/home.tscn"
const LOADABLES: Array[String] = [
	"res://assets/main.theme",
	HOME_SCREEN
]
var _loadables_size: int = LOADABLES.size()
var _in_progress: Array[String] = []
var _success: Array[String] = []
var _failure: Array[String] = []
var _progress_status: Array[float] = []

@onready
var _icon: TextureRect = %Icon
@onready
var _status: RichTextLabel = %Status
@onready
var _progress_bar: ProgressBar = %ProgressBar

const BLURBS: Array[String] = [
	"Loading resources",
	"[color=red]Fixing some bugs[/color]",
	"[wave]Watering the plants[/wave]",
	"[color=blue]Painting the sky blue[/color]",
	"[wave]Taking a quick nap[/wave]"
]

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _ready() -> void:
	var current_screen := DisplayServer.window_get_current_screen()
	var current_screen_size := DisplayServer.screen_get_size(current_screen)
	var new_window_size := current_screen_size * 0.75
	
	DisplayServer.window_set_size(new_window_size)
	DisplayServer.window_set_position((current_screen_size * 0.5) - (new_window_size * 0.5))
	# TODO August 1, 2023 Godot still moves the window to screen 1 instead of screen 0
	DisplayServer.window_set_current_screen(current_screen)
	
	_icon.pivot_offset = _icon.texture.get_size() / 2.0
	
	for i in LOADABLES:
		ResourceLoader.load_threaded_request(i)
		_in_progress.push_back(i)

func _process(delta: float) -> void:
	_icon.rotation += delta * 5.0
	
	var completed_amount: float = (_success.size() + _failure.size()) as float
	for i in _in_progress:
		match ResourceLoader.load_threaded_get_status(i, _progress_status):
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				completed_amount += _progress_status[0]
			ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				_update_load_amount(i, false)
			ResourceLoader.THREAD_LOAD_LOADED:
				_update_load_amount(i, true)
				
	
	_progress_bar.value = completed_amount / _loadables_size
	
	if _in_progress.is_empty():
		get_tree().change_scene_to_file(HOME_SCREEN)

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

func _update_load_amount(loadable: String, success: bool) -> void:
	_status.text = "[center]{0}[/center]".format([BLURBS.pick_random()])
	
	_in_progress.erase(loadable)
	if success:
		_success.push_back(loadable)
	else:
		printerr("Failed to preload {0}".format([loadable]))
		_failure.push_back(loadable)

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

