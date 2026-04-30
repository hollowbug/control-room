extends Node2D

var draw_scale := 1.0
var players: Array[Player]

var _player_cone_texture := load("uid://ub4c1mpl6jxn") as Texture2D

func _ready() -> void:
	players.assign(get_tree().get_nodes_in_group("players"))


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	players = players.filter(is_instance_valid)
	for player in players:
		var color := player.color * 0.25 if player.is_dead else player.color
		draw_circle(Vector2(player.position.x, player.position.z) * draw_scale, draw_scale, color, true, -1, true)
		if not player.is_dead:
			draw_set_transform(Vector2(player.position.x, player.position.z) * draw_scale, -player.rotation.y - PI * 0.5, Vector2.ONE * draw_scale * 0.3)
			var pos := Vector2.UP * _player_cone_texture.get_size().y * 0.5 + Vector2.LEFT * 4
			draw_texture(_player_cone_texture, pos)
			draw_set_transform(Vector2())
