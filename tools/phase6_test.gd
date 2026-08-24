extends SceneTree
## Dev utility: verifies the HUD reflects GameState changes, death pauses the
## game and shows real stats, and the restart button reloads into a fresh
## run. Not part of the shipped game.

func _initialize() -> void:
	_run().call_deferred()

func _run() -> Callable:
	return func():
		var main: Node3D = load("res://scenes/Main.tscn").instantiate()
		get_root().add_child(main)
		# Godot's normal project-boot flow sets this automatically when
		# loading run/main_scene; reload_current_scene() (used by the
		# restart button) needs it, so set it explicitly since this harness
		# instances the scene directly instead of going through that flow.
		current_scene = main
		await _wait_frames(10)

		var game_state := get_root().get_node("/root/GameState")
		var hud = main.get_node("HUD")
		var death_screen = main.get_node("DeathScreen")
		var player = main.get_node("Player")

		# --- HUD reflects damage ---
		game_state.take_damage(30.0)
		await _wait_frames(3)
		var health_bar: ProgressBar = hud.get_node("Root/TopLeft/VBox/HealthRow/HealthBar")
		print("health after 30 dmg: game_state=%s hud_bar=%s" % [game_state.health, health_bar.value])
		print("PASS HUD tracks health" if absf(health_bar.value - 70.0) < 0.01 else "FAIL HUD tracks health")

		# --- Death: pause, stats, player animation ---
		game_state.take_damage(1000.0)
		await _wait_frames(5)
		print("run_active after lethal damage: ", game_state.run_active)
		print("tree paused: ", get_root().get_tree().paused)
		print("death screen visible: ", death_screen.visible)
		print("PASS death pauses and shows screen" if (get_root().get_tree().paused and death_screen.visible) else "FAIL death pauses and shows screen")
		var stats_label: Label = death_screen.get_node("Root/CenterContainer/VBoxContainer/StatsLabel")
		print("death stats text: ", stats_label.text)
		print("player is_dead: ", player.get("_is_dead"))
		print("PASS player marked dead" if player.get("_is_dead") else "FAIL player marked dead")

		# --- Restart ---
		var restart_button: Button = death_screen.get_node("Root/CenterContainer/VBoxContainer/RestartButton")
		restart_button.pressed.emit()
		await _wait_frames(15)
		print("tree paused after restart: ", get_root().get_tree().paused)
		print("health after restart: ", game_state.health)
		print("run_time after restart: ", game_state.run_time)
		print("PASS restart resets run" if (not get_root().get_tree().paused and game_state.health == game_state.max_health and game_state.run_time < 1.0) else "FAIL restart resets run")

		print("DONE")
		quit()

func _wait_frames(n: int) -> void:
	for i in range(n):
		await process_frame
