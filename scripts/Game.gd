extends Node
class_name Game

@export var CardTemplate: PackedScene
@export var PlayerHand: PackedScene
@export var InfoText: Label
@export var RoundTimer: TextureProgressBar


@export var cameraHinge: Node3D
@export var cardstack: Node3D
@export var players: Node3D

enum {UP,DOWN}
var card_spacing = 0.065

var game_cards = []
var card_rules = []


var player_hands = {}

# Define the phases of your infinite high-level loop
enum GameState {
	LOADING,
	PLAYING,
	PAUSED,
	GAME_OVER
}

signal player_turn_finished(id)



# TODO this should vary in local payer mode
static func get_own_player_id():
	return NetworkLobby.players[NetworkLobby.own_id]["player_id"]

# Track the current loop state
var current_state: GameState = GameState.LOADING

func count_player_card_files(path: String) -> int:
	var count := 0
	for file in DirAccess.get_files_at(path):
		if file.ends_with(".txt") and file.get_basename().is_valid_int():
			count += 1
	return count

func _ready():
	player_turn_finished.connect(func(id): play_round( (id + 1)  % NetworkLobby.players.size()))
	load_cardpack("Testpack")
	set_player_view(get_own_player_id())
	NetworkLobby.player_loaded.rpc()

func load_cardpack(path):
	print("Loading Cardpack: "+path)
	var card_pack_path = "user://card_packs/"+path+"/"
	var meta_file = FileAccess.open(card_pack_path+"meta.txt", FileAccess.READ)
	var cardset_name = meta_file.get_line()
	print("Cardset: "+cardset_name)
	var number_cards = count_player_card_files(card_pack_path)
	print("Number of Cards: "+str(number_cards))
	while not meta_file.eof_reached():
		var card_rule_line = meta_file.get_line()
		var card_rule_data = card_rule_line.split(",")
		card_rules.append(card_rule_data)
	print("Card Fields: "+str(card_rules))
	for card_id in range(number_cards):
		var game_card = load_card(path,card_id)
		if game_card:
			game_cards.append(game_card)


func load_card(path, card_id):
	var card_path = "user://card_packs/"+path+"/"+str(card_id)+".txt"
	var card_image_path = "user://card_packs/"+path+"/"+str(card_id)+".png"
	# 1. Check if the file exists before attempting to open
	if FileAccess.file_exists(card_path):
		var file = FileAccess.open(card_path, FileAccess.READ)
		
		# 2. Check if the file opened successfully (it returns null on failure)
		if file != null:
			var card = CardTemplate.instantiate()
			card.name = str(card_id)
			var card_name = file.get_line()
			cardstack.add_child(card)
			
			var card_fields = {}
			
			for card_rule in card_rules:
				var card_field_value = file.get_line()
				card_fields[card_rule[0]] = card_field_value
			
			card.initialize_card(card_name,card_fields)
			card.set_image(card_image_path)
			card.position = Vector3(0,card_id*card_spacing,0)
			card.rotation_degrees = Vector3(-90,0,0)
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



func shuffle_cards():
	InfoText.set_info("Shuffling Cards")

func deal_cards():
	shuffle_cards()
	InfoText.set_info("Dealing Cards")
	for i in range(game_cards.size()):
		var card_owner_id = i % NetworkLobby.players.size()
		var selected_card = cardstack.get_child(-1)
		print("Giving Card "+str(selected_card)+" to Player "+str(card_owner_id))
		player_hands[card_owner_id].place_card_in_hand(selected_card)
		await get_tree().create_timer(1).timeout





func set_player_view(player_id):
	cameraHinge.rotation_degrees.y = 90 + player_id*(360/NetworkLobby.players.size())



	

# only called by server
func start_game():
	print("Started Game")
	$UI/DebugText.text = str(get_own_player_id())
	for i in range(NetworkLobby.players.size()):
		
		var playerHand = PlayerHand.instantiate()
		playerHand.name = str(i)
		
		players.add_child(playerHand)
		player_hands[i] = playerHand
		
		playerHand.position = playerHand.position_of_player_hand(i)
		playerHand.look_at(playerHand.position_of_player_hand(i)*2 + Vector3.UP*2, Vector3.UP)
	
	await get_tree().create_timer(1).timeout
	await deal_cards()
	current_state = GameState.PLAYING
	play_round(0)


var picked_stat_index = 0

func picked_stat():
	return card_rules[picked_stat_index][0]

const REACTION_TIME = 6

var current_player_turn = -1

func play_round(player_id):
	current_player_turn = player_id
	print("Playing Round of Player "+str(player_id))
	if player_hands[player_id].get_top_card() == null:
		await get_tree().create_timer(1).timeout
		print("Player had no cards")
		player_turn_finished.emit(player_id)
	var player_text = ""
	
	InfoText.set_turn_text(player_id)
	
	for i in range(NetworkLobby.players.size()):
		player_hands[i].position = player_hands[i].position_of_player_hand(i) + Vector3.UP * int(i == player_id)
	player_hands[player_id].get_top_card().highlight_stat(picked_stat())
	# TODO allow faster end by stopping timer on RPC with selected feature
	
	var timer = get_tree().create_timer(REACTION_TIME)
	RoundTimer.start(timer,REACTION_TIME)
	await timer.timeout
	finish_round(player_id)
	
		
func finish_round(player_id):
	# lock player from changing input
	current_player_turn = -1
	# TODO turn over cards
	# evaluate logic
	
	var round_winner = 0
	var max_card_value = player_hands[player_id].get_players_card_value(picked_stat())
	var top_cards = []
	for i in range(NetworkLobby.players.size()):
		var other_player_top_card = player_hands[i].get_top_card()
		if other_player_top_card != null:
			top_cards.append(other_player_top_card)
			print(other_player_top_card.card_values.keys())
			var player_card_value = other_player_top_card.card_values[picked_stat()]
			print("Card: "+str(other_player_top_card.plain_card_name)+" with value "+str(player_card_value))
			if player_card_value > max_card_value:
				print("Beats")
				round_winner = i
				max_card_value = player_card_value
	
	# clear the highlight color
	player_hands[player_id].get_top_card().highlight_stat(picked_stat())
	
	# TODO currently only supports maximum, needs beats(a,b) predicate
	
	
	
	await get_tree().create_timer(1).timeout
	# TODO what if players have same value: stechen mechanic
	
	InfoText.set_info("Player "+str(round_winner+1)+" wins the round!")
	
	await get_tree().create_timer(1).timeout
	for card in top_cards:
		player_hands[round_winner].place_card_in_hand(card,false)
		await get_tree().create_timer(0.5).timeout
	current_player_turn = -1
	var current_player_wins = true
	for i in range(NetworkLobby.players.size()):
		#print(str(i)+" "+str(player_hands[i].get_top_card()))
		if i != player_id && player_hands[i].get_top_card() != null:
			# another player still has a card
			current_player_wins = false
	if current_player_wins:
		InfoText.declare_winner(player_id)
	else:
		player_turn_finished.emit(player_id)

	

func _unhandled_input(event: InputEvent) -> void:
	if current_player_turn == get_own_player_id():
		if event.is_action_pressed("card_stat_selection_down"): # or "menu_down"
			# Move down; wrap to 0 when reaching the end
			picked_stat_index = (picked_stat_index + 1) % card_rules.size()
			print("Test")
			player_hands[get_own_player_id()].get_top_card().highlight_stat(picked_stat())

		elif event.is_action_pressed("card_stat_selection_up"):
			picked_stat_index = (picked_stat_index - 1) % card_rules.size()
			player_hands[get_own_player_id()].get_top_card().highlight_stat(picked_stat())
