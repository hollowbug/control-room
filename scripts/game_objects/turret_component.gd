extends Node3D

var _bullet_scene := load("uid://cg2dfyeqomjl2") as PackedScene
@export var _bullet_spawn_marker: Marker3D
@export var shots_per_second := 20.0
@export var inaccuracy := 0.1

var _cooldown := 0.0


func shoot(delta: float) -> void:
	_cooldown -= delta
	if _cooldown <= 0.0:
		_cooldown += 1.0 / maxf(0.01, shots_per_second)
		_shoot.rpc(Utils.get_random_direction(), randf_range(-1, 1) * inaccuracy)


@rpc("call_local")
func _shoot(axis: Vector3, angle: float) -> void:
	var bullet := _bullet_scene.instantiate() as Node3D
	if not bullet: return
	if _bullet_spawn_marker:
		bullet.position = _bullet_spawn_marker.global_position
	else:
		bullet.position = global_position
	bullet.rotation = global_rotation
	bullet.rotate(axis, angle)
	add_child(bullet)
