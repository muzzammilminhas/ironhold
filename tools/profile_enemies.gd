extends SceneTree
## Dev utility: Phase 4 profiling checkpoint. Loads Main.tscn, spawns a stress
## batch of enemies at the concurrent cap the design doc targets (15-20), lets
## them chase/flock/path for a few seconds, and reports average/worst frame
## time via the Performance singleton. Not part of the shipped game.

const ENEMY_COUNT := 20

func _initialize() -> void:
	_run().call_deferred()

func _run() -> Callable:
	return func():
		var main: Node3D = load("res://scenes/Main.tscn").instantiate()
		get_root().add_child(main)

		var enemies_root: Node3D = main.get_node("Enemies")
		for i in range(300):
			if enemies_root.get_child_count() > 0:
				break
			await process_frame
		for child in enemies_root.get_children():
			child.queue_free()
		await process_frame

		var enemy_scene: PackedScene = load("res://scenes/Enemy.tscn")
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for i in range(ENEMY_COUNT):
			var e := enemy_scene.instantiate()
			enemies_root.add_child(e)
			var angle := rng.randf_range(0.0, TAU)
			var radius := rng.randf_range(10.0, 19.0)
			e.global_position = Vector3(cos(angle) * radius, 0, sin(angle) * radius)

		print("Spawned %d enemies. Warming up..." % ENEMY_COUNT)
		await _wait_frames(30)

		var frame_times: Array[float] = []
		for i in range(180):
			var t0 := Time.get_ticks_usec()
			await process_frame
			var t1 := Time.get_ticks_usec()
			frame_times.append((t1 - t0) / 1000.0)

		frame_times.sort()
		var total := 0.0
		for t in frame_times:
			total += t
		var avg := total / frame_times.size()
		var worst := frame_times[frame_times.size() - 1]
		var p95 := frame_times[int(frame_times.size() * 0.95)]
		print("avg frame time: %.2f ms (%.1f fps)" % [avg, 1000.0 / avg])
		print("p95 frame time: %.2f ms" % p95)
		print("worst frame time: %.2f ms" % worst)
		print("PASS 60fps headroom" if avg < 16.6 else "FAIL 60fps headroom")
		quit()

func _wait_frames(n: int) -> void:
	for i in range(n):
		await process_frame
