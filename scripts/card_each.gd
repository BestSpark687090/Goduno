extends Button

@export var card_type = "4"
@export var card_color = "red"
@export var first_card = true
signal placed(card)
func _pressed():
	placed.emit(self)

	

	# figure out how to send to node2d
	#queue_free()
	#get_node("/root/Node2D").
	pass
