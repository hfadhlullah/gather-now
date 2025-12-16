# LoginScreen.gd
# Handles the login/username input screen with password authentication

extends Control

## Signal when login is complete
signal login_completed(username: String)

## Mock user database for testing
## In production, this would be replaced with server authentication
const MOCK_USERS: Dictionary = {
	"dev1": "dev1",
	"dev2": "dev2",
	"admin": "admin123",
}

## UI References
@onready var username_input: LineEdit = $VBoxContainer/UsernameInput
@onready var password_input: LineEdit = $VBoxContainer/PasswordInput
@onready var join_button: Button = $VBoxContainer/JoinButton
@onready var error_label: Label = $VBoxContainer/ErrorLabel
@onready var hint_label: Label = $VBoxContainer/HintLabel
@onready var controls_info: Label = $ControlsInfo


func _ready() -> void:
	error_label.text = ""
	error_label.visible = false

	# Connect signals
	join_button.pressed.connect(_on_join_pressed)
	username_input.text_submitted.connect(_on_username_submitted)
	password_input.text_submitted.connect(_on_password_submitted)

	# Focus the input field
	username_input.grab_focus()

	# Connect to network manager for username rejection
	NetworkManager.username_rejected.connect(_on_username_rejected)


func _on_join_pressed() -> void:
	_attempt_login()


func _on_username_submitted(_text: String) -> void:
	# Move focus to password field
	password_input.grab_focus()


func _on_password_submitted(_text: String) -> void:
	_attempt_login()


func _attempt_login() -> void:
	var username := username_input.text.strip_edges()
	var password := password_input.text

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

	# Validate password
	if password.is_empty():
		_show_error("Password cannot be empty")
		return

	# Check credentials against mock database
	if not _validate_credentials(username, password):
		_show_error("Invalid username or password")
		return

	# Store username in NetworkManager
	NetworkManager.local_username = username

	# Hide error and proceed
	error_label.visible = false
	login_completed.emit(username)


## Validate credentials against mock database
func _validate_credentials(username: String, password: String) -> bool:
	# Check if user exists in mock database
	if MOCK_USERS.has(username):
		return MOCK_USERS[username] == password

	return false


func _on_username_rejected(reason: String) -> void:
	_show_error(reason)


func _show_error(message: String) -> void:
	error_label.text = message
	error_label.visible = true
	error_label.modulate = Color.RED


## Reset the screen for reuse
func reset() -> void:
	username_input.text = ""
	password_input.text = ""
	error_label.visible = false
	username_input.grab_focus()
