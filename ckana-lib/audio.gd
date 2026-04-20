extends Node

#TODO Create an enum for sound effects
#enum {SOUND_WIN, SOUND_LOSE}


var _music_player: AudioStreamPlayer
var _sfx_players: Dictionary[int, AudioStreamPlayer]


#func _ready() -> void:
	#_start_music()
	#_init_sfx()


func play_sound(idx: int) -> void:
	if idx in _sfx_players:
		_sfx_players[idx].play()
	else:
		push_error("No SFX player found for sound effect index: %d" % idx)



func _start_music() -> void:
	# Uncomment the commented lines if using a separate intro and loop track
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = &"Music"
	_music_player.stream = load("") # Music path (or intro if using intro)
	#var stream2 = load("") # Loop path if using intro
	add_child(_music_player)
	_music_player.play()
	#await _music_player.finished
	#_music_player.stream = stream2
	#_music_player.play()


func _init_sfx() -> void:
	pass # Use _add_sfx for each sound effect here


func _add_sfx(idx: int, stream: AudioStream, max_polyphony: int = 1) -> void:
	var player = AudioStreamPlayer.new()
	player.bus = &"SFX"
	player.stream = stream
	player.max_polyphony = max_polyphony
	add_child(player)
	_sfx_players[idx] = player


func _add_randomized_sfx(idx: int, streams: Array[AudioStream], max_polyphony: int = 1,
		random_pitch: float = 1.0, random_volume_offset_db: float = 0.0) -> void:
	var randomizer := AudioStreamRandomizer.new()
	for stream in streams:
		randomizer.add_stream(-1, stream, 1.0)
	randomizer.random_pitch = random_pitch
	randomizer.random_volume_offset_db = random_volume_offset_db
	var player := AudioStreamPlayer.new()
	player.bus = &"SFX"
	player.stream = randomizer
	player.set_max_polyphony(max_polyphony)
	add_child(player)
	_sfx_players[idx] = player
