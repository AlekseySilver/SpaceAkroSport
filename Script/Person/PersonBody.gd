class_name PersonBody extends RigidBody3D


@export var skel_bone_name: StringName
@export var parent: PersonBody
@export var joint: PersonJoint
@export_flags_3d_physics var GROUND_MASK: int = 1


var skel_bone_id := -1
var skel_bone_parent := -1
var rbody2skbone_offset: Basis


var has_ground_contact := false
var ground_normal: Vector3
var ground_position: Vector3
var ground_contact_object: PhysicsBody3D = null
var grab_contact_object: PhysicsBody3D = null



func relax() -> void:
	if joint:
		joint.relax()


func freeze() -> void:
	if joint:
		joint.freeze()


func start_limit(range_: float) -> void:
	if joint:
		joint.start_limit(range_)



func get_rbody_basis() -> Basis:
	return global_transform.basis


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	has_ground_contact = false
	ground_contact_object = null
	grab_contact_object = null
	if state.get_contact_count() > 0:
		var body = state.get_contact_collider_object(0) as PhysicsBody3D
		if body:
			if body.collision_layer & GROUND_MASK > 0:
				ground_normal = state.get_contact_local_normal(0)
				ground_position = state.get_contact_collider_position(0)
				ground_contact_object = body
				has_ground_contact = true
			elif body.collision_layer & 2 > 0:
				grab_contact_object = body



