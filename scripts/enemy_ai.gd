extends CharacterBody3D
## Enemy AI: real NavigationAgent3D pathfinding toward the player (never a
## straight-line vector — get_next_path_position() routes around obstacles
## via the baked navmesh), plus a light separation steering force so groups
## flock instead of overlapping or clipping through each other. State
## (chase/attack/dying) drives animation.

const MOVE_SPEED := 3.2
const SEPARATION_RADIUS := 1.6
const SEPARATION_WEIGHT := 0.6
const ATTACK_RANGE := 1.6
const ATTACK_DAMAGE := 10.0
const MAX_HEALTH := 40.0
const XP_REWARD := 8.0
const PATH_UPDATE_INTERVAL := 0.2
const ROTATION_SPEED := 8.0
const GRAVITY := 18.0
const CORPSE_LIFETIME := 3.0

const ANIM_IDLE := "SkeletonArmature|Skeleton_Idle"
const ANIM_RUN := "SkeletonArmature|Skeleton_Running"
const ANIM_ATTACK := "SkeletonArmature|Skeleton_Attack"
const ANIM_DEATH := "SkeletonArmature|Skeleton_Death"

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var model_pivot: Node3D = $ModelPivot
@onready var _anim_player: AnimationPlayer = _find_animation_player(model_pivot)

var _health := MAX_HEALTH
var _target: Node3D
var _is_dead := false
var _is_attacking := false
var _path_update_timer := 0.0
var _vertical_velocity := 0.0

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("damageable")
	AnimUtils.mark_looping(_anim_player, [ANIM_IDLE, ANIM_RUN])
	_target = get_tree().get_first_node_in_group("player")
	# Enemies spawned in the same frame would otherwise all recompute their
	# nav path on the same frame every PATH_UPDATE_INTERVAL, turning a cheap
	# per-agent cost into a periodic whole-pack spike. Stagger the phase.
	_path_update_timer = randf() * PATH_UPDATE_INTERVAL
	if _anim_player and _anim_player.has_animation(ANIM_IDLE):
		_anim_player.play(ANIM_IDLE)
	# Enemies spawn in packs of 15-20; letting all of them cast dynamic
	# shadows re-renders the shadow map for that many skinned meshes every
	# frame for very little visual payoff at this scale. The player and
	# static arena geometry still cast shadows.
	for mesh in _find_all_mesh_instances(model_pivot):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _find_all_mesh_instances(root: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	for child in root.get_children():
		if child is MeshInstance3D:
			result.append(child)
		result.append_array(_find_all_mesh_instances(child))
	return result

func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	if is_on_floor():
		_vertical_velocity = -0.5
	else:
		_vertical_velocity -= GRAVITY * delta

	if _target == null or not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("player")

	var dist_to_target := global_position.distance_to(_target.global_position) if _target else INF

	if _target and dist_to_target <= ATTACK_RANGE and not _is_attacking:
		_start_attack()

	if _is_attacking or _target == null:
		velocity.x = 0.0
		velocity.z = 0.0
	elif dist_to_target <= ATTACK_RANGE:
		velocity.x = 0.0
		velocity.z = 0.0
		_face_point_instant(_target.global_position)
	else:
		_path_update_timer -= delta
		if _path_update_timer <= 0.0:
			_path_update_timer = PATH_UPDATE_INTERVAL
			nav_agent.target_position = _target.global_position
		var next_pos := nav_agent.get_next_path_position()
		var to_next := next_pos - global_position
		to_next.y = 0.0
		var nav_dir := to_next.normalized() if to_next.length_squared() > 0.0001 else Vector3.ZERO
		var move_dir := nav_dir + _compute_separation() * SEPARATION_WEIGHT
		if move_dir.length_squared() > 0.0001:
			move_dir = move_dir.normalized()
			_face_direction(move_dir, delta)
		velocity.x = move_dir.x * MOVE_SPEED
		velocity.z = move_dir.z * MOVE_SPEED

	velocity.y = _vertical_velocity
	move_and_slide()
	_update_animation()

## Steers away from nearby enemies, weighted lightly relative to the
## nav-follow direction (see SEPARATION_WEIGHT), so groups spread out
## naturally instead of stacking on the same path point.
func _compute_separation() -> Vector3:
	var push := Vector3.ZERO
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == self or not (other is Node3D):
			continue
		var o3d: Node3D = other
		var offset := global_position - o3d.global_position
		offset.y = 0.0
		var d := offset.length()
		if d > 0.001 and d < SEPARATION_RADIUS:
			push += offset.normalized() * (1.0 - d / SEPARATION_RADIUS)
	return push

func _face_direction(dir: Vector3, delta: float) -> void:
	if dir.length_squared() < 0.0001:
		return
	var target_yaw := atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-ROTATION_SPEED * delta))

func _face_point_instant(point: Vector3) -> void:
	var dir := point - global_position
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		return
	rotation.y = atan2(-dir.x, -dir.z)

func _start_attack() -> void:
	_is_attacking = true
	if _target:
		_face_point_instant(_target.global_position)
	var length := 0.6
	if _anim_player and _anim_player.has_animation(ANIM_ATTACK):
		_anim_player.play(ANIM_ATTACK)
		length = _anim_player.get_animation(ANIM_ATTACK).length
	get_tree().create_timer(length * 0.5).timeout.connect(_apply_attack_damage)
	get_tree().create_timer(maxf(length * 0.95, 0.1)).timeout.connect(_end_attack)

func _apply_attack_damage() -> void:
	if _is_dead or _target == null or not is_instance_valid(_target):
		return
	if global_position.distance_to(_target.global_position) <= ATTACK_RANGE + 0.5:
		if _target.has_method("take_damage"):
			_target.take_damage(ATTACK_DAMAGE, self)

func _end_attack() -> void:
	_is_attacking = false

func take_damage(amount: float, _source: Node) -> void:
	if _is_dead:
		return
	_health -= amount
	if _health <= 0.0:
		_die()

func _die() -> void:
	_is_dead = true
	remove_from_group("damageable")
	remove_from_group("enemies")
	collision_layer = 0
	collision_mask = 0
	GameState.add_xp(XP_REWARD)
	GameState.register_kill()
	if _anim_player and _anim_player.has_animation(ANIM_DEATH):
		_anim_player.play(ANIM_DEATH)
	get_tree().create_timer(CORPSE_LIFETIME).timeout.connect(queue_free)

func _update_animation() -> void:
	if not _anim_player or _is_dead:
		return
	var desired := ANIM_IDLE
	if _is_attacking:
		desired = ANIM_ATTACK
	elif Vector2(velocity.x, velocity.z).length() > 0.3:
		desired = ANIM_RUN
	if _anim_player.has_animation(desired) and _anim_player.current_animation != desired:
		_anim_player.play(desired)

func _find_animation_player(root: Node) -> AnimationPlayer:
	return root.find_child("AnimationPlayer", true, false) as AnimationPlayer
