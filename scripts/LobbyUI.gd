extends Node

@export var player_info_scene: PackedScene
@export var player_list: Control
@export var card_decks: Control

@export var card_deck_template: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	NetworkLobby.player_connected.connect(add_player_to_list)
	add_player_to_list(1,NetworkLobby.player_info)
	add_card_decks_to_list()
	$LaunchGame.disabled = !multiplayer.is_server()


func add_player_to_list(peer_id,player_info):
	if multiplayer.is_server():
		var new_player_ui = player_info_scene.instantiate()
		# CRITICAL: Name the node using the peer ID.
		# Godot's multiplayer relies on node paths being identical across all clients.
		new_player_ui.name = str(peer_id)
		new_player_ui.player_name = player_info["name"]
		print("Adding Player Info for peer "+str(peer_id))
		player_list.add_child(new_player_ui)



var peer_deck_hashes: Dictionary = {}
var server_deck_map: Dictionary = {}

func add_card_decks_to_list() -> void:
	var deckPaths: PackedStringArray = DirAccess.get_directories_at("user://card_packs")
	var local_decks = {}
	var local_hashes = []
	
	for deck_path in deckPaths:
		var pack_hash = Game.compute_cardpack_hash(deck_path)
		local_decks[pack_hash] = deck_path
		local_hashes.append(pack_hash)
		
	if multiplayer.is_server():
		server_deck_map = local_decks
		peer_deck_hashes[multiplayer.get_unique_id()] = local_hashes
		check_and_process_intersections()
	else:
		rpc_id(1, "_server_receive_deck_hashes", multiplayer.get_unique_id(), local_hashes)

@rpc("any_peer", "call_local", "reliable")
func _server_receive_deck_hashes(peer_id: int, hashes: Array) -> void:
	if not multiplayer.is_server():
		return
		
	peer_deck_hashes[peer_id] = hashes
	check_and_process_intersections()

func check_and_process_intersections() -> void:
	if not multiplayer.is_server():
		return
	
	var connected_peers = multiplayer.get_peers()
	var total_expected = connected_peers.size() + 1
	
	if peer_deck_hashes.size() < total_expected:
		return 
	
	var intersection = []
	var first = true
	
	for peer_id in peer_deck_hashes:
		var hashes = peer_deck_hashes[peer_id]
		if first:
			intersection = hashes.duplicate()
			first = false
		else:
			var new_intersection = []
			for h in intersection:
				if h in hashes:
					new_intersection.append(h)
			intersection = new_intersection
	for hash_val in intersection:
		if server_deck_map.has(hash_val):
			var deck_path = server_deck_map[hash_val]
			var new_card_deck_ui = card_deck_template.instantiate()
			new_card_deck_ui.name = deck_path
			new_card_deck_ui.load(deck_path)
			card_decks.add_child(new_card_deck_ui)



func on_launch_game_pressed() -> void:
	NetworkLobby.load_game.rpc("res://scenes/game.tscn")
