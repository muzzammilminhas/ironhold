extends Node3D
## Procedurally places obstacles within the arena bounds and bakes the
## NavigationRegion3D navmesh afterward. Placement uses rejection sampling:
## pick a random point, keep it only if it clears the open center and doesn't
## crowd an already-placed obstacle, up to a bounded number of attempts so a
## bad draw can't hang the game.

signal generation_complete

const ARENA_HALF_EXTENT := 20.0     # inside the boundary walls (walls sit at +-22)
const CENTER_CLEAR_RADIUS := 6.0    # keeps the middle open so early fights aren't a maze
const OBSTACLE_COUNT := 10
const MIN_OBSTACLE_SPACING := 3.2
const MAX_ATTEMPTS_PER_OBSTACLE := 60

@onready var _obstacle_container: Node3D = $NavRegion/Obstacles
@onready var _nav_region: NavigationRegion3D = $NavRegion

var _rng := RandomNumberGenerator.new()
var _placed_positions: Array[Vector3] = []
var _shared_material: StandardMaterial3D

func generate(seed_value: int) -> void:
	_rng.seed = seed_value
	print("Arena seed: %d" % seed_value)
	_clear_obstacles()
	_place_obstacles()
	_nav_region.bake_finished.connect(_on_bake_finished, CONNECT_ONE_SHOT)
	_nav_region.bake_navigation_mesh(true)

func _on_bake_finished() -> void:
	generation_complete.emit()

## Used by wave_spawner.gd to avoid dropping enemies on top of obstacles.
func get_obstacle_positions() -> Array[Vector3]:
	return _placed_positions.duplicate()

func _clear_obstacles() -> void:
	for child in _obstacle_container.get_children():
		child.queue_free()
	_placed_positions.clear()

func _place_obstacles() -> void:
	var kinds := [Callable(self, "_make_pillar"), Callable(self, "_make_low_wall"), Callable(self, "_make_rubble")]
	var placed := 0
	var attempts := 0
	while placed < OBSTACLE_COUNT and attempts < OBSTACLE_COUNT * MAX_ATTEMPTS_PER_OBSTACLE:
		attempts += 1
		var margin := 3.0
		var pos := Vector3(
			_rng.randf_range(-ARENA_HALF_EXTENT + margin, ARENA_HALF_EXTENT - margin),
			0.0,
			_rng.randf_range(-ARENA_HALF_EXTENT + margin, ARENA_HALF_EXTENT - margin)
		)
		if pos.length() < CENTER_CLEAR_RADIUS:
			continue
		if not _clears_existing(pos):
			continue
		var make_fn: Callable = kinds[_rng.randi_range(0, kinds.size() - 1)]
		var yaw := _rng.randf_range(0.0, TAU)
		var obstacle: Node3D = make_fn.call(pos, yaw)
		_obstacle_container.add_child(obstacle)
		_placed_positions.append(pos)
		placed += 1
	if placed < OBSTACLE_COUNT:
		push_warning("Arena generator only placed %d/%d obstacles before exhausting attempts." % [placed, OBSTACLE_COUNT])

func _clears_existing(pos: Vector3) -> bool:
	for existing in _placed_positions:
		if existing.distance_to(pos) < MIN_OBSTACLE_SPACING:
			return false
	return true

func _get_shared_material() -> StandardMaterial3D:
	if _shared_material == null:
		_shared_material = StandardMaterial3D.new()
		_shared_material.albedo_color = Color(0.42, 0.4, 0.38)
		_shared_material.roughness = 0.85
	return _shared_material

func _make_pillar(pos: Vector3, yaw: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Pillar"
	body.transform = Transform3D(Basis(Vector3.UP, yaw), pos)

	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.6
	cyl.bottom_radius = 0.7
	cyl.height = 3.2
	cyl.radial_segments = 12
	var mesh := MeshInstance3D.new()
	mesh.mesh = cyl
	mesh.position.y = 1.6
	mesh.set_surface_override_material(0, _get_shared_material())
	body.add_child(mesh)

	var shape := CylinderShape3D.new()
	shape.radius = 0.65
	shape.height = 3.2
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position.y = 1.6
	body.add_child(col)
	return body

func _make_low_wall(pos: Vector3, yaw: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "LowWall"
	body.transform = Transform3D(Basis(Vector3.UP, yaw), pos)

	var size := Vector3(_rng.randf_range(2.5, 4.5), 1.4, 0.7)
	var box := BoxMesh.new()
	box.size = size
	var mesh := MeshInstance3D.new()
	mesh.mesh = box
	mesh.position.y = size.y * 0.5
	mesh.set_surface_override_material(0, _get_shared_material())
	body.add_child(mesh)

	var shape := BoxShape3D.new()
	shape.size = size
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position.y = size.y * 0.5
	body.add_child(col)
	return body

func _make_rubble(pos: Vector3, yaw: float) -> Node3D:
	var group := Node3D.new()
	group.name = "Rubble"
	group.transform = Transform3D(Basis(Vector3.UP, yaw), pos)

	var chunk_count := _rng.randi_range(3, 5)
	for i in range(chunk_count):
		var offset := Vector3(_rng.randf_range(-0.8, 0.8), 0.0, _rng.randf_range(-0.8, 0.8))
		var size := Vector3(
			_rng.randf_range(0.4, 0.9),
			_rng.randf_range(0.3, 0.7),
			_rng.randf_range(0.4, 0.9)
		)
		var body := StaticBody3D.new()
		body.transform = Transform3D(Basis(Vector3.UP, _rng.randf_range(0.0, TAU)), offset + Vector3(0, size.y * 0.5, 0))

		var box := BoxMesh.new()
		box.size = size
		var mesh := MeshInstance3D.new()
		mesh.mesh = box
		mesh.set_surface_override_material(0, _get_shared_material())
		body.add_child(mesh)

		var shape := BoxShape3D.new()
		shape.size = size
		var col := CollisionShape3D.new()
		col.shape = shape
		body.add_child(col)

		group.add_child(body)
	return group
