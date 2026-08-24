extends SceneTree
## Dev utility: prints the node tree and available animations of an imported
## scene, since imported FBX/glTF hierarchies aren't otherwise inspectable
## without running the editor UI. Not part of the shipped game.
## Usage: godot --headless --path . --script res://tools/inspect_scene.gd -- <scene_path>

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var scene_path := args[0] if args.size() >= 1 else "res://assets/characters/enemies/skeleton/Skeleton.fbx"
	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("Could not load: " + scene_path)
		quit(1)
		return
	var inst := packed.instantiate()
	_print_tree(inst, 0)
	var anim_player := inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim_player:
		print("--- Animations on ", anim_player.get_path(), " ---")
		for anim_name in anim_player.get_animation_list():
			var anim := anim_player.get_animation(anim_name)
			print(" - %s (%.2fs, loop=%s)" % [anim_name, anim.length, anim.loop_mode])
	else:
		print("No AnimationPlayer found.")
	quit()

func _print_tree(node: Node, depth: int) -> void:
	print("  ".repeat(depth), node.name, " [", node.get_class(), "]")
	for child in node.get_children():
		_print_tree(child, depth + 1)
