class_name PlayTouchControls extends Control


@onready var arr_texs := [["B0_Xbox.png", "B0_PlayStation.png", "B0_Switch.png"]
							, ["B1_Xbox.png", "B1_PlayStation.png", "B1_Switch.png"]
							, ["B2_Xbox.png", "B2_PlayStation.png", "B2_Switch.png"]
							, ["B3_Xbox.png", "B3_PlayStation.png", "B3_Switch.png"]]

@onready var action_controls: Array[TouchActionControl] = [$Analog, $B0, $B1, $B2, $B3]



func _ready() -> void:
	set_buttons_tex(AppConfig.gamepad_button_layout)
	
	if AppConfig.touch_controls:
		for i in min(len(AppConfig.touch_controls), len(action_controls)):
			var v := AppConfig.touch_controls[i]
			var control := action_controls[i]
			control.call_deferred("init_dim", v)


func set_buttons_tex(id: int) -> void:
	for i in len(action_controls) - 1:
		action_controls[i + 1].texture = load("res://textures/gamepad/" + arr_texs[i][id])


func _input(event: InputEvent) -> void:
	var touch_event := event as InputEventScreenTouch
	if touch_event:
		if touch_event.pressed:
			for ctrl in action_controls:
				if ctrl.contains(touch_event.position):
					ctrl.start_touch(touch_event.index, touch_event.position)
					break


		else: # released
			for ctrl in action_controls:
				if ctrl.touch_id == touch_event.index:
					ctrl.stop_touch()
					break

	else:
		var drag_event := event as InputEventScreenDrag
		if drag_event:
			for ctrl in action_controls:
				if ctrl.touch_id == drag_event.index:
					ctrl.update_touch(drag_event.position)
					break
