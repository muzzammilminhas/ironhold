extends CharacterBody3D
## Player controller. Phase 1: model + idle animation only.
## Movement, attack, and dodge land in Phase 2.

@onready var model_pivot: Node3D = $ModelPivot
@onready var _anim_player: AnimationPlayer = _find_animation_player(model_pivot)

func _ready() -> void:
	if _anim_player and _anim_player.has_animation("Idle"):
		_anim_player.play("Idle")

func _find_animation_player(root: Node) -> AnimationPlayer:
	return root.find_child("AnimationPlayer", true, false) as AnimationPlayer
