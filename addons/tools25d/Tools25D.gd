@tool
extends EditorPlugin

var _menu: ActionMenu25D

func _enter_tree():
	print("Tools 2.5D plugin enabled")
	_menu = preload("res://addons/tools25d/ActionMenu25D.tscn").instantiate()
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _menu)
	get_editor_interface().get_selection().selection_changed.connect(selection_changed)
	selection_changed()


func _exit_tree():
	if _menu:
		remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _menu)
		_menu.queue_free()
	print("Tools 2.5D plugin disabled")


func selection_changed() -> void:
	#print("selection_changed")
	_menu.selection = get_editor_interface().get_selection().get_selected_nodes()


func _forward_3d_gui_input(viewport_camera, event) -> int:
	if _menu.editor_camera != viewport_camera:
		print("_forward_3d_gui_input")
		_menu.editor_camera = viewport_camera
	return 0

