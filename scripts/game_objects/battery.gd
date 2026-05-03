extends Area3D


func _ready() -> void:
	if multiplayer.is_server():
		body_entered.connect(_on_body_entered)
	else:
		monitoring = false


func _process(delta: float) -> void:
	rotate_y(delta * 2.5)


func _on_body_entered(_body: Node3D) -> void:
	SignalBus.battery_collected.emit(self)
	_collect.rpc()


@rpc("call_local")
func _collect() -> void:
	$battery.hide()
	$GPUParticles3D.restart()
	if multiplayer.is_server():
		$GPUParticles3D.finished.connect(queue_free)
