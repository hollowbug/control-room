extends Node3D
class_name Door

signal opened()
signal closed()

const TWEEN_DURATION = 0.4

var is_open := false

var _tween: Tween


## Call with RPC ID 1 to request opening the door
@rpc("any_peer", "call_local")
func request_open() -> void:
	if not is_multiplayer_authority(): return
	SignalBus.door_open_requested.emit(self)


## Call with RPC ID 1 to request closing the door
@rpc("any_peer", "call_local")
func request_close() -> void:
	if not is_multiplayer_authority(): return
	SignalBus.door_close_requested.emit(self)


@rpc("call_local")
func open() -> void:
	if is_open: return
	is_open = true
	opened.emit()
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CIRC).set_parallel()
	_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.tween_property($Left, "position:x", -5, TWEEN_DURATION)
	_tween.tween_property($Right, "position:x", 5, TWEEN_DURATION)


@rpc("call_local")
func close() -> void:
	if not is_open: return
	is_open = false
	closed.emit()
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CIRC).set_parallel()
	_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.tween_property($Left, "position:x", -1.5, TWEEN_DURATION)
	_tween.tween_property($Right, "position:x", 1.5, TWEEN_DURATION)
