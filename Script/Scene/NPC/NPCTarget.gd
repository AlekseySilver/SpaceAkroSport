class_name NPCTarget extends Node3D

@export var next: NPCTarget

@export var slow_down_dist := 5.0


func check_reached(_person: Person) -> bool:
	return false

