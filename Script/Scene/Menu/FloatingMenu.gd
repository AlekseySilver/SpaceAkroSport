class_name FloatingMenu extends ColorRect


const SPEED = 0.7
const TRANS = Tween.TRANS_QUINT
const EASE = Tween.EASE_IN_OUT


var dialog_result := 0
var _is_floating := false

signal closed


func _float(left0: float, left1: float) -> Signal:
	_is_floating = true
	anchor_left = left0
	anchor_right = left0 + 1.0
	visible = true
	var tween := get_tree().create_tween()
	tween.connect("finished", _tween_finished)
	tween.tween_property(self, "anchor_left", left1, SPEED).set_trans(TRANS).set_ease(EASE)
	tween.set_parallel()
	tween.tween_property(self, "anchor_right", left1 + 1.0, SPEED).set_trans(TRANS).set_ease(EASE)
	return tween.finished

func float_in() -> Signal:
	return _float(-1.0, 0.0)

func float_out() -> Signal:
	return _float(0.0, 1.0)

func _tween_finished():
	_is_floating = false
	visible = anchor_left == 0.0


func close_dialog() -> void:
	await float_out()
	emit_signal(closed.get_name())


func prepare_show(_init_data) -> void:
	pass # for override

