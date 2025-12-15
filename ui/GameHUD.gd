# GameHUD.gd
# In-game heads-up display showing player info, area, and nearby players

extends CanvasLayer

## Settings panel scene
var settings_panel_scene := preload("res://ui/SettingsPanel.tscn")

## Settings panel instance
var settings_panel: PanelContainer = null

## Mic icons
var mic_on_texture: Texture2D
var mic_off_texture: Texture2D

## UI References
@onready var username_label: Label = $TopBar/UsernameLabel
@onready var area_label: Label = $TopBar/AreaLabel
@onready var mic_button: Button = $TopBar/MicButton
@onready var settings_button: Button = $TopBar/SettingsButton
@onready var nearby_panel: PanelContainer = $NearbyPanel
@onready var nearby_list: VBoxContainer = $NearbyPanel/VBoxContainer/NearbyList
@onready var controls_panel: PanelContainer = $ControlsPanel


func _ready() -> void:
	mic_on_texture = load("res://assets/sprites/ui/mic_on.png")
	mic_off_texture = load("res://assets/sprites/ui/mic_off.png")

	_update_mic_button()
	username_label.text = NetworkManager.local_username
	area_label.text = "Area: ---"

	settings_panel = settings_panel_scene.instantiate()
	add_child(settings_panel)
	settings_panel.hide()
	settings_panel.settings_closed.connect(_on_settings_closed)
	settings_panel.logout_requested.connect(_on_logout_requested)

	mic_button.pressed.connect(_on_mic_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	VoiceManager.mic_toggled.connect(_on_mic_toggled)
	VoiceManager.player_entered_voice_range.connect(_on_player_entered_range)
	VoiceManager.player_exited_voice_range.connect(_on_player_exited_range)

	await get_tree().process_frame
	var area_detector := get_tree().get_first_node_in_group("area_detector")
	if area_detector and area_detector.has_signal("area_changed"):
		area_detector.area_changed.connect(_on_area_changed)

	_update_nearby_list()

	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_update_nearby_list)
	add_child(timer)


func _on_mic_button_pressed() -> void:
	VoiceManager.toggle_mic()


func _on_mic_toggled(_enabled: bool) -> void:
	_update_mic_button()


func _update_mic_button() -> void:
	if VoiceManager.mic_enabled:
		mic_button.icon = mic_on_texture
		mic_button.text = "Mic ON"
		mic_button.modulate = Color.GREEN
	else:
		mic_button.icon = mic_off_texture
		mic_button.text = "Mic OFF"
		mic_button.modulate = Color.WHITE


func _on_area_changed(area_name: String) -> void:
	if area_name.is_empty():
		area_label.text = "Area: ---"
	else:
		area_label.text = "Area: " + area_name


func _on_player_entered_range(_peer_id: int) -> void:
	_update_nearby_list()


func _on_player_exited_range(_peer_id: int) -> void:
	_update_nearby_list()


func _update_nearby_list() -> void:
	for child in nearby_list.get_children():
		child.queue_free()

	var nearby_players := VoiceManager.get_nearby_players()

	if nearby_players.is_empty():
		var label := Label.new()
		label.text = "No one nearby"
		label.modulate = Color(0.6, 0.6, 0.6)
		nearby_list.add_child(label)
	else:
		for peer_id in nearby_players:
			var player_data := NetworkManager.get_player_data(peer_id)
			var label := Label.new()
			label.text = "• " + player_data.get("username", "Player %d" % peer_id)
			nearby_list.add_child(label)


func toggle_controls() -> void:
	controls_panel.visible = not controls_panel.visible


func set_username(username: String) -> void:
	username_label.text = username


func _on_settings_button_pressed() -> void:
	if settings_panel:
		settings_panel.show_settings()


func _on_settings_closed() -> void:
	pass  # Settings panel handles hiding itself


func _on_logout_requested() -> void:
	var main_node := get_tree().get_first_node_in_group("main")
	if main_node and main_node.has_method("disconnect_and_return"):
		main_node.disconnect_and_return()
	else:
		var root := get_tree().root
		for child in root.get_children():
			if child.has_method("disconnect_and_return"):
				child.disconnect_and_return()
				return

		print("[GameHUD] Could not find Main, reloading scene")
		get_tree().reload_current_scene()
