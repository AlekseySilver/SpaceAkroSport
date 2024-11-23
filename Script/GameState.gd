extends Node


const SAVE_FILE_NAME = "user://savegame.save"


func save_game():
	var save_file = FileAccess.open(SAVE_FILE_NAME, FileAccess.WRITE)
	save_file.store_var(0) #todo

# https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html

func load_game():
	if not FileAccess.file_exists(SAVE_FILE_NAME):
		return # Error! We don't have a save to load.

	var save_file = FileAccess.open(SAVE_FILE_NAME, FileAccess.READ)
	while save_file.get_position() < save_file.get_length():
		save_file.get_line() #todo


