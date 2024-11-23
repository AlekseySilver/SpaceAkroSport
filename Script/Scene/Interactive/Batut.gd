class_name Batut extends Node3D


@onready var bones: Array[BatutBody] = [$RigidBody3D1, $RigidBody3D2, $RigidBody3D3, $RigidBody3D4]
@onready var _skel: Skeleton3D = $Skeleton3D
@onready var _center: Node3D = $RigidBody3D2/Center

var _center_top: float

var rumple: float

func _ready() -> void:
	_center_top = _center.global_position.y

	# bones
	for i in _skel.get_bone_count():
		for bone in bones:
			if bone.skel_bone_name == _skel.get_bone_name(i):
				bone.skel_bone_id = i
				break

	# parent rotation offsets
	for bone in bones:
		if bone.skel_bone_id == -1:
			continue
		var cgr := _skel.global_transform * _skel.get_bone_global_pose(bone.skel_bone_id)
		var gb := bone.global_transform
		bone.rbody2skbone_offset = Transform3D(Xts.term_second(cgr.basis, gb.basis), cgr.origin - gb.origin)


func _process(_delta: float) -> void:
	# update skeleton bone rotations
	for bone in bones:
		var pgr := _skel.global_transform
		var cgr := bone.global_transform * bone.rbody2skbone_offset
		var cr := Xts.term_second(cgr.basis, pgr.basis)
		_skel.set_bone_pose_rotation(bone.skel_bone_id, cr.get_rotation_quaternion())
		_skel.set_bone_pose_position(bone.skel_bone_id, cgr.origin - pgr.origin)


	# rumple
	rumple = _center_top - _center.global_position.y