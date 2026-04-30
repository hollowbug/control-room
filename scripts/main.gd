extends Node

const RoomGenerator = preload("uid://bc204rjvbei42")
const StartButton = preload("uid://vdx11c47or")
const Screen3D = preload("uid://7qvord22my3h")
const PLAYER_UID = "uid://54njlhvy4526"
const PLAYER_COLORS = [ Color.RED, Color.DEEP_SKY_BLUE, Color.GREEN, Color.HOT_PINK, Color.ORANGE ]

enum State { LOBBY, PLAYING }

#region host-only variables
@export var player_spawn_markers: Array[Marker3D]
@export var lobby_spawn_marker: Marker3D
@onready var _room_generator: Node = $RoomGenerator
@onready var _spawner: NodeSpawner = $NodeSpawner
var _connected_players: Array[int] = [1]
var _disconnected_players: Array[int]
var _living_players: Array[int]
var _spectators: Array[int]
var _player_colors: Dictionary[int, Color] = { 1: PLAYER_COLORS[0] }
var _state := State.LOBBY
var _current_cctv_camera: CCTVCamera
#endregion

var _max_power := 10
var _current_power: int
var _spectating := false


func _ready() -> void:
	UI.show()
	_room_generator.map_generation_finished.connect(_on_map_generation_finished)
	match MultiplayerManager.mode:
		MultiplayerManager.Mode.SINGLE_PLAYER:
			_host_setup()
		MultiplayerManager.Mode.LOCAL_HOST:
			if MultiplayerManager.host_local_lobby() != OK:
				_return_to_menu()
				return
			_host_setup()
		MultiplayerManager.Mode.LOCAL_CLIENT:
			if MultiplayerManager.join_local_lobby() != OK:
				_return_to_menu()
				return
			_client_setup()
		MultiplayerManager.Mode.STEAM_HOST:
			# TODO error handling
			MultiplayerManager.host_steam_lobby()
			_host_setup()
	#%LoadingScreen.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and event.keycode == KEY_ESCAPE:
		if UI.is_pause_menu_open():
			UI.close_pause_menu()
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			UI.open_pause_menu()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed("reset") and MultiplayerManager.mode == MultiplayerManager.Mode.SINGLE_PLAYER:
		get_tree().reload_current_scene()


func _client_setup() -> void:
	%StartButton.queue_free()


func _return_to_menu() -> void:
	multiplayer.multiplayer_peer.close()
	get_tree().change_scene_to_file.call_deferred("uid://0olohqhibl5v")


#region HOST-ONLY FUNCTIONS //////////////////////////////

func _host_setup() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	SignalBus.room_power_on_requested.connect(_on_room_power_on_requested)
	SignalBus.room_power_off_requested.connect(_on_room_power_off_requested)
	SignalBus.door_open_requested.connect(_on_door_open_requested)
	SignalBus.door_close_requested.connect(_on_door_close_requested)
	SignalBus.cctv_camera_change_requested.connect(_on_cctv_camera_change_requested)
	_add_player()
	%StartButton.pressed.connect(_start_round)


func _add_player(id := 1) -> void:
	_spawner.spawn({
		uid = PLAYER_UID,
		id = id,
		position = lobby_spawn_marker.global_position,
		rotation = lobby_spawn_marker.global_rotation,
		color = _player_colors[id],
	})


func _remove_player(id: int) -> void:
	if has_node(str(id)):
		get_node(str(id)).queue_free()


func _start_round() -> void:
	print("Starting round")
	_set_current_power.rpc(_max_power)
	_living_players = _connected_players
	_current_cctv_camera = null
	_room_generator.generate_map()
	
	# Teleport players into the starting room
	player_spawn_markers.shuffle()
	for i in _connected_players.size():
		var id := _connected_players[i]
		var pos := player_spawn_markers[i].global_position
		var rot := player_spawn_markers[i].global_rotation
		get_node(str(id)).set_global_transform_rpc.rpc_id(id, pos, rot)


func _on_peer_connected(id: int) -> void:
	_disconnected_players.erase(id)
	if id not in _connected_players:
		_connected_players.append(id)
	
	# Assign next available color when a new peer connects
	if id not in _player_colors:
		var color := mini(PLAYER_COLORS.size() - 1, _connected_players.size() + _disconnected_players.size() - 1)
		_player_colors[id] = PLAYER_COLORS[color]
	
	if _state == State.LOBBY:
		_add_player(id)
	else:
		if id not in _spectators:
			_spectators.append(id)
		if id not in _living_players:
			_become_spectator.rpc_id(id)


func _on_peer_disconnected(id: int) -> void:
	if _state == State.LOBBY or id in _living_players:
		_remove_player(id)
		_connected_players.erase(id)
		if id not in _disconnected_players:
			_disconnected_players.append(id)


func _on_room_power_on_requested(room: Room) -> void:
	if not room.is_powered and _current_power > 0:
		_set_current_power.rpc(_current_power - 1)
		room.power_on.rpc()


func _on_room_power_off_requested(room: Room) -> void:
	if room.is_powered and _current_power > 0:
		_set_current_power.rpc(_current_power - 1)
		room.power_off.rpc()


func _on_door_open_requested(door: Door) -> void:
	if not door.is_open and _current_power > 0:
		_set_current_power.rpc(_current_power - 1)
		door.open.rpc()


func _on_door_close_requested(door: Door) -> void:
	if door.is_open and _current_power > 0:
		_set_current_power.rpc(_current_power - 1)
		door.close.rpc()


func _on_cctv_camera_change_requested(new_camera: CCTVCamera) -> void:
	if new_camera != _current_cctv_camera:
		if new_camera.activated:
			new_camera.select.rpc()
		elif _current_power > 0:
			_set_current_power.rpc(_current_power - 1)
			new_camera.select.rpc()
		


#endregion ///////////////////////////////////////////

func _on_map_generation_finished() -> void:
	## Setup the screen when the map is fully loaded
	var screen := get_tree().get_first_node_in_group("screen") as Screen3D
	if screen:
		screen.turn_on()
	else:
		printerr("Screen not found")

#region RPCs /////////////////////////////////////////

@rpc("call_local")
func _set_current_power(value: int) -> void:
	_current_power = value
	UI.set_current_power(value)


@rpc("call_local")
func _set_max_power(value: int) -> void:
	_max_power = value
	UI.set_max_power(value)


## Called on clients that join mid-round
@rpc()
func _become_spectator() -> void:
	pass
	

#endregion ///////////////////////////////////////////
