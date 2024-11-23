class_name NPCController extends BaseController

enum FSM_METHOD_STATE {START, LOOP}


@export var RELEASE_BAR_VELOCITY: float = 5.0
@export var RELEASE_BAR_TARGET_OFFSET: float = 10.0
@export var TARGET: NPCTarget = null


var _person: Person = null
var _fsm_method: Callable = fsm_idle
var _fsm_method_state := FSM_METHOD_STATE.LOOP
var _active_pose_id := -1
var _axis_x := 0.0
var _fsm_method_time := 0.0

func _ready() -> void:
	set_process(false)

func _process(delta: float) -> void:
	if _person:
		_fsm_method_time += delta
		_fsm_method.call()

		check_got_target()


func is_pose(pose_id: int) -> bool:
	return _active_pose_id == pose_id

func axis_x() -> float:
	return _axis_x


func init_person(person: Person) -> void:
	assert(not _person)
	_person = person
	var ncparea := load(Scenes.NPCBodyAreaPath).instantiate() as NPCBodyArea
	_person._body.add_child(ncparea)
	ncparea.init_controller(self)
	set_process(true)



func goto_method(method: Callable) -> void:
	_fsm_method = method
	_fsm_method_state = FSM_METHOD_STATE.START
	_fsm_method.call()
	_fsm_method_state = FSM_METHOD_STATE.LOOP
	_fsm_method_time = 0.0


func check_grab() -> bool:
	if _person._grab_manager.grab_count > 0:
		goto_method(fsm_bar__swing)
		return true
	return false


func check_got_target() -> bool:
	if TARGET and TARGET.check_reached(_person):
		goto_next_target()
		return true
	return false



func axis2target() -> void:
	if TARGET:
		var delta := TARGET.global_position.x - _person._body.global_position.x
		_axis_x = signf(delta)
		if signf(_person._body.linear_velocity.x) == _axis_x:
			delta = absf(delta)
			if delta < TARGET.slow_down_dist:
				_axis_x *= delta / TARGET.slow_down_dist
	elif _axis_x:
		_axis_x = 0.0

func goto_next_target(back: bool = false) -> void:
	if TARGET:
		TARGET = TARGET.prev if back else TARGET.next


func try_set_target(target: NPCTarget) -> bool:
	var gbar := _person._grab_manager.grabbed_body
	if gbar:
		var tbar := target as NPCTargetBar
		if tbar and tbar._bar == gbar:
			return false
	TARGET = target
	return true


#region FSM

func fsm_idle() -> void:
	if _fsm_method_state == FSM_METHOD_STATE.START:
		# print("idle")
		_axis_x = 0.0
		_active_pose_id = -1 # relax
	else:
		if check_grab():
			return
		if _person.has_ground_contact:
			goto_method(fsm_jump__group_and_roll)
		else:
			axis2target()


func fsm_jump__group_and_roll() -> void:
	if _fsm_method_state == FSM_METHOD_STATE.START:
		# print("jump group")
		_axis_x = 0.0
		_active_pose_id = 1 # group
	else:
		if check_grab():
			return
		if _person.has_ground_contact:
			var by := _person._body.global_basis.y
			if by.y > Xts.SIN60:
				goto_method(fsm_jump__straigth)
			elif _fsm_method_time > 3.0:
				goto_method(fsm_jump__straigth)
			else:
				_axis_x = -by.x
		elif _fsm_method_time > 1.0:
			goto_method(fsm_idle)
		else:
			axis2target()



func fsm_jump__straigth() -> void:
	if _fsm_method_state == FSM_METHOD_STATE.START:
		# print("jump straigth")
		_axis_x = 0.0
		_active_pose_id = 0 # straigth
	else:
		if check_grab():
			return
		if _person.has_ground_contact:
			goto_method(fsm_jump__group_and_roll)
		else:
			axis2target()



func fsm_bar__swing() -> void:
	if _fsm_method_state == FSM_METHOD_STATE.START:
		# print("bar swing")
		_axis_x = 0.0
		_active_pose_id = -1 # relax

		# check has new target from bar
		var grabbed := _person._grab_manager.grabbed_body
		if grabbed:
			for child in grabbed.get_children():
				var tgt := child as NPCTarget
				if tgt:
					TARGET = tgt
	else:
		if _person._grab_manager.grab_count == 0:
			goto_method(fsm_idle)
		else:
			var dir := Xts.XY(_person._grab_manager.grabbed_body.global_position) - Xts.XY(_person._body.global_position)
			dir = dir.normalized()
			if dir.y < -Xts.SIN30 or dir.y > Xts.SIN30:
				_axis_x = signf(_person._body.linear_velocity.x)
			else:
				_axis_x = 0.0

			if TARGET:
				# dir = Xts.XY(TARGET.global_position)
				# dir.y += RELEASE_BAR_TARGET_OFFSET
				# dir -= Xts.XY(_person._body.global_position)
				# dir = dir.normalized()
				dir = Vector2(0.0, 1.0)
				var vel := Xts.XY(_person._body.linear_velocity)
				var vel_dir := vel.normalized()
				if vel_dir.dot(dir) > Xts.SIN85 and (vel_dir.dot(vel) > RELEASE_BAR_VELOCITY or _fsm_method_time > 30.0):
					#print("release_grab ", dir, "      ", _person._body.linear_velocity)
					_person.release_grab()
			elif _fsm_method_time > 10.0 and dir.y > Xts.SIN85:
				_person.release_grab()



#endregion


func get_debug_text() -> String:
	var txt = "%s\n%s\n%s" % [_fsm_method.get_method(), _active_pose_id, sign(_axis_x)]
	if TARGET:
		txt += "\n%s" % TARGET.name
	return txt



