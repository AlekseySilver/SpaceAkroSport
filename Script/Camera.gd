extends Camera3D


@export var target_path: NodePath: get = get_target_path, set = set_garget_path
@export var offset: Vector3
@export var blend := 0.5

var _target: Node3D
var _target_path: NodePath

func get_target_path() -> NodePath:
	return _target_path

func set_garget_path(value: NodePath) -> void:
	_target_path = value
	_target = get_node_or_null(value)
	#print("T=", value)



func _ready() -> void:
	set_garget_path(target_path)


func _physics_process(_delta: float) -> void:
	if _target:
		var need = _target.global_position + offset
		position = position.lerp(need, blend)
