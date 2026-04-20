extends Node

const RoomGenerator = preload("uid://bc204rjvbei42")
const StartButton = preload("uid://vdx11c47or")
const PLAYER_SCENE = preload("uid://54njlhvy4526")

enum State { LOBBY, PLAYING }

@export var player_spawn_markers: Array[Marker3D]
@export var lobby_spawn_marker: Marker3D

@onready var _room_generator: Node = $RoomGenerator
@onready var _spawner: MultiplayerSpawner = $MultiplayerSpawner
var _next_player_spawn_marker := 0
var _connected_players: Array[int] = [1]
var _disconnected_players: Array[int]
var _field_agents: Array[int]
var _spectators: Array[int]
var _state := State.LOBBY


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	UI.show()
	_spawner.spawn_function = _spawn_node
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


func _host_setup() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	_add_player()
	%StartButton.pressed.connect(_start_game)


func _client_setup() -> void:
	%StartButton.queue_free()


func _return_to_menu() -> void:
	get_tree().change_scene_to_file.call_deferred("uid://0olohqhibl5v")


func _on_peer_connected(id: int) -> void:
	if _state == State.LOBBY:
		_add_player(id)


func _on_peer_disconnected(id: int) -> void:
	if _state == State.LOBBY or id in _field_agents:
		_remove_player(id)


func _spawn_node(data: Variant) -> Node:
	var dict := data as Dictionary
	if not dict: return
	match dict.get("type"):
		"player": 
			var player := PLAYER_SCENE.instantiate() as Player
			if player:
				player.name = str(dict.get("id", 0))
				player.position = dict.get("position", Vector3())
				return player
	return null


func _add_player(id := 1) -> void:
	_spawner.spawn({
		type = "player",
		id = id,
		position = lobby_spawn_marker.global_position,
	})


func _remove_player(id: int) -> void:
	if has_node(str(id)):
		get_node(str(id)).queue_free()


func _start_game() -> void:
	print("Starting round")
	_field_agents = _connected_players
	_room_generator.generate_map()
	player_spawn_markers.shuffle()
	for i in _connected_players.size():
		var id := _connected_players[i]
		var pos := player_spawn_markers[i].global_position
		get_node(str(id)).set_global_position_rpc.rpc_id(id, pos)
