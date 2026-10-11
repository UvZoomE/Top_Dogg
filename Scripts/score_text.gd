extends Label

@onready var player = get_tree().get_first_node_in_group("Player") as RigidBody2D
@onready var slingshot = get_tree().get_first_node_in_group("SlingShot") as SlingShot
@onready var gameover = get_tree().get_first_node_in_group("GameOver") as Control
@export var current_score = 0
var waiting = 0

# We don't need the camera anymore!
# @onready var camera = ... 

func _process(delta):
		# Just get the number
		current_score = player.global_position.x
		
		# Update the text
		# "%.0f" rounds it to a whole number so it looks clean
		self.text = "Score: %.0f" % current_score
		if slingshot && slingshot.SlingShotState == slingshot.SlingState.characterThrown:
			if player.linear_velocity.x < 3 && player.linear_velocity.y < 3:
				waiting += delta
				if waiting >= 3.0:
					gameover.visible = true
		
	# NO manual position code needed. 
	# The CanvasLayer and Anchor settings handle the X/Y automatically.
