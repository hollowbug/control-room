class_name VisionComponent extends RayCast3D

enum Mode { Y_ONLY, OMNIDIRECTIONAL }

## OMNIDIRECTIONAL is not yet implemented.
## This property currently has no effect.
@export var mode := Mode.Y_ONLY
@export var vision_range := 30.0:
	set(value):
		vision_range = value
		_range_sq = value * value
@export_custom(PROPERTY_HINT_RANGE, "0,360,1,radians_as_degrees") var fov := PI
@export var node_to_rotate: Node3D
@export var rotation_speed := 4.0
## If [code]true[/code], the target rotation was reached with
## the latest call to [method rotate_toward_nearest_player_by_angle].
var target_rotation_reached := false

var _range_sq := pow(vision_range, 2.0)


func _ready() -> void:
	# Enable raycast in editor builds for the purpose of visible collision shapes
	# (it doesn't need to actually be enabled to use force_raycast_update())
	enabled = OS.has_feature("editor")


#func find_nearest_player() -> Player:


## Raycasts towards [Player]s that are within range and field of view.
## If any are detected, rotates [member node_to_rotate] towards the target
## that requires the smallest rotation and returns the target.
func rotate_toward_nearest_player_by_angle(delta: float) -> Player:
	target_rotation_reached = false
	if not is_instance_valid(node_to_rotate):
		return null
	
	var target: Player
	var smallest_angle := PI
	for player in Player.living_players:
		if global_position.distance_squared_to(player.global_position) > _range_sq:
			continue
		var to_target := (player.global_position - global_position)
		var angle_to_target := Vector2(-to_target.z, -to_target.x).angle()
		var angle := angle_difference(node_to_rotate.global_rotation.y, angle_to_target)
		if angle > fov * 0.5 or abs(angle) > abs(smallest_angle):
			continue
		look_at(player.global_position.slide(Vector3.UP) + Vector3.UP * global_position.y)
		force_raycast_update()
		if get_collider() is Player:
			smallest_angle = angle
			target = get_collider()
	
	if not target: return null
	
	var rotation_delta := minf(rotation_speed * delta, abs(smallest_angle)) * signf(smallest_angle)
	node_to_rotate.rotate_y(rotation_delta)
	target_rotation_reached = abs(smallest_angle) < rotation_speed * delta
	return target
