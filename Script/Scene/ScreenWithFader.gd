class_name ScreenWithFader extends Control


@onready var fader_anim: AnimationPlayer = $Fader/AnimationPlayer
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer
@onready var _tree: SceneTree = get_tree()

var is_closing := false

func _ready() -> void:
	fade_out_async()

func fade_in() -> void:
	$Fader.visible = true
	fader_anim.play_backwards("Fade")

func fade_in_async() -> Signal:
	fade_in()
	return fader_anim.animation_finished

func fade_out() -> void:
	fader_anim.play("Fade")

func fade_out_async() -> Signal:
	#fade_out()
	fader_anim.play("Fade")
	await fader_anim.animation_finished
	$Fader.visible = false
	return fader_anim.animation_finished


func change_scene(scene_path: String, back_save: bool = false) -> void:
	is_closing = true
	await fade_in_async()
	if back_save:
		Global.push_prev_scene(_tree.current_scene.scene_file_path)
	_tree.change_scene_to_file(scene_path)


func restart_scene() -> void:
	change_scene(_tree.current_scene.scene_file_path)


func play_sound(res: String) -> void:
	if audio.stream and audio.stream.resource_name == res:
		pass
	else:
		audio.stream = load(res)
	audio.play()


