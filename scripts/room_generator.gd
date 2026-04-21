@tool
extends Node

## Emitted when all nodes have spawned on this peer
signal map_generation_finished(map_id: int)

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
var map_index := -1

var _ceilings: Dictionary[Vector2i, PackedScene] = {
	Vector2i(1, 1): load("uid://cmpn21nlov2kw"),
	Vector2i(2, 1): load("uid://b2ic70oyt8cfy"),
	Vector2i(2, 2): load("uid://ds11bisonvhce"),
}
var _starting_room: PackedScene = load("uid://7bs7c7wvcu1d")
var _wall: PackedScene = load("uid://bcn52n0r6ewsn")
var _wall_with_door: PackedScene = load("uid://583hxvak04ds")
var _door: PackedScene = load("uid://bg3i1qg76jyw8")
var _light: PackedScene = load("uid://1eghxwbnkubr")
var _rooms: Array[PackedScene] = [
	load("uid://eu6u2228knpv"),
]
var _directions: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
var _grid: Dictionary[Vector2i, int]
var _nodes: Array[Node]
var _generating_map := false
var _num_nodes_to_spawn: int
var _num_nodes_spawned := 0


func _ready() -> void:
	if spawner:
		spawner.spawned.connect(_on_spawner_node_spawned)


func generate_map() -> void:
	map_index += 1
	
	# Cleanup
	for node in _nodes:
		node.queue_free()
	_nodes.clear()
	_grid.clear()
	if spawner:
		for child in spawner.get_children():
			child.queue_free()
	_rooms.shuffle()
	
	# Populate _grid
	for i in room_count:
		var room: Room = _starting_room.instantiate() if i == 0\
				else _rooms[(i - 1) % _rooms.size()].instantiate()
		
		# 50% chance to rotate room
		var rotated := randf() < 0.5
		var room_size := Vector2i(room.room_size.y, room.room_size.x) if rotated\
				else room.room_size
		
		var pos := Vector2i()
		
		if not _grid.is_empty():
			# Find a place where the room fits
			var positions := _grid.keys()
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
							if cell_pos in _grid:
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
				_grid[Vector2i(pos.x + x, pos.y + y)] = i
		
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
	
	if _grid.size() < room_count:
		print("Wasn't able to place all rooms")	
	
	# Place walls and doors
	var doors: Array[Vector4i] # Store doors as the two connected grid cells in a Vector4i
	for pos: Vector2i in _grid:
		var room_idx := _grid[pos]
		for dir: Vector2i in _directions:
			var neighbor_pos := pos + dir
			var wall_position := Vector3(pos.x * CELL_SIZE, 0, pos.y * CELL_SIZE)
			var wall_rotation := Basis.looking_at(Vector3(dir.x, 0, dir.y)).get_euler()
			var wall_scene: PackedScene
			var neighbor_idx: int = _grid.get(neighbor_pos, -1)
			if neighbor_idx == -1:
				wall_scene = _wall
			elif neighbor_idx != room_idx:
				wall_scene = _wall_with_door
				var door_vecs: Array[Vector4i] = [
					Vector4i(neighbor_pos.x, neighbor_pos.y, pos.x, pos.y),
					Vector4i(pos.x, pos.y, neighbor_pos.x, neighbor_pos.y),
				]
				if door_vecs[0] not in doors and door_vecs[1] not in doors:
					doors.append(door_vecs[0])
					var door := _door.instantiate()
					door.position = wall_position + Vector3(dir.x, 0, dir.y) * CELL_SIZE * 0.5
					door.rotation = wall_rotation
					_spawn_node(door)
			if wall_scene:
				var inst: Node3D = wall_scene.instantiate()
				inst.position = wall_position
				inst.rotation = wall_rotation
				_spawn_node(inst)
	
	if is_multiplayer_authority():
		map_generation_finished.emit()
	elif spawner:
		_start_generation.rpc(map_index, spawner.get_child_count())


func is_map_generated(map_id: int) -> bool:
	return map_index == map_id and not _generating_map


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


## Called on remote peers to notify them that level generation started
@rpc("reliable")
func _start_generation(map_id: int, num_nodes: int) -> void:
	map_index = map_id
	if _num_nodes_spawned >= num_nodes:
		_num_nodes_to_spawn = -1
		_num_nodes_spawned = 0
		map_generation_finished.emit()
	else:
		_generating_map = true
		_num_nodes_to_spawn = num_nodes


func _on_spawner_node_spawned(_node: Node) -> void:
	_num_nodes_spawned += 1
	if _generating_map and _num_nodes_spawned >= _num_nodes_to_spawn:
		_generating_map = false
		_num_nodes_spawned = 0
		map_generation_finished.emit()
