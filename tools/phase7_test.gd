extends SceneTree
## Dev utility: verifies the on-screen joystick and attack/dodge buttons
## drive the same Input Map actions keyboard/mouse do, and that the player
## actually responds (moves, attacks, dodges) through them. The visibility
## auto-detect (DisplayServer.is_touchscreen_available()) is forced on here
## since this dev machine has no real touchscreen. Not part of the shipped
## game.

func _initialize() -> void:
	_run().call_deferred()

func _run() -> Callable:
	return func():
		var main: Node3D = load("res://scenes/Main.tscn").instantiate()
		get_root().add_child(main)
		current_scene = main
		await _wait_frames(10)

		var controls = main.get_node("MobileControls")
		controls.visible = true
		var joystick = controls.get_node("Joystick")
		var attack_button: Button = controls.get_node("AttackButton")
		var dodge_button: Button = controls.get_node("DodgeButton")
		var player: Node3D = main.get_node("Player")
		var dummy: Node3D = main.get_node("TrainingDummy")

		# --- Joystick: push right, expect a rightward analog input vector. ---
		joystick._update_from_position(joystick.size * 0.5 + Vector2(60, 0))
		var v := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		print("input vector after joystick push right: ", v)
		print("PASS joystick drives move actions" if v.x > 0.5 else "FAIL joystick drives move actions")

		var start_pos: Vector3 = player.global_position
		await _wait_frames(30)
		var moved := player.global_position.distance_to(start_pos)
		print("player moved via joystick: ", moved)
		print("PASS joystick moves player" if moved > 0.5 else "FAIL joystick moves player")

		joystick._reset()
		await _wait_frames(3)
		var v_after_release := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		print("input vector after joystick release: ", v_after_release)
		print("PASS joystick release stops input" if v_after_release.length() < 0.01 else "FAIL joystick release stops input")

		# --- Place the player next to the dummy, then use the attack button.
		# (Not walked there via the joystick: the earlier rightward-push
		# sub-test already turned the player, so a further "push forward"
		# doesn't reliably aim back at the dummy - this test is about the
		# touch button wiring, not re-proving pathing precision.) ---
		joystick._reset()
		player.global_position = dummy.global_position + Vector3(0, 0, 1.5)
		await _wait_frames(5)
		print("distance to dummy before touch attack: ", player.global_position.distance_to(dummy.global_position))

		var health_before: float = dummy.get("_health")
		attack_button.button_down.emit()
		await _wait_frames(2)
		attack_button.button_up.emit()
		await _wait_frames(60)
		var health_after: float = dummy.get("_health")
		print("dummy health before/after touch attack: ", health_before, " / ", health_after)
		print("PASS attack button deals damage" if health_after < health_before else "FAIL attack button deals damage")

		# --- Dodge button ---
		await _wait_frames(10)
		var pre_dodge: Vector3 = player.global_position
		dodge_button.button_down.emit()
		await _wait_frames(2)
		dodge_button.button_up.emit()
		await _wait_frames(30)
		var dodge_dist := player.global_position.distance_to(pre_dodge)
		print("dodge displacement via touch button: ", dodge_dist)
		print("PASS dodge button moves player" if dodge_dist > 0.5 else "FAIL dodge button moves player")

		print("DONE")
		quit()

func _wait_frames(n: int) -> void:
	for i in range(n):
		await process_frame
