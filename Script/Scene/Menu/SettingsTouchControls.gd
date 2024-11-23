extends Control

@onready var action_controls: Array[TouchActionControl] = [$Analog, $B0, $B1, $B2, $B3]


var _edit_control: TouchActionControl = null
var _edit_control_start_pos: Vector2
var _edit_control_start_size: Vector2
var _touch_start_pos: Vector2
var _touch2_start_pos: Vector2


func _ready() -> void:
	if AppConfig.touch_controls:
		# print(AppConfig.touch_controls)
		for i in min(len(AppConfig.touch_controls), len(action_controls)):
			var v := AppConfig.touch_controls[i]
			var control := action_controls[i]
			control.call_deferred("init_dim", v)
	else:
		call_deferred("set_defaults")



func __control_vector(control: TouchActionControl) -> Vector3:
	return Xts.XYA(control.position, control.size.x)


func save() -> void:
	AppConfig.touch_controls.clear()
	AppConfig.touch_controls.append_array(action_controls.map(__control_vector))


func set_defaults() -> void:
	for ctrl in action_controls:
		ctrl.offset_top = 0.0
		ctrl.offset_bottom = 0.0
		ctrl.offset_left = 0.0
		ctrl.offset_right = 0.0
		ctrl.update_circle()


func _input(event: InputEvent) -> void:
	# print(event)
	var touch_event := event as InputEventScreenTouch
	if touch_event:
		if touch_event.pressed:
			if _edit_control == null:
				for ctrl in action_controls:
					if ctrl.contains(touch_event.position):
						#print(ctrl.name)
						_edit_control = ctrl
						ctrl.touch_id = touch_event.index
						break

			if _edit_control:
				if _edit_control.touch_id == touch_event.index: #move
					_touch_start_pos = touch_event.position
					_edit_control_start_pos = _edit_control.position
					_edit_control_start_size = _edit_control.size
				else:
					_touch2_start_pos = touch_event.position

		elif _edit_control and _edit_control.touch_id == touch_event.index:
			_edit_control.update_circle()
			_edit_control = null

	elif _edit_control:
		var drag_event := event as InputEventScreenDrag
		if drag_event:
			if _edit_control.touch_id == drag_event.index: #move
				_edit_control.position = drag_event.position - _touch_start_pos + _edit_control_start_pos
			else: #scale with keep center
				var size_scale := (drag_event.position - _touch_start_pos).length() / (_touch_start_pos - _touch2_start_pos).length()
				var center = Xts.get_center(_edit_control)
				_edit_control.size = _edit_control_start_size * size_scale
				Xts.set_center(_edit_control, center)



