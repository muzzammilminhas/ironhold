extends SceneTree
## Dev utility: screenshots the live HUD, then forces death and screenshots
## the death screen. Not part of the shipped game.

func _initialize() -> void:
	_run().call_deferred()

func _run() -> Callable:
	return func():
		var main: Node3D = load("res://scenes/Main.tscn").instantiate()
		get_root().add_child(main)
		current_scene = main
		await _wait_frames(10)

		var game_state := get_root().get_node("/root/GameState")
		game_state.take_damage(35.0)
		game_state.add_xp(12.0)
		await _wait_frames(10)
		var img := get_root().get_texture().get_image()
		img.save_png("C:/Users/muzza/AppData/Local/Temp/claude/D--Muzammil-Misc-Projects-Ironhold/162aba76-bc9f-4782-a171-4b0e5bd9efa5/scratchpad/hud_live.png")

		game_state.take_damage(1000.0)
		await _wait_frames(10)
		var img2 := get_root().get_texture().get_image()
		img2.save_png("C:/Users/muzza/AppData/Local/Temp/claude/D--Muzammil-Misc-Projects-Ironhold/162aba76-bc9f-4782-a171-4b0e5bd9efa5/scratchpad/death_screen.png")

		print("saved")
		quit()

func _wait_frames(n: int) -> void:
	for i in range(n):
		await process_frame
