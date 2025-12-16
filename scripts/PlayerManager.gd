# PlayerManager.gd
# Handles spawning and despawning of player nodes
# Works with MultiplayerSpawner for network replication

extends Node

## Scene to instantiate for each player
const PLAYER_SCENE := preload("res://scenes/Player.tscn")

## Spawn positions (can be customized per map)
var spawn_position := Vector2(400, 300)

## Container node for all players
@onready var players_container: Node = self


func _ready() -> void:
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)


func _on_player_connected(peer_id: int, player_data: Dictionary) -> void:
	if has_node(str(peer_id)):
		return

	var player := PLAYER_SCENE.instantiate()
	player.name = str(peer_id)

	player.set_multiplayer_authority(peer_id)

	var offset := Vector2(randf_range(-50, 50), randf_range(-50, 50))
	player.position = spawn_position + offset

	players_container.add_child(player, true)

	player.setup(peer_id, player_data.get("username", "Player"), player_data.get("character_id", 0))

	if peer_id == NetworkManager.get_my_id():
		NetworkManager.local_player = player

	print("[PlayerManager] Spawned player: ", player_data.get("username", "?"), " (", peer_id, ")")


func _on_player_disconnected(peer_id: int) -> void:
	var player_node := players_container.get_node_or_null(str(peer_id))
	if player_node:
		player_node.queue_free()
		print("[PlayerManager] Removed player: ", peer_id)


func get_all_players() -> Array[Node]:
	var result: Array[Node] = []
	for child in players_container.get_children():
		result.append(child)
	return result


func get_player(peer_id: int) -> Node:
	return players_container.get_node_or_null(str(peer_id))


func set_spawn_position(pos: Vector2) -> void:
	spawn_position = pos
