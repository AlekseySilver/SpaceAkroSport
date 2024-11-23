extends Node


const PERSONS = ["res://Person/Sophie.tscn", "res://Person/Adam.tscn", "res://Person/Timmy.tscn"
			, "res://Person/BigVegas.tscn", "res://Person/Mutant.tscn", "res://Person/Ortiz.tscn"]



#var current_person_name: String = "res://Person/Sophie.tscn"
var current_person_name: String = "res://Person/Adam.tscn"
#var current_person_name: String = "res://Person/Timmy.tscn"
#var current_person_name: String = "res://Person/BigVegas.tscn"
#var current_person_name: String = "res://Person/Mutant.tscn"
#var current_person_name: String = "res://Person/Ortiz.tscn"

var current_play_mode := 1 # 0 - free play, 1 - race


var scene_stack: Array[String]

func push_prev_scene(scene_name: String) -> void:
	scene_stack.push_back(scene_name)

func pop_prev_scene() -> String:
	return scene_stack.pop_back() if len(scene_stack) else ""


func random_person_name(exclude: String) -> String:
	var person_id := randi() % len(PERSONS)
	var person_name: String = PERSONS[person_id]
	if person_name == exclude:
		person_id += 1
		if person_id >= len(PERSONS):
			person_id = 0
		person_name = PERSONS[person_id]
	return person_name


