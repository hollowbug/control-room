@tool
extends Node

## Emitted when all nodes have spawned on this peer
signal map_generation_finished(map_id: int)

#const UIDS = {
	#wall = "uid://bcn52n0r6ewsn",
	#wall_with_door = "uid://583hxvak04ds",
	#light = "uid://1eghxwbnkubr",
	#starting_room = "uid://7bs7c7wvcu1d",
#}
#const ROOM_UIDS = [
	#"uid://eu6u2228knpv",
#]

@export var room_count := 10
@export var spawner: NodeSpawner
@export_tool_button("Generate") var generate_action := generate_map
var map_index := -1

var _ceilings: Dictionary[Vector2i, PackedScene] = {
	Vector2i(1, 1): load("uid://ccotmq2blruil"),
	Vector2i(2, 1): load("uid://2cnd3uqpb6ux"),
	Vector2i(2, 2): load("uid://m1e7amepqeqg"),
}
var _scenes: Dictionary[String, PackedScene] = {
	starting_room = load("uid://7bs7c7wvcu1d"),
	door = load("uid://bg3i1qg76jyw8"),
	wall = load("uid://bcn52n0r6ewsn"),
	wall_with_door = load("uid://583hxvak04ds"),
	battery = load("uid://cmqe6rq82e3mv"),
}
var _room_scenes: Array[PackedScene] = [
	load("uid://eu6u2228knpv"),
	load("uid://bvy6smqlncnii"),
	load("uid://lq3ikfse6o6i"),
	load("uid://cmq1ti3i315ii"),
	load("uid://c5onjgipo1fqg"),
]
var _grid: Dictionary[Vector2i, int]
var _rooms: Array[Room]
var _nodes: Array[Node]
var _generating_map := false
var _num_nodes_to_spawn: int
var _num_nodes_spawned := 0


func _ready() -> void:
	if spawner:
		spawner.spawned.connect(_on_spawner_node_spawned)


func generate_map() -> void:
	print(_room_scenes)
	map_index += 1
	
	#print("\n==== STARTING GENERATION ====\n")
	
	# Cleanup
	for node in _nodes:
		node.queue_free()
	_nodes.clear()
	_grid.clear()
	_rooms.clear()
	if spawner:
		for child in spawner.get_children():
			child.queue_free()
	
	# Place rooms
	_room_scenes.shuffle()
	for i in room_count:
		#print()
		var room: Room = _scenes.starting_room.instantiate() if i == 0\
				else _room_scenes[(i - 1) % _room_scenes.size()].instantiate()
		
		var room_size := room.room_size
		var room_cells: Array[Vector2i]
		for x: int in room_size.x:
			for y: int in room_size.y:
				room_cells.append(Vector2i(x, y))
		
		# Randomly rotate room
		room.room_rotation = randi() % 4
		for j in room_cells.size():
			room_cells[j] = Utils.rotate_vector2i(room_cells[j], room.room_rotation)
		#if room_cells.size() > 1:
		#prints("Allowed connections before:", room.allowed_connections.map(_conn_to_string))
		for j in room.allowed_connections.size():
			room.allowed_connections = room.allowed_connections.duplicate_deep(Resource.DeepDuplicateMode.DEEP_DUPLICATE_ALL)
			room.allowed_connections[j].position = Utils.rotate_vector2i(room.allowed_connections[j].position, room.room_rotation)
			room.allowed_connections[j].direction = Utils.rotate_vector2i(room.allowed_connections[j].direction, room.room_rotation)
		#if room_cells.size() > 1:
		#prints("Allowed connections after:", room.allowed_connections.map(_conn_to_string))
		
		#print("%s room.room_rotation: %s, room_cells: %s" % [room, room.room_rotation, room_cells])
		#print("%s room.room_rotation: %s, room_cells: %s, allowed_connections: %s" % [room, room.room_rotation, room_cells, room.allowed_connections.map(_conn_to_string)])
		
		var pos := Vector2i()
		
		if i != 0:
			#var print_string := ""
			# Find a place where the room fits
			_rooms.shuffle()
			room.allowed_connections.shuffle()
			var valid_pos_found := false
			for r: Room in _rooms:
				for conn: RoomConnection in room.allowed_connections:
					#print_string += "\nChecking options for connection %s against room %s at %s" % [_conn_to_string(conn), r, r.grid_position]
					for conn2: RoomConnection in r.allowed_connections:
						pos = r.grid_position + conn2.position + conn2.direction - conn.position
						#print_string += "\n\tChecking %s's connection %s at %s" % [r, _conn_to_string(conn2), pos]
						if conn.direction != -conn2.direction:
							#print_string += ": doors don't align."
							continue
						var blocked := false
						for cell in room_cells:
							var cell_pos := cell + pos
							if cell_pos in _grid:
								blocked = true
								#print_string += ": blocked."
								break
						if not blocked:
							valid_pos_found = true
							r.allowed_connections.erase(conn2)
							r.connections[conn2] = room
							room.allowed_connections.erase(conn)
							room.connections[conn] = r
							break
					if valid_pos_found:
						break
				if valid_pos_found:
					break
			if not valid_pos_found:
				room.queue_free()
				#print(print_string)
				continue
		
		room.grid_position = pos
		_rooms.append(room)
		
		for cell in room_cells:
			_grid[pos + cell] = i
		
		# Place room and ceiling
		room.position = Vector3(pos.x, 0, pos.y) * Globals.CELL_SIZE
		room.rotate_y(room.room_rotation * PI * -0.5)
		_spawn_node(room)
		if room.room_size in _ceilings:
			var ceiling: Node3D = _ceilings[room.room_size].instantiate()
			ceiling.transform = room.transform
			
			# Keep one random camera per room, none in starting room
			var cameras: Array[Node3D]
			cameras.assign(ceiling.find_children("", "CCTVCamera"))
			var random_cam := -1
			if cameras and not room.is_in_group("starting_room"):
				random_cam = randi() % cameras.size()
			ceiling.set_meta("camera_index", random_cam)
			for c in cameras.size():
				if c != random_cam:
					cameras[c].queue_free()
			
			_spawn_node(ceiling)
	
	if _grid.size() < room_count:
		print("Wasn't able to place all rooms")	
	
	# Place walls and doors
	for room in _rooms:
		for conn in room.allowed_connections + room.connections.keys():
			var wall := (_scenes.wall_with_door if conn in room.connections else _scenes.wall).instantiate() as Node3D
			wall.position = Vector3(
				room.grid_position.x + conn.position.x,
				0,
				room.grid_position.y + conn.position.y
			) * Globals.CELL_SIZE
			wall.basis = Basis.looking_at(Vector3(conn.direction.x, 0, conn.direction.y))
			_spawn_node(wall)
		
		for conn in room.connections:
			if conn not in room.doors:
				var door := _scenes.door.instantiate() as Door
				var room2 := room.connections[conn]
				room.doors[conn] = door
				for conn2 in room2.connections:
					if room2.connections[conn2] == room:
						room2.doors[conn2] = door
						break
				door.position = Vector3(
					room.grid_position.x + conn.position.x + conn.direction.x * 0.5,
					0,
					room.grid_position.y + conn.position.y + conn.direction.y * 0.5
				) * Globals.CELL_SIZE
				door.basis = Basis.looking_at(Vector3(conn.direction.x, 0, conn.direction.y))
				_spawn_node(door)
	
	# Spawn batteries
	var batteries := get_tree().get_nodes_in_group("battery_placeholders")
	batteries.shuffle()
	for placeholder: Node3D in batteries.slice(0, mini(batteries.size(), 5)):
		var battery := _scenes.battery.instantiate() as Node3D
		if not battery: break
		battery.global_transform = placeholder.global_transform
		_spawn_node(battery)
	
	
	if is_multiplayer_authority():
		map_generation_finished.emit()
		if spawner:
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
		if node is Room:
			dict.room_position = node.grid_position
			dict.room_rotation = node.room_rotation
		if node.has_meta("camera_index"):
			dict.camera_index = node.get_meta("camera_index")
		spawner.spawn(dict)
		node.queue_free()
	else:
		add_child(node, true)
		_nodes.append(node)


## Called on remote peers to notify them that level generation started
@rpc
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


func _conn_to_string(conn: RoomConnection) -> String:
	return "(pos: %s, dir: %s)" % [conn.position, conn.direction]
