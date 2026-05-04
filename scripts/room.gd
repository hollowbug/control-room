@tool
extends Node3D
class_name Room

signal powered_on()
signal powered_off()

@export var room_size := Vector2i.ONE
@export var allowed_connections: Array[RoomConnection]
@export var is_powered := true
var grid_position: Vector2i
var room_rotation: int
var connections: Dictionary[RoomConnection, Room]
var doors: Dictionary[RoomConnection, Door]


func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		add_to_group("rooms")


## Call with RPC ID 1 to request powering on the room
@rpc("any_peer", "call_local")
func request_power_on() -> void:
	if not is_multiplayer_authority(): return
	SignalBus.room_power_on_requested.emit(self)


## Call with RPC ID 1 to request powering off the room
@rpc("any_peer", "call_local")
func request_power_off() -> void:
	if not is_multiplayer_authority(): return
	SignalBus.room_power_off_requested.emit(self)


@rpc("call_local")
func power_on() -> void:
	if is_powered: return
	is_powered = true
	powered_on.emit()


@rpc("call_local")
func power_off() -> void:
	if not is_powered: return
	is_powered = false
	powered_off.emit()


#func _process(delta: float) -> void:
	#if Engine.is_editor_hint():
		#DebugDraw.
