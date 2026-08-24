extends Node3D
## Third-person chase camera. Position follows the target smoothly; yaw follows
## a separately-smoothed heading rather than the target's instantaneous facing,
## so the camera doesn't whip around every time the player snap-turns to attack.
## Placement is computed directly (position behind target + look_at) rather than
## via SpringArm3D, since SpringArm3D's push axis and a child camera's forward
## axis are the same local -Z: with an unrotated child that puts the target
## behind the camera, not in front of it.

@export var target: Node3D
@export var distance := 6.5
@export var height := 3.2
@export var look_height := 1.3
@export var follow_speed := 6.0
@export var yaw_follow_speed := 3.0

var _yaw := 0.0

func _physics_process(delta: float) -> void:
	if target == null:
		return
	_yaw = lerp_angle(_yaw, target.rotation.y, 1.0 - exp(-yaw_follow_speed * delta))
	var behind := Vector3(sin(_yaw), 0, cos(_yaw)) * distance
	var desired_pos := target.global_position + behind + Vector3(0, height, 0)
	global_position = global_position.lerp(desired_pos, 1.0 - exp(-follow_speed * delta))
	look_at(target.global_position + Vector3(0, look_height, 0), Vector3.UP)
