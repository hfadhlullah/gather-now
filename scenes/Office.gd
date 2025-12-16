# Office.gd
# Office map script - handles area detection setup and floor generation

extends Node2D

## Floor tile size
const TILE_SIZE := 32

## Spawn position for new players
@export var spawn_position := Vector2(400, 300)

## Texture reference for floor patterns
var floor_texture: Texture2D

## Area definitions for floor generation (position and size in pixels)
var lobby_rect := Rect2(32, 32, 448, 536)
var meeting_rect := Rect2(544, 32, 448, 224)
var lounge_rect := Rect2(544, 320, 448, 248)

## Texture regions from FloorAndGround.png (x, y positions of 32x32 tiles)
var lobby_tile_region := Rect2(0, 0, 32, 32)
var meeting_tile_region := Rect2(32, 0, 32, 32)
var lounge_tile_region := Rect2(64, 0, 32, 32)

## Reference to AreaDetector
var area_detector: Node


func _ready() -> void:
	floor_texture = load("res://assets/maps/tilesets/FloorAndGround.png")

	var lobby_floor_tex = load("res://assets/sprites/floor/floor1.png")

	_generate_floor_with_texture($FloorLayers/LobbyFloor, lobby_rect, lobby_floor_tex)
	_generate_floor($FloorLayers/MeetingRoomFloor, meeting_rect, meeting_tile_region)
	_generate_floor($FloorLayers/LoungeFloor, lounge_rect, lounge_tile_region)

	area_detector = get_tree().get_first_node_in_group("area_detector")

	for area in get_tree().get_nodes_in_group("named_area"):
		if area is Area2D:
			area.body_entered.connect(_on_area_body_entered.bind(area.name))
			area.body_exited.connect(_on_area_body_exited.bind(area.name))

	var player_manager := get_tree().get_first_node_in_group("player_manager")
	if player_manager and player_manager.has_method("set_spawn_position"):
		player_manager.set_spawn_position(spawn_position)


func _generate_floor(container: Node2D, rect: Rect2, tile_region: Rect2) -> void:
	if not floor_texture:
		push_error("Floor texture not loaded!")
		return

	var atlas_tex := AtlasTexture.new()
	atlas_tex.atlas = floor_texture
	atlas_tex.region = tile_region

	var cols := int(rect.size.x / TILE_SIZE)
	var rows := int(rect.size.y / TILE_SIZE)

	for row in range(rows):
		for col in range(cols):
			var sprite := Sprite2D.new()
			sprite.texture = atlas_tex
			sprite.centered = false
			sprite.position = Vector2(
				rect.position.x + col * TILE_SIZE, rect.position.y + row * TILE_SIZE
			)
			container.add_child(sprite)


func _generate_floor_with_texture(container: Node2D, rect: Rect2, tex: Texture2D) -> void:
	if not tex:
		push_error("Texture not provided!")
		return

	var tex_size := tex.get_size()
	var cols := int(rect.size.x / tex_size.x) + 1
	var rows := int(rect.size.y / tex_size.y) + 1

	for row in range(rows):
		for col in range(cols):
			var sprite := Sprite2D.new()
			sprite.texture = tex
			sprite.centered = false
			sprite.position = Vector2(
				rect.position.x + col * tex_size.x, rect.position.y + row * tex_size.y
			)
			container.add_child(sprite)


func _on_area_body_entered(body: Node2D, area_name: String) -> void:
	if body == NetworkManager.local_player:
		if area_detector and area_detector.has_method("on_area_entered"):
			area_detector.on_area_entered(area_name)


func _on_area_body_exited(body: Node2D, area_name: String) -> void:
	if body == NetworkManager.local_player:
		if area_detector and area_detector.has_method("on_area_exited"):
			area_detector.on_area_exited(area_name)
