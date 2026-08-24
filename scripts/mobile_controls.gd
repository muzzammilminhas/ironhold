extends CanvasLayer
## Shows on-screen touch controls only when a touchscreen is actually
## available - correct whether that's the Android export or a phone/tablet
## browser hitting the Web export - so desktop keyboard/mouse players never
## see them. Buttons drive the same Input Map actions as keyboard/mouse
## (attack, dodge), matching the joystick's approach for movement.

@onready var _attack_button: Button = $AttackButton
@onready var _dodge_button: Button = $DodgeButton

func _ready() -> void:
	visible = DisplayServer.is_touchscreen_available()
	_attack_button.button_down.connect(func(): Input.action_press("attack"))
	_attack_button.button_up.connect(func(): Input.action_release("attack"))
	_dodge_button.button_down.connect(func(): Input.action_press("dodge"))
	_dodge_button.button_up.connect(func(): Input.action_release("dodge"))
