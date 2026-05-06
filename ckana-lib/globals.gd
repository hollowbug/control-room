extends Node

const CELL_SIZE = 22.0
const CELL_MARGIN = 1.0

var local_player: Player
var debug_draw_enabled := true
var debug_players_invincible := false


func _ready() -> void:
	if not OS.has_feature("debug"):
		debug_draw_enabled = false
		debug_players_invincible = false
