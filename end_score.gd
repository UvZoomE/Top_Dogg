extends Label
@onready var player = get_tree().get_first_node_in_group("Player") as RigidBody2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.text = "%.0f" % player.position.x
	pass
