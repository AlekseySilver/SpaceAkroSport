class_name Person extends Node3D


@export var IMPULSE_AIR := 150.0
@export var IMPULSE_GROUND := 100.0
@export var IMPULSE_RELAX_GROUND := 25.0
@export var MAX_HORIZONTAL_SPEED := 9.0
@export var MAX_VERTICAL_SPEED := 9.0
@export var MAX_VERTICAL_BATUT_SPEED := 20.0

@export var POSE_COOLDOWN: float = 0.5
@export var ROLL_IMPULSE := 500.0
@export var ROLL_MAX_VEL := 9.0
@export var IN_AIR_DIRECTION_DEAD_ZONE: float = 5.0
@export var GRAB_COOLDOWN: float = 1.0

@export var OFFGRAB_IMPULSE := 5.0

@export var BODY_ALIGN_FORCE := 40.0

@export var STRAIGTH_POSE_IMPULSE := 1000.0

@export var GRAB_TO_BAR_FORCE := 5.0

@export var CAN_2_HAND_GRAB := true

@export var GROUND_COOLDOWN: float = 0.5

@export var IMPULSE_BATUT := 150.0
@export var BATUT_COOLDOWN_RATE := 0.2
@export var MIN_BATUT_COOLDOWN := 0.3
@export_flags_3d_physics var IMPULSE_MASK: int = 0
@export_flags_3d_physics var BATUT_MASK: int = 4


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


@onready var _poses: PersonPoses = $Poses

@onready var _anim: AnimationPlayer = $Body/AnimationPlayer

@onready var _grab_manager: GrabManager = $GrabManager


var bones: Array[PersonBody]
var bones_priority: Array[PersonBody]


var _pose_cooldown: float = -1.0
var _current_pose_id := -1

var has_ground_contact := false
var ground_normal: Vector3
var ground_position: Vector3
var ground_contact_object: PhysicsBody3D = null

var _max_air_y: float # max height in air
var _air_x_dir: float # direction in air

var _is_hand_on_ground := false
var _grab_cooldown: float = -1.0
var _is_in_air_off_bar := false
var _is_posing := false

var _ground_cooldown: float = -1.0


var controller: BaseController

var _batut: Batut = null
var _batut_rumple: float
var _batut_cooldown: float = -1.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_poses.init(self)

	_body.add_collision_exception_with(_rthigh1)
	_body.add_collision_exception_with(_lthigh1)
	_body.add_collision_exception_with(_ruarm1)
	_body.add_collision_exception_with(_luarm1)
	_head.add_collision_exception_with(_ruarm1)
	_head.add_collision_exception_with(_luarm1)

	bones.append_array([_body, _head, _rthigh0, _lthigh0, _rthigh1, _lthigh1, _rcalf, _lcalf, _ruarm0, _luarm0, _ruarm1, _luarm1, _rfarm, _lfarm])
	bones_priority.append_array(bones)

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
	# if Input.is_action_just_pressed("relax"):
	# 	relax()
	# if Input.is_action_just_pressed("freeze"):
	# 	freeze()

	_is_posing = false
	if controller and _pose_cooldown < 0:
		if controller.is_pose(0):
			if _grab_manager.grab_count != 1:
				if goto_pose(0):
					var by := _body.global_basis.y
					by *= STRAIGTH_POSE_IMPULSE if _body.angular_velocity.dot(by) > 0.0 else -STRAIGTH_POSE_IMPULSE
					_body.apply_torque_impulse(by)
			else: 
				rotate_body2bar()
		elif controller.is_pose(1):
			if _grab_manager.grab_count != 1:
				goto_pose(1)
			else: 
				rotate_body2bar()
		elif controller.is_pose(2):
			if _grab_manager.grab_count > 0:
				release_grab()
			else:
				goto_pose(2)
		elif controller.is_pose(3):
			if _grab_manager.grab_count > 0:
				release_grab()
			else:
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

# Vector2 force = gravity * mass + applied_force + constant_force;
# real_t torque = applied_torque + constant_torque;
# linear_velocity *= damp;
# angular_velocity *= angular_damp_new;
# linear_velocity += _inv_mass * force * p_step;
# angular_velocity += _inv_inertia * torque * p_step;
func _physics_process(delta: float) -> void:
	_body.constant_force = Vector3.ZERO
	_body.constant_torque = Vector3.ZERO

	if _ground_cooldown > 0.0:
		_ground_cooldown -= delta
	else:
		# new ground contact
		var new_has_ground_contact := false
		var y := -1.1
		for bone in bones:
			if bone.has_ground_contact:
				new_has_ground_contact = true
				if bone.ground_normal.y > y:
					ground_position = bone.ground_position
					ground_normal = bone.ground_normal
					ground_contact_object = bone.ground_contact_object
					y = ground_normal.y

		var new_is_hand_on_ground := _lfarm.has_ground_contact or _rfarm.has_ground_contact
		if _is_hand_on_ground != new_is_hand_on_ground:
			_is_hand_on_ground = new_is_hand_on_ground
			if _is_hand_on_ground:
				_anim.play("HandOnGround")
			else:
				_anim.play_backwards("HandOnGround")


		# ground/air
		if has_ground_contact != new_has_ground_contact:
			has_ground_contact = new_has_ground_contact
			if has_ground_contact:
				_max_air_y = _body.position.y
				_air_x_dir = 0.0
				_is_in_air_off_bar = false
				_ground_cooldown = GROUND_COOLDOWN
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

	var is_in_air := not has_ground_contact and _grab_manager.grab_count == 0

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
	var move_value := controller.axis_x() if controller else 0.0
	var impulse := Vector2(move_value, 0.0)
	if is_in_air:
		impulse.x *= IMPULSE_AIR
	elif _is_posing or _grab_manager.grab_count > 0:
		impulse.x *= IMPULSE_GROUND
	else:
		impulse.x *= IMPULSE_RELAX_GROUND

	var max_vert_speed := 0.0

	if _pose_cooldown >= 0.0:
		_pose_cooldown -= delta
		if has_ground_contact and (_current_pose_id == 0 or _current_pose_id == 3):
			impulse += Xts.XY(ground_normal) * IMPULSE_AIR
			impulse.y += IMPULSE_AIR
			#impulse += ground_normal * IMPULSE_AIR
			max_vert_speed = MAX_VERTICAL_SPEED


	# BATUT
	if _batut_cooldown > 0.0:
		_batut_cooldown -= delta
		if _batut_cooldown > 0.0:
			impulse.y += _batut_rumple * IMPULSE_BATUT
			max_vert_speed = MAX_VERTICAL_BATUT_SPEED
		else:
			_batut = null
	elif has_ground_contact and (ground_contact_object.collision_layer & 4) > 0:
		if _batut:
			var rumple := _batut.rumple
			if rumple > _batut_rumple:
				_batut_rumple = rumple
		else:
			_batut = ground_contact_object.get_parent() as Batut
			_batut_rumple = 0.0

		if _body.linear_velocity.y > 0.0:
			_batut_cooldown = _batut_rumple * BATUT_COOLDOWN_RATE + MIN_BATUT_COOLDOWN

		# var vel_y := _body.linear_velocity.y
		# if vel_y > 0.0:
		# 	impulse.y += (vel_y * vel_y + 1.0) * IMPULSE_BATUT
		# 	max_vert_speed = MAX_VERTICAL_BATUT_SPEED
	
	# _debug_str = "%s \n _batut_cooldown %s \n _batut_rumple %s" \
	# 			% [_batut != null, _batut_cooldown, _batut_rumple]




	if impulse != Vector2.ZERO:
		if signf(impulse.x) * _body.linear_velocity.x > MAX_HORIZONTAL_SPEED:
			impulse.x = 0.0
		elif (is_in_air
				and impulse.x * _air_x_dir < 0.0
				and _body.linear_velocity.x * _air_x_dir < 0.0
			): # in air can turn in opposite side
				impulse.x *= 0.5

		if max_vert_speed and delta:
			# from godot source:
			# Vector2 force = gravity * mass + applied_force + constant_force;
			# linear_velocity += _inv_mass * force * p_step;
			var add_vel_y := impulse.y * delta
			if _body.linear_velocity.y + add_vel_y > max_vert_speed:
				add_vel_y = max_vert_speed - _body.linear_velocity.y
				impulse.y = add_vel_y / delta
		# if _body.linear_velocity.y > max_vert_speed:
		# 	impulse.y = 0.0

		#_body.apply_force(impulse, Vector3.ZERO if _is_in_air_off_bar else IMPULSE_POSITION)
		_body.constant_force = Xts.XY0(impulse) # .apply_central_force(impulse)	
		if has_ground_contact and (ground_contact_object.collision_layer & IMPULSE_MASK) > 0:
			ground_contact_object.apply_force(-_body.constant_force, ground_position - ground_contact_object.global_position)

	# ROLL
	if _is_in_air_off_bar and move_value == 0.0:
		_is_in_air_off_bar = false
	if _grab_manager.grab_count == 0 and (not has_ground_contact or ground_normal.y > Xts.SIN45):
		var torque := move_value * -ROLL_IMPULSE
		if _is_in_air_off_bar:
			torque = -torque
		var roll_max_vel := ROLL_MAX_VEL
		if _current_pose_id != 1: # not grouped
			roll_max_vel *= 0.5

		# from godot source:
		# real_t torque = applied_torque + constant_torque;
		# angular_velocity += _inv_inertia * torque * p_step;
		var torque_dir := signf(torque)
		var add_vel_z := torque * torque_dir * delta
		# _debug_str = "\n torque_dir %s \n add_vel_z %s \n _body.inertia %s" % [torque_dir, add_vel_z, _body.inertia]
		if _body.angular_velocity.z * torque_dir + add_vel_z > roll_max_vel and delta:
			add_vel_z = roll_max_vel * torque_dir - _body.angular_velocity.z
			torque = add_vel_z / delta
		# _body.apply_torque(Vector3(0.0, 0.0, torque))
		_body.constant_torque = Vector3(0.0, 0.0, torque)

	# GRAB
	if _grab_cooldown >= 0.0:
		_grab_cooldown -= delta

	if _grab_manager.grab_count == 0:
		if _grab_cooldown < 0.0:
			for bone in bones:
				if bone.grab_contact_object:
					if _grab_manager.grab_first_hand(bone.grab_contact_object):
						_anim.play("HandOnBar")
						relax()
					break

		# align body
		match _current_pose_id:
			0: # straight
				var bgy := _body.global_basis.y
				var axis := Vector3(bgy.x, bgy.y, 0.0).normalized()
				align_body(bgy, axis)
			1: # group
				align_body(_body.global_basis.z, Vector3.BACK)
			2: # star
				align_body(_body.global_basis.x, Vector3.BACK)

	elif CAN_2_HAND_GRAB and _grab_manager.grab_count == 1:
		if _grab_manager.grab_second_hand(_body.global_transform):
			relax()


func align_body(body_axis: Vector3, target_axis: Vector3) -> void:
	if body_axis.z < 0.0:
		target_axis = -target_axis
	var torque := target_axis.cross(body_axis) * BODY_ALIGN_FORCE
	_body.apply_torque(torque)

func rotate_body2bar() -> void:
	var body2bar := (_grab_manager.grabbed_body.global_position - _body.global_position).normalized()
	var torque := body2bar.cross(_body.global_basis.y) * GRAB_TO_BAR_FORCE
	_body.apply_torque(torque)


func release_grab():
	if _grab_manager.grab_count > 0:
		_grab_cooldown = GRAB_COOLDOWN
		_grab_manager.release_grab()
		_pose_cooldown = POSE_COOLDOWN
		_body.apply_central_impulse(_body.linear_velocity * OFFGRAB_IMPULSE)
		_anim.play_backwards("HandOnBar")
		_is_in_air_off_bar = sign(_body.angular_velocity.z) == sign(_body.linear_velocity.x)


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

func goto_pose(pose_id: int) -> bool:
	_is_posing = true
	if _current_pose_id == pose_id:
		return false
	_current_pose_id = pose_id
	_pose_cooldown = POSE_COOLDOWN
	_poses.goto_pose(pose_id)
	if _grab_manager.grab_count == 2:
		_luarm1.relax()
		_ruarm1.relax()

	return true





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


var _debug_str: String
func get_debug_text() -> String:
	# return "ground y{0}\nair max y{1}".format([ground_position.y, 0.0])
	# return str(roundf(_body.linear_velocity.y))
	return _debug_str




