extends BackMenu


@onready var _persons_root: Node3D = $Node3D/Persons
@onready var _btnSelect: Button = $UI/btnSelect


var _person_id := 0
var _tween: Tween


func _ready():
	_tween = _tree.create_tween()
	move_camera()
	super()
	if AppConfig.control_type_id != 2:
		$UI/btnNext.grab_focus()


func move_camera():
	_btnSelect.text = _persons_root.get_child(_person_id).name.to_upper()

	_tween.kill()
	_tween = _tree.create_tween()

	var pos := _persons_root.position
	pos.x = _person_id * -10.0
	_tween.tween_property(_persons_root, "position", pos, 0.5)


func _on_btn_prev_pressed() -> void:
	play_sound(AudioList.Clave)
	_person_id -= 1
	if _person_id < 0:
		_person_id = _persons_root.get_child_count() - 1
	move_camera()


func _on_btn_next_pressed() -> void:
	play_sound(AudioList.Clave)
	_person_id += 1
	if _person_id >= _persons_root.get_child_count():
		_person_id = 0
	move_camera()


func _on_btn_select_pressed() -> void:
	if is_closing:
		return
	play_sound(AudioList.Clave)
	Global.current_person_name = "res://Person/%s.tscn" % _persons_root.get_child(_person_id).name
	change_scene(Scenes.LevelSelectMenuPath, true)


