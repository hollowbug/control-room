extends MultiplayerSpawner
class_name NodeSpawner


func _init() -> void:
	spawn_function = _spawn_node


func _spawn_node(data: Variant) -> Node:
	var dict := data as Dictionary
	if not dict: return null
	var packed := load(dict.get("uid", "")) as PackedScene
	if not (packed and packed.can_instantiate()):
		return null
	var node := packed.instantiate()
	if node is Node3D:
		node.position = dict.get("position", Vector3())
		node.rotation = dict.get("rotation", Vector3())
	if node is Room:
		node.grid_position = dict.get("room_position", Vector2i())
		node.room_rotation = dict.get("room_rotation", 0)
	if "id" in dict:
		node.name = str(dict.id)
	if node is Player:
		node.color = dict.get("color", Color.WHITE)
	return node
