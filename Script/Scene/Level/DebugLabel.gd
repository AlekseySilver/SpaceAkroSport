extends Label


@export var target: Node = null:
	get: return target
	set(value):
		target = value
		process_enabled_update()


func _ready() -> void:
	process_enabled_update()


func _process(_delta):
	if target and target.has_method("get_debug_text"):
		text = target.get_debug_text()


func process_enabled_update() -> void:
	set_process(target != null)


