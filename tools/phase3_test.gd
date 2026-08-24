extends SceneTree
## Dev utility: verifies arena generation produces obstacles and a real baked
## navmesh, and that two runs with different seeds produce different layouts.
## Not part of the shipped game.

func _initialize() -> void:
	_run().call_deferred()

func _run() -> Callable:
	return func():
		var layout_a := await _generate_and_measure(12345)
		var layout_b := await _generate_and_measure(999)
		print("layout A obstacle positions: ", layout_a)
		print("layout B obstacle positions: ", layout_b)
		print("PASS different layouts" if layout_a != layout_b else "FAIL different layouts (same seed result?)")
		quit()

func _generate_and_measure(seed_value: int) -> Array:
	var packed: PackedScene = load("res://scenes/Arena.tscn")
	var arena := packed.instantiate()
	get_root().add_child(arena)
	arena.generate(seed_value)
	await arena.generation_complete

	var obstacles := arena.get_node("NavRegion/Obstacles")
	var nav_region: NavigationRegion3D = arena.get_node("NavRegion")
	var nav_mesh := nav_region.navigation_mesh
	print("seed %d -> obstacles: %d, navmesh vertices: %d, navmesh polygons: %d" % [
		seed_value, obstacles.get_child_count(), nav_mesh.get_vertices().size(), nav_mesh.get_polygon_count()
	])
	print("PASS obstacle count" if obstacles.get_child_count() == 10 else "FAIL obstacle count")
	print("PASS navmesh baked" if nav_mesh.get_polygon_count() > 0 else "FAIL navmesh baked")

	var positions: Array = []
	for child in obstacles.get_children():
		positions.append(child.position.snapped(Vector3(0.01, 0.01, 0.01)))

	arena.queue_free()
	await process_frame
	return positions
