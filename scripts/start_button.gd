extends Node3D

signal pressed()


func _ready() -> void:
	var interact_area: InteractArea = $InteractArea
	interact_area.interact_ray_entered.connect(_on_interact_ray_entered)
	interact_area.interact_ray_exited.connect(_on_interact_ray_exited)
	interact_area.interact_requested.connect(_on_interact_requested)


func _on_interact_ray_entered(player: Player) -> void:
	if player.name != "1" or multiplayer.get_unique_id() != 1: return
	UI.show_interact_prompt("Start")


func _on_interact_ray_exited(player: Player) -> void:
	if player.name != "1" or multiplayer.get_unique_id() != 1: return
	UI.hide_interact_prompt()


func _on_interact_requested(player: Player) -> void:
	if player.name != "1" or multiplayer.get_unique_id() != 1: return
	pressed.emit()
