class_name PowerableComponent extends Node

@export var room: Room
var powered: bool


func _ready() -> void:
	if multiplayer.is_server() and room:
		room.powered_on.connect(set.bind("powered", true))
		room.powered_off.connect(set.bind("powered", false))
		powered = room.is_powered
