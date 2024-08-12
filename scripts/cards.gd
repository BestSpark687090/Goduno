extends Node2D

@onready var cont = $"FlowContainer"
const card_types = ["0","1","2","3","4","5","6","7","8","9","draw2","draw4","skip","reverse","wild"]
const card_colors = ["red","yellow","blue","green"]
var card_count = 0
var peer  = ENetMultiplayerPeer.new()
# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().get_root().size_changed.connect(resize)
	add_card()
		#peer.host = peer

func _input(event):
	if event.is_action_pressed("ui_accept"):
		add_card()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func add_card():
	
	var spr = Button.new()
	
	spr.set_script(load("res://card_each.gd"))
	spr.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var picked_type = card_types.pick_random()
	var picked_color = ""
	if picked_type == "draw4" or picked_type == "wild":
		# Skip over color picking
		picked_color = "wild"
	else:
		picked_color = card_colors.pick_random()
	spr.material = ShaderMaterial.new()
	spr.material.shader = load("res://shaders/"+picked_color+".gdshader")
	spr.card_type = picked_type
	spr.card_color = picked_color
	spr.icon = load("res://cards/card_"+picked_type+".png")
	
	#spr.position.x = 625 + (card_count * 100)
	#spr.position.y = 525
	spr.flat = true
	cont.add_child(spr)
	card_count+=1
	rpc("update_card_count", card_count, cont.cards)
	
	#cont.position.x -= 50
# Called when the window resizes.
func resize():
	cont.size.x = (get_window().size.x)
#@rpc("any_peer", "reliable")
#func transfer_some_input(rmt_card_count):
	#print("are we doing it?",rmt_card_count,card_count)
	## The server knows who sent the input.
	#var sender_id = multiplayer.get_remote_sender_id()
	#if sender_id == multiplayer.get_unique_id():
		#return -1
	#return card_count
	# Process the input and affect game logic.
@rpc("any_peer", "call_local", "reliable")
func update_card_count(new_card_count, cardArray):
	print(multiplayer.get_remote_sender_id(),str(multiplayer.is_server()))
	if multiplayer.is_server():
		return
	#$"Label".text = "Cards: "+str(new_card_count)+" & Card List: " + str(cardA)
	# This could trigger UI updates or other game logic
