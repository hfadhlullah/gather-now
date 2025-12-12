# Office.gd
# Office map script - handles area detection setup

extends Node2D

## Spawn position for new players
@export var spawn_position := Vector2(400, 300)

## Reference to AreaDetector
var area_detector: Node


func _ready() -> void:
	# Find or create area detector
	area_detector = get_tree().get_first_node_in_group("area_detector")
	
	# Connect all area zones to the detector
	for area in get_tree().get_nodes_in_group("named_area"):
		if area is Area2D:
			area.body_entered.connect(_on_area_body_entered.bind(area.name))
			area.body_exited.connect(_on_area_body_exited.bind(area.name))
	
	# Set spawn position in PlayerManager if it exists
	var player_manager := get_tree().get_first_node_in_group("player_manager")
	if player_manager and player_manager.has_method("set_spawn_position"):
		player_manager.set_spawn_position(spawn_position)


func _on_area_body_entered(body: Node2D, area_name: String) -> void:
	# Check if this is the local player
	if body == NetworkManager.local_player:
		if area_detector and area_detector.has_method("on_area_entered"):
			area_detector.on_area_entered(area_name)


func _on_area_body_exited(body: Node2D, area_name: String) -> void:
	if body == NetworkManager.local_player:
		if area_detector and area_detector.has_method("on_area_exited"):
			area_detector.on_area_exited(area_name)
