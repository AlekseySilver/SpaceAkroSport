extends LevelBase



func init_npc() -> void:
	super()

	if Global.current_play_mode == 0: # train
		add_npc("NPCStartTrain")




