extends Node3D
class_name CCTVCamera

@export var camera: Camera3D
var activated := false


## Call with RPC ID 1 to request switching to this camera
@rpc("any_peer", "call_local")
func request_select() -> void:
	if not is_multiplayer_authority(): return
	SignalBus.cctv_camera_change_requested.emit(self)


@rpc("call_local")
func select() -> void:
	activated = true
	SignalBus.current_cctv_camera_changed.emit(self)
