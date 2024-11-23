class_name BackMenu extends ScreenWithFader


func _ready():
	super()
	if AppConfig.control_type_id != 2:
		$UI/btnBack.grab_focus()


func _on_btn_back_pressed() -> void:
	if is_closing:
		return
	play_sound(AudioList.Clave)
	var back2scene := Global.pop_prev_scene()
	if back2scene:
		change_scene(back2scene)


