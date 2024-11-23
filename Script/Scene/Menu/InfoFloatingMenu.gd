extends FloatingMenu

func _ready() -> void:
	if AppConfig.control_type_id != 2:
		$btnContinue.grab_focus()


func _on_btn_continue_pressed() -> void:
	float_out()



