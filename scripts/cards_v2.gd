extends Node2D

@onready var cont = $"FlowContainer"
const card_types = ["0","1","2","3","4","5","6","7","8","9","draw2","draw4","skip","reverse","wild"]
const card_colors = ["red","yellow","blue","green"]
var card_count = 0
var peer = ENetMultiplayerPeer.new()
var multiplayer_api = multiplayer

# Called when the node enters the scene tree for the first time.
func _ready():
	start_server()
	#multiplayer_api = multiplayer
	multiplayer_api.multiplayer_peer = peer
	multiplayer_api.connect("peer_connected", _on_peer_connected)
	multiplayer_api.connect("peer_disconnected", _on_peer_disconnected)
	multiplayer_api.connect("connected_to_server", _on_connected_to_server)
	multiplayer_api.connect("connection_failed", _on_connection_failed)
	multiplayer_api.connect("server_disconnected", _on_server_disconnected)
	
	# Optionally, start the server or connect to a server
	# Start as a server


	# Or connect as a client
	# connect_to_server("127.0.0.1", 9876)
	
	get_tree().get_root().size_changed.connect(resize)
	add_card()

func _input(event):
	if event.is_action_pressed("ui_accept"):
		add_card()

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
	spr.material.shader = load("res://shaders/" + picked_color + ".gdshader")
	spr.card_type = picked_type
	spr.card_color = picked_color
	spr.icon = load("res://cards/card_" + picked_type + ".png")
	spr.flat = true
	cont.add_child(spr)
	card_count += 1

	# Notify peers of the new card count
	rpc("update_card_count", card_count)

# Called when the window resizes.
func resize():
	cont.size.x = get_viewport().size.x

# Server/Client setup
func start_server():
	peer.create_server(8000, 10)
	multiplayer_api = multiplayer
	multiplayer_api.multiplayer_peer = peer
	
	print("Server started")

func connect_to_server(ip: String, port: int):
	peer.create_client(ip, port)
	multiplayer_api.multiplayer_peer = peer
	print("Connecting to server...")

# RPC functions
@rpc("any_peer", "reliable")
func update_card_count(new_card_count):
	if not multiplayer_api.is_server():
		$"Label".text = "Cards: " + str(new_card_count)

# Signals
func _on_peer_connected(id):
	print("Peer connected with ID: ", id)

func _on_peer_disconnected(id):
	print("Peer disconnected with ID: ", id)


func _on_connected_to_server():
	print("Connected to server")

func _on_connection_failed():
	print("Failed to connect to server")

func _on_server_disconnected():
	print("Disconnected from server")
