extends BackMenu


@onready var _confirm := $UI/LevelConfirmMenu


func _ready() -> void:
	for child in $UI.get_children():
		if child.name.begins_with("Button"):
			child.pressed.connect(_on_button_level_pressed.bind(int(child.name.right(2))))
	
	super()
	if AppConfig.control_type_id != 2:
		$UI/Button01.grab_focus()


func _on_button_level_pressed(level_num: int) -> void:
	if is_closing:
		return
	play_sound(AudioList.Clave)

	_confirm.prepare_show(level_num)
	await _confirm.float_in()
	await _confirm.closed
	match _confirm.dialog_result:
		1: # train
			Global.current_play_mode = 0
			change_scene(Scenes.get_level_path(level_num))
		2: # race
			Global.current_play_mode = 1
			change_scene(Scenes.get_level_path(level_num))
		_: # cancel
			get_node("UI/Button%02d" % level_num).grab_focus()


