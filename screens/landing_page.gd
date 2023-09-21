extends VBoxContainer

const RunningApp: PackedScene = preload("res://screens/running_app.tscn")

@onready
var _running_apps: VBoxContainer = %RunningApps

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

## Add a new running app to be displayed.
func add_running_app(app_name: String, pid: int) -> void:
	var app := RunningApp.instantiate()
	_running_apps.add_child(app)
	
	app.app_name.text = app_name
	app.pid.text = str(pid)
	
	app.stopped.connect(func(pid: int) -> void:
		# Only bail out early if we cannot kill the PID and it's still running
		# If the PID was killed elsewhere, then just remove the item
		if OS.kill(pid) != OK and OS.is_process_running(pid):
			printerr("Unable to kill {0}:{1}".format([app_name, pid]))
			return
		app.queue_free()
	)

## Check all running apps to see if they are still running.
func refresh_running_status() -> void:
	for app in get_running_apps():
		var pid: int = app.pid.text.to_int()
		if not OS.is_process_running(pid):
			print_debug("{0} is no longer running, removing GUI item".format([pid]))
			app.queue_free()

## Get all running app nodes.
func get_running_apps() -> Array[Node]:
	return _running_apps.get_children()

## Kill all running apps.
func kill_all() -> void:
	for child in _running_apps.get_children():
		child.stopped.emit(child.pid.text.to_int())
