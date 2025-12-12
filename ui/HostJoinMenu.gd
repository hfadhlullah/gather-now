# HostJoinMenu.gd
# Menu for hosting or joining a multiplayer game

extends Control

## Signals
signal host_started
signal join_started
signal back_pressed

## UI References
@onready var host_button: Button = $VBoxContainer/HostButton
@onready var ip_input: LineEdit = $VBoxContainer/IPContainer/IPInput
@onready var port_input: LineEdit = $VBoxContainer/PortContainer/PortInput
@onready var join_button: Button = $VBoxContainer/JoinButton
@onready var back_button: Button = $VBoxContainer/BackButton
@onready var status_label: Label = $VBoxContainer/StatusLabel


func _ready() -> void:
	# Set defaults
	ip_input.text = "127.0.0.1"
	port_input.text = str(NetworkManager.DEFAULT_PORT)
	status_label.text = ""
	status_label.visible = false
	
	# Connect buttons
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Connect network events
	NetworkManager.server_started.connect(_on_server_started)
	NetworkManager.connection_succeeded.connect(_on_connection_succeeded)
	NetworkManager.connection_failed.connect(_on_connection_failed)


func _on_host_pressed() -> void:
	var port := int(port_input.text)
	if port <= 0 or port > 65535:
		_show_status("Invalid port number", Color.RED)
		return
	
	_show_status("Starting server...", Color.YELLOW)
	host_button.disabled = true
	join_button.disabled = true
	
	var error: Error = NetworkManager.create_server(port)
	if error != OK:
		_show_status("Failed to start server", Color.RED)
		host_button.disabled = false
		join_button.disabled = false


func _on_join_pressed() -> void:
	var ip := ip_input.text.strip_edges()
	var port := int(port_input.text)
	
	if ip.is_empty():
		_show_status("Please enter an IP address", Color.RED)
		return
	
	if port <= 0 or port > 65535:
		_show_status("Invalid port number", Color.RED)
		return
	
	_show_status("Connecting to %s:%d..." % [ip, port], Color.YELLOW)
	host_button.disabled = true
	join_button.disabled = true
	
	var error: Error = NetworkManager.join_server(ip, port)
	if error != OK:
		_show_status("Failed to connect", Color.RED)
		host_button.disabled = false
		join_button.disabled = false


func _on_back_pressed() -> void:
	back_pressed.emit()


func _on_server_started() -> void:
	_show_status("Server started! Entering world...", Color.GREEN)
	host_started.emit()


func _on_connection_succeeded() -> void:
	_show_status("Connected! Entering world...", Color.GREEN)
	join_started.emit()


func _on_connection_failed(reason: String) -> void:
	_show_status("Error: " + reason, Color.RED)
	host_button.disabled = false
	join_button.disabled = false


func _show_status(message: String, color: Color) -> void:
	status_label.text = message
	status_label.modulate = color
	status_label.visible = true


## Reset the menu state
func reset() -> void:
	host_button.disabled = false
	join_button.disabled = false
	status_label.visible = false
	ip_input.text = "127.0.0.1"
	port_input.text = str(NetworkManager.DEFAULT_PORT)
