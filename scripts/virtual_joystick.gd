extends Control
## On-screen virtual joystick. Feeds the same move_* Input Map actions the
## keyboard uses (via analog action strength through Input.action_press), so
## player_controller.gd needs no platform branching for movement - it always
## just reads Input.get_vector(...).

const MAX_RADIUS := 60.0
const RING_COLOR := Color(0.9, 0.85, 0.7, 0.3)
const KNOB_COLOR := Color(0.9, 0.85, 0.7, 0.65)

var _touch_index := -1
var _knob_offset := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, MAX_RADIUS, RING_COLOR)
	draw_circle(center + _knob_offset, MAX_RADIUS * 0.45, KNOB_COLOR)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_update_from_position(event.position)
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			_reset()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update_from_position(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Mouse fallback so the joystick is testable on desktop/in-editor.
		if event.pressed:
			_touch_index = 0
			_update_from_position(event.position)
		elif _touch_index == 0:
			_touch_index = -1
			_reset()
	elif event is InputEventMouseMotion and _touch_index == 0:
		_update_from_position(event.position)

func _update_from_position(pos: Vector2) -> void:
	var center := size * 0.5
	var offset := pos - center
	if offset.length() > MAX_RADIUS:
		offset = offset.normalized() * MAX_RADIUS
	_knob_offset = offset
	_apply_input(offset / MAX_RADIUS)
	queue_redraw()

func _reset() -> void:
	_knob_offset = Vector2.ZERO
	_apply_input(Vector2.ZERO)
	queue_redraw()

func _apply_input(vec: Vector2) -> void:
	_set_axis("move_right", "move_left", vec.x)
	_set_axis("move_back", "move_forward", vec.y)

func _set_axis(positive_action: String, negative_action: String, value: float) -> void:
	if value > 0.01:
		Input.action_press(positive_action, value)
		Input.action_release(negative_action)
	elif value < -0.01:
		Input.action_press(negative_action, -value)
		Input.action_release(positive_action)
	else:
		Input.action_release(positive_action)
		Input.action_release(negative_action)
