extends Node

const Laser = preload("uid://2n5w84ivb4dw")

@export var room: Room
@export var lasers: Array[Laser]

var _tween: Tween


func _ready() -> void:
	if room and multiplayer.is_server():
		room.powered_on.connect(_on_room_powered_on)
		room.powered_off.connect(_on_room_powered_off)


func _on_room_powered_on() -> void:
	if _tween: _tween.kill()
	for laser in lasers:
		if laser.anim_player:
			if not (_tween and _tween.is_valid()):
				_tween = create_tween().set_parallel()
			_tween.tween_property(laser.anim_player, "speed_scale", 1.0, 1.0)


func _on_room_powered_off() -> void:
	for laser in lasers:
		if laser.anim_player:
			if not (_tween and _tween.is_valid()):
				_tween = create_tween().set_parallel()
			_tween.tween_property(laser.anim_player, "speed_scale", 0.0, 1.0)
	
