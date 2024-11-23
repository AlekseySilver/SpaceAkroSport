extends Area3D
class_name ControlPoint


const TWEEN_TRANS = Tween.TRANS_QUINT
const TWEEN_EASE = Tween.EASE_IN_OUT


@export var center_offset: Vector3
@export var person_body: PersonBody
@export var max_impulse_len: float = 5.0
@export var impulse_scale: float = 5.0
@export var impulse_duration: float = 1.0

@onready var _mesh: MeshInstance3D = $Mesh
@onready var _arrow_top: MeshInstance3D = $ArrowTop
@onready var _arrow_body: MeshInstance3D = $ArrowBody

var _default_pos: Vector3
var _default_scale: Vector3
var _impulse_direction: Vector3
var _impulse_len: float
var _impulse_value: Vector3
var _impulse_duration_rest: float = 0.0

func _ready() -> void:
	_default_pos = _mesh.position
	_default_scale = _mesh.scale


func _process(_delta: float) -> void:
	if _arrow_top.visible:
		_arrow_top.global_position = _impulse_value + global_position
		_arrow_body.global_position = _impulse_value * 0.5 + global_position

func _physics_process(delta: float) -> void:
	if _impulse_duration_rest > 0.0:
		_impulse_duration_rest -= delta
		person_body.apply_central_impulse(_impulse_value * impulse_scale)



func show_prepare(center: Vector3, tween: Tween, duration: float) -> void:
	_mesh.scale = Vector3.ZERO
	_mesh.global_position = center + center_offset
	_mesh.visible = true

	tween.tween_property(_mesh, "position", _default_pos, duration).set_trans(TWEEN_TRANS).set_ease(TWEEN_EASE)
	tween.set_parallel()
	tween.tween_property(_mesh, "scale", _default_scale, duration)
	tween.set_parallel()


func hide_prepare(center: Vector3, tween: Tween, duration: float) -> void:
	hide_arrow()

	var offset := _arrow_top.global_basis.y * 10.0

	tween.tween_property(_mesh, "global_position", center + offset, duration).set_trans(TWEEN_TRANS).set_ease(TWEEN_EASE)
	tween.set_parallel()
	tween.tween_property(_mesh, "scale", Vector3.ZERO, duration)
	tween.set_parallel()


func hide_arrow() -> void:
	_arrow_top.visible = false
	_arrow_body.visible = false


func show_arrow(to: Vector3) -> void:
	_impulse_value = to - global_position
	_impulse_len = _impulse_value.length_squared()
	if _impulse_len > 0.0:
		_impulse_len = sqrt(_impulse_len)
		_impulse_direction = _impulse_value / _impulse_len
		if _impulse_len > max_impulse_len:
			_impulse_len = max_impulse_len
			_impulse_value = _impulse_direction * _impulse_len

		var up_basis := Xts.up_align(_arrow_top.global_basis, _impulse_direction)

		_arrow_top.global_basis = up_basis
		_arrow_body.global_basis = up_basis

		_arrow_top.global_position = _impulse_value + global_position
		_arrow_body.global_position = _impulse_value * 0.5 + global_position
		_arrow_body.scale = Vector3(1.0, _impulse_len, 1.0)

		_arrow_top.visible = true
		_arrow_body.visible = true
	else:
		hide_arrow()



func apply_impulse():
	_mesh.visible = false
	_impulse_duration_rest = impulse_duration


