@tool
extends Node

const CELL_SIZE = 22.0
#const UIDS = {
	#wall = "uid://bcn52n0r6ewsn",
	#wall_with_door = "uid://583hxvak04ds",
	#light = "uid://1eghxwbnkubr",
	#starting_room = "uid://7bs7c7wvcu1d",
#}
#const ROOM_UIDS = [
	#"uid://eu6u2228knpv",
#]

@export var room_count := 5
@export var spawner: NodeSpawner
@export_tool_button("Generate") var generate_action := generate_map
var grid: Dictionary[Vector2i, int]

var _ceilings: Dictionary[Vector2i, PackedScene] = {
	Vector2i(1, 1): load("uid://cmpn21nlov2kw"),
	Vector2i(2, 1): load("uid://b2ic70oyt8cfy"),
	Vector2i(2, 2): load("uid://ds11bisonvhce"),
}
var _starting_room: PackedScene = load("uid://7bs7c7wvcu1d")
var _wall: PackedScene = load("uid://bcn52n0r6ewsn")
var _wall_with_door: PackedScene = load("uid://583hxvak04ds")
var _light: PackedScene = load("uid://1eghxwbnkubr")
var _rooms: Array[PackedScene] = [
	load("uid://eu6u2228knpv"),
]
var _directions: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
var _nodes: Array[Node]


func generate_map() -> void:
	# Cleanup
	for node in _nodes:
		node.queue_free()
	_nodes.clear()
	grid.clear()
	if spawner:
		for child in spawner.get_children():
			child.queue_free()
	_rooms.shuffle()
	
	# Populate grid
	for i in room_count:
		var room: Room = _starting_room.instantiate() if i == 0\
				else _rooms[(i - 1) % _rooms.size()].instantiate()
		
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
		_spawn_node(room)
		var ceiling: Node3D = _ceilings[room.room_size].instantiate()
		ceiling.position = room.position
		if not rotated:
			ceiling.rotate_y(PI * 0.5)
		_spawn_node(ceiling)
		var light: Node3D = _light.instantiate()
		light.position = room.position
		light.position.y = 12.5
		_spawn_node(light)
	
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
				inst.rotation = Basis.looking_at(Vector3(dir.x, 0, dir.y)).get_euler()
				_spawn_node(inst)


func _spawn_node(node: Node) -> void:
	if spawner:
		var dict := {
			type = "general",
			uid = ResourceUID.path_to_uid(node.scene_file_path),
		}
		if node is Node3D:
			dict.position = node.position
			dict.rotation = node.rotation
		spawner.spawn(dict)
		node.queue_free()
	else:
		add_child(node)
		_nodes.append(node)
