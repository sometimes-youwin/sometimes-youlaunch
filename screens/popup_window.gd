class_name PopupWindow
extends Window

const BG_COLOR := Color("1d2229")

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

func _init(window_name: StringName, gui: PopupInterface) -> void:
	gui.set("window", self)
	
	title = window_name
	
	var background := ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = BG_COLOR
	
	var panel_container := PanelContainer.new()
	panel_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel_container.theme = preload("res://assets/main.theme")
	
	panel_container.add_child(gui)
	add_child(panel_container)
	
	close_requested.connect(func(_data: Variant = null) -> void:
		queue_free()
	)
	visibility_changed.connect(func() -> void:
		if not visible:
			close_requested.emit()
	)
	gui.finished.connect(func(data: Variant = null) -> void:
		close_requested.emit(data)
	)

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#
