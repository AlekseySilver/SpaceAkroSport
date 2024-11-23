extends LevelBase


const TWEEN_DURATION = 0.5
const NEED_STAR_MOVE_DURATION = 4.0


@onready var lbl_tasks: Array[RichTextLabel] = [$UI/lblTask1, $UI/lblTask2, $UI/lblTask3]
@onready var tr_tasks: Array[TextureRect] = [$UI/trTask1, $UI/trTask2, $UI/trTask3]
@onready var arr_checked := [load("res://textures/block_unchecked.png"), load("res://textures/block_checked.png")]

var _tweens: Array[Tween] = [null, null, null, null]

enum TRAIN_STATE {NONE, NEED_GROUP, NEED_ROLL, NEED_STRAIGTH, NEED_JUMP_OUT
				, NEED_LEARN_WHEEL, NEED_STAR, NEED_STAR_MOVE
				, NEED_GRAB_BAR, NEED_SUN, NEED_RELEASE_GRAB
				}
var _train_state := TRAIN_STATE.NONE
signal train_state_changed


var keytips := { &"move_left": [], &"move_right": [], &"pose1": [], &"pose2": [], &"pose3": [], &"pose4": [], }
var _current_keytips_type := -1

var _star_move_time := 0.0

var _task_txts: Array[String] = ["", "", ""]


func _ready() -> void:
	super()

	fill_keytips(AppConfig.control_type_id)

	for i in len(_tweens):
		_tweens[i] = _tree.create_tween()
		_tweens[i].kill()

	training_path()


func fill_keytips(type: int) -> void:
	if type == _current_keytips_type:
		return
	var tex_size := int(tr_tasks[0].size.x * 0.7)
	_current_keytips_type = type
	for key in keytips:
		var data: Array = keytips[key]
		data.clear()
		data.append("")
		data.append("")

		var keymap = KeyPersistence.keymaps[key]
		if keymap:
			var arr = keymap.filter(func(x): return (x is InputEventKey) == (type == 0))
			var event: InputEvent = arr[0] if arr else keymap[0]
			#texture path
			if type == 0:
				data[0] = "[img=%sx%s]res://textures/kb_key.png[/img]" % [tex_size, tex_size]
			elif event is InputEventJoypadButton:
				if Xts.is_between(event.button_index, 0, 3):
					data[0] = "[img=%sx%s]%s[/img]" % [tex_size, tex_size, KeyPersistence.get_joy_button_texture_path(AppConfig.gamepad_button_layout, event.button_index)]

			elif event is InputEventJoypadMotion:
				data[0] = "[img=%sx%s]res://textures/gamepad/small_circle.png[/img]" % [tex_size, tex_size]
			#debug
			# else: data[0] = event.as_text()

			#text
			if type == 2: #  - touch - icons only
				if event is InputEventJoypadMotion:
					data[1] = tr("RIGHT" if event.axis_value > 0.0 else "LEFT")
			else: # kb or joy
				data[1] = KeyPersistence.input_event_text(event)




func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		AppConfig.set_control_type_id(0)
		fill_keytips(0)
	elif event is InputEventJoypadButton:
		AppConfig.set_control_type_id(1)
		fill_keytips(1)
	elif event is InputEventJoypadMotion:
		AppConfig.set_control_type_id(1)
		fill_keytips(1)



func _process(delta: float) -> void:
	super(delta)

	match _train_state:
		TRAIN_STATE.NEED_GROUP:
			if _person._current_pose_id == 1:
				var bb := _person._body.global_basis
				if bb.y.y > Xts.SIN45 and lbl_tasks[1].text:
					set_train_state__need_straigth()
				else:
					set_train_state__need_roll()

		TRAIN_STATE.NEED_ROLL:
			if _person._current_pose_id != 1:
				set_train_state__need_group()
			else:
				var bb := _person._body.global_basis
				if bb.y.y > Xts.SIN45:
					set_train_state__need_straigth()

		TRAIN_STATE.NEED_STRAIGTH:
			if _person._current_pose_id == 0:
				set_train_state(TRAIN_STATE.NEED_JUMP_OUT)
			else:
				var bb := _person._body.global_basis
				if bb.y.y > Xts.SIN20:
					set_train_state__need_straigth()
				else:
					set_train_state__need_roll()
		TRAIN_STATE.NEED_STAR:
			if _person._current_pose_id == 3:
				set_train_state__need_star_move()
		TRAIN_STATE.NEED_STAR_MOVE:
			if (Input.get_axis("move_left", "move_right") != 0):
				_star_move_time += delta
			if _star_move_time > NEED_STAR_MOVE_DURATION:
				set_train_state(TRAIN_STATE.NEED_JUMP_OUT)
			elif _person._current_pose_id != 3:
				set_train_state__need_star()
		TRAIN_STATE.NEED_GRAB_BAR:
			if _person._grab_manager.grab_count > 0:
				set_train_state__need_sun()
		TRAIN_STATE.NEED_SUN:
			if _person._grab_manager.grab_count == 0:
				set_train_state__need_grab_bar()
			else:
				var bb := _person._body.global_basis
				if bb.y.y < -Xts.SIN45:
					set_train_state__need_release()
		TRAIN_STATE.NEED_RELEASE_GRAB:
			if _person._grab_manager.grab_count == 0:
				set_train_state(TRAIN_STATE.NEED_JUMP_OUT)



func set_train_state(value: TRAIN_STATE) -> bool:
	if _train_state == value:
		return false
	_train_state = value
	emit_signal("train_state_changed")
	return true


func set_train_state__need_group() -> void:
	if set_train_state(TRAIN_STATE.NEED_GROUP):
		var text := tr("HOLD_GROUP") % get_button_text("pose2")
		set_task_text(0, text)
		set_tasks_done(0)


func set_train_state__need_roll() -> void:
	if set_train_state(TRAIN_STATE.NEED_ROLL):
		set_task_text(1, tr("ROLL_ON_FEET") % [get_button_text("move_left"), get_button_text("move_right")])
		set_tasks_done(1)


func set_train_state__need_straigth() -> void:
	if set_train_state(TRAIN_STATE.NEED_STRAIGTH):
		var text := tr("STRAIGHT_AND_JUMP") % get_button_text("pose1")
		set_task_text(2, text)
		set_tasks_done(2)


func set_train_state__need_star() -> void:
	if set_train_state(TRAIN_STATE.NEED_STAR):
		var text := tr("HOLD_STAR") % get_button_text("pose4")
		set_task_text(0, text)
		set_tasks_done(0)

func set_train_state__need_star_move() -> void:
	if set_train_state(TRAIN_STATE.NEED_STAR_MOVE):
		var text := tr("MOVE_KEYS") % [get_button_text("move_left"), get_button_text("move_right")]
		set_task_text(1, text)
		set_tasks_done(1)
		_star_move_time = 0.0


func set_train_state__need_grab_bar() -> void:
	if set_train_state(TRAIN_STATE.NEED_GRAB_BAR):
		var text := tr("GRAB_BAR")
		set_task_text(0, text)
		set_tasks_done(0)

func set_train_state__need_sun() -> void:
	if set_train_state(TRAIN_STATE.NEED_SUN):
		var text := tr("GRAB_SUN") % [get_button_text("move_left"), get_button_text("move_right")]
		set_task_text(1, text)
		set_tasks_done(1)

func set_train_state__need_release() -> void:
	if set_train_state(TRAIN_STATE.NEED_RELEASE_GRAB):
		var text := tr("GRAB_RELEASE") % [get_button_text("pose3"), get_button_text("pose4")]
		set_task_text(2, text)
		set_tasks_done(2)


func set_info_text(text: String) -> void:
	_set_text(lbl_info, 0, "[center]" + tr(text) + "[/center]")


func _set_text(lbl: RichTextLabel, tween_id: int, text: String) -> void:
	lbl.visible_ratio = 0.0
	lbl.text = text
	_tweens[tween_id].kill()
	if text:
		_tweens[tween_id] = _tree.create_tween()
		_tweens[tween_id].tween_property(lbl, "visible_ratio", 1.0, TWEEN_DURATION)


func get_button_text(action: String) -> String:
	var text := "%s [color=#438FFFFF]%s[/color]" % keytips[action]
	#print(text)
	return text


func set_task_text(task_id: int, text: String) -> void:
	_task_txts[task_id] = text
	_set_text(lbl_tasks[task_id], task_id + 1, text)

func set_tasks_done(done_count: int):
	for i in 3:
		set_task_done(i, i < done_count)
		set_task_highlight(i, i == done_count)

func set_task_highlight(task_id: int, high_light: bool = false) -> void:
	var text := _task_txts[task_id]
	if text:
		if high_light:
			text = "[color=#99FF99FF]%s[/color]" % text
	lbl_tasks[task_id].text = text


func set_task_done(task_id: int, done: int) -> void:
	tr_tasks[task_id].texture = arr_checked[done] if _task_txts[task_id] and done >= 0 else null

func task_clear() -> void:
	for i in 3:
		_task_txts[i] = ""
		_set_text(lbl_tasks[i], i + 1, "")
		set_task_done(i, -1)


func training_path() -> void:
	# jump tutor
	await _tree.create_timer(2.0).timeout
	set_info_text("TUTORIAL_WELCOME")
	await _tree.create_timer(3.0).timeout
	set_info_text("TUTORIAL_JUMP")
	await _tree.create_timer(2.0).timeout

	set_train_state__need_group()
	# wait jump
	while true:
		match _train_state:
			TRAIN_STATE.NEED_JUMP_OUT:
				set_tasks_done(3)
				set_info_text("TUTORIAL_JUMP_OUT")
				await _tree.create_timer(2.0).timeout
				$Root3D/Door01/AnimationPlayer.play("Open")
				set_info_text(tr("TUTORIAL_JUMP_OUT") + "\n" + tr("MOVE_IN_AIR") % [get_button_text("move_left"), get_button_text("move_right")])
				break

		await train_state_changed
	
	# wheel move tutor
	await $Root3D/AreaRoom2.body_entered
	task_clear()
	set_info_text("TUTORIAL_WHEEL")
	await _tree.create_timer(2.0).timeout
	set_train_state__need_star()

	# wait wheel
	while true:
		match _train_state:
			TRAIN_STATE.NEED_JUMP_OUT:
				set_tasks_done(2)
				set_info_text("TUTORIAL_JUMP_OUT2")
				await _tree.create_timer(2.0).timeout
				$Root3D/Door02/AnimationPlayer.play("Open")
				break

		await train_state_changed

	# bar tutor
	await $Root3D/AreaRoom3.body_entered
	task_clear()

	set_info_text("TUTORIAL_BAR")
	await _tree.create_timer(2.0).timeout
	set_train_state__need_grab_bar()

	# wait bar
	while true:
		match _train_state:
			TRAIN_STATE.NEED_JUMP_OUT:
				set_tasks_done(3)
				set_info_text("TUTORIAL_JUMP_OUT3")
				await _tree.create_timer(2.0).timeout
				$Root3D/Door03/AnimationPlayer.play("Open")
				break

		await train_state_changed


	# end tutor
	await $Root3D/AreaRoom4.body_entered
	task_clear()
	# set_info_text("TUTORIAL_WELL_DONE")
	# await _tree.create_timer(5.0).timeout
	# change_scene(Scenes.LevelSelectMenuPath)
