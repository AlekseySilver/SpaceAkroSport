extends Label

@export var target_path: NodePath: get = get_target_path, set = set_garget_path


var _target: Node
var _target_path: NodePath

func get_target_path() -> NodePath:
	return _target_path

func set_garget_path(value: NodePath) -> void:
	_target_path = value
	_target = get_node_or_null(value)
	if _target and not _target.has_method("get_debug_text"):
		_target = null

func _ready() -> void:
	set_garget_path(target_path)

func _process(_delta: float) -> void:
	if _target:
		text = _target.get_debug_text()
