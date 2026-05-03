extends CanvasLayer

const MAIN_SCENE_UID = "uid://v3lx8vapp48e"


func _ready() -> void:
	UI.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	match MultiplayerManager.error:
		OK: %Popup.hide()
		_: _show_popup(error_string(MultiplayerManager.error))


func _start_game() -> void:
	get_tree().change_scene_to_file.call_deferred(MAIN_SCENE_UID)


func _show_popup(text: String) -> void:
	%Popup.show()
	%LabelPopup.text = text


func _on_button_single_player_pressed() -> void:
	_start_game()


func _on_button_host_local_pressed() -> void:
	MultiplayerManager.mode = MultiplayerManager.Mode.LOCAL_HOST
	_start_game()


func _on_button_join_local_pressed() -> void:
	MultiplayerManager.mode = MultiplayerManager.Mode.LOCAL_CLIENT
	_start_game()


func _on_button_host_steam_pressed() -> void:
	MultiplayerManager.mode = MultiplayerManager.Mode.STEAM_HOST
	_start_game()


func _on_button_join_steam_pressed() -> void:
	MultiplayerManager.mode = MultiplayerManager.Mode.STEAM_CLIENT
	MultiplayerManager.lobby_code = %LineEdit.text
	_start_game()


func _on_button_quit_pressed() -> void:
	get_tree().quit()
	

func _on_button_close_popup_pressed() -> void:
	%Popup.hide()
