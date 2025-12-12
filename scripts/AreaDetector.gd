# AreaDetector.gd
# Detects which named area the player is currently in
# Uses Area2D overlap detection

extends Node

## Signal emitted when player enters a new area
signal area_changed(area_name: String)

## Current area name (empty if not in any named area)
var current_area: String = ""

## Reference to the local player
var local_player: CharacterBody2D = null


func _ready() -> void:
	# Wait for player to spawn
	await get_tree().create_timer(0.5).timeout
	_find_local_player()


func _find_local_player() -> void:
	if NetworkManager.local_player:
		local_player = NetworkManager.local_player
	else:
		# Retry if player not spawned yet
		await get_tree().create_timer(0.5).timeout
		_find_local_player()


## Called by Area2D zones when player enters
func on_area_entered(area_name: String) -> void:
	if current_area != area_name:
		current_area = area_name
		area_changed.emit(area_name)
		print("[AreaDetector] Entered: ", area_name)


## Called by Area2D zones when player exits
func on_area_exited(area_name: String) -> void:
	if current_area == area_name:
		current_area = ""
		area_changed.emit("")
		print("[AreaDetector] Exited: ", area_name)


## Get the current area name
func get_current_area() -> String:
	return current_area
