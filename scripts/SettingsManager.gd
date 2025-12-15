# SettingsManager.gd
# Autoload that applies saved settings on game startup

extends Node

## Settings config file path (same as SettingsPanel)
const SETTINGS_FILE := "user://settings.cfg"

## Config file instance
var config := ConfigFile.new()


func _ready() -> void:
	# Apply saved settings on startup
	_load_and_apply_settings()


func _load_and_apply_settings() -> void:
	var err := config.load(SETTINGS_FILE)
	if err == OK:
		# Apply saved input device
		var saved_mic := config.get_value("audio", "input_device", "") as String
		if saved_mic != "":
			AudioServer.input_device = saved_mic
			print("[SettingsManager] Set input device: ", saved_mic)

		print("[SettingsManager] Loaded and applied settings from config")
	else:
		print("[SettingsManager] No saved settings found, using defaults")
