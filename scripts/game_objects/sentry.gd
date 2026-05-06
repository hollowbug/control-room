extends CharacterBody3D

const SPEED = 3.0
const ACCELERATION = 50.0
const TURRET_ROT_SPEED = 4.0
const BASE_ROT_SPEED = 2.0
const TurretComponent = preload("uid://k0yyoomj42jk")

enum State { STANDBY, READY_TO_CHASE, ROTATING_TURRET, ROTATING_BASE, MOVING }

var powered := true

@onready var _vision: VisionComponent = $VisionComponent
@onready var _turret: TurretComponent = $turret
@export var _powerable: PowerableComponent
var _state := State.STANDBY
var _target_pos: Vector3
var _move_dir := 1
var _try_move_result: Vector3


func _ready() -> void:
	if not multiplayer.is_server():
		set_physics_process(false)


func _physics_process(delta: float) -> void:
	if _powerable and not _powerable.powered: return
	
	if Globals.debug_draw_enabled:
		DebugDraw3D.draw_sphere(_target_pos, 0.5, Color.RED)
	
	var target := _vision.rotate_toward_nearest_player_by_angle(delta)
	
	# Shoot when seeing players
	if _vision.target_rotation_reached:
		_turret.shoot(delta)
	
	if target:
		velocity = Vector3.UP * velocity.y
		if _try_move(target.global_position) and  _try_move_result.distance_to(target.global_position) < 2:
			_state = State.READY_TO_CHASE
			_target_pos = _try_move_result
		elif _state != State.READY_TO_CHASE:
			_state = State.STANDBY
	
	# Otherwise move randomly and rotate cannon randomly
	else:
		_roam_behavior(delta)
	
	velocity += get_gravity()
	move_and_slide()


func _roam_behavior(delta: float) -> void:
	match _state:
		State.STANDBY:
			# Wait a random amount of time
			if randf() < 0.98: return
			# 25% chance to pick a random target position and move to it
			if randf() < 0.25:
				if _try_move(global_position + Vector3.RIGHT.rotated(Vector3.UP, randf() * TAU) * 50):
					_state = State.ROTATING_BASE
					_target_pos = _try_move_result
			if _state == State.STANDBY: # 75% chance to start rotating cannon to a random angle
				_state = State.ROTATING_TURRET
				_target_pos = global_position + Vector3.RIGHT.rotated(Vector3.UP, randf() * TAU)
		
		State.ROTATING_TURRET:
			if Utils.rotate_toward_target(_turret, _target_pos, TURRET_ROT_SPEED * delta):
				_state = State.STANDBY
		
		State.ROTATING_BASE, State.READY_TO_CHASE:
			_state = State.ROTATING_BASE
			var tmp := _turret.global_rotation
			var target := _target_pos if _move_dir == 1 else\
				(_target_pos - global_position) * -1 + global_position
			if Utils.rotate_toward_target(self, target, BASE_ROT_SPEED * delta):
				_state = State.MOVING
			_turret.global_rotation = tmp
		
		State.MOVING:
			velocity = -global_basis.z * SPEED * _move_dir
			if Globals.debug_draw_enabled:
				DebugDraw3D.draw_arrow(global_position, _target_pos, Color.WHITE, 0.5)
			if global_position.distance_squared_to(_target_pos) < 0.5:
				_state = State.STANDBY
				velocity = Vector3.ZERO


func _try_move(target: Vector3) -> bool:
	target.y = global_position.y
	var test_coll := KinematicCollision3D.new()
	var test_motion := global_position.direction_to(target) * 50
	var result := test_move(global_transform, test_motion, test_coll)
	var pos := test_coll.get_position() if result else global_position + test_motion
	pos.y = global_position.y
	var dist := global_position.distance_to(pos) if result else 50.0
	if dist > 5.0:
		_move_dir = 1 if global_basis.z.angle_to(test_motion) > PI * 0.5 else -1
		var target_dist := randf_range(dist * 0.5, dist - 2.0)
		_try_move_result = global_position.move_toward(pos, target_dist)
		return true
	return false
