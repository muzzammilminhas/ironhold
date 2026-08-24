extends SceneTree
## Dev utility: automated smoke test for movement/attack/dodge, since there's
## no human at the keyboard in this environment. Drives Input action state
## directly (same as any Godot input-automation bot) and asserts on resulting
## world state. Not part of the shipped game.
## Usage: godot --path . --script res://tools/phase2_test.gd

var player: CharacterBody3D
var dummy: Node

func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/Main.tscn")
	var instance := packed.instantiate()
	get_root().add_child(instance)
	player = instance.get_node("Player")
	dummy = instance.get_node("TrainingDummy")
	_run().call_deferred()

func _run() -> Callable:
	return func():
		await _wait_frames(10)
		var start_pos := player.global_position
		print("start pos: ", start_pos)

		# Movement test: hold forward for a bit, expect meaningful displacement.
		Input.action_press("move_forward")
		await _wait_frames(30)
		Input.action_release("move_forward")
		await _wait_frames(5)
		var moved := player.global_position.distance_to(start_pos)
		print("moved after move_forward: ", moved)
		print("PASS move" if moved > 1.0 else "FAIL move")

		# Close the remaining distance to the dummy (it's straight ahead along -Z).
		for i in range(90):
			var to_dummy: Vector3 = dummy.global_position - player.global_position
			to_dummy.y = 0
			if to_dummy.length() < 2.0:
				break
			Input.action_press("move_forward")
			await _wait_frames(1)
		Input.action_release("move_forward")
		await _wait_frames(10)
		print("distance to dummy before attack: ", player.global_position.distance_to(dummy.global_position))

		var health_before: float = dummy.get("_health")
		Input.action_press("attack")
		await _wait_frames(2)
		Input.action_release("attack")
		await _wait_frames(90)
		print("is_attacking after wait: ", player.get("_is_attacking"))
		var health_after: float = dummy.get("_health")
		print("dummy health before/after attack: ", health_before, " / ", health_after)
		print("PASS attack" if health_after < health_before else "FAIL attack")

		# Dodge test: measure displacement over a short, known window.
		await _wait_frames(20)
		print("is_attacking before dodge: ", player.get("_is_attacking"))
		var pre_dodge := player.global_position
		Input.action_press("move_left")
		Input.action_press("dodge")
		await _wait_frames(2)
		Input.action_release("dodge")
		Input.action_release("move_left")
		await _wait_frames(25)
		var dodge_dist := player.global_position.distance_to(pre_dodge)
		print("dodge displacement: ", dodge_dist)
		print("PASS dodge" if dodge_dist > 0.8 else "FAIL dodge")

		if not DisplayServer.get_name() == "headless":
			var img := get_root().get_texture().get_image()
			img.save_png("C:/Users/muzza/AppData/Local/Temp/claude/D--Muzammil-Misc-Projects-Ironhold/162aba76-bc9f-4782-a171-4b0e5bd9efa5/scratchpad/phase2_combat.png")
		print("DONE")
		quit()

func _wait_frames(n: int) -> void:
	for i in range(n):
		await process_frame
