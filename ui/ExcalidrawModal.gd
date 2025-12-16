# ExcalidrawModal.gd
# Modal overlay for Excalidraw whiteboard
# Uses Godot WRY WebView for native in-game browser

extends Node2D

## Emitted when the modal is closed
signal modal_closed

## The Excalidraw URL to load
const EXCALIDRAW_URL := "https://excalidraw.com"

## Reference to UI elements
@onready var background: ColorRect = $Background
@onready var header: HBoxContainer = $Header
@onready var browser_window: Window = $BrowserWindow
@onready var webview: WebView = $BrowserWindow/WebView


func _ready() -> void:
	# Hide everything by default
	background.visible = false
	header.visible = false
	browser_window.visible = false

	# Connect to WhiteboardManager
	WhiteboardManager.whiteboard_opened.connect(_on_whiteboard_opened)
	WhiteboardManager.whiteboard_closed.connect(_on_whiteboard_closed)


func _on_whiteboard_opened() -> void:
	# Show overlay
	background.visible = true
	header.visible = true

	# Show browser window
	browser_window.visible = true

	# Wait a frame then load URL and resize
	await get_tree().process_frame

	# Force reload the URL
	webview.load_url(EXCALIDRAW_URL)

	# Call resize to update webview dimensions
	if webview.has_method("resize"):
		webview.resize()

	print("[ExcalidrawModal] WebView opened with URL: ", EXCALIDRAW_URL)


func _on_whiteboard_closed() -> void:
	# Hide everything
	background.visible = false
	header.visible = false
	browser_window.visible = false
	print("[ExcalidrawModal] WebView closed")


## Close button pressed
func _on_close_pressed() -> void:
	WhiteboardManager.close_whiteboard()
	modal_closed.emit()


## Handle escape key to close modal
func _input(event: InputEvent) -> void:
	if not browser_window.visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_close_pressed()
		get_viewport().set_input_as_handled()
