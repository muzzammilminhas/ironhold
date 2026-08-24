extends SceneTree
## Dev utility: loads Main.tscn (which manually spawns 5 test enemies around
## the arena edge once the navmesh bakes), lets simulation run, and checks
## that enemies actually close distance to the player over time (i.e. they're
## pathfinding, not stuck). Also saves a screenshot for visual confirmation
## that they route around obstacles instead of clipping through them.
## Not part of the shipped game.

func _initialize() -> void:
	_run().call_deferred()

func _run() -> Callable:
	return func():
		var packed: PackedScene = load("res://scenes/Main.tscn")
		var main := packed.instantiate()
		get_root().add_child(main)

		var player: Node3D = main.get_node("Player")
		var enemies_root: Node3D = main.get_node("Enemies")

		# main.gd's own _ready() awaits arena.generation_complete internally
		# before spawning enemies; that one-shot signal may already have
		# fired by the time we'd try to await it externally, so poll for the
		# spawn's side effect instead of racing the same signal.
		for i in range(300):
			if enemies_root.get_child_count() > 0:
				break
			await process_frame
		var start_distances := {}
		for e in enemies_root.get_children():
			start_distances[e] = e.global_position.distance_to(player.global_position)
			print("enemy at ", e.global_position, " start dist ", start_distances[e])

		await _wait_frames(30)
		var probe = enemies_root.get_child(0)
		print("probe target: ", probe.get("_target"))
		print("probe nav_agent map: ", probe.nav_agent.get_navigation_map())
		print("probe nav target_position: ", probe.nav_agent.target_position)
		print("probe next_path_position: ", probe.nav_agent.get_next_path_position())
		print("probe is_navigation_finished: ", probe.nav_agent.is_navigation_finished())
		print("probe global_position: ", probe.global_position)
		var path: PackedVector3Array = probe.nav_agent.get_current_navigation_path()
		print("probe path size: ", path.size(), " path: ", path)

		# Freeze the player in place (no input) so this is purely an AI-approach test.
		await _wait_frames(240)

		var all_closed := true
		for e in enemies_root.get_children():
			if not is_instance_valid(e):
				continue
			var d: float = e.global_position.distance_to(player.global_position)
			var closed: float = start_distances[e] - d
			print("enemy end dist ", d, " (closed ", closed, ")")
			if closed < 1.0:
				all_closed = false
		print("PASS enemies approach player" if all_closed else "FAIL enemies approach player")

		if not DisplayServer.get_name() == "headless":
			var img := get_root().get_texture().get_image()
			img.save_png("C:/Users/muzza/AppData/Local/Temp/claude/D--Muzammil-Misc-Projects-Ironhold/162aba76-bc9f-4782-a171-4b0e5bd9efa5/scratchpad/phase4_enemies.png")

		print("DONE")
		quit()

func _wait_frames(n: int) -> void:
	for i in range(n):
		await process_frame
