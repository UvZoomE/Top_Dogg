extends PanelContainer

@onready var rank_chip: PanelContainer = %RankChip
@onready var position_label: Label = %Position
@onready var username_label: Label = %Username
@onready var score_label: Label = %Score

# Gold, silver, bronze for the podium places.
const PODIUM_COLORS := [
	Color(1.0, 0.82, 0.4),
	Color(0.80, 0.85, 0.92),
	Color(0.86, 0.55, 0.32),
]

func set_data(pos: int, username: String, score: float) -> void:
	if position_label:
		position_label.text = str(pos + 1)
	if username_label:
		username_label.text = username
	if score_label:
		score_label.text = str(int(score))
	_apply_style(pos)

func _apply_style(pos: int) -> void:
	var on_podium := pos < PODIUM_COLORS.size()

	# Row background: faint stripes, with a coloured tint for the top 3.
	var row := StyleBoxFlat.new()
	row.set_corner_radius_all(12)
	row.content_margin_left = 12
	row.content_margin_right = 12
	row.content_margin_top = 7
	row.content_margin_bottom = 7
	if on_podium:
		row.bg_color = Color(PODIUM_COLORS[pos], 0.14)
	else:
		row.bg_color = Color(1, 1, 1, 0.06 if pos % 2 == 0 else 0.02)
	add_theme_stylebox_override("panel", row)

	# Rank chip.
	var chip := StyleBoxFlat.new()
	chip.set_corner_radius_all(10)
	if on_podium:
		chip.bg_color = PODIUM_COLORS[pos]
		position_label.add_theme_color_override("font_color", Color(0.10, 0.12, 0.22))
		username_label.add_theme_color_override("font_color", Color(1, 0.95, 0.82))
	else:
		chip.bg_color = Color(1, 1, 1, 0.10)
		position_label.add_theme_color_override("font_color", Color(0.80, 0.88, 1.0))
	rank_chip.add_theme_stylebox_override("panel", chip)
