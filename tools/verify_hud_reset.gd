extends SceneTree
## Dev utility: regression test for the HUD level-badge-not-resetting-on-
## restart bug found via a marketing screenshot. Not part of the shipped
## game.

func _initialize() -> void:
	_run().call_deferred()

func _run() -> Callable:
	return func():
		var main: Node3D = load("res://scenes/Main.tscn").instantiate()
		get_root().add_child(main)
		current_scene = main
		await _wait_frames(5)

		var game_state := get_root().get_node("/root/GameState")
		var hud = main.get_node("HUD")
		var level_label: Label = hud.get_node("Root/TopLeft/VBox/HealthRow/LevelLabel")

		game_state.add_xp(game_state.xp_to_next_level) # -> level 2
		await _wait_frames(3)
		print("level label before restart: ", level_label.text)

		reload_current_scene()
		await _wait_frames(15)

		main = current_scene
		hud = main.get_node("HUD")
		level_label = hud.get_node("Root/TopLeft/VBox/HealthRow/LevelLabel")
		print("game_state.level after restart: ", game_state.level)
		print("level label after restart: ", level_label.text)
		print("PASS HUD level resets on restart" if level_label.text == "Lv 1" else "FAIL HUD level resets on restart")
		print("DONE")
		quit()

func _wait_frames(n: int) -> void:
	for i in range(n):
		await process_frame
