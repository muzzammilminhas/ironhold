class_name AnimUtils
extends RefCounted
## Shared animation helpers used by both player_controller.gd and enemy_ai.gd.

## Marks the given clips as looping. The Quaternius FBX/glTF packs don't
## reliably carry a loop flag on import, so idle/locomotion clips default to
## LOOP_NONE and freeze on their last frame after one pass; this corrects it
## at runtime rather than requiring a per-asset import remap.
static func mark_looping(anim_player: AnimationPlayer, names: Array[String]) -> void:
	if anim_player == null:
		return
	for anim_name in names:
		if anim_player.has_animation(anim_name):
			anim_player.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
