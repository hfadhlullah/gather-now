# PlayerManager.gd
# Handles spawning and despawning of player nodes
# Works with MultiplayerSpawner for network replication

extends Node

## Scene to instantiate for each player
const PLAYER_SCENE := preload("res://scenes/Player.tscn")

## Container node for all players
@onready var players_container: Node = self

## Spawn positions (can be customized per map)
var spawn_position := Vector2(400, 300)


func _ready() -> void:
	# Connect to NetworkManager signals
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)


## Spawn a player for the given peer
func _on_player_connected(peer_id: int, player_data: Dictionary) -> void:
	# Don't spawn if already exists
	if has_node(str(peer_id)):
		return
	
	var player := PLAYER_SCENE.instantiate()
	player.name = str(peer_id)
	
	# Set authority BEFORE adding to tree
	player.set_multiplayer_authority(peer_id)
	
	# Set initial position
	var offset := Vector2(randf_range(-50, 50), randf_range(-50, 50))
	player.position = spawn_position + offset
	
	# Add to scene tree
	players_container.add_child(player, true)
	
	# Setup player data
	player.setup(
		peer_id,
		player_data.get("username", "Player"),
		player_data.get("character_id", 0)
	)
	
	# Store reference if this is local player
	if peer_id == NetworkManager.get_my_id():
		NetworkManager.local_player = player
	
	print("[PlayerManager] Spawned player: ", player_data.get("username", "?"), " (", peer_id, ")")


## Remove a player when they disconnect
func _on_player_disconnected(peer_id: int) -> void:
	var player_node := players_container.get_node_or_null(str(peer_id))
	if player_node:
		player_node.queue_free()
		print("[PlayerManager] Removed player: ", peer_id)


## Get all current player nodes
func get_all_players() -> Array[Node]:
	var result: Array[Node] = []
	for child in players_container.get_children():
		result.append(child)
	return result


## Get a specific player node by peer ID
func get_player(peer_id: int) -> Node:
	return players_container.get_node_or_null(str(peer_id))


## Set spawn position (called when loading a map)
func set_spawn_position(pos: Vector2) -> void:
	spawn_position = pos
