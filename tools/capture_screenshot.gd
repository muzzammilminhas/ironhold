extends SceneTree
## Dev utility: loads a scene, lets it render for a few frames, saves a PNG, quits.
## Usage: godot --path . --script res://tools/capture_screenshot.gd -- <scene_path> <out_png> [wait_frames]
## Not part of the shipped game.

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var scene_path := "res://scenes/Main.tscn"
	var out_path := "user://screenshot.png"
	var wait_frames := 30
	if args.size() >= 1:
		scene_path = args[0]
	if args.size() >= 2:
		out_path = args[1]
	if args.size() >= 3:
		wait_frames = int(args[2])

	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("Could not load scene: " + scene_path)
		quit(1)
		return
	var instance := packed.instantiate()
	get_root().add_child(instance)

	for i in range(wait_frames):
		await process_frame

	var img := get_root().get_texture().get_image()
	img.save_png(out_path)
	print("Saved screenshot to: " + out_path)
	quit()
