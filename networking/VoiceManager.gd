# VoiceManager.gd
# Autoload singleton for proximity-based voice chat
#
# HOW PROXIMITY DETECTION WORKS:
# 1. Every physics frame, we check distance from local player to all other players
# 2. If distance < VOICE_RANGE_NEAR, player is "in range" at full volume
# 3. If distance > VOICE_RANGE_FAR, player is "out of range" (no voice)
# 4. Between NEAR and FAR, volume fades linearly
# 5. Signals are emitted when players enter/exit voice range
#
# WHERE TO PLUG IN REAL VOICE CHAT:
# - For WebRTC: Create WebRTCPeerConnection per nearby player
# - For custom UDP: Use PacketPeerUDP to stream audio data
# - Audio capture: Use AudioStreamMicrophone + AudioEffectCapture
# - Audio playback: Create AudioStreamPlayer2D per remote player
#
# CURRENT IMPLEMENTATION:
# - Full proximity detection logic
# - Mic toggle state management
# - Speaking detection stub (based on mic input level)
# - Visual indicator states

extends Node

## Signals for voice state changes
signal player_entered_voice_range(peer_id: int)
signal player_exited_voice_range(peer_id: int)
signal mic_toggled(enabled: bool)
signal speaking_changed(is_speaking: bool)

## Voice range constants (in pixels)
const VOICE_RANGE_NEAR := 100.0  # Full volume within this range
const VOICE_RANGE_FAR := 200.0   # No voice beyond this range

## Speaking detection threshold (normalized 0-1)
const SPEAKING_THRESHOLD := 0.05

## State
var mic_enabled: bool = false
var is_speaking: bool = false

## Currently in-range players: { peer_id: volume_level (0-1) }
var players_in_range: Dictionary = {}

## Reference to local player (set by Player.gd)
var local_player: Node2D = null

## References to all player nodes: { peer_id: Node2D }
var player_nodes: Dictionary = {}

## Audio capture for mic input (stub - would need AudioEffectCapture)
var audio_capture: AudioEffectCapture = null

## Audio players for each remote player (stub)
var audio_players: Dictionary = {}  # { peer_id: AudioStreamPlayer2D }


func _ready() -> void:
	# Set up audio input capture (stub)
	_setup_audio_capture()


func _physics_process(_delta: float) -> void:
	if local_player == null:
		return
	
	_update_proximity()
	_update_speaking_state()


## Toggle microphone on/off
func toggle_mic() -> void:
	mic_enabled = not mic_enabled
	mic_toggled.emit(mic_enabled)
	
	if mic_enabled:
		_start_audio_capture()
	else:
		_stop_audio_capture()
		if is_speaking:
			is_speaking = false
			speaking_changed.emit(false)


## Set microphone state directly
func set_mic_enabled(enabled: bool) -> void:
	if mic_enabled != enabled:
		mic_enabled = enabled
		mic_toggled.emit(mic_enabled)
		
		if mic_enabled:
			_start_audio_capture()
		else:
			_stop_audio_capture()


## Register a player node for proximity tracking
func register_player(peer_id: int, player_node: Node2D) -> void:
	player_nodes[peer_id] = player_node
	
	# Check if this is the local player
	if peer_id == NetworkManager.get_my_id():
		local_player = player_node


## Unregister a player node
func unregister_player(peer_id: int) -> void:
	player_nodes.erase(peer_id)
	
	if players_in_range.has(peer_id):
		players_in_range.erase(peer_id)
		player_exited_voice_range.emit(peer_id)
	
	if audio_players.has(peer_id):
		audio_players[peer_id].queue_free()
		audio_players.erase(peer_id)


## Get the volume level for a specific player (0-1)
func get_player_volume(peer_id: int) -> float:
	return players_in_range.get(peer_id, 0.0)


## Check if a player is in voice range
func is_player_in_range(peer_id: int) -> bool:
	return players_in_range.has(peer_id) and players_in_range[peer_id] > 0.0


## Get list of all players currently in voice range
func get_nearby_players() -> Array[int]:
	var result: Array[int] = []
	for peer_id in players_in_range:
		if players_in_range[peer_id] > 0.0:
			result.append(peer_id)
	return result


## Update proximity for all players
func _update_proximity() -> void:
	var my_id := NetworkManager.get_my_id()
	var my_pos: Vector2 = local_player.global_position
	
	for peer_id in player_nodes:
		if peer_id == my_id:
			continue
		
		var other_player: Node2D = player_nodes[peer_id]
		if not is_instance_valid(other_player):
			continue
		
		var distance: float = my_pos.distance_to(other_player.global_position)
		var was_in_range: bool = players_in_range.has(peer_id) and players_in_range[peer_id] > 0.0
		
		# Calculate volume based on distance
		var volume: float = 0.0
		if distance <= VOICE_RANGE_NEAR:
			volume = 1.0
		elif distance >= VOICE_RANGE_FAR:
			volume = 0.0
		else:
			# Linear fade between NEAR and FAR
			volume = 1.0 - (distance - VOICE_RANGE_NEAR) / (VOICE_RANGE_FAR - VOICE_RANGE_NEAR)
		
		var is_in_range: bool = volume > 0.0
		
		# Update state and emit signals if changed
		if is_in_range and not was_in_range:
			players_in_range[peer_id] = volume
			player_entered_voice_range.emit(peer_id)
			_create_audio_player_for_peer(peer_id)
		elif not is_in_range and was_in_range:
			players_in_range.erase(peer_id)
			player_exited_voice_range.emit(peer_id)
			_remove_audio_player_for_peer(peer_id)
		elif is_in_range:
			players_in_range[peer_id] = volume
			_update_audio_player_volume(peer_id, volume)


## Update speaking state based on mic input level
func _update_speaking_state() -> void:
	if not mic_enabled:
		return
	
	# STUB: Get audio input level
	# In a real implementation, you would:
	# 1. Get the AudioEffectCapture from the mic bus
	# 2. Read audio frames and calculate RMS volume
	# 3. Compare against SPEAKING_THRESHOLD
	
	var input_level: float = _get_mic_input_level()
	var was_speaking := is_speaking
	is_speaking = input_level > SPEAKING_THRESHOLD
	
	if is_speaking != was_speaking:
		speaking_changed.emit(is_speaking)


## Setup audio capture for microphone input
func _setup_audio_capture() -> void:
	# STUB: In a real implementation:
	# 1. Add an AudioEffectCapture to the "Mic" audio bus
	# 2. Store reference for reading audio data
	# 3. Configure sample rate and buffer size
	#
	# Example (requires audio bus setup):
	# var mic_bus_idx = AudioServer.get_bus_index("Mic")
	# audio_capture = AudioServer.get_bus_effect(mic_bus_idx, 0) as AudioEffectCapture
	pass


## Start capturing audio from microphone
func _start_audio_capture() -> void:
	# STUB: In a real implementation:
	# 1. Create AudioStreamMicrophone and assign to AudioStreamPlayer
	# 2. Call audio_capture.clear_buffer()
	# 3. Start the audio stream
	#
	# Example:
	# var mic_stream = AudioStreamMicrophone.new()
	# var player = AudioStreamPlayer.new()
	# player.stream = mic_stream
	# player.bus = "Mic"
	# add_child(player)
	# player.play()
	print("[VoiceManager] Mic capture started (stub)")


## Stop capturing audio from microphone
func _stop_audio_capture() -> void:
	# STUB: Stop the AudioStreamPlayer with mic input
	print("[VoiceManager] Mic capture stopped (stub)")


## Get current microphone input level (0-1)
func _get_mic_input_level() -> float:
	# STUB: In a real implementation:
	# 1. Get audio frames from audio_capture.get_buffer()
	# 2. Calculate RMS (root mean square) of samples
	# 3. Return normalized value (0-1)
	#
	# Example:
	# if audio_capture:
	#     var frames = audio_capture.get_buffer(audio_capture.get_frames_available())
	#     var sum_squares = 0.0
	#     for frame in frames:
	#         sum_squares += frame.x * frame.x + frame.y * frame.y
	#     var rms = sqrt(sum_squares / max(frames.size(), 1))
	#     return clamp(rms * 10.0, 0.0, 1.0)  # Scale factor may need tuning
	return 0.0


## Create an AudioStreamPlayer2D for a remote player
func _create_audio_player_for_peer(peer_id: int) -> void:
	# STUB: In a real implementation with WebRTC:
	# 1. Create AudioStreamPlayer2D
	# 2. Attach to the player node for spatial audio
	# 3. Connect to WebRTC audio track
	#
	# For now, we just track that they're in range
	print("[VoiceManager] Player %d entered voice range" % peer_id)


## Remove the AudioStreamPlayer2D for a remote player
func _remove_audio_player_for_peer(peer_id: int) -> void:
	if audio_players.has(peer_id):
		audio_players[peer_id].queue_free()
		audio_players.erase(peer_id)
	print("[VoiceManager] Player %d exited voice range" % peer_id)


## Update volume for a remote player's audio
func _update_audio_player_volume(peer_id: int, volume: float) -> void:
	if audio_players.has(peer_id):
		# Convert linear volume to decibels
		var db := linear_to_db(volume)
		audio_players[peer_id].volume_db = db
