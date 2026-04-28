extends Node2D

var room: Room


func _ready() -> void:
	$TextureButton.pressed.connect(_on_pressed)
	if room:
		room.powered_on.connect(_on_room_powered_on)
		room.powered_off.connect(_on_room_powered_off)


func _on_pressed() -> void:
	if room:
		if room.is_powered:
			room.request_power_off.rpc_id(1)
		else:
			room.request_power_on.rpc_id(1)


func _on_room_powered_on() -> void:
	modulate = Color.GREEN


func _on_room_powered_off() -> void:
	modulate = Color.RED
