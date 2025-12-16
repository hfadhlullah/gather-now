# WhiteboardManager.gd
# Manages the embedded Excalidraw whiteboard state
# Handles area-based availability and input blocking

extends Node

## Emitted when whiteboard becomes available (player enters Meeting Room)
signal whiteboard_available

## Emitted when whiteboard becomes unavailable (player leaves Meeting Room)
signal whiteboard_unavailable

## Emitted when whiteboard modal is opened
signal whiteboard_opened

## Emitted when whiteboard modal is closed
signal whiteboard_closed

## The area name that has the whiteboard feature
const WHITEBOARD_AREA := "MeetingRoom"

## Is the whiteboard currently available (player in Meeting Room)
var is_available: bool = false

## Is the whiteboard modal currently open
var is_open: bool = false


func _ready() -> void:
	# Connect to AreaDetector when it's available
	await get_tree().process_frame
	_connect_to_area_detector()


func _connect_to_area_detector() -> void:
	var area_detector = get_tree().get_first_node_in_group("area_detector")
	if area_detector and area_detector.has_signal("area_changed"):
		area_detector.area_changed.connect(_on_area_changed)
		# Check if already in Meeting Room
		if area_detector.has_method("get_current_area"):
			var current: String = area_detector.get_current_area()
			if current == WHITEBOARD_AREA:
				_set_available(true)


func _on_area_changed(area_name: String) -> void:
	if area_name == WHITEBOARD_AREA:
		_set_available(true)
	elif is_available:
		_set_available(false)
		# Auto-close whiteboard if player leaves area while it's open
		if is_open:
			close_whiteboard()


func _set_available(available: bool) -> void:
	if is_available == available:
		return
	is_available = available
	if available:
		whiteboard_available.emit()
		print("[WhiteboardManager] Whiteboard available")
	else:
		whiteboard_unavailable.emit()
		print("[WhiteboardManager] Whiteboard unavailable")


## Open the whiteboard modal
func open_whiteboard() -> void:
	if not is_available:
		push_warning("[WhiteboardManager] Cannot open - not in Meeting Room")
		return
	if is_open:
		return

	is_open = true
	_set_player_input_enabled(false)
	whiteboard_opened.emit()
	print("[WhiteboardManager] Whiteboard opened")


## Close the whiteboard modal
func close_whiteboard() -> void:
	if not is_open:
		return

	is_open = false
	_set_player_input_enabled(true)
	whiteboard_closed.emit()
	print("[WhiteboardManager] Whiteboard closed")


## Enable/disable player input
func _set_player_input_enabled(enabled: bool) -> void:
	if NetworkManager.local_player and NetworkManager.local_player.has_method("set_input_enabled"):
		NetworkManager.local_player.set_input_enabled(enabled)
	elif NetworkManager.local_player:
		# Fallback: set property directly if method doesn't exist
		if "input_enabled" in NetworkManager.local_player:
			NetworkManager.local_player.input_enabled = enabled
