extends SceneTree
## Dev utility: captures the real gameplay screenshots for linkedin-post/ -
## combat, the level-up choice screen, the death/stats screen, and an arena
## overview. Each shot reaches its moment via GameState/scene manipulation
## (the same technique most game marketing screenshots use) rather than
## being hand-drawn - it's the real engine, real assets, real UI throughout.
## Not part of the shipped game.

const OUT_DIR := "D:/Muzammil/Misc/Projects/Ironhold/linkedin-post/"

func _initialize() -> void:
	_run().call_deferred()

func _run() -> Callable:
	return func():
		await _capture_combat()
		await _capture_level_up()
		await _capture_death_screen()
		await _capture_arena_overview()
		await _capture_mobile_controls()
		print("ALL SHOTS SAVED")
		quit()

func _fresh_main() -> Node3D:
	var main: Node3D = load("res://scenes/Main.tscn").instantiate()
	get_root().add_child(main)
	current_scene = main
	await process_frame
	# The training dummy is a dev/test fixture (Phase 2) - hide it so its
	# floating HP label doesn't clutter promotional screenshots.
	main.get_node("TrainingDummy").visible = false
	return main

func _save(name: String) -> void:
	var img := get_root().get_texture().get_image()
	img.save_png(OUT_DIR + name)
	print("saved ", name)

func _wait_frames(n: int) -> void:
	for i in range(n):
		await process_frame

# --- Combat: player mid-swing, a few enemies closing in, HUD showing real
# (non-full) health/XP so it doesn't look like a fresh boot screenshot. ---
func _capture_combat() -> void:
	var main := await _fresh_main()
	var player: CharacterBody3D = main.get_node("Player")
	var enemies_root: Node3D = main.get_node("Enemies")
	var enemy_scene: PackedScene = load("res://scenes/Enemy.tscn")

	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var placements := [Vector3(-1.6, 0, -3.2), Vector3(1.8, 0, -2.6), Vector3(0.3, 0, -4.5), Vector3(-2.4, 0, -1.8)]
	for p in placements:
		var e := enemy_scene.instantiate()
		enemies_root.add_child(e)
		e.global_position = p

	var game_state := get_root().get_node("/root/GameState")
	game_state.take_damage(38.0)
	game_state.add_xp(14.0)

	await _wait_frames(20)
	Input.action_press("attack")
	await _wait_frames(4)
	Input.action_release("attack")
	await _wait_frames(6)
	await _save("combat.png")
	main.queue_free()
	await _wait_frames(3)

# --- Level-up: force a level and screenshot the real choice UI. ---
func _capture_level_up() -> void:
	var main := await _fresh_main()
	var game_state := get_root().get_node("/root/GameState")
	game_state.add_xp(game_state.xp_to_next_level)
	await _wait_frames(10)
	await _save("level_up.png")
	main.queue_free()
	await _wait_frames(3)

# --- Death screen: simulate some real run progress first so the stats
# shown aren't just zeros. ---
func _capture_death_screen() -> void:
	var main := await _fresh_main()
	var game_state := get_root().get_node("/root/GameState")
	for i in range(7):
		game_state.register_kill()
	game_state.add_xp(55.0)
	game_state.run_time = 225.0 # 03:45 - a representative mid-run survival time
	await _wait_frames(5)
	game_state.take_damage(1000.0)
	await _wait_frames(10)
	await _save("death_screen.png")
	main.queue_free()
	await _wait_frames(3)

# --- Arena overview: elevated wide angle over the procedurally generated
# layout, obstacles and a few enemies visible. Camera script is paused for
# one frame so the manual overview transform isn't immediately overwritten. ---
func _capture_arena_overview() -> void:
	var main := await _fresh_main()
	var enemies_root: Node3D = main.get_node("Enemies")
	var enemy_scene: PackedScene = load("res://scenes/Enemy.tscn")
	var edge_points := [Vector3(-14, 0, -14), Vector3(14, 0, -10), Vector3(10, 0, 12), Vector3(-12, 0, 9)]
	for p in edge_points:
		var e := enemy_scene.instantiate()
		enemies_root.add_child(e)
		e.global_position = p

	await _wait_frames(5)
	var camera_rig: Node3D = main.get_node("CameraRig")
	camera_rig.set_physics_process(false)
	camera_rig.global_transform = Transform3D(
		Basis(Vector3(1, 0, 0), deg_to_rad(-55)),
		Vector3(0, 26, 24)
	)
	await _wait_frames(3)
	await _save("arena_overview.png")
	main.queue_free()
	await _wait_frames(3)

# --- Mobile controls: joystick mid-drag and the touch buttons visible,
# demonstrating the on-screen control scheme used on Android / mobile Web. ---
func _capture_mobile_controls() -> void:
	var main := await _fresh_main()
	var enemies_root: Node3D = main.get_node("Enemies")
	var enemy_scene: PackedScene = load("res://scenes/Enemy.tscn")
	var e := enemy_scene.instantiate()
	enemies_root.add_child(e)
	e.global_position = Vector3(1.0, 0, -3.0)

	var game_state := get_root().get_node("/root/GameState")
	game_state.take_damage(20.0)

	var controls = main.get_node("MobileControls")
	controls.visible = true
	var joystick = controls.get_node("Joystick")
	joystick._update_from_position(joystick.size * 0.5 + Vector2(35, -25))
	await _wait_frames(15)
	await _save("mobile_controls.png")
	main.queue_free()
	await _wait_frames(3)
