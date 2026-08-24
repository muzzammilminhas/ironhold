extends CanvasLayer
## Shown on GameState.player_died: freezes the world, reports run stats, and
## offers a restart. GameState is an autoload and survives scene reloads, so
## reload_current_scene() gives a genuinely fresh run (new arena seed, reset
## stats) without needing any manual state teardown here.

@onready var _stats_label: Label = $Root/CenterContainer/VBoxContainer/StatsLabel
@onready var _restart_button: Button = $Root/CenterContainer/VBoxContainer/RestartButton

func _ready() -> void:
	visible = false
	GameState.player_died.connect(_on_player_died)
	_restart_button.pressed.connect(_on_restart_pressed)

func _on_player_died() -> void:
	get_tree().paused = true
	var minutes := int(GameState.run_time) / 60
	var seconds := int(GameState.run_time) % 60
	_stats_label.text = "Survived %02d:%02d\nEnemies defeated: %d\nLevel reached: %d" % [
		minutes, seconds, GameState.enemies_defeated, GameState.level,
	]
	visible = true

func _on_restart_pressed() -> void:
	visible = false
	get_tree().paused = false
	get_tree().reload_current_scene()
