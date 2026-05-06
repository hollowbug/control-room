extends RigidBody3D

var powered := true:
	set(v):
		powered = v
		if v:
			_check_overlapping_bodies()
		else:
			_timer.stop()
var falling_started := false

@onready var _timer: Timer = $Timer
@onready var _area: Area3D = $Area3D
var _start_xform: Transform3D


func _ready() -> void:
	freeze = true
	if multiplayer.is_server():
		_start_xform = transform
		_area.body_entered.connect(_on_area_body_entered)
		_timer.timeout.connect(_on_timer_timeout)
	else:
		_area.queue_free()
		_timer.queue_free()


@rpc("call_local")
func start_falling() -> void:
	freeze = false


func reset() -> void:
	_reset.rpc(_start_xform)


@rpc("call_local")
func _reset(xform: Transform3D) -> void:
	freeze = true
	falling_started = false
	await get_tree().physics_frame
	transform = xform


func _on_area_body_entered(_body: Node3D) -> void:
	if powered and _timer.is_stopped():
		_timer.start()


func _on_timer_timeout() -> void:
	falling_started = true
	start_falling.rpc()


func _check_overlapping_bodies() -> void:
	if _area.has_overlapping_bodies():
		_timer.start()
