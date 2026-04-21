extends Node3D

const ControlScreen = preload("uid://c27xetfc8jtx6")

@export var _interact_area: InteractArea
@export var _camera: Camera3D
@export var _sub_viewport: SubViewport
@export var _screen_mesh: MeshInstance3D
@onready var _screen_plane: Plane
var _turned_on := false
var _player_using_screen := false
var _screen: CanvasLayer


func _ready() -> void:
	if not (_interact_area and _camera and _sub_viewport and _screen_mesh):
		return
	_screen_plane = Plane(_camera.global_basis.z, -_camera.global_position.z)
	_interact_area.interact_ray_entered.connect(_on_interact_area_ray_entered)
	_interact_area.interact_ray_exited.connect(_on_interact_area_ray_exited)
	_interact_area.interact_requested.connect(_on_interact_area_interact_requested)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _sub_viewport.get_texture()
	_screen_mesh.material_override = mat


@rpc("reliable", "call_local")
func turn_on() -> void:
	if not _sub_viewport: return
	_turned_on = true
	_screen = load("uid://b4v2edubn7buh").instantiate() as ControlScreen
	if _screen:
		_sub_viewport.add_child(_screen)


@rpc("reliable", "call_local")
func turn_off() -> void:
	_turned_on = false


func _on_interact_area_ray_entered(_player: Player) -> void:
	UI.show_interact_prompt("View")


func _on_interact_area_ray_exited(_player: Player) -> void:
	UI.hide_interact_prompt()


func _on_interact_area_interact_requested(player: Player) -> void:
	if _camera and _turned_on and not _player_using_screen:
		_player_using_screen = true
		player.give_up_control()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_camera.global_transform = player.camera.global_transform
		var tween = create_tween().set_trans(Tween.TRANS_QUART)
		tween.tween_property(_camera, "transform", Transform3D.IDENTITY, 0.3)
