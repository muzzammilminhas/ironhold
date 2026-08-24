extends CharacterBody3D
## Player controller: camera-relative movement, an auto-targeted melee attack,
## and a dodge roll. Animation state is derived from movement/attack/dodge
## flags each physics frame rather than driven directly by input, so it stays
## correct even while a one-shot action (attack, dodge) is playing.
##
## Melee hit detection uses a distance + range check against the "damageable"
## group rather than a physical hitbox Area3D — simpler, and standard for
## auto-targeted action combat where the weapon's exact swing volume doesn't
## need to matter.

const ROTATION_SPEED := 10.0
const DODGE_SPEED := 9.5
const DODGE_DURATION := 0.32
const DODGE_COOLDOWN := 0.9
const ATTACK_COOLDOWN := 0.5
const GRAVITY := 18.0
const HIT_REACTION_DURATION := 0.35
const CLEAVE_RADIUS := 2.6

# Base stats. Mutable (not const) because upgrade_system.gd scales these
# directly on level-up; ATTACK_DAMAGE/MOVE_SPEED/ATTACK_RANGE growth and the
# has_cleave flag are exactly the "new attack" / stat-boost upgrades the
# design doc calls for.
var move_speed := 5.5
var attack_range := 2.2
var attack_damage := 18.0
var has_cleave := false

@export var camera_rig_path: NodePath = ^"../CameraRig"

@onready var model_pivot: Node3D = $ModelPivot
@onready var _anim_player: AnimationPlayer = _find_animation_player(model_pivot)
@onready var _camera_rig: Node3D = get_node_or_null(camera_rig_path)

var _dodge_timer := 0.0
var _dodge_cooldown_timer := 0.0
var _dodge_direction := Vector3.ZERO
var _attack_cooldown_timer := 0.0
var _is_attacking := false
var _attack_target: Node3D = null
var _hit_reaction_timer := 0.0
var _vertical_velocity := 0.0

func _ready() -> void:
	add_to_group("player")
	AnimUtils.mark_looping(_anim_player, ["Idle", "Run", "Walk"])
	if _anim_player and _anim_player.has_animation("Idle"):
		_anim_player.play("Idle")

func _physics_process(delta: float) -> void:
	_attack_cooldown_timer = maxf(0.0, _attack_cooldown_timer - delta)
	_dodge_cooldown_timer = maxf(0.0, _dodge_cooldown_timer - delta)
	_hit_reaction_timer = maxf(0.0, _hit_reaction_timer - delta)

	if is_on_floor():
		_vertical_velocity = -0.5
	else:
		_vertical_velocity -= GRAVITY * delta

	if _dodge_timer > 0.0:
		_dodge_timer -= delta
		velocity.x = _dodge_direction.x * DODGE_SPEED
		velocity.z = _dodge_direction.z * DODGE_SPEED
	elif _is_attacking:
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		_handle_movement(delta)

	velocity.y = _vertical_velocity
	move_and_slide()

	if not _is_attacking and _dodge_timer <= 0.0:
		if Input.is_action_just_pressed("dodge") and _dodge_cooldown_timer <= 0.0:
			_start_dodge()
		elif Input.is_action_just_pressed("attack") and _attack_cooldown_timer <= 0.0:
			_start_attack()

	_update_animation()

func _handle_movement(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input_dir.length_squared() < 0.0001:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var move_dir := _camera_relative_direction(input_dir)
	velocity.x = move_dir.x * move_speed
	velocity.z = move_dir.z * move_speed
	_face_direction(move_dir, delta)

func _camera_relative_direction(input_dir: Vector2) -> Vector3:
	var basis := _camera_rig.global_transform.basis if _camera_rig else Basis.IDENTITY
	var forward := basis.z
	forward.y = 0.0
	var right := basis.x
	right.y = 0.0
	if forward.length_squared() < 0.0001 or right.length_squared() < 0.0001:
		return Vector3.ZERO
	var dir := right.normalized() * input_dir.x + forward.normalized() * input_dir.y
	return dir.normalized() if dir.length_squared() > 0.0001 else Vector3.ZERO

## Godot's forward is -Z; for a flat direction (dx, dz), the yaw that makes a
## node face it is atan2(-dx, -dz).
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

func _start_dodge() -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := _camera_relative_direction(input_dir)
	if dir.length_squared() < 0.0001:
		dir = -transform.basis.z # no input: dodge in the direction currently faced
	_dodge_direction = dir
	_dodge_timer = DODGE_DURATION
	_dodge_cooldown_timer = DODGE_COOLDOWN
	_face_direction(dir, 1.0)
	if _anim_player and _anim_player.has_animation("Roll"):
		_anim_player.play("Roll")

func _start_attack() -> void:
	_is_attacking = true
	# Player doesn't move while attacking, so the target must already be
	# within strike range for the swing (below) to actually connect.
	_attack_target = _find_nearest_damageable(attack_range)
	if _attack_target:
		_face_point_instant(_attack_target.global_position)
	var length := 0.6
	var anim_name := "Sword_Attack"
	if _anim_player and _anim_player.has_animation(anim_name):
		_anim_player.play(anim_name)
		length = _anim_player.get_animation(anim_name).length
	_attack_cooldown_timer = maxf(ATTACK_COOLDOWN, length * 0.9)
	# Impact and recovery are timed as fractions of the clip's real length
	# rather than hardcoded seconds, so timing stays correct regardless of
	# the source animation's actual duration.
	get_tree().create_timer(length * 0.45).timeout.connect(_apply_attack_damage)
	get_tree().create_timer(length * 0.9).timeout.connect(_end_attack)

func _apply_attack_damage() -> void:
	if _attack_target and is_instance_valid(_attack_target) and _attack_target.has_method("take_damage"):
		var dist := global_position.distance_to(_attack_target.global_position)
		if dist <= attack_range + 0.4:
			_attack_target.take_damage(attack_damage, self)
			if has_cleave:
				_apply_cleave_damage(_attack_target)
	_attack_target = null

## "New attack" upgrade: also hits one other nearby enemy besides the main
## target, so it reads as a distinct new capability rather than another
## damage multiplier.
func _apply_cleave_damage(primary_target: Node3D) -> void:
	for node in get_tree().get_nodes_in_group("damageable"):
		if node == self or node == primary_target or not (node is Node3D):
			continue
		var n3d: Node3D = node
		if global_position.distance_to(n3d.global_position) <= CLEAVE_RADIUS and n3d.has_method("take_damage"):
			n3d.take_damage(attack_damage * 0.6, self)
			break

func _end_attack() -> void:
	_is_attacking = false

func take_damage(amount: float, _source: Node) -> void:
	if _dodge_timer > 0.0:
		return # brief invulnerability while rolling
	GameState.take_damage(amount)
	if not _is_attacking:
		_hit_reaction_timer = HIT_REACTION_DURATION

func _find_nearest_damageable(radius: float) -> Node3D:
	var nearest: Node3D = null
	var nearest_dist := radius
	for node in get_tree().get_nodes_in_group("damageable"):
		if node == self or not (node is Node3D):
			continue
		var n3d: Node3D = node
		var d := global_position.distance_to(n3d.global_position)
		if d <= nearest_dist:
			nearest_dist = d
			nearest = n3d
	return nearest

func _update_animation() -> void:
	if not _anim_player:
		return
	var desired := "Idle"
	if _dodge_timer > 0.0:
		desired = "Roll"
	elif _is_attacking:
		desired = "Sword_Attack"
	elif _hit_reaction_timer > 0.0:
		desired = "RecieveHit"
	elif Vector2(velocity.x, velocity.z).length() > 0.3:
		desired = "Run"
	if _anim_player.has_animation(desired) and _anim_player.current_animation != desired:
		_anim_player.play(desired)

func _find_animation_player(root: Node) -> AnimationPlayer:
	return root.find_child("AnimationPlayer", true, false) as AnimationPlayer
