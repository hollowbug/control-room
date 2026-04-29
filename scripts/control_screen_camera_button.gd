extends Node2D

var camera: CCTVCamera
@onready var _button: TextureButton = $TextureButton


func _ready() -> void:
	_button.pressed.connect(_on_pressed)
	SignalBus.current_cctv_camera_changed.connect(_on_current_cctv_camera_changed)


func _on_pressed() -> void:
	if camera:
		camera.request_select.rpc_id(1)


func _on_current_cctv_camera_changed(new_camera: CCTVCamera) -> void:
	if camera == new_camera:
		modulate = Color.GREEN
	elif modulate == Color.GREEN:
		modulate = Color.DEEP_SKY_BLUE
