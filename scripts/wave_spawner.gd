extends Node
## Timer-driven waves: spawn interval and burst size both ramp with run time,
## live enemy count is capped (profiled at 20 concurrent in Phase 4 with
## heavy headroom), and spawn points are sampled around the arena edge and
## rejected if they'd land on top of a placed obstacle.

const ENEMY_SCENE := preload("res://scenes/Enemy.tscn")

const MAX_CONCURRENT := 20
const SPAWN_RADIUS := 19.0
const OBSTACLE_CLEARANCE := 2.5
const SPAWN_POINT_ATTEMPTS := 8

const BASE_INTERVAL := 3.0    # seconds between spawns at run start
const MIN_INTERVAL := 0.6     # floor as the run escalates
const INTERVAL_RAMP_DURATION := 240.0
const BURST_RAMP_DURATION := 180.0
const MAX_BURST_SIZE := 3
const INITIAL_DELAY := 1.5

@export var arena_path: NodePath = ^"../Arena"
@export var enemies_root_path: NodePath = ^"../Enemies"

@onready var _arena: Node = get_node(arena_path)
@onready var _enemies_root: Node3D = get_node(enemies_root_path)

var _timer := 0.0
var _active := false

func _ready() -> void:
	GameState.player_died.connect(func(): _active = false)

func start() -> void:
	_active = true
	_timer = INITIAL_DELAY

func _process(delta: float) -> void:
	if not _active:
		return
	_timer -= delta
	if _timer <= 0.0:
		_try_spawn_burst()
		_timer = _current_interval()

func _current_interval() -> float:
	var frac := clampf(GameState.run_time / INTERVAL_RAMP_DURATION, 0.0, 1.0)
	return lerpf(BASE_INTERVAL, MIN_INTERVAL, frac)

func _current_burst_size() -> int:
	var frac := clampf(GameState.run_time / BURST_RAMP_DURATION, 0.0, 1.0)
	return 1 + int(round(frac * (MAX_BURST_SIZE - 1)))

func _try_spawn_burst() -> void:
	var live := get_tree().get_nodes_in_group("enemies").size()
	var room := MAX_CONCURRENT - live
	if room <= 0:
		return
	GameState.current_wave += 1
	var count := mini(_current_burst_size(), room)
	for i in range(count):
		_spawn_one()

func _spawn_one() -> void:
	var enemy := ENEMY_SCENE.instantiate()
	_enemies_root.add_child(enemy)
	enemy.global_position = _pick_spawn_point()

func _pick_spawn_point() -> Vector3:
	var obstacles: Array[Vector3] = []
	if _arena.has_method("get_obstacle_positions"):
		obstacles = _arena.get_obstacle_positions()
	var fallback := Vector3.ZERO
	for attempt in range(SPAWN_POINT_ATTEMPTS):
		var angle := randf_range(0.0, TAU)
		var point := Vector3(cos(angle) * SPAWN_RADIUS, 0.0, sin(angle) * SPAWN_RADIUS)
		fallback = point
		var clear := true
		for obs in obstacles:
			if Vector2(obs.x, obs.z).distance_to(Vector2(point.x, point.z)) < OBSTACLE_CLEARANCE:
				clear = false
				break
		if clear:
			return point
	return fallback
