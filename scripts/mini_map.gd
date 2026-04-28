extends Node2D

var draw_scale := 1.0
var players: Array[Player]

@export var _player_texture: Texture2D


func _ready() -> void:
	players.assign(get_tree().get_nodes_in_group("players"))


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	for player in players:
		draw_set_transform(Vector2(player.position.x, player.position.z) * draw_scale, -player.rotation.y - PI * 0.5, Vector2.ONE * draw_scale)
		var color := player.color * 0.25 if player.is_dead else player.color
		draw_texture(_player_texture, _player_texture.get_size() * -0.5, color)
