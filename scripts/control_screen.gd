extends CanvasLayer

const MINIMAP_MARGIN = 10.0
const MiniMap = preload("uid://mhiesrb42cqw")
const RoomButton = preload("uid://dkcl37srj8ro5")
const DoorButton = preload("uid://bkug5p21t45qo")

@onready var _mini_map: MiniMap = %MiniMap
var _door_button_scene: PackedScene = load("uid://bwivs6k02v0qm")
var _room_button_scene: PackedScene = load("uid://smfvgr0mbiy1")


func _ready() -> void:
	# Wait for Controls to update their size
	while %MiniMapContainer.size == Vector2.ZERO:
		await get_tree().process_frame
		if not is_inside_tree(): return
	setup()


func setup() -> void:
	var rooms: Array[Room]
	rooms.assign(get_tree().get_nodes_in_group("rooms"))
	
	# Calculate the map size
	var used_rect := Rect2()
	for room in rooms:
		for x in room.room_size.x:
			for y in room.room_size.y:
				var rotated := Utils.rotate_vector2i(Vector2i(x,y), room.room_rotation)
				used_rect = used_rect.expand(room.grid_position + rotated)
		if room.is_in_group("starting_room"):
			%MiniMapPivot.rotation = room.rotation.y + PI * 0.5
	used_rect.size += Vector2.ONE
	used_rect.position += Vector2.ONE * -0.5
	var size_with_margin = %MiniMapContainer.size - Vector2.ONE * MINIMAP_MARGIN
	_mini_map.draw_scale = minf(
	#_mini_map.scale = minf(
		size_with_margin.x / (used_rect.size.x * Globals.CELL_SIZE),
		size_with_margin.y / (used_rect.size.y * Globals.CELL_SIZE)
	)# * Vector2.ONE
	var map_center := Vector2(used_rect.position) + Vector2(used_rect.size) * 0.5
	_mini_map.position = -map_center * Globals.CELL_SIZE * _mini_map.draw_scale
	
	# Generate minimap
	#var i = 0
	for room in rooms:
		var pivot := Node2D.new()
		pivot.position = Vector2(room.grid_position) * Globals.CELL_SIZE * _mini_map.draw_scale
		pivot.rotation = room.room_rotation * PI * 0.5
		
		var color_rect := ColorRect.new()
		color_rect.position = Vector2(-0.5, -0.5) * (Globals.CELL_SIZE - Globals.CELL_MARGIN * 2) * _mini_map.draw_scale
		color_rect.color = Color(1,1,1,0.5)
		color_rect.size = (Vector2(room.room_size) * Globals.CELL_SIZE - Vector2.ONE * Globals.CELL_MARGIN * 2) * _mini_map.draw_scale
		color_rect.z_index = -3
		pivot.add_child(color_rect)
		
		#color_rect = ColorRect.new()
		#color_rect.color = Color.AQUA
		#color_rect.size = Vector2.ONE * 10
		#color_rect.position = Vector2.ONE * -5
		#pivot.add_child(color_rect)
		
		_mini_map.add_child(pivot)
		
		#color_rect = ColorRect.new()
		#color_rect.size = Vector2.ONE * 10
		#color_rect.position = Vector2(room.global_position.x, room.global_position.z) * _mini_map.draw_scale
		#_mini_map.add_child(color_rect)
		
		#var label := Label.new()
		#label.text = str(i)
		#label.set_anchors_preset(Control.PRESET_CENTER)
		#color_rect.add_child(label)
		#i += 1
		
		var button := _room_button_scene.instantiate() as RoomButton
		if not button: continue
		button.room = room
		button.position = Vector2(room.room_size - Vector2i.ONE) * 0.5 * Globals.CELL_SIZE * _mini_map.draw_scale
		pivot.add_child(button)
		button.global_rotation = 0
	
	#get_tree().call_group("doors", "open")
	
	var doors: Array[Door]
	doors.assign(get_tree().get_nodes_in_group("doors"))
	for door in doors:
		var button := _door_button_scene.instantiate() as DoorButton
		if not button: break
		button.door = door
		button.position = Vector2(door.global_position.x, door.global_position.z) * _mini_map.draw_scale
		button.rotation = door.rotation.y
		_mini_map.add_child(button)
