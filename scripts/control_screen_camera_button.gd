extends Node2D

var camera: CCTVCamera
@onready var _button: TextureButton = $TextureButton
@onready var _vision_sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_button.pressed.connect(_on_pressed)
	SignalBus.current_cctv_camera_changed.connect(_on_current_cctv_camera_changed)


func _on_pressed() -> void:
	if camera:
		camera.request_select.rpc_id(1)


func _on_current_cctv_camera_changed(new_camera: CCTVCamera) -> void:
	if camera == new_camera:
		_button.modulate = Color.GREEN
		_vision_sprite.show()
	elif _button.modulate == Color.GREEN:
		_button.modulate = Color.DEEP_SKY_BLUE
		_vision_sprite.hide()
