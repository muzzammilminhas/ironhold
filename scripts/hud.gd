extends CanvasLayer
## Run HUD: health bar, XP bar, level badge, run timer. Pure display — reads
## GameState, never writes it.

@onready var _health_bar: ProgressBar = $Root/TopLeft/VBox/HealthRow/HealthBar
@onready var _xp_bar: ProgressBar = $Root/TopLeft/VBox/XPBar
@onready var _level_label: Label = $Root/TopLeft/VBox/HealthRow/LevelLabel
@onready var _timer_label: Label = $Root/TopCenter/TimerLabel

func _ready() -> void:
	GameState.health_changed.connect(_on_health_changed)
	GameState.xp_changed.connect(_on_xp_changed)
	GameState.level_up.connect(_on_level_up)
	GameState.run_started.connect(_on_run_started)
	_on_run_started()

## Also covers this node's own initial sync, and any future restart:
## GameState.start_run() emits run_started once its reset is complete, which
## corrects any stale read from before that reset (a fresh HUD's _ready()
## always runs before Main's, since children ready before their parent).
func _on_run_started() -> void:
	_on_health_changed(GameState.health, GameState.max_health)
	_on_xp_changed(GameState.xp, GameState.xp_to_next_level)
	_on_level_up(GameState.level)

func _process(_delta: float) -> void:
	var t := int(GameState.run_time)
	_timer_label.text = "%02d:%02d" % [t / 60, t % 60]

func _on_health_changed(current: float, max_health: float) -> void:
	_health_bar.max_value = max_health
	_health_bar.value = current

func _on_xp_changed(current: float, to_next: float) -> void:
	_xp_bar.max_value = to_next
	_xp_bar.value = current

func _on_level_up(new_level: int) -> void:
	_level_label.text = "Lv %d" % new_level
