extends CanvasLayer

@onready var _interact_label: RichTextLabel = $InteractLabel
@onready var _crosshair: Control = $Crosshair

signal main_menu_pressed()


func _ready() -> void:
	hide()
	hide_interact_prompt()
	close_pause_menu()
	hide_loading_screen()
	set_spectated_player(-1)
	if OS.has_feature("debug"):
		%CheckBoxDebugDraw.button_pressed = Globals.debug_draw_enabled
		%CheckBoxInvinciblePlayers.button_pressed = Globals.debug_players_invincible
		%CheckBoxInvinciblePlayers.visible = multiplayer.is_server()
	else:
		%DebugMenu.queue_free()


func show_crosshair() -> void:
	_crosshair.show()


func hide_crosshair() -> void:
	_crosshair.hide()


func show_interact_prompt(text: String) -> void:
	if _interact_label:
		_interact_label.show()
		_interact_label.text = text
		#_interact_label.text = "[E] " + text


func hide_interact_prompt() -> void:
	if _interact_label:
		_interact_label.hide()


func set_current_power(_value: int) -> void:
	#%LabelCurrentPower.text = str(value)
	pass


func set_max_power(_value: int) -> void:
	#%LabelMaxPower.text = str(value)
	pass


func set_spectated_player(id: int) -> void:
	if id < 1:
		%LabelSpectating.hide()
	else:
		%LabelSpectating.show()
		%LabelSpectating.text = "Spectating %d" % id


func open_pause_menu() -> void:
	if not multiplayer.has_multiplayer_peer():
		get_tree().paused = true
	%LabelPaused.text = "Paused" if MultiplayerManager.mode == MultiplayerManager.Mode.SINGLE_PLAYER\
			else "Not Paused!"
	%PauseMenu.show()


func close_pause_menu() -> void:
	get_tree().paused = false
	%PauseMenu.hide()


func is_pause_menu_open() -> bool:
	return %PauseMenu.visible


func show_loading_screen() -> void:
	%LoadingScreen.show()


func hide_loading_screen() -> void:
	%LoadingScreen.hide()


func is_loading_screen_visible() -> bool:
	return %LoadingScreen.visible


func _on_button_main_menu_pressed() -> void:
	main_menu_pressed.emit()


func _on_button_quit_pressed() -> void:
	get_tree().quit()


func _on_check_box_debug_draw_toggled(toggled_on: bool) -> void:
	Globals.debug_draw_enabled = toggled_on


func _on_check_box_invincible_players_toggled(toggled_on: bool) -> void:
	Globals.debug_players_invincible = toggled_on
