extends Node3D
## Top-level scene orchestration. Owns the run seed so the arena layout and
## GameState's own bookkeeping are reproducible from a single logged number,
## and kicks off arena generation before anything that depends on the navmesh
## (enemy spawning) is allowed to start.

const ENEMY_SCENE := preload("res://scenes/Enemy.tscn")

@onready var arena: Node3D = $Arena
@onready var enemies_root: Node3D = $Enemies

func _ready() -> void:
	var run_seed := randi()
	GameState.start_run(run_seed)
	arena.generate(run_seed)
	await arena.generation_complete
	print("Arena generated and navmesh baked.")
	_spawn_manual_test_enemies()

## Phase 4 manual spawn to verify pathfinding/flocking against the baked
## navmesh. Replaced by wave_spawner.gd's timer-driven waves in Phase 5.
func _spawn_manual_test_enemies() -> void:
	var edge_points := [
		Vector3(-18, 0, -18), Vector3(18, 0, -18), Vector3(18, 0, 18),
		Vector3(-18, 0, 18), Vector3(0, 0, -19),
	]
	for point in edge_points:
		var enemy := ENEMY_SCENE.instantiate()
		enemies_root.add_child(enemy)
		enemy.global_position = point
