extends StaticBody3D

const SHOOT_INTERVAL = 0.2
const INACCURACY = 0.1
const RANGE_SQ = pow(30, 2)
const ROTATION_SPEED = 4.0

var powered := true

var _bullet_scene := load("uid://cg2dfyeqomjl2") as PackedScene
@export var _room: Room
@onready var _spawn_marker: Marker3D = $turret/Marker3D
@onready var _ray_cast: RayCast3D = $RayCast3D
@onready var _turret: Node3D = $turret
var _cooldown := 0.0


func _ready() -> void:
	if multiplayer.is_server():
		if _room:
			_room.powered_on.connect(set.bind("powered", true))
			_room.powered_off.connect(set.bind("powered", false))
	else:
		set_physics_process(false)


func _physics_process(delta: float) -> void:
	if not powered: return
	var targets: Array[Player]
	for player in Player.living_players:
		if global_position.distance_squared_to(player.global_position) > RANGE_SQ:
			continue
		_ray_cast.look_at(player.global_position.slide(Vector3.UP) + Vector3.UP * _ray_cast.global_position.y)
		_ray_cast.force_raycast_update()
		if _ray_cast.get_collider() is Player:
			targets.append(_ray_cast.get_collider())
	
	_cooldown -= delta
	if not targets:
		_cooldown = maxf(_cooldown, 0.0)
		return
	
	var smallest_angle := PI
	for target in targets:
		var to_target := (target.global_position - global_position)
		var angle_to_target := Vector2(-to_target.z, -to_target.x).angle()
		var angle := angle_difference(_turret.global_rotation.y, angle_to_target)
		#print(angle)
		if abs(angle) < abs(smallest_angle):
			smallest_angle = angle
	
	var rotation_delta := minf(ROTATION_SPEED * delta, abs(smallest_angle)) * signf(smallest_angle)
	_turret.rotate_y(rotation_delta)
	if _cooldown <= 0.0 and abs(smallest_angle) < ROTATION_SPEED * delta:
		_cooldown += SHOOT_INTERVAL
		_shoot.rpc(Utils.get_random_direction(), randf_range(-1, 1) * INACCURACY)


@rpc("call_local")
func _shoot(axis: Vector3, angle: float) -> void:
	var bullet := _bullet_scene.instantiate() as Node3D
	if not bullet: return
	bullet.position = _spawn_marker.global_position
	bullet.rotation = _turret.global_rotation
	bullet.rotate(axis, angle)
	add_child(bullet)
