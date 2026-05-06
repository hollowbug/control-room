extends CharacterBody3D
class_name Player

const SPEED = 6.5
const JUMP_VELOCITY = 4.0
const JUMP_GRAVITY = -4.0
const FALL_GRAVITY = 12.0
const CAMERA_MAX_PITCH_DEGREES = 85
const MOUSE_SENSITIVITY = 0.002

# Head bob
const BOB_FREQ = 2.0
const BOB_AMP = 0.08
var _t_bob: float

# FOV
const BASE_FOV := 70.0
const FOV_CHANGE := 10.0

static var living_players: Array[Player]

# Interactions
@export var interact_ray: RayCast3D
var interact_area: InteractArea

# Holding items
var carry_strength := 1000.0
var held_item: RigidBody3D
var held_item_target_distance: float

@export var jump_timer: Timer
@export var player_control: bool
@export var camera: Camera3D
var is_dead := false
var color: Color

var _jumping := false


func _enter_tree() -> void:
	living_players.append(self)
	if name.is_valid_int():
		set_multiplayer_authority(int(name))


func _exit_tree() -> void:
	living_players.erase(self)


func _ready() -> void:
	if jump_timer:
		jump_timer.timeout.connect(_on_jump_timer_timeout)
	if is_multiplayer_authority():
		Globals.local_player = self
		take_control()
	else:
		#set_physics_process(false)
		if interact_ray:
			interact_ray.enabled = false


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and player_control and not UI.is_pause_menu_open() and not is_dead:
			rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
			camera.rotation.x -= event.relative.y * MOUSE_SENSITIVITY
			camera.global_rotation.x = clampf(camera.global_rotation.x, -deg_to_rad(CAMERA_MAX_PITCH_DEGREES), deg_to_rad(CAMERA_MAX_PITCH_DEGREES))


func _unhandled_input(event: InputEvent) -> void:
	if not player_control or UI.is_pause_menu_open(): return
	if event.is_action_pressed("interact"):
		if held_item:
			drop_held_item()
			get_viewport().set_input_as_handled()
		elif interact_area:
			interact_area.interact_requested.emit(self)
			get_viewport().set_input_as_handled()	
	if OS.has_feature("debug") and event.is_action_pressed("debug_kill"):
		_on_death.rpc()


func _physics_process(delta: float) -> void:
	# Add gravity
	if not is_on_floor():
		if _jumping and not Input.is_action_pressed("jump"):
			_jumping = false
		velocity += Vector3.DOWN * (JUMP_GRAVITY if _jumping else FALL_GRAVITY) * delta

	# Handle jump
	elif not is_dead and Input.is_action_just_pressed("ui_accept"):
		if jump_timer:
			jump_timer.start()
			_jumping = true
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement
	var input_dir := Vector2()
	if player_control and not is_dead and not UI.is_pause_menu_open():
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized() * SPEED
	direction.y = velocity.y
	velocity = velocity.move_toward(direction, delta * SPEED * (2.5 if is_on_floor() else 0.8))
	
	# Head bob
	if not is_dead:
		_t_bob += delta * velocity.length() * float(is_on_floor())
		camera.position = _head_bob(_t_bob)
	
	# FOV
	var speed_ratio := minf(velocity.length(), SPEED * 2) / SPEED
	var target_fov := BASE_FOV + FOV_CHANGE * speed_ratio
	camera.fov = lerpf(camera.fov, target_fov, delta * 8.0)

	move_and_slide()
	_process_interact_ray()
	_move_held_item(delta)


func take_control() -> void:
	if not player_control:
		player_control = true
		UI.show_crosshair()
		if camera:
			camera.make_current()
		if interact_ray:
			interact_ray.enabled = true


func give_up_control() -> void:
	if player_control:
		player_control = false
		UI.hide_interact_prompt()
		UI.hide_crosshair()
		drop_held_item()
		if interact_ray:
			interact_ray.enabled = false


func pick_up_item(item: RigidBody3D) -> void:
	# Ignore if already holding an item
	if is_instance_valid(held_item): return
	held_item = item
	held_item_target_distance = camera.global_position.distance_to(item.global_position)
	if interact_ray:
		interact_ray.enabled = false


func drop_held_item() -> void:
	held_item = null
	if interact_ray:
		interact_ray.enabled = true


func die() -> void:
	## Host handles killing players
	if multiplayer.is_server():
		_on_death.rpc()


func _head_bob(time) -> Vector3:
	return Vector3.UP * sin(time * BOB_FREQ) * BOB_AMP


func _process_interact_ray() -> void:
	if not interact_ray: return
	var collider := interact_ray.get_collider() if interact_ray.enabled else null
	if collider != interact_area:
		if interact_area:
			interact_area.interact_ray_exited.emit(self)
			UI.hide_interact_prompt()
			interact_area = null
		elif collider is InteractArea:
			interact_area = collider
			interact_area.interact_ray_entered.emit(self)


func _move_held_item(_delta: float) -> void:
	if not is_instance_valid(held_item): return
	
	# Release item if too far
	var dot := -camera.global_basis.z.dot(camera.global_position.direction_to(held_item.global_position))
	if dot < 0.5:
		drop_held_item()
		return
	
	var target_pos := camera.global_position - camera.global_basis.z * held_item_target_distance
	var target_velocity := (target_pos - held_item.global_position) * 100
	var linear_force := (target_velocity - held_item.linear_velocity * 10) * held_item.mass
	linear_force = linear_force.limit_length(carry_strength)
	#DebugDraw3D.draw_arrow_ray(held_item.global_position, force, 0.1, Color.WHITE, 0.1)
	held_item.apply_force(linear_force)
	var angular_force := held_item.angular_velocity * -5
	held_item.apply_torque(angular_force)


func _on_jump_timer_timeout() -> void:
	_jumping = false


func _death_animation() -> void:
	var target_basis: Basis
	if velocity.slide(Vector3.UP).length() > 0.5:
		target_basis = Basis(velocity.slide(Vector3.UP).normalized().rotated(Vector3.UP, PI * 0.5), PI * 0.5)
	else:
		target_basis = Basis(Vector3.RIGHT.rotated(Vector3.UP, randf() * TAU), PI * 0.5)
	var tween = create_tween().set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN).set_parallel()
	tween.tween_property($CollisionShape3D, "global_basis", target_basis, 0.3)
	tween.tween_property($MeshInstance3D, "global_basis", target_basis, 0.3)


#region RPCs called by the host /////////////////////////////

@rpc("any_peer", "call_local")
func set_global_transform_rpc(pos: Vector3, rot: Vector3) -> void:
	global_position = pos
	global_rotation = rot


@rpc("any_peer", "call_local")
func _on_death() -> void:
	if is_dead: return
	is_dead = true
	if interact_ray:
		interact_ray.enabled = false
	living_players.erase(self)
	SignalBus.player_died.emit(self)
	var camera_xform = camera.transform.translated(Vector3(0, 3, 3)).rotated_local(Vector3.LEFT, PI * 0.35)
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera, "transform", camera_xform, 3.0)
	if is_multiplayer_authority():
		_death_animation()

#endregion
