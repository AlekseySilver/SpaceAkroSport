class_name BatutBody extends RigidBody3D

@export var skel_bone_name: StringName

var skel_bone_id := -1

var rbody2skbone_offset: Transform3D


func get_rbody_basis() -> Basis:
	return global_transform.basis

