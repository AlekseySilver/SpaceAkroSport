extends ColorRect

signal option_selected(id: int)

func _ready() -> void:
	for id in get_child_count():
		get_child(id).pressed.connect(_on_button_pressed.bind(id))
	
func _on_button_pressed(id: int) -> void:
	for i in get_child_count():
		get_child(i).button_pressed = i != id
	option_selected.emit(id)


