class_name Utils extends Object

static func is_event_left_click(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.pressed\
	and event.button_index == MOUSE_BUTTON_LEFT


static func is_event_right_click(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.pressed\
	and event.button_index == MOUSE_BUTTON_RIGHT


static func is_event_mouse_wheel_up(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP


static func is_event_mouse_wheel_down(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN


static func rotate_vector2i(vector: Vector2i, clockwise_rotations: int) -> Vector2i:
	var x := vector.x
	var y := vector.y
	match posmod(clockwise_rotations, 4):
		1: return Vector2i(-y, x)
		2: return Vector2i(-x, -y)
		3: return Vector2i(y, -x)
	return Vector2i(x, y)


static func get_random_direction() -> Vector3:
	return Vector3(
		randf_range(-1, 1),
		randf_range(-1, 1),
		randf_range(-1, 1)
	).normalized()


static func save_config_file(file_path: String, data: Variant) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("data", "data", data)
	cfg.save(file_path)


static func load_config_file(file_path: String) -> Variant:
	var config = ConfigFile.new()
	var err = config.load(file_path)
	# If the file didn't load, ignore it.
	if err != OK:
		return null
		
	return config.get_value("data", "data")
