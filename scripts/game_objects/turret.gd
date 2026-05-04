extends StaticBody3D

const TurretComponent = preload("uid://k0yyoomj42jk")
const IDLE_ROTATION_SPEED = 1.0

var powered := true

@export var _powerable: PowerableComponent
@onready var _turret: TurretComponent = $turret
@onready var _vision: VisionComponent = $VisionComponent


func _ready() -> void:
	if not multiplayer.is_server():
		set_physics_process(false)


func _physics_process(delta: float) -> void:
	if _powerable and not _powerable.powered: return
	if _vision.rotate_toward_nearest_player_by_angle(delta):
		if _vision.target_rotation_reached:
			_turret.shoot(delta)
	else:
		_turret.rotate_y(IDLE_ROTATION_SPEED * delta)
