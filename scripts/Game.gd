extends Node
class_name Game

@export var CardTemplate: PackedScene
@export var PlayerHand: PackedScene
@export var InfoText: Label
@export var RoundTimer: TextureProgressBar


@export var cameraHinge: Node3D
@export var cardStack: Node3D
@export var cardSurface: Node3D
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

func get_player_hand(player_id):
	if player_hands.has(player_id):
		return player_hands[player_id]
	else:
		player_hands[player_id] = players.find_child(str(player_id),false,false)
		return player_hands[player_id]

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
	set_player_view()
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
			cardStack.add_child(card)
			
			var card_fields = {}
			
			for card_rule in card_rules:
				var card_field_value = file.get_line()
				card_fields[card_rule[0]] = card_field_value
			
			card.initialize_card(card_name,card_fields)
			card.set_image(card_image_path)
			card.target_position = Vector3(0,card_id*card_spacing,0)
			card.target_rotation = Quaternion.from_euler(Vector3(deg_to_rad(-90), 0, 0))
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
	InfoText.set_info.rpc("Shuffling Cards")

func deal_cards():
	shuffle_cards()
	InfoText.set_info.rpc("Dealing Cards")
	for i in range(game_cards.size()):
		var card_owner_id = i % NetworkLobby.players.size()
		var selected_card = cardStack.get_child(-1)
		get_player_hand(card_owner_id).place_card_in_hand(selected_card)
		await get_tree().create_timer(0.2).timeout




@rpc("any_peer", "call_local", "reliable")
func set_topdown_view():
	cameraHinge.rotation_degrees = Vector3(-60,-180,0)
	cameraHinge.get_child(0).position = Vector3(0,1.6,2.5)

@rpc("any_peer", "call_local", "reliable")
func set_player_view():
	cameraHinge.rotation_degrees = Vector3(0,90 + get_own_player_id()*(360/NetworkLobby.players.size()),0)
	cameraHinge.get_child(0).position = 0.8*Vector3(0,3,5)




	

# only called by server
func start_game():
	print("Started Game")
	$UI/DebugText.text = str(get_own_player_id())
	for i in range(NetworkLobby.players.size()):
		
		var playerHand = PlayerHand.instantiate()
		playerHand.name = str(i)
		
		players.add_child(playerHand)
		player_hands[i] = playerHand
		
		playerHand.target_position = playerHand.position_of_player_hand(i)
		playerHand.look_at(playerHand.position_of_player_hand(i)*2 + Vector3.UP*2, Vector3.UP)
	
	await get_tree().create_timer(1).timeout
	await deal_cards()
	current_state = GameState.PLAYING
	play_round(0)


var picked_stat_index = 0

func picked_stat():
	return card_rules[picked_stat_index][0]

const REACTION_TIME = 10

@export var current_player_turn = -1

func play_round(player_id):
	current_player_turn = player_id
	print("Playing Round of Player "+str(player_id))
	if get_player_hand(player_id).get_top_card() == null:
		await get_tree().create_timer(1).timeout
		print("Player had no cards")
		player_turn_finished.emit(player_id)
	var player_text = ""
	
	InfoText.set_turn_text.rpc(player_id)
	
	for i in range(NetworkLobby.players.size()):
		get_player_hand(i).target_position = get_player_hand(i).position_of_player_hand(i) + Vector3.UP * int(i == player_id)
	get_player_hand(player_id).get_top_card().highlight_stat(picked_stat())
	# TODO allow faster end by stopping timer on RPC with selected feature
	
	var timer = get_tree().create_timer(REACTION_TIME)
	RoundTimer.start(timer,REACTION_TIME)
	await timer.timeout
	finish_round(player_id)



func place_cards_on_surface(cards,card_players: Array[int],elevated_cards,offset = 0):
	for i in range(cards.size()):
		var card = cards[i]
		card.request_reparent(cardSurface)
		card.highlight_stat.rpc(picked_stat())
		card.target_position =cardSurface.transform.basis.x*card_players[i] + 0.5*cardSurface.transform.basis.y*(offset + int(card in elevated_cards))
		card.target_rotation = Quaternion.from_euler(Vector3(deg_to_rad(90), 0, 0))


# TODO currently only supports maximum of integers, needs beats(a,b) predicate between cards and better parsing instead
func find_winner_card_set(card_players,cards):
	assert(card_players.size() == cards.size())
	var round_winners: Array[int] = []
	var winner_cards = []
	var max_card_value = 0
	for i in range(card_players.size()):
		var player_card_value: int = int(cards[i].card_values[picked_stat()])
		print("Card: \""+str(cards[i].plain_card_name)+"\" with value "+str(player_card_value)+ " against "+str(max_card_value))
		if player_card_value > max_card_value:
			print("Beats")
			max_card_value = player_card_value
			winner_cards = [cards[i]]
			round_winners = [card_players[i]]
		elif player_card_value == max_card_value:
			winner_cards.append(cards[i])
			round_winners.append(card_players[i])
	print("Winners: "+str(round_winners)+ " with cards: "+str(winner_cards))
	return [round_winners,winner_cards]

func finish_round(player_id):
	for i in range(NetworkLobby.players.size()):
		get_player_hand(i).target_position = get_player_hand(i).position_of_player_hand(i)
	# lock player from changing input
	current_player_turn = -1
	
	
	# evaluate logic
	
	var top_cards = []
	var competing_players: Array[int] = []
	for i in range(NetworkLobby.players.size()):
		var top_card = get_player_hand(i).get_top_card()
		if top_card != null:
			top_cards.append(top_card)
			competing_players.append(i)
	
	
	
	# Turn over cards
	set_topdown_view.rpc()
	
	
	place_cards_on_surface(top_cards,competing_players,[])
	
	
	var r = find_winner_card_set(range(NetworkLobby.players.size()),top_cards)
	var round_winners = r[0]
	var winner_cards = r[1]
	
	await get_tree().create_timer(2).timeout
	
	place_cards_on_surface(top_cards,competing_players,winner_cards)
	await get_tree().create_timer(2).timeout
	

	# If players have same value: stechen mechanic -> players keep picking top card with same stat until one player wins
	var c = 0
	while round_winners.size() > 1:
		InfoText.set_info.rpc("Players "+str(round_winners)+" stechen!")
		# place cards back down on the surface
		for j in range(cardSurface.get_child_count()):
			var card = cardSurface.get_child(j)
			card.clear_stat_selection.rpc()
			card.target_position = Vector3.FORWARD + card_spacing*Vector3.UP*j
			# card.target_rotation = Quaternion.from_euler(Vector3(deg_to_rad(90), deg_to_rad(90), 0))
			card.target_rotation = Quaternion.from_euler(Vector3(deg_to_rad(90), deg_to_rad(90), 0))
		
		await get_tree().create_timer(2).timeout
		# collect next top level cards
		var next_competing_cards = []
		var next_competing_players: Array[int] = []
		for round_winner_id in round_winners:
			var top_card = get_player_hand(round_winner_id).get_top_card()
			if top_card != null:
				top_card.highlight_stat(picked_stat())
				next_competing_cards.append(top_card)
				next_competing_players.append(round_winner_id)
		place_cards_on_surface(next_competing_cards,next_competing_players,[],(c+1)*0.25)
		await get_tree().create_timer(2).timeout
		r = find_winner_card_set(next_competing_players,next_competing_cards)
		round_winners = r[0]
		winner_cards = r[1]
		place_cards_on_surface(next_competing_cards,next_competing_players,winner_cards,(c+1)*0.25)
		c = c + 1
	
	var round_winner = round_winners[0]
	
	InfoText.set_info.rpc("Player "+str(round_winner+1)+" wins the round!")
	
	set_player_view.rpc()
	# clear the stat selection
	for card in cardSurface.get_children():
		card.clear_stat_selection.rpc()
	
	
	await get_tree().create_timer(2).timeout
	for card in cardSurface.get_children():
		get_player_hand(round_winner).place_card_in_hand(card,false)
		await get_tree().create_timer(0.5).timeout
	current_player_turn = -1
	var current_player_wins = true
	for i in range(NetworkLobby.players.size()):
		if i != player_id && get_player_hand(i).get_top_card() != null:
			# another player still has a card
			current_player_wins = false
	if current_player_wins:
		InfoText.declare_winner.rpc(player_id)
	else:
		player_turn_finished.emit(player_id)

@rpc("any_peer", "call_local", "reliable")
func set_selected_stat(stat_index):
	if current_player_turn == NetworkLobby.players[multiplayer.get_remote_sender_id()]["player_id"]:
		picked_stat_index = stat_index


func _unhandled_input(event: InputEvent) -> void:
	if current_player_turn == get_own_player_id():
		if event.is_action_pressed("card_stat_selection_down"): # or "menu_down"
			# Move down; wrap to 0 when reaching the end
			set_selected_stat.rpc((picked_stat_index + 1) % card_rules.size())
			get_player_hand(get_own_player_id()).get_top_card().highlight_stat(picked_stat())

		elif event.is_action_pressed("card_stat_selection_up"):
			set_selected_stat.rpc((picked_stat_index - 1) % card_rules.size())
			get_player_hand(get_own_player_id()).get_top_card().highlight_stat(picked_stat())
