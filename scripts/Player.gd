# Player.gd
# Controls the player character: movement, collision, display
#
# MULTIPLAYER AUTHORITY:
# - Only the owning client can control their player (is_multiplayer_authority())
# - Position is synced via RPC to ensure host->client sync works
# - Visual updates (name, character sprite) are set once on spawn

extends CharacterBody2D

## Movement constants
const SPEED := 200.0
const ACCELERATION := 1200.0
const FRICTION := 1000.0

## Sync interval (send position updates every N physics frames)
const SYNC_INTERVAL := 2
var sync_counter := 0

## Player data (set on spawn)
var player_username: String = ""
var character_id: int = 0
var peer_id: int = 0

## Target position for interpolation (remote players)
var target_position: Vector2 = Vector2.ZERO

## References to child nodes
@onready var sprite: Sprite2D = $Sprite2D
@onready var name_label: Label = $NameLabel
@onready var mic_indicator: Sprite2D = $MicIndicator
@onready var speaking_indicator: Sprite2D = $SpeakingIndicator
@onready var camera: Camera2D = $Camera2D

## Character sprite textures (loaded on ready)
var character_textures: Array[Texture2D] = []

## Flag to track if setup has been called
var is_setup_complete: bool = false


func _ready() -> void:
	# Load character textures
	for i in range(1, 7):
		var tex := load("res://assets/sprites/characters/character_%d.png" % i) as Texture2D
		if tex:
			character_textures.append(tex)
	
	# Register with VoiceManager for proximity tracking
	VoiceManager.register_player(peer_id, self)
	
	# Connect to voice manager signals for this player
	VoiceManager.mic_toggled.connect(_on_mic_toggled)
	VoiceManager.speaking_changed.connect(_on_speaking_changed)
	
	# Camera setup is deferred to setup() when authority is known
	camera.enabled = false
	
	# Initialize target position
	target_position = position


func _exit_tree() -> void:
	VoiceManager.unregister_player(peer_id)


func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		# Local player: process input and move
		var input_dir := Vector2.ZERO
		input_dir.x = Input.get_axis("move_left", "move_right")
		input_dir.y = Input.get_axis("move_up", "move_down")
		input_dir = input_dir.normalized()
		
		# Apply acceleration or friction
		if input_dir != Vector2.ZERO:
			velocity = velocity.move_toward(input_dir * SPEED, ACCELERATION * delta)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		
		# Move and handle collisions
		move_and_slide()
		
		# Sync position to all other clients periodically
		sync_counter += 1
		if sync_counter >= SYNC_INTERVAL:
			sync_counter = 0
			_sync_position.rpc(position)
		
		# Check for mic toggle input
		if Input.is_action_just_pressed("toggle_mic"):
			VoiceManager.toggle_mic()
	else:
		# Remote player: interpolate to target position
		position = position.lerp(target_position, 15.0 * delta)


## RPC to sync position from authority to all peers
@rpc("authority", "call_remote", "unreliable_ordered")
func _sync_position(pos: Vector2) -> void:
	target_position = pos


## Initialize player with data from network
func setup(p_peer_id: int, p_username: String, p_character_id: int) -> void:
	peer_id = p_peer_id
	player_username = p_username
	character_id = p_character_id
	
	# Set multiplayer authority to the owning peer
	set_multiplayer_authority(p_peer_id)
	
	# Now check if this is local player and enable camera
	if is_multiplayer_authority():
		camera.enabled = true
		camera.make_current()
		print("[Player] Local player camera enabled for peer ", p_peer_id)
	else:
		camera.enabled = false
		print("[Player] Remote player (peer ", p_peer_id, ") - camera disabled")
	
	# Update visuals if nodes are ready
	if is_node_ready():
		_update_visuals()
	
	is_setup_complete = true
	target_position = position


## Update visual elements (sprite, name label)
func _update_visuals() -> void:
	# Set character sprite
	if character_id >= 0 and character_id < character_textures.size():
		sprite.texture = character_textures[character_id]
	
	# Set name label
	name_label.text = player_username
	
	# Initialize mic indicator state
	_update_mic_indicator()


## Update mic indicator visibility
func _update_mic_indicator() -> void:
	if not is_multiplayer_authority():
		# For remote players, show if they're speaking to us
		mic_indicator.visible = VoiceManager.is_player_in_range(peer_id)
		return
	
	# For local player, show mic state
	if VoiceManager.mic_enabled:
		mic_indicator.texture = load("res://assets/sprites/ui/mic_on.png")
		mic_indicator.visible = true
	else:
		mic_indicator.texture = load("res://assets/sprites/ui/mic_off.png")
		mic_indicator.visible = true


## Callback when mic is toggled
func _on_mic_toggled(_enabled: bool) -> void:
	if is_multiplayer_authority():
		_update_mic_indicator()


## Callback when speaking state changes
func _on_speaking_changed(speaking: bool) -> void:
	if is_multiplayer_authority():
		speaking_indicator.visible = speaking
