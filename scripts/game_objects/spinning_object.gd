extends AnimatableBody3D

@export var power_comp: PowerableComponent
@export var rotation_axis := Vector3.UP
@export var rotation_speed := 2.0
@export var host_only := true


func _physics_process(delta: float) -> void:
	if host_only and not multiplayer.is_server():
		return
	if power_comp and not power_comp.powered:
		return
	rotate(rotation_axis, rotation_speed * delta)
