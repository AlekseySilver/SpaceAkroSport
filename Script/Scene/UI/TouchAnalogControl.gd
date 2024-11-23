extends TouchActionControl


var _action_left: StringName
var _action_right: StringName
var _small_center: Vector2

@onready var _small: TextureRect = $AnalogSmall

func _ready() -> void:
	super()
	_action_left = action_name + "_left"
	_action_right = action_name + "_right"
	_small_center = Xts.get_center(_small)

func init_dim(pos: Vector3) -> void:
	super(pos)
	_small_center = Xts.get_center(_small)


func start_touch(_touch_id: int, _touch_pos: Vector2) -> void:
	touch_id = _touch_id
	update_touch(_touch_pos)


func update_touch(_touch_pos: Vector2) -> void:
	var delta := (_touch_pos - _center) / _radius
	delta.x = clampf(delta.x, -1.0, 1.0)
	delta.y = clampf(delta.y, -1.0, 1.0)
	if delta.x < -0.2:
		Input.action_press(_action_left, -delta.x)
	elif delta.x > 0.2:
		Input.action_press(_action_right, delta.x)

	var sq := delta.length_squared()
	if sq > 1.0:
		delta *= 1.0 / sqrt(sq)
	Xts.set_center(_small, delta * _radius + _small_center)


func stop_touch() -> void:
	touch_id = -1
	Input.action_release(_action_left)
	Input.action_release(_action_right)
	_small.offset_top = 0.0
	_small.offset_bottom = 0.0
	_small.offset_left = 0.0
	_small.offset_right = 0.0
