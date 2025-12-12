# CharacterSelect.gd
# Character selection screen with 6 character options

extends Control

## Signal when character is selected and confirmed
signal character_selected(character_id: int)

## Currently selected character index
var selected_character: int = 0

## UI References
@onready var character_buttons: Array[PanelContainer] = []
@onready var enter_button: Button = $VBoxContainer/EnterButton
@onready var username_label: Label = $VBoxContainer/UsernameLabel
@onready var characters_container: HBoxContainer = $VBoxContainer/CharactersContainer

## Selection highlight style
var selected_style: StyleBoxFlat
var normal_style: StyleBoxFlat


func _ready() -> void:
	# Create selection styles
	selected_style = StyleBoxFlat.new()
	selected_style.bg_color = Color(0.2, 0.6, 1.0, 0.5)
	selected_style.border_width_left = 3
	selected_style.border_width_right = 3
	selected_style.border_width_top = 3
	selected_style.border_width_bottom = 3
	selected_style.border_color = Color(0.3, 0.7, 1.0)
	selected_style.corner_radius_top_left = 8
	selected_style.corner_radius_top_right = 8
	selected_style.corner_radius_bottom_left = 8
	selected_style.corner_radius_bottom_right = 8
	
	normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.15, 0.15, 0.15, 0.8)
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8
	
	# Setup character buttons
	_setup_character_buttons()
	
	# Connect enter button
	enter_button.pressed.connect(_on_enter_pressed)
	
	# Show current username
	username_label.text = "Playing as: " + NetworkManager.local_username
	
	# Select first character by default
	_select_character(0)


func _setup_character_buttons() -> void:
	# Clear existing buttons if any
	for child in characters_container.get_children():
		child.queue_free()
	character_buttons.clear()
	
	# Create 6 character selection buttons
	for i in range(6):
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(80, 100)
		
		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		panel.add_child(vbox)
		
		var texture_rect := TextureRect.new()
		texture_rect.texture = load("res://assets/sprites/characters/character_%d.png" % (i + 1))
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.custom_minimum_size = Vector2(48, 72)
		texture_rect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		vbox.add_child(texture_rect)
		
		var label := Label.new()
		label.text = "Char %d" % (i + 1)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(label)
		
		# Make the panel clickable
		var button := Button.new()
		button.flat = true
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		var idx := i # Capture for closure
		button.pressed.connect(func(): _select_character(idx))
		button.custom_minimum_size = panel.custom_minimum_size
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		# Use a MarginContainer to overlay the button
		var margin := MarginContainer.new()
		margin.add_child(panel)
		margin.add_child(button)
		
		characters_container.add_child(margin)
		
		# Store reference to panel for styling
		character_buttons.append(panel)
	
	await get_tree().process_frame
	_update_selection_ui()


func _select_character(index: int) -> void:
	selected_character = index
	NetworkManager.local_character_id = index
	_update_selection_ui()


func _update_selection_ui() -> void:
	for i in range(character_buttons.size()):
		var panel: PanelContainer = character_buttons[i]
		if i == selected_character:
			panel.add_theme_stylebox_override("panel", selected_style)
		else:
			panel.add_theme_stylebox_override("panel", normal_style)


func _on_enter_pressed() -> void:
	character_selected.emit(selected_character)


## Update the displayed username
func set_username(username: String) -> void:
	if username_label:
		username_label.text = "Playing as: " + username
