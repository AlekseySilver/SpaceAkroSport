extends Area3D

@export var target: NPCTarget


func _on_area_entered(area: Area3D) -> void:
	var body := area as NPCBodyArea
	if body and target:
		body.switch2target(target)


