extends SceneTree
## Dev utility: baseline frame-time profiling with zero enemies, to isolate
## whether cost comes from rendering pipeline (shadows/SSAO/glow) or the
## enemy AI/skinning. Not part of the shipped game.

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
		print("BASELINE (0 enemies) avg frame time: %.2f ms (%.1f fps), worst %.2f ms" % [avg, 1000.0 / avg, frame_times[frame_times.size()-1]])
		quit()

func _wait_frames(n: int) -> void:
	for i in range(n):
		await process_frame
