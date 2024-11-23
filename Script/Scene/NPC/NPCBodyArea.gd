class_name NPCBodyArea extends Area3D


var _npc: NPCController


func init_controller(controller: NPCController) -> void:
	_npc = controller


func switch2target(target: NPCTarget) -> void:
	_npc.try_set_target(target)


