class_name TouchActionControl extends TextureRect


const DEFAULT_OPACITY = 50.0


@export var action_name: StringName


var touch_id := -1
var _radius: float
var _radius_sq: float
var _center: Vector2


func _ready() -> void:
	update_circle()

func init_dim(pos: Vector3) -> void:
	position = Xts.XY(pos)
	size = Vector2(pos.z, pos.z)
	update_circle()

func update_circle() -> void:
	var rect := get_global_rect()
	_radius = rect.size.x * 0.5
	_center = rect.get_center()
	_radius_sq = _radius * _radius



func is_touch() -> bool:
	return touch_id >= 0


func contains(point: Vector2) -> bool:
	var rect := get_global_rect()
	if rect.has_point(point):
		return (_center - point).length_squared() < _radius_sq
	return false


func start_touch(_touch_id: int, _touch_pos: Vector2) -> void:
	touch_id = _touch_id
	Input.action_press(action_name)

func update_touch(_touch_pos: Vector2) -> void:
	pass

func stop_touch() -> void:
	touch_id = -1
	Input.action_release(action_name)





