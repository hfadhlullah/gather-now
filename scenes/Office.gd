# Office.gd
# Office map script - handles area detection setup and floor generation

extends Node2D

## Spawn position for new players
@export var spawn_position := Vector2(400, 300)

## Floor tile size
const TILE_SIZE := 32

## Area definitions for floor generation
var lobby_rect := Rect2(32, 32, 448, 536)
var meeting_rect := Rect2(544, 32, 448, 224)
var lounge_rect := Rect2(544, 320, 448, 248)

## Reference to AreaDetector
var area_detector: Node


func _ready() -> void:
	# Generate floors for each area
	_generate_floor($FloorLayers/LobbyFloor, lobby_rect, "res://assets/sprites/floors/floor_000.png")
	_generate_floor($FloorLayers/MeetingRoomFloor, meeting_rect, "res://assets/sprites/floors/floor_064.png")
	_generate_floor($FloorLayers/LoungeFloor, lounge_rect, "res://assets/sprites/floors/floor_128.png")
	
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


func _generate_floor(container: Node2D, rect: Rect2, tile_path: String) -> void:
	var texture := load(tile_path) as Texture2D
	if not texture:
		push_error("Could not load floor texture: " + tile_path)
		return
	
	var cols := int(rect.size.x / TILE_SIZE)
	var rows := int(rect.size.y / TILE_SIZE)
	
	for row in range(rows):
		for col in range(cols):
			var sprite := Sprite2D.new()
			sprite.texture = texture
			sprite.centered = false
			sprite.position = Vector2(rect.position.x + col * TILE_SIZE, rect.position.y + row * TILE_SIZE)
			container.add_child(sprite)


func _on_area_body_entered(body: Node2D, area_name: String) -> void:
	# Check if this is the local player
	if body == NetworkManager.local_player:
		if area_detector and area_detector.has_method("on_area_entered"):
			area_detector.on_area_entered(area_name)


func _on_area_body_exited(body: Node2D, area_name: String) -> void:
	if body == NetworkManager.local_player:
		if area_detector and area_detector.has_method("on_area_exited"):
			area_detector.on_area_exited(area_name)
