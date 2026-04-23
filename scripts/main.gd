extends Node

const RoomGenerator = preload("uid://bc204rjvbei42")
const StartButton = preload("uid://vdx11c47or")
const ControlRoomScreen = preload("uid://7qvord22my3h")
const PLAYER_UID = "uid://54njlhvy4526"

enum State { LOBBY, PLAYING }

@export var player_spawn_markers: Array[Marker3D]
@export var lobby_spawn_marker: Marker3D

@onready var _room_generator: Node = $RoomGenerator
@onready var _spawner: NodeSpawner = $NodeSpawner
var _connected_players: Array[int] = [1]
var _disconnected_players: Array[int]
var _living_players: Array[int]
var _spectators: Array[int]
var _state := State.LOBBY
var _max_power := 10
var _current_power: int


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


func _input(event: InputEvent) -> void:
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
	_add_player()
	%StartButton.pressed.connect(_start_round)


func _on_peer_connected(id: int) -> void:
	if _state == State.LOBBY:
		_add_player(id)
		if id not in _connected_players:
			_connected_players.append(id)
	elif id not in _spectators:
		_spectators.append(id)


func _on_peer_disconnected(id: int) -> void:
	if _state == State.LOBBY or id in _living_players:
		_remove_player(id)
		_connected_players.erase(id)
		if id not in _disconnected_players:
			_disconnected_players.append(id)


func _add_player(id := 1) -> void:
	_spawner.spawn({
		uid = PLAYER_UID,
		id = id,
		position = lobby_spawn_marker.global_position,
		rotation = lobby_spawn_marker.global_rotation
	})


func _remove_player(id: int) -> void:
	if has_node(str(id)):
		get_node(str(id)).queue_free()


func _start_round() -> void:
	print("Starting round")
	_set_current_power.rpc(_max_power)
	_living_players = _connected_players
	_room_generator.generate_map()
	
	# Teleport players into the starting room
	player_spawn_markers.shuffle()
	for i in _connected_players.size():
		var id := _connected_players[i]
		var pos := player_spawn_markers[i].global_position
		var rot := player_spawn_markers[i].global_rotation
		get_node(str(id)).set_global_transform_rpc.rpc_id(id, pos, rot)

#endregion ///////////////////////////////////////////

func _on_map_generation_finished() -> void:
	## Setup the screen when the map is fully loaded
	var screen := get_tree().get_first_node_in_group("screen") as ControlRoomScreen
	if screen:
		screen.turn_on()
	else:
		printerr("Screen not found")

#region RPCs /////////////////////////////////////////

@rpc("reliable", "call_local")
func _set_current_power(value: int) -> void:
	_current_power = value
	UI.set_current_power(value)


@rpc("reliable", "call_local")
func _set_max_power(value: int) -> void:
	_max_power = value
	UI.set_max_power(value)

#endregion ///////////////////////////////////////////
