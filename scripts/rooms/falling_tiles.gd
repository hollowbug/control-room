extends Node

const FallingTile = preload("uid://csqikpio13qfn")

@export var room: Room

@export var _first_tile: FallingTile
@onready var _tiles: Array[FallingTile] = [_first_tile]


func _ready() -> void:
	if multiplayer.is_server():
		room.powered_on.connect(_on_room_powered_on)
		room.powered_off.connect(_on_room_powered_off)
	_create_tiles()


func _create_tiles() -> void:
	var start_pos := Vector3(-9, 0, -9)
	_first_tile.position = start_pos
	for x in 21:
		for y in 21:
			if x == 0 and y == 0: continue
			var new_tile: FallingTile = _first_tile.duplicate()
			new_tile.position = start_pos + Vector3(x * 2, 0, y * 2)
			get_parent().add_child.call_deferred(new_tile, true)
			_tiles.append(new_tile)


func _on_room_powered_on() -> void:
	for tile in _tiles:
		tile.powered = true
		if tile.falling_started:
			tile.reset()


func _on_room_powered_off() -> void:
	for tile in _tiles:
		tile.powered = false
