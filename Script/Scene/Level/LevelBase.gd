class_name LevelBase extends ScreenWithFader


@onready var cutscene_anim: AnimationPlayer = $Cutscene/AnimationPlayer
@onready var _UIroot := $UI
@onready var _btn_pause := $UI/btnPause
@onready var _pause_menu := $PauseMenu
@onready var _root3D := $Root3D
@onready var _dir_light := $Root3D/DirLight
@onready var lbl_info: RichTextLabel = $UI/lblInfo

var _person: Person


func _ready() -> void:
	_dir_light.shadow_enabled = AppConfig.graphics_show_shadows == 1

	if AppConfig.control_type_id == 2:
		var tc = load(Scenes.PlayTouchControlsPath).instantiate()
		_UIroot.add_child(tc)
		_UIroot.move_child(tc, 0)

	_person = load(Global.current_person_name).instantiate()
	$Root3D.add_child(_person)
	_person.controller = $Root3D/PlayerStart
	_person.global_transform = _person.controller.global_transform
	$Root3D/Camera3D.target_path = _person._body.get_path()

	# debug person
	# $DebugLabel.target = _person

	init_npc()

	wait_finish()

	super()


func _process(_delta: float) -> void:
	if _btn_pause.is_visible_in_tree() and (Input.is_action_just_pressed("start") or Input.is_action_just_pressed("ui_cancel")):
		_on_btn_pause_pressed()


func init_npc() -> void:
	if Global.current_play_mode == 1: # race
		add_npc("NPCStart")


func add_npc(path: NodePath) -> bool:
	var npc_start := $Root3D.get_node_or_null(path) as NPCController
	if npc_start:
		var npc_person = load(Global.random_person_name(Global.current_person_name)).instantiate()
		#var npc_person = load("res://Person/Sophie.tscn").instantiate()
		$Root3D.add_child(npc_person)
		npc_person.controller = npc_start
		npc_person.global_transform = npc_start.global_transform
		npc_start.init_person(npc_person)
		return true
	return false


func cutscene_start() -> void:
	#player_controller.is_enabled = false
	_btn_pause.visible = false
	cutscene_anim.play("Cutscene")

func cutscene_end() -> void:
	#player_controller.is_enabled = true
	#camera.smooth_set_target(player_controller.target_path)
	cutscene_anim.play_backwards("Cutscene")
	_btn_pause.visible = true



func _on_btn_pause_pressed() -> void:
	if is_closing:
		return
	_UIroot.visible = false
	_root3D.process_mode = Node.PROCESS_MODE_DISABLED
	await _pause_menu.float_in()
	await _pause_menu.closed
	_root3D.process_mode = Node.PROCESS_MODE_INHERIT
	
	match _pause_menu.dialog_result:
		1: # restart
			restart_scene()
		2: #quit
			change_scene(Scenes.LevelSelectMenuPath)
		_: # continue play
			_UIroot.visible = true


func set_info_text(text: String) -> void:
	lbl_info.text = "[center]" + tr(text) + "[/center]"


func wait_finish() -> void:
	var finish := $Root3D/Finish
	await finish.finished()
	_btn_pause.visible = false # hide pause button
	if finish.first_entered_person == _person:
		set_info_text("TUTORIAL_WELL_DONE")
		play_sound(AudioList.Finish)
	else:
		set_info_text("YOU_LOSE")
		play_sound(AudioList.Fail)
	await _tree.create_timer(5.0).timeout
	change_scene(Scenes.LevelSelectMenuPath)



