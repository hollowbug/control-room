extends Node3D
class_name Door

const TWEEN_DURATION = 0.4

var _tween: Tween


@rpc("reliable", "call_local")
func open() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CIRC)
	_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.tween_property($Left, "position:x", -5, TWEEN_DURATION)
	_tween.tween_property($Right, "position:x", 5, TWEEN_DURATION)


@rpc("reliable", "call_local")
func close() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CIRC)
	_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.tween_property($Left, "position:x", -1.5, TWEEN_DURATION)
	_tween.tween_property($Right, "position:x", 1.5, TWEEN_DURATION)
