extends SceneTree
## Dev utility: forces mobile controls visible and screenshots the overlay.
## Not part of the shipped game.

func _initialize() -> void:
	_run().call_deferred()

func _run() -> Callable:
	return func():
		var main: Node3D = load("res://scenes/Main.tscn").instantiate()
		get_root().add_child(main)
		current_scene = main
		await _wait_frames(10)
		main.get_node("MobileControls").visible = true
		var joystick = main.get_node("MobileControls/Joystick")
		joystick._update_from_position(joystick.size * 0.5 + Vector2(30, -30))
		await _wait_frames(5)
		var img := get_root().get_texture().get_image()
		img.save_png("C:/Users/muzza/AppData/Local/Temp/claude/D--Muzammil-Misc-Projects-Ironhold/162aba76-bc9f-4782-a171-4b0e5bd9efa5/scratchpad/mobile_controls.png")
		print("saved")
		quit()

func _wait_frames(n: int) -> void:
	for i in range(n):
		await process_frame
