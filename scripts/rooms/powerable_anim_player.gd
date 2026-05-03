extends AnimationPlayer

@export var room: Room
@export var animation_name: String
@export var speed_up_duration := 1.0
@export var speed_up_trans := Tween.TRANS_LINEAR
@export var speed_up_ease := Tween.EASE_IN
@export var slow_down_duration := 1.0
@export var slow_down_trans := Tween.TRANS_LINEAR
@export var slow_down_ease := Tween.EASE_OUT

var _tween: Tween


func _ready() -> void:
	if multiplayer.is_server():
		play(animation_name)
		if room:
			room.powered_on.connect(_on_room_powered_on)
			room.powered_off.connect(_on_room_powered_off)


func _on_room_powered_on() -> void:
	if _tween: _tween.kill()
	_tween = create_tween().set_trans(speed_up_trans).set_ease(speed_up_ease)
	_tween.tween_property(self, "speed_scale", 1.0, speed_up_duration)


func _on_room_powered_off() -> void:
	if _tween: _tween.kill()
	_tween = create_tween().set_trans(slow_down_trans).set_ease(slow_down_ease)
	_tween.tween_property(self, "speed_scale", 0.0, slow_down_duration)
