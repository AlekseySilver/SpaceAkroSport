class_name NPCTargetBar extends NPCTarget

var _bar: PhysicsBody3D


func _ready() -> void:
	_bar = get_parent()


func check_reached(person: Person) -> bool:
	return person._grab_manager.grabbed_body == _bar


