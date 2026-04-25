extends Node2D

var door: Door


func _ready() -> void:
	$Button.pressed.connect(_on_pressed)
	if door:
		door.opened.connect(_on_door_opened)
		door.closed.connect(_on_door_closed)


func _on_pressed() -> void:
	if door:
		if door.is_open:
			door.request_close.rpc_id(1)
		else:
			door.request_open.rpc_id(1)


func _on_door_opened() -> void:
	%ColorRect.color = Color.GREEN


func _on_door_closed() -> void:
	%ColorRect.color = Color.RED
