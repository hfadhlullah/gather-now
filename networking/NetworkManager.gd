# NetworkManager.gd
# Autoload singleton for handling multiplayer networking
# Uses Godot's High-Level Multiplayer API with ENet (reliable UDP)
#
# NETWORKING FLOW:
# 1. Server calls create_server() to host on a port
# 2. Clients call join_server(ip, port) to connect
# 3. On connection, client sends username + character via RPC
# 4. Server validates username uniqueness
# 5. Server broadcasts player data to all clients
# 6. MultiplayerSpawner handles spawning replicated Player nodes
# 7. MultiplayerSynchronizer handles position syncing

extends Node

## Signals for UI to react to network events
signal connection_succeeded
signal connection_failed(reason: String)
signal server_started
signal player_connected(peer_id: int, player_data: Dictionary)
signal player_disconnected(peer_id: int)
signal username_rejected(reason: String)

## Default network settings
const DEFAULT_PORT := 7777
const MAX_CLIENTS := 16

## Stores all connected players: { peer_id: { username, character_id, position } }
var players: Dictionary = {}

## Local player data (set before connecting)
var local_username: String = ""
var local_character_id: int = 0

## Reference to the spawned local player node
var local_player: Node = null

## Track if we're the server
var is_server: bool = false


func _ready() -> void:
	# Connect multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


## Create and host a server on the given port
func create_server(port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, MAX_CLIENTS)
	
	if error != OK:
		connection_failed.emit("Failed to create server on port %d" % port)
		return error
	
	multiplayer.multiplayer_peer = peer
	is_server = true
	
	# Register self as player on server
	var my_id := multiplayer.get_unique_id()
	players[my_id] = {
		"username": local_username,
		"character_id": local_character_id,
		"position": Vector2.ZERO
	}
	
	server_started.emit()
	player_connected.emit(my_id, players[my_id])
	print("[Server] Started on port ", port)
	return OK


## Join an existing server at ip:port
func join_server(ip: String, port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(ip, port)
	
	if error != OK:
		connection_failed.emit("Failed to connect to %s:%d" % [ip, port])
		return error
	
	multiplayer.multiplayer_peer = peer
	is_server = false
	print("[Client] Connecting to ", ip, ":", port)
	return OK


## Disconnect from the current session
func disconnect_from_server() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	players.clear()
	is_server = false


## Called when we successfully connect to server (client only)
func _on_connected_to_server() -> void:
	print("[Client] Connected to server!")
	# Request to join with our credentials
	_request_join.rpc_id(1, local_username, local_character_id)


## Called when connection to server fails (client only)
func _on_connection_failed() -> void:
	connection_failed.emit("Could not connect to server")
	multiplayer.multiplayer_peer = null


## Called when disconnected from server (client only)
func _on_server_disconnected() -> void:
	connection_failed.emit("Disconnected from server")
	players.clear()
	multiplayer.multiplayer_peer = null


## Called when any peer connects (server sees new clients, clients see each other)
func _on_peer_connected(peer_id: int) -> void:
	print("[Network] Peer connected: ", peer_id)


## Called when any peer disconnects
func _on_peer_disconnected(peer_id: int) -> void:
	print("[Network] Peer disconnected: ", peer_id)
	if players.has(peer_id):
		players.erase(peer_id)
		player_disconnected.emit(peer_id)


## RPC: Client requests to join with username and character
## Only the server processes this
@rpc("any_peer", "reliable")
func _request_join(username: String, character_id: int) -> void:
	if not multiplayer.is_server():
		return
	
	var sender_id := multiplayer.get_remote_sender_id()
	
	# Validate username uniqueness
	for peer_id in players:
		if players[peer_id].username == username:
			_reject_join.rpc_id(sender_id, "Username '%s' is already taken" % username)
			return
	
	# Username is valid, register the player
	var player_data := {
		"username": username,
		"character_id": character_id,
		"position": Vector2.ZERO
	}
	players[sender_id] = player_data
	
	# Notify the new client they're accepted and send existing players
	_accept_join.rpc_id(sender_id, players)
	
	# Notify all other clients about the new player
	_on_player_joined.rpc(sender_id, player_data)
	
	player_connected.emit(sender_id, player_data)
	print("[Server] Player joined: ", username, " (", sender_id, ")")


## RPC: Server rejects join request
@rpc("authority", "reliable")
func _reject_join(reason: String) -> void:
	username_rejected.emit(reason)
	connection_failed.emit(reason)
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null


## RPC: Server accepts join and sends all current players
@rpc("authority", "reliable")
func _accept_join(all_players: Dictionary) -> void:
	players = all_players
	connection_succeeded.emit()
	
	# Emit signals for each existing player
	for peer_id in players:
		player_connected.emit(peer_id, players[peer_id])
	
	print("[Client] Joined! Players: ", players.keys())


## RPC: Broadcast to all clients that a new player joined
@rpc("authority", "reliable", "call_local")
func _on_player_joined(peer_id: int, player_data: Dictionary) -> void:
	if not players.has(peer_id):
		players[peer_id] = player_data
		player_connected.emit(peer_id, player_data)


## Get player data by peer ID
func get_player_data(peer_id: int) -> Dictionary:
	return players.get(peer_id, {})


## Get our own peer ID
func get_my_id() -> int:
	if multiplayer.multiplayer_peer:
		return multiplayer.get_unique_id()
	return 0


## Check if a username is available (server-side check for UI feedback)
func is_username_available(username: String) -> bool:
	for peer_id in players:
		if players[peer_id].username == username:
			return false
	return true
