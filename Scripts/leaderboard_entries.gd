extends HBoxContainer

@onready var position_label: Label = $Position
@onready var username_label: Label = %Username
@onready var score_label: Label = %Score

func set_data(pos: int, username: String, score: float) -> void:
	if position_label:
		position_label.text = str(pos + 1)
	if username_label:
		username_label.text = username
	if score_label:
		score_label.text = str(int(score))
