extends CanvasLayer

@onready var _interact_label: RichTextLabel = $InteractLabel
@onready var _crosshair: Control = $Crosshair


func _ready() -> void:
	hide()
	hide_interact_prompt()
	close_pause_menu()


func show_crosshair() -> void:
	_crosshair.show()


func hide_crosshair() -> void:
	_crosshair.hide()


func show_interact_prompt(text: String) -> void:
	if _interact_label:
		_interact_label.show()
		_interact_label.text = "[E] " + text


func hide_interact_prompt() -> void:
	if _interact_label:
		_interact_label.hide()


func open_pause_menu() -> void:
	%LabelPaused.text = "Paused" if MultiplayerManager.mode == MultiplayerManager.Mode.SINGLE_PLAYER\
			else "Not Paused!"
	%PauseMenu.show()


func close_pause_menu() -> void:
	%PauseMenu.hide()


func is_pause_menu_open() -> bool:
	return %PauseMenu.visible
