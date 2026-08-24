extends StaticBody3D
## Practice target: absorbs hits, shows a floating HP label, flashes on hit,
## and respawns after a short delay once destroyed. Dev/test fixture used to
## tune attack timing and damage feel (Phase 2) against something with real
## state, ahead of real enemies landing in Phase 4.

const MAX_HEALTH := 100.0
const RESPAWN_DELAY := 2.0
const HIT_COLOR := Color(1.0, 0.3, 0.25)
const BASE_COLOR := Color(0.65, 0.5, 0.3)

@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _collision: CollisionShape3D = $CollisionShape3D
@onready var _label: Label3D = $HealthLabel
@onready var _material: StandardMaterial3D = _mesh.get_surface_override_material(0)

var _health := MAX_HEALTH
var _flash_tween: Tween

func _ready() -> void:
	add_to_group("damageable")
	_update_label()

func take_damage(amount: float, _source: Node) -> void:
	if _health <= 0.0:
		return
	_health = maxf(0.0, _health - amount)
	_update_label()
	_flash_hit()
	if _health <= 0.0:
		_on_destroyed()

func _update_label() -> void:
	_label.text = "%d / %d" % [int(_health), int(MAX_HEALTH)]

func _flash_hit() -> void:
	if _flash_tween:
		_flash_tween.kill()
	_material.albedo_color = HIT_COLOR
	_flash_tween = create_tween()
	_flash_tween.tween_property(_material, "albedo_color", BASE_COLOR, 0.25)

func _on_destroyed() -> void:
	_mesh.visible = false
	_collision.disabled = true
	get_tree().create_timer(RESPAWN_DELAY).timeout.connect(_respawn)

func _respawn() -> void:
	_health = MAX_HEALTH
	_mesh.visible = true
	_collision.disabled = false
	_material.albedo_color = BASE_COLOR
	_update_label()
