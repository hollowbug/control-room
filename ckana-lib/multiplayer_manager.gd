extends Node

enum Mode {SINGLE_PLAYER, LOCAL_HOST, LOCAL_CLIENT, STEAM_HOST, STEAM_CLIENT}
enum State {DEFAULT, CREATING_STEAM_LOBBY, JOINING_STEAM_LOBBY}

signal connection_result(result: Error)
signal connection_lost()
signal steam_lobby_code_set(code: String)

const PORT = 8000

var mode := Mode.SINGLE_PLAYER
var error: Error
var lobby_id := 0
var lobby_code: String
var peer: MultiplayerPeer = OfflineMultiplayerPeer.new()
var is_steam_initialized := false
var is_host := false
var state := State.DEFAULT


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	is_steam_initialized = Steam.steamInit(480, true)
	print("Steam initialized: ", is_steam_initialized)
	if is_steam_initialized:
		Steam.initRelayNetworkAccess()
		Steam.lobby_created.connect(_on_steam_lobby_created)
		Steam.lobby_match_list.connect(_on_steam_lobby_match_list)
		Steam.lobby_joined.connect(_on_steam_lobby_joined)
		Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)


func host_local_lobby() -> Error:
	peer = ENetMultiplayerPeer.new()
	error = peer.create_server(PORT)
	if error == OK:
		print("Created local lobby")
		multiplayer.multiplayer_peer = peer
	else:
		print("Error creating local lobby: ", error_string(error))
	return error


func join_local_lobby() -> Error:
	peer = ENetMultiplayerPeer.new()
	error = peer.create_client("127.0.0.1", PORT)
	if error == OK:
		print("Joined local lobby")
		multiplayer.multiplayer_peer = peer
	else:
		print("Error joining local lobby: ", error_string(error))
	return error


func host_steam_lobby() -> void:
	state = State.CREATING_STEAM_LOBBY
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 16)
	is_host = true


func join_steam_lobby(join_code: String) -> void:
	state = State.JOINING_STEAM_LOBBY
	lobby_code = join_code
	_initiate_steam_lobby_connection()


func _on_steam_lobby_created(result: int, id: int) -> void:
	if result == Steam.RESULT_OK:
		Steam.requestLobbyList()
		lobby_id = id
		peer = SteamMultiplayerPeer.new()
		peer.server_relay = true
		error = peer.create_host()
		if error == OK:
			multiplayer.multiplayer_peer = peer
			_initiate_steam_lobby_connection()
			print("Created Steam lobby: ", lobby_id)
		connection_result.emit(error)
	else:
		connection_result.emit(result)


func _on_steam_lobby_match_list(lobbies: Array) -> void:
	print("Steam.lobby_match_list received")
	print("State: %s" % State.find_key(state))
	if state == State.CREATING_STEAM_LOBBY:
		state = State.DEFAULT
		# Assign a random join code when creating a lobby,
		# and ensure it doesn't clash with an existing one
		var codes := PackedStringArray()
		for id: int in lobbies:
			codes.append(Steam.getLobbyData(id, "join_code"))
		while true:
			lobby_code = "%05d" % (randi() % 10_000)
			if lobby_code not in codes: break
		print("Attempting to set 'join_code' to %s for lobby %d" % [lobby_code, lobby_id])
		if Steam.setLobbyData(lobby_id, "join_code", lobby_code):
			print("Success")
			steam_lobby_code_set.emit(lobby_code)
	elif state == State.JOINING_STEAM_LOBBY:
		for id: int in lobbies:
			if Steam.getLobbyData(id, "join_code") == lobby_code:
				Steam.joinLobby(id)


func _on_steam_lobby_joined(id: int, _permissions: int, _locked: bool, response: int) -> void:
	if state != State.JOINING_STEAM_LOBBY: return
	if response == Steam.RESULT_OK:
		state = State.DEFAULT
		lobby_id = id
		print("Joined Steam lobby: ", lobby_id)
		peer = SteamMultiplayerPeer.new()
		peer.create_client(Steam.getLobbyOwner(id))
		error = peer.connect_to_lobby(id)
		connection_result.emit(error)
		multiplayer.multiplayer_peer = peer
	else:
		connection_result.emit(response)


func _initiate_steam_lobby_connection() -> void:
	Steam.requestLobbyList()
	await get_tree().create_timer(2.5).timeout
	print("State after await: ", State.find_key(state))
	if state != State.DEFAULT:
		connection_result.emit(ERR_TIMEOUT)
