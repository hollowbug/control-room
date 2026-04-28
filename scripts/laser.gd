extends Node3D

@export var ray_cast: RayCast3D
@export var mesh_inst: MeshInstance3D
@export var anim_player: AnimationPlayer
var turned_on := true


func _ready() -> void:
	if multiplayer.is_server():
		anim_player.play("laser_1")


func _physics_process(_delta: float) -> void:
	if not ray_cast or not mesh_inst: return
	var laser_length := ray_cast.target_position.length()
	
	if ray_cast.is_colliding():
		laser_length = global_position.distance_to(ray_cast.get_collision_point()) + 0.1
		if is_multiplayer_authority():
			var player := ray_cast.get_collider() as Player
			if player:
				player.die.rpc()
	
	var cylinder := mesh_inst.mesh as CylinderMesh
	if cylinder:
		cylinder.height = laser_length
		mesh_inst.position = ray_cast.target_position.normalized() * laser_length * 0.5


@rpc("call_local")
func turn_on() -> void:
	turned_on = true
	if ray_cast: ray_cast.enabled = true
	if mesh_inst: mesh_inst.show()


@rpc("call_local")
func turn_off() -> void:
	turned_on = false
	if ray_cast: ray_cast.enabled = false
	if mesh_inst: mesh_inst.hide()
