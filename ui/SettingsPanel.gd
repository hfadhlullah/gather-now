# SettingsPanel.gd
# Settings panel with microphone settings and logout

extends PanelContainer

## Signals
signal settings_closed
signal logout_requested

## Settings config file path
const SETTINGS_FILE := "user://settings.cfg"

## Level meter constants
const DB_MIN := -60.0
const DB_MAX := 0.0
const PEAK_FALL_SPEED := 15.0
const LEVEL_SMOOTHING := 0.15

## Colors for level gradient
const COLOR_GREEN := Color(0.2, 0.85, 0.35)
const COLOR_YELLOW := Color(0.95, 0.85, 0.2)
const COLOR_RED := Color(0.95, 0.25, 0.2)

## Config file instance
var config := ConfigFile.new()

## Available input devices (raw names from AudioServer)
var input_devices: PackedStringArray = []

## Friendly device names for display
var friendly_device_names: Array[String] = []

## Microphone test player for level detection
var mic_player: AudioStreamPlayer = null
var mic_capture_effect: AudioEffectCapture = null

## Level meter state
var current_level: float = 0.0
var current_db: float = DB_MIN
var peak_position: float = 0.0
var peak_hold_time: float = 0.0

## UI References
var mic_option: OptionButton
var level_bar_container: Control
var level_bar: ColorRect
var level_peak: ColorRect
var db_label: Label
var logout_button: Button
var close_button: Button


func _ready() -> void:
	# Get UI references
	mic_option = $MarginContainer/VBoxContainer/MicContainer/MicOption
	var meter_path := "MarginContainer/VBoxContainer/LevelMeterContainer"
	var bar_path := meter_path + "/MarginContainer/LevelBarContainer"
	level_bar_container = get_node(bar_path)
	level_bar = get_node(bar_path + "/LevelBar")
	level_peak = get_node(bar_path + "/LevelPeak")
	db_label = get_node(meter_path + "/DbLabel")
	logout_button = $MarginContainer/VBoxContainer/LogoutButton
	close_button = $MarginContainer/VBoxContainer/CloseButton

	_refresh_input_devices()
	_load_settings()

	mic_option.item_selected.connect(_on_mic_selected)
	logout_button.pressed.connect(_on_logout_pressed)
	close_button.pressed.connect(_on_close_pressed)

	_setup_mic_level_detection()


func _process(delta: float) -> void:
	if not visible:
		return

	if mic_capture_effect and is_instance_valid(mic_player) and mic_player.playing:
		_update_mic_level(delta)


func _reset_level_meter() -> void:
	current_level = 0.0
	current_db = DB_MIN
	peak_position = 0.0
	peak_hold_time = 0.0
	if level_bar:
		level_bar.size.x = 0
	if level_peak:
		level_peak.position.x = 0
		level_peak.visible = false
	if db_label:
		db_label.text = "-∞ dB"
		db_label.modulate = Color.WHITE


func _refresh_input_devices() -> void:
	mic_option.clear()
	input_devices = AudioServer.get_input_device_list()
	friendly_device_names.clear()

	if input_devices.size() == 0:
		mic_option.add_item("No microphone detected")
		mic_option.disabled = true
	else:
		mic_option.disabled = false

		var actual_default_name := ""
		for device in input_devices:
			if device != "Default":
				actual_default_name = _get_friendly_device_name(device)
				break

		for device in input_devices:
			var friendly_name: String
			if device == "Default" and actual_default_name != "":
				friendly_name = "Default (" + actual_default_name + ")"
			else:
				friendly_name = _get_friendly_device_name(device)
			friendly_device_names.append(friendly_name)
			mic_option.add_item(friendly_name)

		var current_device := AudioServer.input_device
		var idx := 0
		for i in range(input_devices.size()):
			if input_devices[i] == current_device:
				idx = i
				break
		mic_option.select(idx)

	print("[Settings] Found %d input devices:" % input_devices.size())
	for i in range(input_devices.size()):
		print("  [%d] Raw: '%s' -> '%s'" % [i, input_devices[i], friendly_device_names[i]])


func _get_friendly_device_name(raw_name: String) -> String:
	if raw_name == "Default":
		return "Default Microphone"

	var friendly := raw_name

	friendly = friendly.replace("alsa_input.", "")
	friendly = friendly.replace("alsa_output.", "")
	friendly = friendly.replace("pulse_input.", "")
	friendly = friendly.replace("pulse_output.", "")

	friendly = friendly.replace(".analog-stereo", " (Analog)")
	friendly = friendly.replace(".analog-mono", " (Analog Mono)")
	friendly = friendly.replace(".digital-stereo", " (Digital)")
	friendly = friendly.replace(".hdmi-stereo", " (HDMI)")
	friendly = friendly.replace(".iec958-stereo", " (S/PDIF)")
	friendly = friendly.replace("-stereo", "")
	friendly = friendly.replace("-mono", "")

	var pci_regex := RegEx.new()
	pci_regex.compile("pci-[0-9a-fA-F_\\.]+\\.")
	friendly = pci_regex.sub(friendly, "")

	var usb_regex := RegEx.new()
	usb_regex.compile("usb-[0-9a-fA-F_\\.-]+\\.")
	friendly = usb_regex.sub(friendly, "")

	friendly = friendly.replace("_", " ")
	friendly = friendly.replace(".", " ")

	while "  " in friendly:
		friendly = friendly.replace("  ", " ")

	friendly = friendly.strip_edges()

	var words := friendly.split(" ")
	var capitalized: Array[String] = []
	for word in words:
		if word.length() > 0:
			capitalized.append(word.capitalize())
	friendly = " ".join(capitalized)

	if friendly.is_empty() or friendly.length() < 3:
		return raw_name

	return friendly


func _setup_mic_level_detection() -> void:
	var bus_idx := AudioServer.get_bus_index("MicTest")
	if bus_idx == -1:
		bus_idx = AudioServer.bus_count
		AudioServer.add_bus(bus_idx)
		AudioServer.set_bus_name(bus_idx, "MicTest")
		AudioServer.set_bus_send(bus_idx, "Master")
		AudioServer.set_bus_volume_db(bus_idx, -80.0)

		mic_capture_effect = AudioEffectCapture.new()
		mic_capture_effect.buffer_length = 0.1
		AudioServer.add_bus_effect(bus_idx, mic_capture_effect)
		print("[Settings] Created MicTest audio bus at index ", bus_idx)
	else:
		for i in range(AudioServer.get_bus_effect_count(bus_idx)):
			var effect = AudioServer.get_bus_effect(bus_idx, i)
			if effect is AudioEffectCapture:
				mic_capture_effect = effect
				break

		if mic_capture_effect == null:
			mic_capture_effect = AudioEffectCapture.new()
			mic_capture_effect.buffer_length = 0.1
			AudioServer.add_bus_effect(bus_idx, mic_capture_effect)

		print("[Settings] Using existing MicTest audio bus at index ", bus_idx)


func _start_mic_test() -> void:
	if is_instance_valid(mic_player):
		mic_player.stop()
		mic_player.queue_free()
	mic_player = null

	var timer := get_tree().create_timer(0.1)
	await timer.timeout

	if not visible:
		return

	mic_player = AudioStreamPlayer.new()
	mic_player.stream = AudioStreamMicrophone.new()
	mic_player.bus = "MicTest"
	add_child(mic_player)
	mic_player.play()

	print("[Settings] Started mic test on device: ", AudioServer.input_device)


func _stop_mic_test() -> void:
	if mic_player:
		mic_player.stop()
		mic_player.queue_free()
		mic_player = null

	_reset_level_meter()


func _update_mic_level(delta: float) -> void:
	if mic_capture_effect == null:
		return

	var frames_available := mic_capture_effect.get_frames_available()
	if frames_available <= 0:
		current_level = lerp(current_level, 0.0, delta * 10.0)
		_update_level_display(delta)
		return

	var buffer := mic_capture_effect.get_buffer(frames_available)

	var sum_squares: float = 0.0
	var peak_sample: float = 0.0
	for frame in buffer:
		var sample: float = (abs(frame.x) + abs(frame.y)) / 2.0
		sum_squares += sample * sample
		peak_sample = max(peak_sample, sample)

	var rms := sqrt(sum_squares / max(buffer.size(), 1))

	var db: float = DB_MIN
	if rms > 0.0001:
		db = 20.0 * log(rms) / log(10.0)
	db = clamp(db, DB_MIN, DB_MAX)
	current_db = db

	var target_level := (db - DB_MIN) / (DB_MAX - DB_MIN)
	target_level = clamp(target_level, 0.0, 1.0)

	if target_level > current_level:
		current_level = lerp(current_level, target_level, 0.5)
	else:
		current_level = lerp(current_level, target_level, LEVEL_SMOOTHING)

	_update_level_display(delta)


func _update_level_display(delta: float) -> void:
	if not is_instance_valid(level_bar_container):
		return

	var container_width := level_bar_container.size.x
	if container_width <= 0:
		return

	var bar_width := current_level * container_width

	level_bar.size.x = bar_width

	var bar_color: Color
	if current_level < 0.5:
		bar_color = COLOR_GREEN.lerp(COLOR_YELLOW, current_level * 2.0)
	else:
		bar_color = COLOR_YELLOW.lerp(COLOR_RED, (current_level - 0.5) * 2.0)
	level_bar.color = bar_color

	if bar_width > peak_position:
		peak_position = bar_width
		peak_hold_time = 0.5
	else:
		peak_hold_time -= delta
		if peak_hold_time <= 0:
			peak_position = max(0, peak_position - PEAK_FALL_SPEED * delta * 10)

	level_peak.position.x = peak_position
	level_peak.visible = peak_position > 3

	if current_db <= DB_MIN + 1:
		db_label.text = "-∞ dB"
	else:
		db_label.text = "%d dB" % int(current_db)

	if current_level > 0.9:
		db_label.modulate = COLOR_RED
	elif current_level > 0.7:
		db_label.modulate = COLOR_YELLOW
	else:
		db_label.modulate = Color.WHITE


func _load_settings() -> void:
	var err := config.load(SETTINGS_FILE)
	if err == OK:
		var saved_mic := config.get_value("audio", "input_device", "") as String
		if saved_mic != "":
			AudioServer.input_device = saved_mic
			_refresh_input_devices()


func _save_settings() -> void:
	if mic_option.selected >= 0 and input_devices.size() > mic_option.selected:
		var device_name := input_devices[mic_option.selected]
		config.set_value("audio", "input_device", device_name)
		var save_err := config.save(SETTINGS_FILE)
		if save_err == OK:
			print("[Settings] Saved mic setting: ", device_name)
		else:
			print("[Settings] ERROR saving settings: ", save_err)


func _on_mic_selected(index: int) -> void:
	if index >= 0 and input_devices.size() > index:
		AudioServer.input_device = input_devices[index]
		print("[Settings] Selected input device: ", input_devices[index])
		_save_settings()

		if visible:
			_start_mic_test()


func _on_logout_pressed() -> void:
	_stop_mic_test()
	hide()
	logout_requested.emit()


func _on_close_pressed() -> void:
	_stop_mic_test()
	settings_closed.emit()
	hide()


func show_settings() -> void:
	show()
	var err := config.load(SETTINGS_FILE)
	if err == OK:
		var saved_mic := config.get_value("audio", "input_device", "") as String
		if saved_mic != "":
			AudioServer.input_device = saved_mic

	_refresh_input_devices()
	_start_mic_test()


func hide_settings() -> void:
	_stop_mic_test()
	hide()
