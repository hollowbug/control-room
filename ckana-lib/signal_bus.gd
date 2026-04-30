extends Node

@warning_ignore_start("unused_signal")
signal door_open_requested(door: Door)
signal door_close_requested(door: Door)
signal room_power_on_requested(room: Room)
signal room_power_off_requested(room: Room)
signal cctv_camera_change_requested(new_camera: CCTVCamera)
signal current_cctv_camera_changed(new_camera: CCTVCamera)
signal player_died(player: Player)
