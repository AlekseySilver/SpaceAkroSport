class_name Scenes


const MainMenuPath = "res://Scene/Menu/MainMenu.tscn"
const PlayerSelectMenuPath = "res://Scene/Menu/PlayerSelectMenu.tscn"
const ControlsMenuPath = "res://Scene/Menu/ControlsMenu.tscn"
const TouchControlsMenuPath = "res://Scene/Menu/TouchControlsMenu.tscn"
const LevelSelectMenuPath = "res://Scene/Menu/LevelSelectMenu.tscn"
const PlayTouchControlsPath = "res://Scene/UI/PlayTouchControls.tscn"
const SettingsMenuPath = "res://Scene/Menu/SettingsMenu.tscn"
const NPCBodyAreaPath = "res://Scene/NPC/NPCBodyArea.tscn"



const Levels = [
	{ name = "TUTORIAL", can_race = false },
	{ name = "GYM", can_race = true },
	{ name = "BATUT", can_race = true },
	{ name = "STAIRS", can_race = true },
	{ name = "BYPASS", can_race = true },
	]


static func get_level_path(id: int) -> String:
	return "res://Scene/Level/Level%02d.tscn" % id

