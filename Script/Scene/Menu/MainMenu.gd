class_name MainMenu extends ScreenWithFader


func _ready():
	super()
	if AppConfig.control_type_id != 2:
		$UI/btnPlay.grab_focus()


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		AppConfig.set_control_type_id(0)
	elif event is InputEventJoypadButton:
		AppConfig.set_control_type_id(1)
	elif event is InputEventJoypadMotion:
		AppConfig.set_control_type_id(1)



func _on_btn_play_pressed():
	if is_closing:
		return
	play_sound(AudioList.Clave)
	change_scene(Scenes.PlayerSelectMenuPath, true)


func _on_btn_language_pressed() -> void:
	if is_closing:
		return
	play_sound(AudioList.Clave)
	var new_locale := "ru_RU" if TranslationServer.get_locale().left(2) == "en" else "en_US"
	TranslationServer.set_locale(new_locale)
	AppConfig.save()
	


func _on_btn_settings_pressed():
	if is_closing:
		return
	play_sound(AudioList.Clave)
	change_scene(Scenes.SettingsMenuPath, true)


func _on_btn_quit_pressed():
	if is_closing:
		return
	_tree.quit()
