extends Node
## On level-up, pauses the game and offers 3 random upgrade choices; applying
## the chosen one un-pauses. The pool intentionally matches the design doc's
## example set: +damage, +move speed, +attack range, +max health, and one
## non-numeric "new attack" (cleave) so it's not purely stat sliders.

const UPGRADE_UI_SCENE := preload("res://scenes/UpgradeUI.tscn")

@export var player_path: NodePath = ^"../Player"

@onready var _player = get_node(player_path)

var _ui: CanvasLayer
var _pending_level_ups := 0

func _ready() -> void:
	GameState.level_up.connect(_on_level_up)
	_ui = UPGRADE_UI_SCENE.instantiate()
	# A sibling under Main, not get_tree().current_scene: that's only set by
	# Godot's normal project-boot flow and is null when a scene is instanced
	# directly (as the dev test tooling in tools/ does). Deferred because
	# Main is still mid-setup (adding its own children) during this _ready().
	get_parent().add_child.call_deferred(_ui)
	_ui.choice_made.connect(_on_choice_made)

func _upgrade_pool() -> Array[Dictionary]:
	# Built per-call (not cached) since the Callables close over nothing
	# mutable and this only runs on the rare level-up frame.
	return [
		{
			"name": "Heavier Blade",
			"description": "+25% attack damage",
			"apply": func(): _player.attack_damage *= 1.25,
		},
		{
			"name": "Swift Boots",
			"description": "+15% move speed",
			"apply": func(): _player.move_speed *= 1.15,
		},
		{
			"name": "Longer Reach",
			"description": "+20% attack range",
			"apply": func(): _player.attack_range *= 1.2,
		},
		{
			"name": "Vitality",
			"description": "+20 max health",
			"apply": func():
				GameState.max_health += 20.0
				GameState.heal(20.0),
		},
		{
			"name": "Cleaving Strikes",
			"description": "Attacks also hit a second nearby enemy",
			"apply": func(): _player.has_cleave = true,
		},
	]

## A single burst of XP (e.g. cleave killing two enemies in one frame) can
## cross more than one level threshold before this ever gets a chance to
## show anything, since GameState.add_xp's loop emits level_up synchronously.
## Queue instead of overwriting, so each level-up still gets its own choice.
func _on_level_up(_new_level: int) -> void:
	_pending_level_ups += 1
	if not get_tree().paused:
		_offer_next()

func _offer_next() -> void:
	var pool := _upgrade_pool()
	pool.shuffle()
	var options := pool.slice(0, 3)
	get_tree().paused = true
	_ui.show_choices(options)

func _on_choice_made(option: Dictionary) -> void:
	option["apply"].call()
	_pending_level_ups = maxi(0, _pending_level_ups - 1)
	if _pending_level_ups > 0:
		_offer_next()
	else:
		get_tree().paused = false
