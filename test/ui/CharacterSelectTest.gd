# CharacterSelectTest.gd
# GdUnit4 tests for CharacterSelect

class_name CharacterSelectTest
extends GdUnitTestSuite

const CharacterSelectScene := preload("res://ui/CharacterSelect.tscn")

var _char_select: Control
var _runner: GdUnitSceneRunner


func before_test() -> void:
	# Set up mock username before creating scene
	NetworkManager.local_username = "TestPlayer"

	_runner = scene_runner(CharacterSelectScene)
	_char_select = _runner.scene()
	# Wait for _setup_character_buttons to complete
	await _runner.simulate_frames(2)


func after_test() -> void:
	_char_select = null
	_runner = null


# ============================================
# Initial State Tests
# ============================================


func test_initial_selected_character_is_zero() -> void:
	assert_int(_char_select.selected_character).is_equal(0)


func test_initial_username_label_shows_player_name() -> void:
	assert_str(_char_select.username_label.text).is_equal("Playing as: TestPlayer")


func test_six_character_buttons_created() -> void:
	assert_int(_char_select.character_buttons.size()).is_equal(6)


func test_character_buttons_are_panel_containers() -> void:
	for button in _char_select.character_buttons:
		assert_object(button).is_instanceof(PanelContainer)


# ============================================
# Character Selection Tests
# ============================================


func test_select_character_updates_selected_character() -> void:
	_char_select._select_character(3)
	assert_int(_char_select.selected_character).is_equal(3)


func test_select_character_updates_network_manager() -> void:
	_char_select._select_character(2)
	assert_int(NetworkManager.local_character_id).is_equal(2)


func test_select_character_boundary_zero() -> void:
	_char_select._select_character(0)
	assert_int(_char_select.selected_character).is_equal(0)


func test_select_character_boundary_five() -> void:
	_char_select._select_character(5)
	assert_int(_char_select.selected_character).is_equal(5)


# ============================================
# Signal Tests
# ============================================


func test_enter_button_emits_character_selected_signal() -> void:
	var signal_emitted := false
	var received_id := -1

	_char_select.character_selected.connect(
		func(character_id: int):
			signal_emitted = true
			received_id = character_id
	)

	_char_select._select_character(4)
	_char_select._on_enter_pressed()

	assert_bool(signal_emitted).is_true()
	assert_int(received_id).is_equal(4)


func test_character_selected_signal_emits_current_selection() -> void:
	var received_ids: Array[int] = []

	_char_select.character_selected.connect(
		func(character_id: int): received_ids.append(character_id)
	)

	_char_select._select_character(1)
	_char_select._on_enter_pressed()

	_char_select._select_character(5)
	_char_select._on_enter_pressed()

	assert_int(received_ids.size()).is_equal(2)
	assert_int(received_ids[0]).is_equal(1)
	assert_int(received_ids[1]).is_equal(5)


# ============================================
# UI Helper Function Tests
# ============================================


func test_set_username_updates_label() -> void:
	_char_select.set_username("NewPlayer")
	assert_str(_char_select.username_label.text).is_equal("Playing as: NewPlayer")


func test_set_username_with_empty_string() -> void:
	_char_select.set_username("")
	assert_str(_char_select.username_label.text).is_equal("Playing as: ")


func test_set_username_with_special_characters() -> void:
	_char_select.set_username("Player@123!")
	assert_str(_char_select.username_label.text).is_equal("Playing as: Player@123!")


# ============================================
# Style Tests
# ============================================


func test_selected_style_has_border() -> void:
	assert_int(_char_select.selected_style.border_width_left).is_equal(3)
	assert_int(_char_select.selected_style.border_width_right).is_equal(3)
	assert_int(_char_select.selected_style.border_width_top).is_equal(3)
	assert_int(_char_select.selected_style.border_width_bottom).is_equal(3)


func test_normal_style_has_rounded_corners() -> void:
	assert_int(_char_select.normal_style.corner_radius_top_left).is_equal(8)
	assert_int(_char_select.normal_style.corner_radius_top_right).is_equal(8)
	assert_int(_char_select.normal_style.corner_radius_bottom_left).is_equal(8)
	assert_int(_char_select.normal_style.corner_radius_bottom_right).is_equal(8)


# ============================================
# Selection UI Update Tests
# ============================================


func test_update_selection_ui_applies_selected_style_to_current() -> void:
	_char_select._select_character(2)
	await _runner.simulate_frames(1)

	var panel: PanelContainer = _char_select.character_buttons[2]
	var current_style = panel.get_theme_stylebox("panel")

	assert_object(current_style).is_equal(_char_select.selected_style)


func test_update_selection_ui_applies_normal_style_to_others() -> void:
	_char_select._select_character(2)
	await _runner.simulate_frames(1)

	# Check a non-selected button
	var panel: PanelContainer = _char_select.character_buttons[0]
	var current_style = panel.get_theme_stylebox("panel")

	assert_object(current_style).is_equal(_char_select.normal_style)
