extends FloatingMenu



func prepare_show(level_num) -> void:
	var lvl = Scenes.Levels[level_num - 1]
	$Title.text = lvl["name"]
	var train := $btnTrain
	var race := $btnRace
	var cancel := $btnCancel
	if lvl["can_race"]:
		train.focus_next = race.get_path()
		cancel.focus_previous = race.get_path()
		race.visible = true
	else:
		train.focus_next = cancel.get_path()
		cancel.focus_previous = train.get_path()
		race.visible = false
		
	train.focus_neighbor_bottom = train.focus_next
	cancel.focus_neighbor_top = cancel.focus_previous



func _tween_finished():
	super()
	if visible and AppConfig.control_type_id != 2:
		$btnTrain.grab_focus()



func _on_btn_train_pressed() -> void:
	dialog_result = 1
	close_dialog()


func _on_btn_race_pressed() -> void:
	dialog_result = 2
	close_dialog()


func _on_btn_cancel_pressed() -> void:
	dialog_result = 0
	close_dialog()

