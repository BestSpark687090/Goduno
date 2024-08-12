extends Node2D

@onready var cont = $"CanvasLayer/FlowContainer"
@onready var label = $"CanvasLayer/Label"
@onready var placed_card = $"CanvasLayer/placed_card"
const card_types = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
	"draw2", "draw4", "skip", "reverse", "wild"]
const card_colors = ["red", "yellow", "blue", "green"]
var card_count = 0

var peer: ENetMultiplayerPeer
# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().get_root().size_changed.connect(resize)
	create_buttons()

func _input(event):
	if event.is_action_pressed("ui_accept"):
		add_card()


func create_buttons():
	var create_server_button = $"StartMenu/create_server"
	create_server_button.connect("pressed", _on_create_server_button_pressed)

	var connect_client_button = $"StartMenu/connect_client"
	connect_client_button.connect("pressed", _on_connect_client_button_pressed)
func _on_create_server_button_pressed():
	if peer == null:
		peer = ENetMultiplayerPeer.new()
		
	peer.create_server(1234, 4)
	multiplayer.multiplayer_peer = peer
	label.text = "Server started"
	$"StartMenu".visible = false
	$"CanvasLayer".visible = true
	$"CanvasLayer/CheckBox".button_pressed = true
	for i in range(7):
		add_card()
func _on_connect_client_button_pressed():
	if peer == null:
		peer = ENetMultiplayerPeer.new()
	var text = $"StartMenu/ip".text if $"StartMenu/ip".text != "" else "127.0.0.1"
	peer.create_client(text , 1234)
	multiplayer.multiplayer_peer = peer
	label.text = "Client connected"
	$"StartMenu".visible = false
	$"CanvasLayer".visible = true
	for i in range(7):
		add_card()
var spr = Button.new()

func add_card():
	spr = Button.new()
	spr.set_script(load("res://scripts/card_each.gd"))
	spr.connect("placed",on_card_pressed,1)
	spr.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var picked_type = card_types.pick_random()
	var picked_color = ""
	if picked_type == "draw4" or picked_type == "wild":
		picked_color = "wild"
	else:
		picked_color = card_colors.pick_random()
	spr.material = ShaderMaterial.new()
	spr.material.shader = load("res://shaders/" + picked_color + ".gdshader")
	spr.card_type = picked_type
	spr.card_color = picked_color
	spr.icon = load("res://cards/card_" + picked_type + ".png")
	spr.flat = true
	cont.add_child(spr)
	card_count += 1
	cont.cards.append(picked_type+" "+picked_color)

	#rpc("update_card_count",card_count, cont.turn)#, cont.cards)

# Called when the window resizes.
func resize():
	cont.size.x = get_window().size.x
	if (get_window().size.y < cont.position.y + 200):
		cont.position.y  = get_window().size.y - 200

var remote_cards = []
@rpc("any_peer", "call_local", "reliable")
func update_card_count(new_card_count,turn=1,card_placed=""):#,cardArray):
	if multiplayer.get_remote_sender_id() != multiplayer.get_unique_id(): 
		
		cont.turn = turn
		
		#and not cardArray[0] == cont.cards[0]:
		#remote_cards.append(cardArray[len(cardArray) - 1])
		#if new_card_count > 1: # no idea why it's setting the card count one above, but it is.
			#label.text = "Cards: " + str(new_card_count - 1)
		#else:
		#label.text = "Cards: " + str(new_card_count)
		# + "& Card List: "#+ str(remote_cards)
		if card_placed:
			$"CanvasLayer/CheckBox".button_pressed = not $"CanvasLayer/CheckBox".button_pressed
			var card = card_placed.split(" ")
			placed_card.texture = load("res://cards/card_"+card[0]+".png")
			placed_card.card_type = card[0]
			placed_card.card_color = card[1]
			placed_card.material = ShaderMaterial.new()
			placed_card.material.shader = load("res://shaders/"+card[1]+".gdshader")
			pass
	#elif multiplayer.get_remote_sender_id() == 1: # server id
		#remote_cards.append(cardArray[len(cardArray) - 1])
	else:
		if card_placed:
			var card = card_placed.split(" ")
			placed_card.texture = load("res://cards/card_"+card[0]+".png")
			placed_card.material = ShaderMaterial.new()
			placed_card.material.shader = load("res://shaders/"+card[1]+".gdshader")
			if turn == multiplayer.get_unique_id() or placed_card.card_color == "wild" :
				$"CanvasLayer/CheckBox".button_pressed = true
			else:
				$"CanvasLayer/CheckBox".button_pressed = false
			#if turn == multiplayer.get_unique_id():
				#$"CanvasLayer/CheckBox".button_pressed = true
			#else:
				#$"CanvasLayer/CheckBox".button_pressed = false
			rpc("update_card_count",card_count)
		else:
			return 
	#label.text = "Cards: " + str(new_card_count)
	
func _on_button_pressed():
	add_card()

func on_card_pressed(card):
	if cont.turn != multiplayer.get_unique_id(): # odd... not letting server send...
		OS.alert("not your turn","nuh uh!")
		return
	card_count -= 1
	if (card.card_color == "wild") or (card.card_color == placed_card.card_color or 
		card.card_type == placed_card.card_type) or cont.first_card == true:
		
		if card.card_color == "wild":
			$"wild_choice".visible = true
		cont.first_card = false
		rpc("update_card_count",len(cont.cards),cont.turn,
			card.card_type+" "+card.card_color)
		cont.cards.erase(card.card_type+" "+card.card_color)
		placed_card.card_type = card.card_type
		placed_card.card_color = card.card_color
		cont.turn = multiplayer.get_peers()[0]
		card.queue_free()
		$"CanvasLayer/CheckBox".button_pressed = not $"CanvasLayer/CheckBox".button_pressed
		rpc("update_card_count", card_count, cont.turn)
	else:
		print(str(card.card_color == "wild")," < is Wild?")
		print(str(card.card_color == placed_card.card_color)," < Matches color?")
		print(str(card.card_type == placed_card.card_type), " < Matches Type?")
		OS.alert("cannot place card down.","no")
		
	#spr.emit_signal("placed")
	#queue_free(
func wild_press(button):
	placed_card.card_color = str(button.name)
	$"wild_choice".visible = false
	placed_card.material = ShaderMaterial.new()
	placed_card.material.shader = load("res://shaders/"+button.name+".gdshader")
	rpc("update_card_count",len(cont.cards),cont.turn,placed_card.card_type+" "+placed_card.card_color)
	pass


func _on_rich_text_label_meta_clicked(meta):
	OS.shell_open(str(meta))
