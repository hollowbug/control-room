extends Node

enum Mode {SINGLE_PLAYER, LOCAL_HOST, LOCAL_CLIENT, STEAM_HOST, STEAM_CLIENT}

const PORT = 8000

var mode := Mode.SINGLE_PLAYER
var error: Error
var lobby_id := 0
var peer: MultiplayerPeer = OfflineMultiplayerPeer.new()
var is_host := false


func _ready() -> void:
	var initialized := Steam.steamInit(480, true)
	print("Steam initialized: ", initialized)
	if initialized:
		Steam.initRelayNetworkAccess()
		Steam.lobby_created.connect(_on_steam_lobby_created)


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
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 16)
	is_host = true


func _on_steam_lobby_created(result: int, id: int) -> void:
	if result == Steam.RESULT_OK:
		lobby_id = id
		peer = SteamMultiplayerPeer.new()
		peer.server_relay = true
		peer.create_host()
		multiplayer.multiplayer_peer = peer
