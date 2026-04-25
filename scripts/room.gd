@tool
extends Node3D
class_name Room

@export var room_size := Vector2i.ONE
@export var allowed_connections: Array[RoomConnection]
var grid_position: Vector2i
var room_rotation: int
var connections: Dictionary[RoomConnection, Room]
var doors: Dictionary[RoomConnection, Door]


func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		add_to_group("rooms")


#func _process(delta: float) -> void:
	#if Engine.is_editor_hint():
		#DebugDraw.
