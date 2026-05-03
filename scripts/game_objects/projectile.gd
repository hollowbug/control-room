extends Node3D

@export var speed := 50.0
@export var _ray_cast: RayCast3D


func _ready() -> void:
	_ray_cast.target_position = Vector3.FORWARD * speed / 60.0


func _physics_process(delta: float) -> void:
	var collider := _ray_cast.get_collider()
	if collider:
		queue_free()
		if multiplayer.is_server() and collider is Player:
			collider.die()
		return
	global_position -= global_basis.z * speed * delta
