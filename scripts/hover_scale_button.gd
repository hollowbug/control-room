extends BaseButton


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		scale = Vector2.ONE * 1.2
	elif what == NOTIFICATION_MOUSE_EXIT:
		scale = Vector2.ONE
