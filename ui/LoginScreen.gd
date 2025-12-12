# LoginScreen.gd
# Handles the login/username input screen

extends Control

## Signal when login is complete
signal login_completed(username: String)

## UI References
@onready var username_input: LineEdit = $VBoxContainer/UsernameInput
@onready var join_button: Button = $VBoxContainer/JoinButton
@onready var error_label: Label = $VBoxContainer/ErrorLabel
@onready var controls_info: Label = $ControlsInfo


func _ready() -> void:
	error_label.text = ""
	error_label.visible = false
	
	# Connect signals
	join_button.pressed.connect(_on_join_pressed)
	username_input.text_submitted.connect(_on_username_submitted)
	
	# Focus the input field
	username_input.grab_focus()
	
	# Connect to network manager for username rejection
	NetworkManager.username_rejected.connect(_on_username_rejected)


func _on_join_pressed() -> void:
	_attempt_login()


func _on_username_submitted(_text: String) -> void:
	_attempt_login()


func _attempt_login() -> void:
	var username := username_input.text.strip_edges()
	
	# Validate username
	if username.is_empty():
		_show_error("Username cannot be empty")
		return
	
	if username.length() < 2:
		_show_error("Username must be at least 2 characters")
		return
	
	if username.length() > 16:
		_show_error("Username must be 16 characters or less")
		return
	
	# Store username in NetworkManager
	NetworkManager.local_username = username
	
	# Hide error and proceed
	error_label.visible = false
	login_completed.emit(username)


func _on_username_rejected(reason: String) -> void:
	_show_error(reason)


func _show_error(message: String) -> void:
	error_label.text = message
	error_label.visible = true
	error_label.modulate = Color.RED


## Reset the screen for reuse
func reset() -> void:
	username_input.text = ""
	error_label.visible = false
	username_input.grab_focus()
