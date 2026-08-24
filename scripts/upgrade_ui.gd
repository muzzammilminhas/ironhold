extends CanvasLayer
## Level-up upgrade picker. Runs at PROCESS_MODE_ALWAYS (set in the scene) so
## its buttons stay clickable while get_tree().paused is true.

signal choice_made(option: Dictionary)

@onready var _cards: Array[Button] = [
	$CenterContainer/VBoxContainer/Cards/Card1 as Button,
	$CenterContainer/VBoxContainer/Cards/Card2 as Button,
	$CenterContainer/VBoxContainer/Cards/Card3 as Button,
]

func _ready() -> void:
	visible = false

func show_choices(options: Array) -> void:
	for i in range(_cards.size()):
		var card := _cards[i]
		_disconnect_all(card)
		if i < options.size():
			var option: Dictionary = options[i]
			card.text = "%s\n\n%s" % [option["name"], option["description"]]
			card.visible = true
			card.pressed.connect(_on_card_pressed.bind(option))
		else:
			card.visible = false
	visible = true

func _disconnect_all(card: Button) -> void:
	for connection in card.pressed.get_connections():
		card.pressed.disconnect(connection["callable"])

func _on_card_pressed(option: Dictionary) -> void:
	visible = false
	choice_made.emit(option)
