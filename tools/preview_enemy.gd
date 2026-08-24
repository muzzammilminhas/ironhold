extends SceneTree
## Dev utility: instances Enemy.tscn alone with a camera and a ground plane
## for scale/orientation reference, and saves a screenshot. Not part of the
## shipped game.

func _initialize() -> void:
	_run().call_deferred()

func _run() -> Callable:
	return func():
		var world_env := WorldEnvironment.new()
		var env := Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.5, 0.6, 0.75)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.8, 0.8, 0.8)
		env.ambient_light_energy = 1.0
		world_env.environment = env
		get_root().add_child(world_env)

		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-50, -30, 0)
		get_root().add_child(light)

		# 1-meter reference cube next to the enemy.
		var ref_cube := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3.ONE
		ref_cube.mesh = box
		ref_cube.position = Vector3(1.5, 0.5, 0)
		get_root().add_child(ref_cube)

		var enemy: Node3D = load("res://scenes/Enemy.tscn").instantiate()
		get_root().add_child(enemy)
		enemy.global_position = Vector3.ZERO

		var cam := Camera3D.new()
		cam.position = Vector3(0, 1.8, 4.5)
		get_root().add_child(cam)
		cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
		cam.current = true

		await _wait_frames(20)
		var img := get_root().get_texture().get_image()
		img.save_png("C:/Users/muzza/AppData/Local/Temp/claude/D--Muzammil-Misc-Projects-Ironhold/162aba76-bc9f-4782-a171-4b0e5bd9efa5/scratchpad/enemy_preview.png")
		print("saved")
		quit()

func _wait_frames(n: int) -> void:
	for i in range(n):
		await process_frame
