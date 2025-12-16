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

## Player data (set on spawn)
var player_username: String = ""
var character_id: int = 0
var peer_id: int = 0

## Target position for interpolation (remote players)
var target_position: Vector2 = Vector2.ZERO

## Sync counter
var sync_counter := 0

## Character sprite textures (loaded on ready)
var character_textures: Array[Texture2D] = []

## Flag to track if setup has been called
var is_setup_complete: bool = false

## Whether player input is enabled (disabled when modal overlays are open)
var input_enabled: bool = true

## References to child nodes
@onready var sprite: Sprite2D = $Sprite2D
@onready var name_label: Label = $NameContainer/NameLabel
@onready var mic_indicator: Sprite2D = $MicContainer/MicIndicator
@onready var speaking_indicator: Sprite2D = $SpeakingIndicator
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	for i in range(1, 7):
		var tex := load("res://assets/sprites/characters/character_%d.png" % i) as Texture2D
		if tex:
			character_textures.append(tex)

	VoiceManager.mic_toggled.connect(_on_mic_toggled)
	VoiceManager.speaking_changed.connect(_on_speaking_changed)

	camera.enabled = false
	target_position = position


func _exit_tree() -> void:
	VoiceManager.unregister_player(peer_id)


func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		var input_dir := Vector2.ZERO

		# Only process input if enabled (disabled during modal overlays)
		if input_enabled:
			input_dir.x = Input.get_axis("move_left", "move_right")
			input_dir.y = Input.get_axis("move_up", "move_down")
			input_dir = input_dir.normalized()

		if input_dir != Vector2.ZERO:
			velocity = velocity.move_toward(input_dir * SPEED, ACCELERATION * delta)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

		move_and_slide()

		sync_counter += 1
		if sync_counter >= SYNC_INTERVAL:
			sync_counter = 0
			_sync_position.rpc(position)

		if Input.is_action_just_pressed("toggle_mic"):
			VoiceManager.toggle_mic()
	else:
		position = position.lerp(target_position, 15.0 * delta)


@rpc("authority", "call_remote", "unreliable_ordered")
func _sync_position(pos: Vector2) -> void:
	target_position = pos


func setup(p_peer_id: int, p_username: String, p_character_id: int) -> void:
	peer_id = p_peer_id
	player_username = p_username
	character_id = p_character_id

	set_multiplayer_authority(p_peer_id)

	if is_multiplayer_authority():
		camera.enabled = true
		camera.make_current()
		print("[Player] Local player camera enabled for peer ", p_peer_id)
	else:
		camera.enabled = false
		print("[Player] Remote player (peer ", p_peer_id, ") - camera disabled")

	VoiceManager.register_player(peer_id, self)

	if is_node_ready():
		_update_visuals()

	is_setup_complete = true
	target_position = position


func _update_visuals() -> void:
	if character_id >= 0 and character_id < character_textures.size():
		sprite.texture = character_textures[character_id]

	name_label.text = player_username
	_update_mic_indicator()


func _update_mic_indicator() -> void:
	if not is_multiplayer_authority():
		mic_indicator.visible = VoiceManager.is_player_in_range(peer_id)
		return

	if VoiceManager.mic_enabled:
		mic_indicator.texture = load("res://assets/sprites/ui/mic_on.png")
		mic_indicator.visible = true
	else:
		mic_indicator.texture = load("res://assets/sprites/ui/mic_off.png")
		mic_indicator.visible = true


func _on_mic_toggled(_enabled: bool) -> void:
	if is_multiplayer_authority():
		_update_mic_indicator()


func _on_speaking_changed(speaking: bool) -> void:
	if is_multiplayer_authority():
		speaking_indicator.visible = speaking


## Enable or disable player input (used by WhiteboardManager for modal overlays)
func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
