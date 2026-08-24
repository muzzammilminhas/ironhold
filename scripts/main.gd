extends Node3D
## Top-level scene orchestration. Owns the run seed so the arena layout and
## GameState's own bookkeeping are reproducible from a single logged number,
## and kicks off arena generation before anything that depends on the navmesh
## (enemy spawning, from Phase 4 on) is allowed to start.

@onready var arena: Node3D = $Arena

func _ready() -> void:
	var run_seed := randi()
	GameState.start_run(run_seed)
	arena.generate(run_seed)
	await arena.generation_complete
	print("Arena generated and navmesh baked.")
