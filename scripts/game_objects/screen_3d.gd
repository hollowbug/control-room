extends Node3D

const ControlScreen = preload("uid://c27xetfc8jtx6")

var screen: ControlScreen

@export var _interact_area: InteractArea
#@export var _camera: Camera3D
@export var _sub_viewport: SubViewport
@export var _sub_viewport_container: SubViewportContainer
@export var _screen_mesh: MeshInstance3D
@export var _screen_frame_mesh: MeshInstance3D
#var _screen_plane: Plane
var _turned_on := false
var _player_using_screen := false
#var _material_white = preload("uid://vevkw7ptvn7n")
var _material_white_outlined = preload("uid://blaiawgnvo4ud")


func _ready() -> void:
	if not (_interact_area and _sub_viewport and _sub_viewport_container and _screen_mesh):
		return
	#_screen_plane = Plane(_camera.global_basis.z, -_camera.global_position.z)
	_interact_area.interact_ray_entered.connect(_on_interact_area_ray_entered)
	_interact_area.interact_ray_exited.connect(_on_interact_area_ray_exited)
	_interact_area.interact_requested.connect(_on_interact_area_interact_requested)


func _input(event: InputEvent) -> void:
	if event.is_pressed() and event is InputEventKey and event.keycode == KEY_ESCAPE and _player_using_screen:
		exit()
		get_viewport().set_input_as_handled()


@rpc("call_local")
func turn_on() -> void:
	if not _sub_viewport: return
	_turned_on = true
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _sub_viewport.get_texture()
	#mat.albedo_texture_force_srgb = true
	#mat.emission_enabled = true
	#mat.emission = Color.WHITE
	#mat.emission_texture = mat.albedo_texture
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	_screen_mesh.material_override = mat
	if not screen:
		screen = load("uid://b4v2edubn7buh").instantiate() as ControlScreen
		if screen:
			_sub_viewport.add_child(screen)


@rpc("call_local")
func turn_off() -> void:
	_turned_on = false
	_screen_mesh.material_override = null


func view() -> void:
	if not (_sub_viewport and _sub_viewport_container and _sub_viewport.get_parent() != _sub_viewport_container\
			and Globals.local_player): return
	_player_using_screen = true
	Globals.local_player.give_up_control()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_sub_viewport.reparent(_sub_viewport_container)
	_sub_viewport_container.show()
	UI.hide()


func exit() -> void:
	if not (_sub_viewport and _sub_viewport_container and _sub_viewport.get_parent() != self\
			and Globals.local_player): return
	_player_using_screen = false
	Globals.local_player.take_control()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_sub_viewport.reparent(self)
	_sub_viewport_container.hide()
	UI.show()


func _on_interact_area_ray_entered(_player: Player) -> void:
	if _turned_on:
		UI.show_interact_prompt("View")
		if _screen_frame_mesh:
			_screen_frame_mesh.material_overlay = _material_white_outlined


func _on_interact_area_ray_exited(_player: Player) -> void:
	UI.hide_interact_prompt()
	if _screen_frame_mesh:
			_screen_frame_mesh.material_overlay = null


func _on_interact_area_interact_requested(_player: Player) -> void:
	if _turned_on and not _player_using_screen:
		view()
