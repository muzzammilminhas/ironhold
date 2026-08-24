extends SceneTree
## Dev utility: verifies the wave spawner actually spawns enemies over time,
## and that a level-up pauses the game, offers 3 real upgrade choices, and
## applying one changes a real player stat and resumes. Not part of the
## shipped game.

func _initialize() -> void:
	_run().call_deferred()

func _run() -> Callable:
	return func():
		var main: Node3D = load("res://scenes/Main.tscn").instantiate()
		get_root().add_child(main)

		# GameState is an autoload, addressed as a bare global identifier from
		# regular scene scripts, but that identifier isn't registered yet when
		# *this* file is parsed as the --script entry point, so it's fetched
		# by path here instead.
		var game_state := get_root().get_node("/root/GameState")

		var enemies_root: Node3D = main.get_node("Enemies")
		var player = main.get_node("Player")

		# --- Wave spawner: enemies should appear on their own over time. ---
		await _wait_seconds(6.0)
		var count_after_6s := enemies_root.get_child_count()
		print("enemies spawned after 6s (no manual spawn): ", count_after_6s)
		print("PASS wave spawner spawns enemies" if count_after_6s > 0 else "FAIL wave spawner spawns enemies")
		print("current_wave: ", game_state.current_wave)

		# --- Upgrade flow: force a level-up and click the first card. ---
		var stats_before := [player.attack_damage, player.move_speed, player.attack_range, player.has_cleave, game_state.max_health]
		print("stats before upgrade [dmg, speed, range, cleave, max_hp]: ", stats_before)
		game_state.add_xp(game_state.xp_to_next_level) # exactly one level-up
		await _wait_frames(5)
		print("tree paused after level-up: ", get_root().get_tree().paused)
		print("PASS pauses on level-up" if get_root().get_tree().paused else "FAIL pauses on level-up")

		var upgrade_system = main.get_node("UpgradeSystem")
		var ui = upgrade_system._ui
		print("ui visible: ", ui.visible)
		var card1: Button = ui.get_node("CenterContainer/VBoxContainer/Cards/Card1")
		print("card1 text: ", card1.text)
		card1.pressed.emit()
		await _wait_frames(5)
		print("tree paused after choice: ", get_root().get_tree().paused)
		print("PASS resumes after choice" if not get_root().get_tree().paused else "FAIL resumes after choice")
		var stats_after := [player.attack_damage, player.move_speed, player.attack_range, player.has_cleave, game_state.max_health]
		print("stats after upgrade [dmg, speed, range, cleave, max_hp]: ", stats_after)
		print("PASS upgrade changed a stat" if stats_after != stats_before else "FAIL upgrade changed a stat")

		print("DONE")
		quit()

func _wait_frames(n: int) -> void:
	for i in range(n):
		await process_frame

func _wait_seconds(s: float) -> void:
	var elapsed := 0.0
	while elapsed < s:
		await process_frame
		elapsed += get_root().get_process_delta_time()
