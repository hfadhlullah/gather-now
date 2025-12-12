# Main.gd
# Entry point scene - manages screen flow and game state
#
# SCREEN FLOW:
# 1. LoginScreen -> enter username
# 2. CharacterSelect -> pick character
# 3. HostJoinMenu -> host or join game
# 4. Game (Office map + HUD)

extends Node

## Screen states
enum GameState {
	LOGIN,
	CHARACTER_SELECT,
	HOST_JOIN,
	PLAYING
}

## Current state
var current_state: GameState = GameState.LOGIN

## Loaded screen scenes
var login_screen_scene := preload("res://ui/LoginScreen.tscn")
var character_select_scene := preload("res://ui/CharacterSelect.tscn")
var host_join_scene := preload("res://ui/HostJoinMenu.tscn")
var game_hud_scene := preload("res://ui/GameHUD.tscn")
var office_scene := preload("res://scenes/Office.tscn")

## Current screen instance
var current_screen: Control = null

## Game world and HUD
var game_world: Node2D = null
var game_hud: CanvasLayer = null

## References
@onready var ui_layer: CanvasLayer = $UILayer
@onready var game_container: Node2D = $GameContainer
@onready var player_manager: Node = $PlayerManager
@onready var area_detector: Node = $AreaDetector


func _ready() -> void:
	# Start at login screen
	_change_state(GameState.LOGIN)


## Change to a new game state
func _change_state(new_state: GameState) -> void:
	# Clean up current screen
	if current_screen:
		current_screen.queue_free()
		current_screen = null
	
	current_state = new_state
	
	match new_state:
		GameState.LOGIN:
			_show_login_screen()
		GameState.CHARACTER_SELECT:
			_show_character_select()
		GameState.HOST_JOIN:
			_show_host_join_menu()
		GameState.PLAYING:
			_start_game()


func _show_login_screen() -> void:
	current_screen = login_screen_scene.instantiate()
	ui_layer.add_child(current_screen)
	current_screen.login_completed.connect(_on_login_completed)


func _show_character_select() -> void:
	current_screen = character_select_scene.instantiate()
	ui_layer.add_child(current_screen)
	current_screen.character_selected.connect(_on_character_selected)


func _show_host_join_menu() -> void:
	current_screen = host_join_scene.instantiate()
	ui_layer.add_child(current_screen)
	current_screen.host_started.connect(_on_host_started)
	current_screen.join_started.connect(_on_join_started)
	current_screen.back_pressed.connect(_on_back_pressed)


func _start_game() -> void:
	# Load the game world
	game_world = office_scene.instantiate()
	game_container.add_child(game_world)
	
	# Add the HUD
	game_hud = game_hud_scene.instantiate()
	add_child(game_hud)
	
	print("[Main] Game started!")


## Callbacks

func _on_login_completed(username: String) -> void:
	print("[Main] Logged in as: ", username)
	_change_state(GameState.CHARACTER_SELECT)


func _on_character_selected(character_id: int) -> void:
	print("[Main] Selected character: ", character_id)
	_change_state(GameState.HOST_JOIN)


func _on_host_started() -> void:
	print("[Main] Hosting game...")
	_change_state(GameState.PLAYING)


func _on_join_started() -> void:
	print("[Main] Joined game...")
	_change_state(GameState.PLAYING)


func _on_back_pressed() -> void:
	_change_state(GameState.CHARACTER_SELECT)


## Disconnect and return to menu
func disconnect_and_return() -> void:
	# Clean up game
	if game_world:
		game_world.queue_free()
		game_world = null
	
	if game_hud:
		game_hud.queue_free()
		game_hud = null
	
	# Disconnect from network
	NetworkManager.disconnect_from_server()
	
	# Return to login
	_change_state(GameState.LOGIN)
