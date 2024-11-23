@tool
extends StaticBody3D


func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		Xts25D.create_convex_collision(self)


