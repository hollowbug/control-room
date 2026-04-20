@tool
extends Node

const CELL_SIZE = 9.0
#const ROOM_SIZES: Array[Vector2i] = [Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)]

@export var room_count := 5
@export_tool_button("Generate") var generate_action := generate_map
var grid: Dictionary[Vector2i, int]

var _ceilings: Dictionary[Vector2i, PackedScene] = {
	Vector2i(1, 1): load("uid://cdasx4d273hxk"),
	Vector2i(2, 1): load("uid://ckkg1ocn4m77"),
	Vector2i(2, 2): load("uid://bk6scu1mmescg"),
}
var _wall: PackedScene = load("uid://c6rtbxfva8btt")
var _wall_with_door: PackedScene = load("uid://hlwuevht7q5w")
var _light: PackedScene = load("uid://1eghxwbnkubr")
var _starting_room: PackedScene = load("uid://7bs7c7wvcu1d")
var _random_rooms: Array[PackedScene] = [
	load("uid://eu6u2228knpv")
]

var _directions: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
var _nodes: Array[Node]


func generate_map() -> void:
	# Cleanup
	for node in _nodes:
		node.queue_free()
	_nodes.clear()
	grid.clear()
	
	_random_rooms.shuffle()
	
	# Populate grid
	for i in room_count:
		var room: Room = _starting_room.instantiate() if i == 0 else _random_rooms[(i - 1) % _random_rooms.size()].instantiate()
		
		# 50% chance to rotate room
		var rotated := randf() < 0.5
		var room_size := Vector2i(room.room_size.y, room.room_size.x) if rotated\
				else room.room_size
		
		var pos := Vector2i()
		
		if not grid.is_empty():
			# Find a place where the room fits
			var positions := grid.keys()
			positions.shuffle()
			var valid_pos_found := false
			for p: Vector2i in positions:
				_directions.shuffle()
				for dir: Vector2i in _directions:
					var blocked := false
					var test_pos := p + dir
					for x: int in room_size.x:
						for y: int in room_size.y:
							var cell_pos := test_pos + Vector2i(x, y)
							if cell_pos in grid:
								blocked = true
								break
					if not blocked:
						valid_pos_found = true
						pos = test_pos
						break
				if valid_pos_found:
					break
			if not valid_pos_found:
				room.queue_free()
				continue
			
		for x in room_size.x:
			for y in room_size.y:
				grid[Vector2i(pos.x + x, pos.y + y)] = i
		
		# Place room, ceiling and _light
		room.position = Vector3(
			(pos.x + (room_size.x - 1) * 0.5) * CELL_SIZE,
			0,
			(pos.y + (room_size.y - 1) * 0.5) * CELL_SIZE,
		)
		var ceiling: Node3D = _ceilings[room.room_size].instantiate()
		if not rotated:
			ceiling.rotate_y(PI * 0.5)
		room.add_child(ceiling)
		var light: Node3D = _light.instantiate()
		light.position.y = 6
		room.add_child(light)
		add_child(room)
		_nodes.append(room)
	
	if grid.size() < room_count:
		print("Wasn't able to place all rooms")	
		
	# Place walls
	for pos: Vector2i in grid:
		var room_idx := grid[pos]
		for dir: Vector2i in _directions:
			var wall_scene: PackedScene
			var neighbor_idx: int = grid.get(pos + dir, -1)
			if neighbor_idx == -1:
				wall_scene = _wall
			elif neighbor_idx != room_idx:
				wall_scene = _wall_with_door
			if wall_scene:
				var inst: Node3D = wall_scene.instantiate()
				inst.position = Vector3(
					pos.x * CELL_SIZE,
					0,
					pos.y * CELL_SIZE,
				)
				add_child(inst)
				inst.look_at(inst.position + Vector3(dir.x, 0, dir.y))
				_nodes.append(inst)
	
