#@tool
extends Node3D
#class_name Person

@export var test_flag: bool: set = _test_flag

@export var IMPULSE_AIR := 200.0
@export var IMPULSE_GROUND := 100.0
@export var MAX_HORIZONTAL_SPEED := 10.0
@export var MAX_VERTICAL_SPEED := 10.0
@export var POSE_COOLDOWN: float = 0.5
@export var IMPULSE_POSITION := Vector3(0.0, 0.5, 0.0)
@export var IN_AIR_DIRECTION_DEAD_ZONE: float = 1.5


const TWEEN_DURATION = 0.7
const TWEEN_TRANS = Tween.TRANS_QUINT
const TWEEN_EASE = Tween.EASE_IN_OUT


@onready var _skel: Skeleton3D = $Body/Skeleton3D

@onready var _body: PersonBody = $Body
@onready var _head: PersonBody = $Head
@onready var _rthigh0: PersonBody = $RThigh0
@onready var _lthigh0: PersonBody = $LThigh0
@onready var _rthigh1: PersonBody = $RThigh1
@onready var _lthigh1: PersonBody = $LThigh1
@onready var _rcalf: PersonBody = $RCalf
@onready var _lcalf: PersonBody = $LCalf
@onready var _ruarm0: PersonBody = $RUArm0
@onready var _luarm0: PersonBody = $LUArm0
@onready var _ruarm1: PersonBody = $RUArm1
@onready var _luarm1: PersonBody = $LUArm1
@onready var _rfarm: PersonBody = $RFArm
@onready var _lfarm: PersonBody = $LFArm

@onready var _ctrl_body: ControlPoint = $Body/ControlPoint
@onready var _ctrl_rcalf: ControlPoint = $RCalf/ControlPoint
@onready var _ctrl_lcalf: ControlPoint = $LCalf/ControlPoint
@onready var _ctrl_rfarm: ControlPoint = $RFArm/ControlPoint
@onready var _ctrl_lfarm: ControlPoint = $LFArm/ControlPoint

@onready var _poses: PersonPoses = $Poses


var bones: Array[PersonBody]
var bones_priority: Array[PersonBody]
var controls: Array[ControlPoint]


var _is_mouse_down: bool
var _mouse_position: Vector2
var _drag_start_position: Vector2
var _selected_control: ControlPoint
var _pose_cooldown: float = -1.0
var _current_pose_id := -1

var has_ground_contact := false
var ground_normal: Vector3
var ground_position: Vector3

var _max_air_y: float # max height in air
var _air_x_dir: float # direction in air


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#_poses.init(self)

	_body.add_collision_exception_with(_rthigh1)
	_body.add_collision_exception_with(_lthigh1)
	_body.add_collision_exception_with(_ruarm1)
	_body.add_collision_exception_with(_luarm1)
	_head.add_collision_exception_with(_ruarm1)
	_head.add_collision_exception_with(_luarm1)

	bones.append_array([_body, _head, _rthigh0, _lthigh0, _rthigh1, _lthigh1, _rcalf, _lcalf, _ruarm0, _luarm0, _ruarm1, _luarm1, _rfarm, _lfarm])
	bones_priority.append_array(bones)
	controls.append_array([_ctrl_body, _ctrl_rcalf, _ctrl_lcalf, _ctrl_rfarm, _ctrl_lfarm])

	for i in _skel.get_bone_count():
		for bone in bones:
			if bone.skel_bone_name == _skel.get_bone_name(i):
				bone.skel_bone_id = i
				bone.skel_bone_parent = _skel.get_bone_parent(i)
				break

	# parent rotation offsets
	for bone in bones:
		if bone.skel_bone_id == -1:
			continue
		var cgr := _skel.global_transform.basis * _skel.get_bone_global_pose(bone.skel_bone_id).basis
		bone.rbody2skbone_offset = Xts.term_second(cgr, bone.get_rbody_basis())



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# update skeleton bone rotations
	for bone in bones:
		if bone.skel_bone_parent >= 0:
			var pgr := _skel.global_transform.basis * _skel.get_bone_global_pose(bone.skel_bone_parent).basis
			var cgr := bone.get_rbody_basis() * bone.rbody2skbone_offset
			var cr := Xts.term_second(cgr, pgr)
			_skel.set_bone_pose_rotation(bone.skel_bone_id, cr.get_rotation_quaternion())

	# input
	if Input.is_action_just_pressed("relax"):
		relax()
	if Input.is_action_just_pressed("freeze"):
		freeze()

	if _pose_cooldown < 0:
		if Input.is_action_pressed("pose1"):
			goto_pose(0)
		elif Input.is_action_pressed("pose2"):
			goto_pose(1)
		elif Input.is_action_pressed("pose3"):
			goto_pose(2)
		elif Input.is_action_pressed("pose4"):
			goto_pose(3)
		else:
			relax()


func bone_comparition(a: PersonBody, b: PersonBody) -> bool:
	if a.has_ground_contact == b.has_ground_contact:
		if a.has_ground_contact: # 2 bones have ground contact
			return a.ground_position.y > b.ground_position.y # bone with higher y contact will be first
		else: # 2 bone no ground contact
			return a.global_position.y > b.global_position.y # bone with higher y pos will be first
	return b.has_ground_contact # bone with ground contact will be second

func _physics_process(delta: float) -> void:
	# new ground contact
	var new_has_ground_contact := false
	var y := -1.1
	for bone in bones:
		if bone.has_ground_contact:
			new_has_ground_contact = true
			if bone.ground_normal.y > y:
				ground_position = bone.ground_position
				ground_normal = bone.ground_normal
				y = ground_normal.y

	# ground/air
	if has_ground_contact != new_has_ground_contact:
		has_ground_contact = new_has_ground_contact
		if has_ground_contact:
			_max_air_y = _body.position.y
			_air_x_dir = 0.0
		else:
			if ground_normal.x > Xts.SIN45:
				_air_x_dir = 1.0
			elif ground_normal.x < -Xts.SIN45:
				_air_x_dir = -1.0
			elif _body.linear_velocity.x > IN_AIR_DIRECTION_DEAD_ZONE:
				_air_x_dir = 1.0
			elif _body.linear_velocity.x < -IN_AIR_DIRECTION_DEAD_ZONE:
				_air_x_dir = -1.0
			else:
				_air_x_dir = 0.0

	var is_in_air := not has_ground_contact

	# max air
	if is_in_air:
		if _max_air_y < _body.position.y:
			_max_air_y = _body.position.y

	# collision_priority
	bones_priority.sort_custom(bone_comparition)
	var priority := 1
	for bone in bones_priority:
		priority += 1
		bone.collision_priority = priority

	# impulse
	var impulse := Vector3.ZERO
	impulse.x = Input.get_axis("move_left", "move_right") * (IMPULSE_GROUND if has_ground_contact else IMPULSE_AIR)

	if _pose_cooldown >= 0.0:
		_pose_cooldown -= delta
		if has_ground_contact:
			impulse += (ground_normal + Vector3.UP) * IMPULSE_AIR #Vector3(0.0, IMPULSE, 0.0)

	if impulse != Vector3.ZERO:
		if signf(impulse.x) * _body.linear_velocity.x > MAX_HORIZONTAL_SPEED:
			impulse.x = 0.0
		elif (is_in_air
				and impulse.x * _air_x_dir < 0.0
				and _body.linear_velocity.x * _air_x_dir < 0.0
			): # in air can turn in opposite side
				impulse.x = 0.0

		if _body.linear_velocity.y > MAX_VERTICAL_SPEED:
			impulse.y = 0.0

		_body.apply_force(impulse, IMPULSE_POSITION)


func relax() -> void:
	if _current_pose_id == -1:
		return
	_current_pose_id = -1
	for bone in bones:
		bone.relax()


func freeze() -> void:
	_current_pose_id = -2
	for bone in bones:
		bone.freeze()

func goto_pose(pose_id: int) -> void:
	if _current_pose_id == pose_id:
		return
	_current_pose_id = pose_id
	_pose_cooldown = POSE_COOLDOWN
	_poses.goto_pose(pose_id)


func control_show() -> Signal:
	var bg := _body.global_position + Vector3(0.0, 0.0, 10.0)
	var duration := Engine.time_scale * TWEEN_DURATION
	var tween := get_tree().create_tween()
	for ctrl in controls:
		ctrl.show_prepare(bg, tween, duration)

	return tween.finished

func control_hide() -> Signal:
	var bg := _body.global_position + Vector3(0.0, 0.0, 10.0)
	var duration := Engine.time_scale * TWEEN_DURATION
	var tween := get_tree().create_tween()
	for ctrl in controls:
		ctrl.hide_prepare(bg, tween, duration)

	tween.tween_callback(control_apply).set_delay(duration)
	return tween.finished

func control_apply() -> void:
	for ctrl in controls:
		ctrl.apply_impulse()


func _input(event):
	if Engine.time_scale >= 1.0:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_mouse_position = event.position
			_is_mouse_down = event.pressed
			if _is_mouse_down:
				_drag_start_position = event.position
				on_drag_start()
			else:
				on_drag_finish()
		
	elif event is InputEventMouseMotion:
		_mouse_position = event.position
		#print("_mouse_position: ", _mouse_position)
		if _is_mouse_down:
			on_drag_move()


func on_drag_start() -> void:
	var camera := get_viewport().get_camera_3d()
	var from := camera.project_ray_origin(_mouse_position)
	var dir := camera.project_ray_normal(_mouse_position)
	var to := dir * (camera.position.z * 2.0) + from

	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = 128 #CONTROL
	var result := space_state.intersect_ray(query)
	if result:
		_selected_control = result.collider as ControlPoint
		#if _selected_control:
		#	print(_selected_control.get_parent().name)

func on_drag_move() -> void:
	if _selected_control:
		var camera := get_viewport().get_camera_3d()
		var from := camera.project_ray_origin(_mouse_position)
		var dir := camera.project_ray_normal(_mouse_position)
		var h := -camera.position.z / dir.z
		var to := dir * h + from
		_selected_control.show_arrow(to)
		#print("from", from, " dir=", dir, " to=", to, " h=", h)

func on_drag_finish() -> void:
	if _selected_control:
		_selected_control = null






func debug_print() -> void:
	var ru := $RUArm1
	print(ru.name)
	var a: Vector3 = ru.get_rbody_basis().get_euler() * 180.0 / 3.14
	var b: Vector3 = _skel.get_bone_pose_rotation(ru.skel_bone_id).get_euler() * 180.0 / 3.14
	print(a - b)



func bone_global_transform(bone_id: int) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var i := bone_id
	while i >= 0:
		xf = _skel.get_bone_pose(i) * xf
		i = _skel.get_bone_parent(i)
	xf = _skel.global_transform * xf
	xf = Transform3D(xf.basis.orthonormalized(), xf.origin)
	return xf

func bone_global_position(bone_id: int) -> Vector3:
	return bone_global_transform(bone_id).origin


func get_debug_text() -> String:
	return "ground y{0}\nair max y{1}".format([ground_position.y, 0.0])



func _test_flag(_value: bool) -> void:
	pass

func _test_flag2(_value: bool) -> void:
	print(1)
	if _skel:
		for i in _skel.get_bone_count():
			#print(_skel.get_bone_name(i))
			match _skel.get_bone_name(i):
				"mixamorig7_Head":
					$J_Body_Head.global_position = bone_global_position(i)
				"mixamorig7_LeftShoulder":
					$J_Body_LUArm0.global_position = bone_global_position(i)
				"mixamorig7_LeftArm":
					$J_LUArm0_LUArm1.global_position = bone_global_position(i)
				"mixamorig7_LeftForeArm":
					$J_LUArm1_LFArm.global_position = bone_global_position(i)
				"mixamorig7_RightShoulder":
					$J_Body_RUArm0.global_position = bone_global_position(i)
				"mixamorig7_RightArm":
					$J_RUArm0_RUArm1.global_position = bone_global_position(i)
				"mixamorig7_RightForeArm":
					$J_RUArm1_RFArm.global_position = bone_global_position(i)
				"mixamorig7_LeftUpLeg":
					$J_LThigh0_LThigh1.global_position = bone_global_position(i)
				"mixamorig7_LeftLeg":
					$J_LThigh1_LCalf.global_position = bone_global_position(i)
				"mixamorig7_RightUpLeg":
					$J_RThigh0_RThigh1.global_position = bone_global_position(i)
				"mixamorig7_RightLeg":
					$J_RThigh1_RCalf.global_position = bone_global_position(i)
	print("_test_flag done")
# mixamorig7_Hips
# mixamorig7_Head
# 
# mixamorig7_LeftShoulder
# mixamorig7_LeftArm
# mixamorig7_LeftForeArm
# 
# mixamorig7_RightShoulder
# mixamorig7_RightArm
# mixamorig7_RightForeArm
# 
# mixamorig7_LeftUpLeg
# mixamorig7_LeftLeg
# 
# mixamorig7_RightUpLeg
# mixamorig7_RightLeg
# 
# #####################################
# 
# mixamorig7_Spine
# mixamorig7_Spine1
# mixamorig7_Spine2
# mixamorig7_Neck
# 
# mixamorig7_HeadTop_End
# 
# 
# mixamorig7_LeftHand
# 
# 
# mixamorig7_RightHand
# 
# mixamorig7_LeftFoot
# mixamorig7_LeftToeBase
# mixamorig7_LeftToe_End
# 
# mixamorig7_RightFoot
# mixamorig7_RightToeBase
# mixamorig7_RightToe_End