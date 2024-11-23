extends Node3D

var first_entered_person: Person = null

func finished() -> Signal:
	return $Area.body_entered


func _on_area_body_entered(body: Node3D) -> void:
	if not first_entered_person:
		while body and not first_entered_person:
			body = body.get_parent()
			first_entered_person = body as Person

