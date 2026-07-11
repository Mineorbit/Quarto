extends Node


@export var CardTemplate: PackedScene
@export var PlayerHand: PackedScene

@export var CurrentPlayer: Label

@export var cameraHinge: Node3D
@export var cardstack: Node3D
@export var players: Node3D

enum {UP,DOWN}
var card_spacing = 0.065

var game_cards = []
var player_cards = []
var player_hands = []

# Define the phases of your infinite high-level loop
enum GameState {
	LOADING,
	PLAYING,
	PAUSED,
	GAME_OVER
}

signal player_turn_finished(id)

var own_player_id



# Track the current loop state
var current_state: GameState = GameState.LOADING



func _ready():
	own_player_id = NetworkLobby.players[NetworkLobby.own_id]["player_id"]
	load_cardpack("Testpack")
	set_player_view(own_player_id)
	NetworkLobby.player_loaded.rpc()
	player_turn_finished.connect(func(id): start_player_turn( (id + 1)  % NetworkLobby.players.size()))

func load_cardpack(path):
	print("Loading Cardpack: "+path)
	var meta_file = FileAccess.open("user://card_packs/"+path+"/meta.txt", FileAccess.READ)
	var cardset_name = meta_file.get_line()
	print("Cardset: "+cardset_name)
	var number_cards = int(meta_file.get_line())
	print("Number of Cards: "+str(number_cards))
	var card_fields = []
	while not meta_file.eof_reached():
		var card_field_line = meta_file.get_line()
		var card_field_data = card_field_line.split(",")
		card_fields.append(card_field_data)
	print("Card Rules: "+str(card_fields))
	for card_id in range(number_cards):
		var game_card = load_card(path,card_id)
		if game_card:
			game_cards.append(game_card)


func load_card(path, card_id):
	var card_path = "user://card_packs/"+path+"/"+str(card_id)+".txt"
	# 1. Check if the file exists before attempting to open
	if FileAccess.file_exists(card_path):
		var file = FileAccess.open(card_path, FileAccess.READ)
		
		# 2. Check if the file opened successfully (it returns null on failure)
		if file != null:
			var card = CardTemplate.instantiate()
			card.name = str(card_id)
			var card_name = file.get_line()
			cardstack.add_child(card)
			card.initialize_card(card_name,{"White":20,"Red":30})
			card.position = Vector3(0,card_id*card_spacing,0)
			card.rotation_degrees.z += 180
			print("Loaded card: "+str(card_id))
			return card
			# FileAccess automatically closes when it goes out of scope, 
			# but you can call file.close() explicitly if desired
		else:
			# 3. Check for specific errors if open failed
			var err = FileAccess.get_open_error()
			print("Failed to open file. Error code: ", err)
			return null
	else:
		print("File does not exist at: ", card_path)
		return null


func place_card_player_hand(card,player):
	print("Placing Card in Player Hand")
	card.position = player_hands[player].position

func deal_cards():
	print("Dealing Cards")
	for i in range(game_cards.size()):
		var card_owner = i % NetworkLobby.players.size()
		print("Giving Card "+str(i)+" to Player "+str(card_owner))
		player_cards[card_owner].append(game_cards[i])
		place_card_player_hand(game_cards[i],card_owner)


var radius = 2



func set_player_view(player_id):
	cameraHinge.rotation_degrees.y = 90 + player_id*(360/NetworkLobby.players.size())


# only called by server
func start_game():
	print("Spiel gestartet")
	for i in range(NetworkLobby.players.size()):
		player_cards.append([])
		# 1. Calculate the angle for this player
		var angle = (float(i) / float(NetworkLobby.players.size())) * 2.0 * PI
		
		# 2. Calculate position using trig
		# We use x and z for a flat ground plane
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		var spawn_pos = Vector3(x, 0, z)
		
		# 3. Create and position the player
		var playerHand = PlayerHand.instantiate()
		playerHand.position = spawn_pos + Vector3.UP * i
		playerHand.name = str(i)
		
		# 4. Rotate to face the center (0,0,0)
		# We look at the center, then adjust so they face "inwards"
		playerHand.look_at(Vector3(0, 0, 0), Vector3.UP)
		
		# 5. Add as child to Node A
		players.add_child(playerHand)
		player_hands.append(playerHand)
		current_state = GameState.PLAYING
		
	
	
	await get_tree().create_timer(1).timeout
	deal_cards()
	start_player_turn(0)


func start_player_turn(player_id):
	var player_text = ""
	
	if player_id == own_player_id:
		player_text = "It's your turn!"
	else:
		player_text = "It's player "+str(player_id + 1)+"'s turn!"
		
	CurrentPlayer.text = player_text
	await get_tree().create_timer(10).timeout
	player_turn_finished.emit(player_id)
