extends Node

signal setting_changed(setting: StringName, new_value: Variant)

const SETTINGS_FILE_PATH = "user://settings.cfg"

#region AUDIO SETTINGS
var master_volume := 0.5:
	set(value):
		master_volume = value
		AudioServer.set_bus_volume_linear(0, value)
var music_volume := 1.0:
	set(value):
		music_volume = value
		AudioServer.set_bus_volume_linear(1, value)
var sfx_volume := 1.0:
	set(value):
		sfx_volume = value
		AudioServer.set_bus_volume_linear(2, value)
#endregion

var _setting_property_names: Array[StringName]


func save_settings() -> void:
	var settings: Dictionary
	if OS.get_name() in ["Windows", "Linux"]:
		_save_window_settings(settings)
	for prop in _setting_property_names:
		settings[prop] = get(prop)
	Utils.save_config_file(SETTINGS_FILE_PATH, settings)


func _ready() -> void:
	_init_property_names()
	get_window().min_size = Vector2(1280, 720)
	_load_settings()
	tree_exiting.connect(save_settings)


func _load_settings() -> void:
	var data = Utils.load_config_file(SETTINGS_FILE_PATH)
	if data is Dictionary:
		for key in data:
			set(key, data[key])
		if OS.get_name() in ["Windows", "Linux"]:
			_restore_window_settings(data)


func _save_window_settings(settings: Dictionary) -> void:
	if OS.get_name() not in ["Windows", "Linux"]: return
	settings.window_mode = DisplayServer.window_get_mode()
	if settings.window_mode == DisplayServer.WINDOW_MODE_FULLSCREEN\
	or settings.window_mode == DisplayServer.WINDOW_MODE_MAXIMIZED:
		settings.window_screen = DisplayServer.window_get_current_screen()
	else:
		settings.window_position = get_window().position
		settings.window_size = get_window().size


func _restore_window_settings(settings: Dictionary) -> void:
	if "window_mode" in settings:
		DisplayServer.window_set_mode(settings.window_mode)
		if settings.window_mode == DisplayServer.WINDOW_MODE_FULLSCREEN\
		or settings.window_mode == DisplayServer.WINDOW_MODE_MAXIMIZED:
			DisplayServer.window_set_current_screen(settings.window_screen)
		else:
			if "window_position" in settings:
				get_window().position = settings.window_position
			if "window_size" in settings:
				get_window().size = settings.window_size


func _set(property: StringName, value: Variant) -> bool:
	# Emit signal when a setting is changed
	if property in _setting_property_names:
		setting_changed.emit(property, value)
	return true


func _init_property_names() -> void:
	for dict in get_script().get_script_property_list():
		if dict.type != TYPE_NIL and dict.name != &"_setting_property_names":
			_setting_property_names.append(dict.name)
