@tool
extends Area3D

const SPIKE_SIZE := 2.0

@export var size := Vector3(4, 0, 4):
	set(value):
		size = value
		update()
@export var spike_mesh: Mesh
@export var coll_shapes: Array[CollisionShape3D]
@export var bottom_mesh: MeshInstance3D

var _mm: MultiMesh


func _ready() -> void:
	if spike_mesh:
		var mm_inst := MultiMeshInstance3D.new()
		_mm = MultiMesh.new()
		_mm.transform_format = MultiMesh.TRANSFORM_3D
		_mm.mesh = spike_mesh
		mm_inst.multimesh = _mm
		mm_inst.position.y = SPIKE_SIZE * 0.5
		add_child(mm_inst)
		update()
	if multiplayer.is_server():
		body_entered.connect(_on_body_entered)
	else:
		monitoring = false


func update():
	var num_spikes_x := floori(size.x / SPIKE_SIZE)
	var num_spikes_z := floori(size.z / SPIKE_SIZE)
	for cs in coll_shapes:
		if cs and cs.shape is BoxShape3D:
			cs.shape.size.x = num_spikes_x * SPIKE_SIZE
			cs.shape.size.z = num_spikes_z * SPIKE_SIZE
	if bottom_mesh and bottom_mesh.mesh is PlaneMesh:
		bottom_mesh.mesh.size.x = num_spikes_x * SPIKE_SIZE
		bottom_mesh.mesh.size.y = num_spikes_z * SPIKE_SIZE
	if not _mm: return
	_mm.instance_count = maxi(0, num_spikes_x * num_spikes_z)
	var start_pos := Vector3(
		(num_spikes_x - 1) * SPIKE_SIZE * -0.5,
		0,
		(num_spikes_z - 1) * SPIKE_SIZE * -0.5
	)
	for i in _mm.instance_count:
		@warning_ignore("integer_division")
		_mm.set_instance_transform(i, Transform3D(Basis(), start_pos + Vector3(
			(i % num_spikes_x) * SPIKE_SIZE,
			0,
			(i / num_spikes_x) * SPIKE_SIZE
		)))


func _on_body_entered(body: Node3D) -> void:
	var player := body as Player
	if player:
		player.die()
