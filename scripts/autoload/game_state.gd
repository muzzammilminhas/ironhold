extends Node
## Central run state: health, XP/level, run timer, and score.
## Autoloaded as "GameState" so both the HUD and gameplay systems read/write one source of truth.

signal health_changed(current: float, max_health: float)
signal xp_changed(current: float, to_next_level: float)
signal level_up(new_level: int)
signal player_died
signal run_started

const MAX_LEVEL_XP_GROWTH := 1.35 # each level requires 35% more XP than the last

var max_health := 100.0
var health := 100.0
var level := 1
var xp := 0.0
var xp_to_next_level := 20.0
var run_time := 0.0
var enemies_defeated := 0
var run_active := false
var current_wave := 0
var rng_seed := 0

func _process(delta: float) -> void:
	if run_active:
		run_time += delta

func start_run(seed_value: int) -> void:
	rng_seed = seed_value
	max_health = 100.0
	health = max_health
	level = 1
	xp = 0.0
	xp_to_next_level = 20.0
	run_time = 0.0
	enemies_defeated = 0
	current_wave = 0
	run_active = true
	health_changed.emit(health, max_health)
	xp_changed.emit(xp, xp_to_next_level)
	# Distinct from level_up: that signal means "leveled up" specifically (and
	# upgrade_system.gd treats every emission as an upgrade to offer), so it
	# can't also be reused to mean "level reset to 1 for a new run" - HUD
	# needs its own signal for that so its level badge resets correctly
	# after a restart even if the node-ready order runs the HUD's initial
	# read before this reset (children are always ready before their
	# parent, so a fresh HUD instance can read GameState before Main's
	# _ready() calls start_run() - the signal corrects it after the fact).
	run_started.emit()

func take_damage(amount: float) -> void:
	if not run_active:
		return
	health = clampf(health - amount, 0.0, max_health)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		run_active = false
		player_died.emit()

func heal(amount: float) -> void:
	health = clampf(health + amount, 0.0, max_health)
	health_changed.emit(health, max_health)

func add_xp(amount: float) -> void:
	if not run_active:
		return
	xp += amount
	while xp >= xp_to_next_level:
		xp -= xp_to_next_level
		level += 1
		xp_to_next_level *= MAX_LEVEL_XP_GROWTH
		level_up.emit(level)
	xp_changed.emit(xp, xp_to_next_level)

func register_kill() -> void:
	enemies_defeated += 1
