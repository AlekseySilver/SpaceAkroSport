extends BackMenu


@onready var kb_key_tex = preload("res://textures/kb_key.png")
@onready var joy_tex = preload("res://textures/gamepad/small_circle.png")

@onready var arr_buttons := [$UI/TabContainer/CONTROLS/Panel0/B0, $UI/TabContainer/CONTROLS/Panel0/B1, $UI/TabContainer/CONTROLS/Panel0/B2, $UI/TabContainer/CONTROLS/Panel0/B3]

@onready var dict_buttons := { 
					&"move_left": [$UI/TabContainer/CONTROLS/Panel2/btn0, $UI/TabContainer/CONTROLS/Panel2/btn1, $UI/TabContainer/CONTROLS/Panel2/btn2],
					&"move_right": [$UI/TabContainer/CONTROLS/Panel3/btn0, $UI/TabContainer/CONTROLS/Panel3/btn1, $UI/TabContainer/CONTROLS/Panel3/btn2],
					&"pose1": [$UI/TabContainer/CONTROLS/Panel4/btn0, $UI/TabContainer/CONTROLS/Panel4/btn1, $UI/TabContainer/CONTROLS/Panel4/btn2],
					&"pose2": [$UI/TabContainer/CONTROLS/Panel5/btn0, $UI/TabContainer/CONTROLS/Panel5/btn1, $UI/TabContainer/CONTROLS/Panel5/btn2],
					&"pose3": [$UI/TabContainer/CONTROLS/Panel6/btn0, $UI/TabContainer/CONTROLS/Panel6/btn1, $UI/TabContainer/CONTROLS/Panel6/btn2],
					&"pose4": [$UI/TabContainer/CONTROLS/Panel7/btn0, $UI/TabContainer/CONTROLS/Panel7/btn1, $UI/TabContainer/CONTROLS/Panel7/btn2],
					}


@onready var _tab_container := $UI/TabContainer
@onready var _show_shadows := $UI/TabContainer/GRAPHICS/ShowShadowsOpt


var waiting_action: StringName
var waiting_id: int = -1



func _ready() -> void:
	set_buttons_tex(AppConfig.gamepad_button_layout)
	draw_keymap()
	set_process_input(false)
	_show_shadows._on_button_pressed(AppConfig.graphics_show_shadows)
	_on_tabs_option_selected(0)
	super()



func _on_btn_back_pressed() -> void:
	$UI/TabContainer/TOUCH_CONTROLS.save()
	AppConfig.save()
	KeyPersistence.save_keymap()
	super()



func _on_tabs_option_selected(id: int) -> void:
	play_sound(AudioList.Clave)
	if id == 0:
		_tab_container.current_tab = 1 if AppConfig.control_type_id == 2 else 0
	else:
		_tab_container.current_tab = id + 1


func _on_btn_default_pressed() -> void:
	play_sound(AudioList.Clave)
	$UI/TabContainer/TOUCH_CONTROLS.set_defaults()
	KeyPersistence.set_default_keymap()
	draw_keymap()
	_show_shadows._on_button_pressed(1)


func set_buttons_tex(id: int) -> void:
	play_sound(AudioList.Clave)
	AppConfig.gamepad_button_layout = id
	for i in len(arr_buttons):
		arr_buttons[i].texture = load(KeyPersistence.get_joy_button_texture_path(id, i))
	draw_keymap()

func _on_btn_xbox_pressed() -> void:
	set_buttons_tex(0)

func _on_btn_play_station_pressed() -> void:
	set_buttons_tex(1)

func _on_btn_switch_pressed() -> void:
	set_buttons_tex(2)



func draw_keymap() -> void:
	for action in dict_buttons:
		var events: Array[InputEvent] = KeyPersistence.keymaps[action]
		for i in 3: #min(len(events), 3):
			var btn: Button = dict_buttons[action][i]
			btn.button_pressed = false
			btn.modulate = Color.WHITE
			if i < len(events):
				var event := events[i]
				btn.text = KeyPersistence.input_event_text(event)
				if event is InputEventKey:
					btn.get_child(0).texture = kb_key_tex
				elif event is InputEventJoypadButton:
					if Xts.is_between(event.button_index, 0, 3):
						btn.get_child(0).texture = arr_buttons[event.button_index].texture
					else:
						btn.get_child(0).texture = null
				elif event is InputEventJoypadMotion:
					btn.get_child(0).texture = joy_tex
				else:
					btn.get_child(0).texture = null
			else:
				btn.text = ""
				btn.get_child(0).texture = null


func _input(event: InputEvent) -> void:
	if waiting_id < 0:
		return

	var check_event: InputEvent = null

	if event is InputEventKey and event.keycode != KEY_ENTER and not event.pressed:
		check_event = InputEventKey.new()
		check_event.physical_keycode = event.keycode
	elif event is InputEventJoypadButton and event.button_index != 6 and not event.pressed:
		check_event = InputEventJoypadButton.new()
		check_event.button_index = event.button_index
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.5:
		check_event = InputEventJoypadMotion.new()
		check_event.axis = event.axis
		check_event.axis_value = signf(event.axis_value)

	if check_event:
		set_process_input(false)
		#print(event)
		var btn: Button = dict_buttons[waiting_action][waiting_id]

		var events: Array[InputEvent]

		# remove same event in other actions
		for action in KeyPersistence.keymaps:
			events = KeyPersistence.keymaps[action]
			for id in len(events):
				if action == waiting_action and id == waiting_id:
					continue
				var rem := false
				if events[id] is InputEventKey and check_event is InputEventKey:
					if events[id].physical_keycode == check_event.physical_keycode:
						rem = true
				elif events[id] is InputEventJoypadButton and check_event is InputEventJoypadButton:
					if events[id].button_index == check_event.button_index:
						rem = true
				elif events[id] is InputEventJoypadMotion and check_event is InputEventJoypadMotion:
					if events[id].axis == check_event.axis and events[id].axis_value == check_event.axis_value:
						rem = true
				if rem:
					events.remove_at(id)
					break

		# set new event
		events = KeyPersistence.keymaps[waiting_action]
		if len(events) < 3:
			events.push_back(check_event)
		else:
			events[waiting_id] = check_event

		waiting_id = -1
		draw_keymap()

		# Grab focus after assigning a key, so that you can go to the next key using the keyboard.
		await _tree.create_timer(0.5).timeout
		btn.grab_focus()


func _on_btn_bind_pressed(action: StringName, id: int) -> void:
	#print(action, id)
	var btn: Button = dict_buttons[action][id]
	btn.text = "<%s>" % tr("PRESS_A_KEY")
	btn.modulate = Color.YELLOW
	btn.release_focus()
	waiting_action = action
	waiting_id = id
	await _tree.create_timer(0.5).timeout
	set_process_input(true)


func _on_show_shadows_opt_option_selected(id:int) -> void:
	play_sound(AudioList.Clave)
	AppConfig.graphics_show_shadows = id

