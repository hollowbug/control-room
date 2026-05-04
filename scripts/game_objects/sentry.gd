extends CharacterBody3D

const SPEED = 3.0
const ROT_SPEED = 2.0
const TurretComponent = preload("uid://k0yyoomj42jk")

var powered := true

@onready var _vision: VisionComponent = $VisionComponent
@onready var _turret: TurretComponent = $turret
@export var _powerable: PowerableComponent


func _ready() -> void:
	if not multiplayer.is_server():
		set_physics_process(false)


func _physics_process(delta: float) -> void:
	if _powerable and not _powerable.powered: return
	_vision.rotate_toward_nearest_player_by_angle(delta)
	if _vision.target_rotation_reached:
		var tmp := _turret.global_rotation.y
		global_rotation.y = rotate_toward(global_rotation.y, _turret.global_rotation.y, ROT_SPEED * delta)
		_turret.global_rotation.y = tmp
		if is_equal_approx(tmp, global_rotation.y):
			_turret.shoot(delta)
			#velocity = -global_basis.z * SPEED
			#move_and_slide()
