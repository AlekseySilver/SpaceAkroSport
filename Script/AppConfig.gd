extends Node

const CONFIG_FILE_NAME = "user://settings.cfg"

var config: ConfigFile

var control_type_id: int = 0 # 0 - keyboard, 1 - joy, 2 - touch
var gamepad_button_layout: int = 0
var graphics_show_shadows: int = 1
var touch_controls: Array[Vector3]

func _ready() -> void:
	config = ConfigFile.new()
	config.load(CONFIG_FILE_NAME)


	match OS.get_name():
		"Android", "iOS":
			control_type_id = 2
		_:
			control_type_id = config.get_value("main", "control_type_id", 0)


	gamepad_button_layout = config.get_value("main", "gamepad_button_layout", 0)

	var locale = config.get_value("main", "locale", "")
	if locale:
		TranslationServer.set_locale(locale)

	var tc = config.get_value("touch", "touch_controls", [])
	if tc:
		touch_controls.append_array(tc)

	graphics_show_shadows = config.get_value("graphics", "show_shadows", 1)

	# var file = FileAccess.open("res://data/level.json", FileAccess.READ)
	# levels_json = JSON.parse_string(file.get_as_text())
	# file.close()

	# current_level_id = config.get_value("main", "current_level_id", 0)
	# random_difficulty = config.get_value("main", "random_difficulty", 0)


func set_control_type_id(value: int) -> void:
	if control_type_id == value:
		return
	control_type_id = value



func save() -> void:
	config.set_value("main", "locale", TranslationServer.get_locale())
	config.set_value("main", "gamepad_button_layout", gamepad_button_layout)
	config.set_value("main", "control_type_id", control_type_id)
	config.set_value("touch", "touch_controls", touch_controls)
	config.save(CONFIG_FILE_NAME)


# func get_stars(level_id: int) -> int:
# 	var data: int = config.get_value("level", str(level_id), 0)
# 	return data

# func save_stars(level_id: int, star1: bool, star2: bool, star3: bool) -> void:
# 	var data := get_stars(level_id)
# 	var add := Xts.set_bit_to_int(0, 0, star1)
# 	add = Xts.set_bit_to_int(add, 1, star2)
# 	add = Xts.set_bit_to_int(add, 2, star3)
# 	data = data | add
# 	config.set_value("level", str(level_id), data)
# 	save()


# func get_current_level() -> Dictionary:
# 	return levels_json["level"][current_level_id]


# func get_level_count() -> int:
# 	return len(levels_json["level"])


# func select_next_level_id() -> bool:
# 	if current_level_id < 0:
# 		return true
# 	var next := current_level_id + 1
# 	if next < get_level_count():
# 		current_level_id = next
# 		return true
# 	return false


# func random_difficulty_add(value: int):
# 	if current_level_id < 0:
# 		random_difficulty = clamp(random_difficulty + value, 0, 20)
