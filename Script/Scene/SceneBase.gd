extends Node3D



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("start"):
		get_tree().quit()


func _on_btn_pause_pressed():
	Engine.time_scale = 0.01
	#get_tree().paused = true
	$UI/btnPause.visible = false
	await $Person.control_show()
	$UI/btnPlay.visible = true


func _on_btn_play_pressed():
	$UI/btnPlay.visible = false
	await $Person.control_hide()
	Engine.time_scale = 1.0
	#get_tree().paused = false
	$UI/btnPause.visible = true
	



