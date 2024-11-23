class_name GrabManager extends Node

@export var left_grab: Node3D
@export var right_grab: Node3D

@export var side_offset: float = 1.0
@export var grab_inv_speed: float = 0.1
@export var max_grab_dist_sq: float = 10.0

var grabbed_body: PhysicsBody3D = null
var grab_count: int = 0

var _left: PersonBody = null
var _right: PersonBody = null

var _smooth_tween: Array[Tween] = [null, null]
var _joints: Array[RID] = [RID(), RID()]

@onready var _tree: SceneTree = get_tree()

func _ready() -> void:
	if left_grab:
		_left = left_grab.get_parent()
	if right_grab:
		_right = right_grab.get_parent()

	var tmp := _tree.create_tween()
	tmp.kill()
	for id in 2:
		_smooth_tween[id] = tmp


func start_tween(id: int) -> Tween:
	_smooth_tween[id].kill()
	_smooth_tween[id] = _tree.create_tween()
	return _smooth_tween[id]


func _grab_by_hand(property: String, body: PersonBody, grab_pos: Node3D, id: int, offset: Vector3) -> void:
	PhysicsServer3D.body_add_collision_exception(body.get_rid(), grabbed_body.get_rid())

	var inv := grabbed_body.global_transform.affine_inverse()
	var source_b: Vector3 = inv * grab_pos.global_position

	_joints[id] = PhysicsServer3D.joint_create()
	PhysicsServer3D.joint_make_pin(_joints[id], body.get_rid(), grab_pos.position, grabbed_body.get_rid(), source_b)
	
	# smooth move to bar
	start_tween(id).tween_property(self, property, offset, source_b.length() * grab_inv_speed)



func grab_first_hand(object: PhysicsBody3D) -> bool:
	var gpos := object.global_position
	var l_dist_sq: float
	var r_dist_sq: float

	if left_grab:
		l_dist_sq = (gpos - left_grab.global_position).length_squared()
	else:
		l_dist_sq = 999999.0

	if right_grab:
		r_dist_sq = (gpos - right_grab.global_position).length_squared()
	else:
		r_dist_sq = 999999.0

	var min_sq = minf(l_dist_sq, r_dist_sq)
	if min_sq > max_grab_dist_sq:
		return false

	release_grab()
	grabbed_body = object

	#var offset := Vector3(0.0, 0.0, -side_offset)
	if l_dist_sq < r_dist_sq:
		_grab_by_hand("l_local_b", _left, left_grab, 0, Vector3.ZERO)
	else:
		_grab_by_hand("r_local_b", _right, right_grab, 1, Vector3.ZERO)

	grab_count = 1
	return true


func grab_second_hand(body_xform: Transform3D) -> bool:
	var body2bar := (grabbed_body.global_position - body_xform.origin).normalized()
	var bb := body_xform.basis
	if body2bar.dot(bb.z) < 0.1 or body2bar.dot(bb.y) < 0.5:
	#if body2bar.dot(bb.y) < 0.5:
		return false

	var offset := Vector3(0.0, 0.0, side_offset)
	if _joints[1].is_valid():
		if bb.x.z < 0.0:
			offset = -offset
		_grab_by_hand("l_local_b", _left, left_grab, 0, offset)
		r_local_b = -offset
	else:
		if bb.x.z > 0.0:
			offset = -offset
		_grab_by_hand("r_local_b", _right, right_grab, 1, offset)
		l_local_b = -offset

	grab_count = 2

	return true



func release_grab() -> void:
	if grabbed_body:
		for tween in _smooth_tween:
			tween.kill()

		var gbrid := grabbed_body.get_rid()
		if _left:
			PhysicsServer3D.body_remove_collision_exception(_left.get_rid(), gbrid)
		if _right:
			PhysicsServer3D.body_remove_collision_exception(_right.get_rid(), gbrid)

		for id in 2:
			if _joints[id].is_valid():
				PhysicsServer3D.free_rid(_joints[id])
				_joints[id] = RID()

		grabbed_body = null
	grab_count = 0


func is_grabbed() -> bool:
	return grab_count > 0



var l_local_b: Vector3: get = get_l_local_b, set = set_l_local_b

func get_l_local_b() -> Vector3:
	return PhysicsServer3D.pin_joint_get_local_b(_joints[0])

func set_l_local_b(value: Vector3) -> void:
	PhysicsServer3D.pin_joint_set_local_b(_joints[0], value)


var r_local_b: Vector3: get = get_r_local_b, set = set_r_local_b

func get_r_local_b() -> Vector3:
	return PhysicsServer3D.pin_joint_get_local_b(_joints[1])

func set_r_local_b(value: Vector3) -> void:
	PhysicsServer3D.pin_joint_set_local_b(_joints[1], value)



