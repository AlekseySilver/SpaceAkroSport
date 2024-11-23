extends Node3D

@onready var joint: JoltHingeJoint3D = $JoltHingeJoint3D


var _bodyA: RigidBody3D
var _bodyB: RigidBody3D

var _A2B_zero: Basis
var _local_axis_around_in_B: Vector3


func _ready():
	_bodyA = joint.get_node(joint.node_a)
	_bodyB = joint.get_node(joint.node_b)

	var A := _bodyA.global_transform.basis
	var B := _bodyB.global_transform.basis

	_A2B_zero = Xts.term_second(B, A)
	_local_axis_around_in_B = joint.global_transform.basis.z * B

	debug_print()

func _process(_delta):
	if Input.is_key_pressed(KEY_Q):
		debug_print()


func get_current_angle() -> float:
	var A := _bodyA.global_transform.basis
	var B := _bodyB.global_transform.basis

	# b = a + a2b
	# a2b = z + d
	# b = a + z + d
	#var A2B := Xts.term_second(B, A)
	#var delta := Xts.term_second(A2B, _A2B_zero)
	var delta := Xts.term_second(B, A * _A2B_zero)
	var q := delta.get_rotation_quaternion()
	#var axis_around_in_B := B * _local_axis_around_in_B
	var angle := q.get_angle()
	if q.get_axis().dot(_local_axis_around_in_B) > 0.0:
		angle = -angle
	return angle


func get_current_angle_deg() -> float:
	return rad_to_deg(get_current_angle())




func debug_print():
	print(get_current_angle_deg())
	print(_local_axis_around_in_B)



