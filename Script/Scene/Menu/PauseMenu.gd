extends FloatingMenu


func _process(_delta: float) -> void:
	if visible and _is_floating == false and (Input.is_action_just_pressed("start") or Input.is_action_just_pressed("ui_cancel")):
		_on_btn_play_pressed()


func _tween_finished():
	super()
	if visible and AppConfig.control_type_id != 2:
		$btnPlay.grab_focus()


func _on_btn_play_pressed() -> void:
	dialog_result = 0
	close_dialog()


func _on_btn_restart_pressed() -> void:
	dialog_result = 1
	close_dialog()


func _on_btn_quit_pressed() -> void:
	dialog_result = 2
	close_dialog()

