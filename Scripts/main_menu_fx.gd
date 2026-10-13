extends Control
## Menu life: floating decor, spinning coins, a breathing title and
## springy hover/press effects on every button in the menu.

@onready var ufo: Sprite2D = $Decor/UFO
@onready var player: Sprite2D = $Decor/Player
@onready var balloon: Sprite2D = $Decor/Balloon
@onready var coins: Array = $Decor/Coins.get_children()

var _t := 0.0
var _base := {}

func _ready() -> void:
	# Remember where each decor piece was placed in the editor so we can float around that spot.
	for n in [ufo, player, balloon] + coins:
		_base[n] = n.position

	_wire_buttons(self)

	# Gentle "breathing" on the title.
	var title := get_tree().get_first_node_in_group("HeaderText") as Label
	if title:
		title.pivot_offset = title.size / 2.0
		title.resized.connect(func(): title.pivot_offset = title.size / 2.0)
		var tw := create_tween().set_loops()
		tw.tween_property(title, "scale", Vector2(1.03, 1.03), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(title, "scale", Vector2.ONE, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _process(delta: float) -> void:
	_t += delta

	ufo.position = _base[ufo] + Vector2(sin(_t * 0.7) * 34.0, sin(_t * 1.6) * 7.0)
	ufo.rotation = sin(_t * 0.7 + 0.8) * 0.05

	player.position = _base[player] + Vector2(0.0, sin(_t * 2.4) * 5.0)
	player.rotation = sin(_t * 1.2) * 0.06

	balloon.position = _base[balloon] + Vector2(sin(_t * 0.9) * 6.0, sin(_t * 1.1) * 12.0)
	balloon.rotation = sin(_t * 0.9) * 0.06

	for i in coins.size():
		var coin: Sprite2D = coins[i]
		coin.frame = int(_t * 9.0 + i * 2) % 6
		coin.position = _base[coin] + Vector2(0.0, sin(_t * 2.0 + i) * 5.0)

# --- Button feel -------------------------------------------------------------

func _wire_buttons(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			_wire_button(child)
		_wire_buttons(child)

func _wire_button(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.resized.connect(func(): btn.pivot_offset = btn.size / 2.0)
	btn.mouse_entered.connect(func(): _pop(btn, 1.06))
	btn.mouse_exited.connect(func(): _pop(btn, 1.0))
	btn.button_down.connect(func(): _pop(btn, 0.95))
	btn.button_up.connect(func(): _pop(btn, 1.06 if btn.is_hovered() else 1.0))

func _pop(btn: Control, s: float) -> void:
	if btn.has_meta("pop_tween"):
		(btn.get_meta("pop_tween") as Tween).kill()
	var tw := create_tween()
	btn.set_meta("pop_tween", tw)
	tw.tween_property(btn, "scale", Vector2(s, s), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
