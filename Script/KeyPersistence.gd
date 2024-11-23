# This is an autoload (singleton) which will save
# the key maps in a simple way through a dictionary.
extends Node


const keymaps_path := "user://keymaps.dat"
var keymaps := { 
				&"move_left": [],
				&"move_right": [],
				&"pose1": [],
				&"pose2": [],
				&"pose3": [],
				&"pose4": [],
				}



func _ready() -> void:
	# First we create the keymap dictionary on startup with all
	# the keymap actions we have.
	set_default_keymap()
	load_keymap()


func ekk(keycode: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = keycode
	return e

func ejb(button_index: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = button_index
	return e

func ejm(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	return e


func set_default_keymap() -> void:
	# for action in InputMap.get_actions():
	# 	if not InputMap.action_get_events(action).is_empty() and keymaps.has(action):
	# 		keymaps[action] = InputMap.action_get_events(action)

	#print(keymaps)

	keymaps = { &"move_left": [ekk(KEY_LEFT), ekk(KEY_A), ejm(JOY_AXIS_LEFT_X, -1.0), ejb(JOY_BUTTON_DPAD_LEFT)] as Array[InputEvent]
			, &"move_right": [ekk(KEY_RIGHT), ekk(KEY_D), ejm(JOY_AXIS_LEFT_X, 1.0), ejb(JOY_BUTTON_DPAD_RIGHT)] as Array[InputEvent]
			, &"pose1": [ekk(KEY_1), ekk(KEY_KP_1), ejb(JOY_BUTTON_A)] as Array[InputEvent]
			, &"pose2": [ekk(KEY_2), ekk(KEY_KP_2), ejb(JOY_BUTTON_X)] as Array[InputEvent]
			, &"pose3": [ekk(KEY_3), ekk(KEY_KP_3), ejb(JOY_BUTTON_B)] as Array[InputEvent]
			, &"pose4": [ekk(KEY_4), ekk(KEY_KP_4), ejb(JOY_BUTTON_Y)] as Array[InputEvent]
			}


func load_keymap() -> void:
	if not FileAccess.file_exists(keymaps_path):
		return

	var file := FileAccess.open(keymaps_path, FileAccess.READ)
	var temp_keymap: Dictionary = file.get_var(true)
	file.close()
	# We don't just replace the keymaps dictionary, because if you
	# updated your game and removed/added keymaps, the data of this
	# save file may have invalid actions. So we check one by one to
	# make sure that the keymap dictionary really has all current actions.
	for action: StringName in keymaps.keys():
		if temp_keymap.has(action):
			keymaps[action] = temp_keymap[action]
			# Whilst setting the keymap dictionary, we also set the
			# correct InputMap event.
			InputMap.action_erase_events(action)
			for event in keymaps[action]:
				InputMap.action_add_event(action, event)


func save_keymap() -> void:
	# For saving the keymap, we just save the entire dictionary as a var.
	var file := FileAccess.open(keymaps_path, FileAccess.WRITE)
	file.store_var(keymaps, true)
	file.close()



func input_event_text(event: InputEvent) -> String:
	if event is InputEventJoypadButton:
		if Xts.is_between(event.button_index, 0, 3):
			return "Joy %s" % event.button_index

	if event is InputEventJoypadMotion:
		match event.axis:
			JOY_AXIS_LEFT_X:
				return "LStick %s " % tr("RIGHT" if event.axis_value > 0.0 else "LEFT")
			JOY_AXIS_LEFT_Y:
				return "LStick %s " % tr("UP" if event.axis_value > 0.0 else "DOWN")
			JOY_AXIS_RIGHT_X:
				return "RStick %s " % tr("RIGHT" if event.axis_value > 0.0 else "LEFT")
			JOY_AXIS_RIGHT_Y:
				return "RStick %s " % tr("UP" if event.axis_value > 0.0 else "DOWN")
		return "%s joy axis %s" % ["+" if event.axis_value > 0.0 else "-", event.axis]

	var text := event.as_text()
	if text.begins_with("Joypad"):
		text = text.replace("Joypad Button ", "")
		text = text.replace("Joypad Motion on Axis ", "")
		text = text.split(",")[0]
	else:
		text = text.replace("(Physical)", "")
	return text


func get_joy_button_texture_path(layout: int, button: int):
	var text: String
	match layout:
		1:
			text = "PlayStation"
		2:
			text = "Switch"
		_:
			text = "Xbox"
	return "res://textures/gamepad/B%s_%s.png" % [button, text]
