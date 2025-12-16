# gdlint: ignore=max-public-methods
class_name LoginScreenTest
extends GdUnitTestSuite

const LOGIN_SCREEN_PATH := "res://ui/LoginScreen.tscn"

var _login_screen: Control


func before_test() -> void:
	var scene := load(LOGIN_SCREEN_PATH)
	_login_screen = auto_free(scene.instantiate())
	add_child(_login_screen)
	await get_tree().process_frame


func after_test() -> void:
	_login_screen = null


# ============================================
# Credential Validation Tests
# ============================================


func test_validate_credentials_valid_user_dev1() -> void:
	var result: bool = _login_screen._validate_credentials("dev1", "dev1")
	assert_bool(result).is_true()


func test_validate_credentials_valid_user_dev2() -> void:
	var result: bool = _login_screen._validate_credentials("dev2", "dev2")
	assert_bool(result).is_true()


func test_validate_credentials_valid_user_admin() -> void:
	var result: bool = _login_screen._validate_credentials("admin", "admin123")
	assert_bool(result).is_true()


func test_validate_credentials_invalid_password() -> void:
	var result: bool = _login_screen._validate_credentials("dev1", "wrongpassword")
	assert_bool(result).is_false()


func test_validate_credentials_invalid_username() -> void:
	var result: bool = _login_screen._validate_credentials("unknown", "password")
	assert_bool(result).is_false()


func test_validate_credentials_empty_username() -> void:
	var result: bool = _login_screen._validate_credentials("", "password")
	assert_bool(result).is_false()


func test_validate_credentials_empty_password() -> void:
	var result: bool = _login_screen._validate_credentials("dev1", "")
	assert_bool(result).is_false()


func test_validate_credentials_case_sensitive_username() -> void:
	var result: bool = _login_screen._validate_credentials("DEV1", "dev1")
	assert_bool(result).is_false()


func test_validate_credentials_case_sensitive_password() -> void:
	var result: bool = _login_screen._validate_credentials("dev1", "DEV1")
	assert_bool(result).is_false()


# ============================================
# UI State Tests
# ============================================


func test_initial_state_error_hidden() -> void:
	assert_bool(_login_screen.error_label.visible).is_false()


func test_initial_state_error_text_empty() -> void:
	assert_str(_login_screen.error_label.text).is_empty()


func test_show_error_makes_label_visible() -> void:
	_login_screen._show_error("Test error")
	assert_bool(_login_screen.error_label.visible).is_true()


func test_show_error_sets_message() -> void:
	_login_screen._show_error("Test error message")
	assert_str(_login_screen.error_label.text).is_equal("Test error message")


func test_reset_clears_username() -> void:
	_login_screen.username_input.text = "testuser"
	_login_screen.reset()
	assert_str(_login_screen.username_input.text).is_empty()


func test_reset_clears_password() -> void:
	_login_screen.password_input.text = "testpass"
	_login_screen.reset()
	assert_str(_login_screen.password_input.text).is_empty()


func test_reset_hides_error() -> void:
	_login_screen._show_error("Some error")
	_login_screen.reset()
	assert_bool(_login_screen.error_label.visible).is_false()


# ============================================
# Login Attempt Tests
# ============================================


func test_login_empty_username_shows_error() -> void:
	_login_screen.username_input.text = ""
	_login_screen.password_input.text = "password"
	_login_screen._attempt_login()

	assert_bool(_login_screen.error_label.visible).is_true()
	assert_str(_login_screen.error_label.text).is_equal("Username cannot be empty")


func test_login_short_username_shows_error() -> void:
	_login_screen.username_input.text = "a"
	_login_screen.password_input.text = "password"
	_login_screen._attempt_login()

	assert_bool(_login_screen.error_label.visible).is_true()
	assert_str(_login_screen.error_label.text).is_equal("Username must be at least 2 characters")


func test_login_long_username_shows_error() -> void:
	_login_screen.username_input.text = "thisusernameistoolong"
	_login_screen.password_input.text = "password"
	_login_screen._attempt_login()

	assert_bool(_login_screen.error_label.visible).is_true()
	assert_str(_login_screen.error_label.text).is_equal("Username must be 16 characters or less")


func test_login_empty_password_shows_error() -> void:
	_login_screen.username_input.text = "dev1"
	_login_screen.password_input.text = ""
	_login_screen._attempt_login()

	assert_bool(_login_screen.error_label.visible).is_true()
	assert_str(_login_screen.error_label.text).is_equal("Password cannot be empty")


func test_login_invalid_credentials_shows_error() -> void:
	_login_screen.username_input.text = "dev1"
	_login_screen.password_input.text = "wrongpassword"
	_login_screen._attempt_login()

	assert_bool(_login_screen.error_label.visible).is_true()
	assert_str(_login_screen.error_label.text).is_equal("Invalid username or password")


func test_login_valid_credentials_emits_signal() -> void:
	var signal_emitted := false
	var received_username := ""

	_login_screen.login_completed.connect(
		func(username: String):
			signal_emitted = true
			received_username = username
	)

	_login_screen.username_input.text = "dev1"
	_login_screen.password_input.text = "dev1"
	_login_screen._attempt_login()

	assert_bool(signal_emitted).is_true()
	assert_str(received_username).is_equal("dev1")


func test_login_valid_credentials_hides_error() -> void:
	_login_screen._show_error("Previous error")
	_login_screen.username_input.text = "dev1"
	_login_screen.password_input.text = "dev1"
	_login_screen._attempt_login()

	assert_bool(_login_screen.error_label.visible).is_false()


func test_login_strips_whitespace_from_username() -> void:
	var received_username := ""

	_login_screen.login_completed.connect(func(username: String): received_username = username)

	_login_screen.username_input.text = "  dev1  "
	_login_screen.password_input.text = "dev1"
	_login_screen._attempt_login()

	assert_str(received_username).is_equal("dev1")
