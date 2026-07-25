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
	player_turn_finished.connect(func(id): play_round( (id + 1)  % NetworkLobby.players.size()))

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



func deal_cards():
	print("Dealing Cards")
	for i in range(game_cards.size()):
		var card_owner_id = i % NetworkLobby.players.size()
		print("Giving Card "+str(i)+" to Player "+str(card_owner_id))
		player_hands[card_owner_id].place_card_in_hand(game_cards[i])





func set_player_view(player_id):
	cameraHinge.rotation_degrees.y = 90 + player_id*(360/NetworkLobby.players.size())



	

# only called by server
func start_game():
	print("Spiel gestartet")
	for i in range(NetworkLobby.players.size()):
		
		var playerHand = PlayerHand.instantiate()
		playerHand.position = playerHand.position_of_player_hand(i)
		playerHand.name = str(i)
		
		playerHand.look_at(playerHand.position_of_player_hand(i)*2, Vector3.UP)
		players.add_child(playerHand)
		player_hands.append(playerHand)
		current_state = GameState.PLAYING
		
	
	
	await get_tree().create_timer(1).timeout
	deal_cards()
	play_round(0)


var picked_feature = "test"



func play_round(player_id):
	print("Playing Round of Player "+str(player_id))
	if player_hands[player_id].get_top_card() == null:
		await get_tree().create_timer(1).timeout
		print("Player had no cards")
		player_turn_finished.emit(player_id)
	var player_text = ""
	
	if player_id == own_player_id:
		player_text = "It's your turn!"
	else:
		player_text = "It's player "+str(player_id + 1)+"'s turn!"
	for i in range(NetworkLobby.players.size()):
		player_hands[i].position = player_hands[i].position_of_player_hand(i) + Vector3.UP * int(i == player_id)
	CurrentPlayer.text = player_text
	
	await get_tree().create_timer(10).timeout
	# TODO turn over cards
	# evaluate logic
	
	var max_player_index = 0
	var max_card_value = player_hands[player_id].get_players_card_value(picked_feature)
	var top_cards = []
	for i in range(NetworkLobby.players.size()):
		var other_player_top_card = player_hands[player_id].get_top_card()
		if other_player_top_card != null:
			top_cards.append(other_player_top_card)
			var player_card_value = player_hands[i].get_players_card_value(picked_feature)
			if player_card_value > max_card_value:
				max_player_index = i
				max_card_value = player_card_value
	
	# TODO currently only supports maximum, needs beats(a,b) predicate
	
	# TODO what if players have same value: stechen mechanic
	
	for card in top_cards:
		player_hands[max_player_index].place_card_in_hand(card)
	
	var current_player_wins = true
	for i in range(NetworkLobby.players.size()):
		if i != player_id && player_hands[i].get_top_card() != null:
			# another player still has a card
			current_player_wins = false
	if current_player_wins:
		if player_id == own_player_id:
			player_text = "You win!"
		else:
			player_text = "Player "+str(player_id + 1)+" wins!"	
		CurrentPlayer.text = player_text
	else:
		player_turn_finished.emit(player_id)
