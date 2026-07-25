extends Node

@export var player_info_scene: PackedScene
@onready var player_list = $Players
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	NetworkLobby.player_connected.connect(add_player_to_list)
	add_player_to_list(1,NetworkLobby.player_info)
	
	$LaunchGame.disabled = !multiplayer.is_server()


func add_player_to_list(peer_id,player_info):
	# ONLY the server executes the spawning logic
	if multiplayer.is_server():
		var new_player_ui = player_info_scene.instantiate()
		
		# CRITICAL: Name the node using the peer ID.
		# Godot's multiplayer relies on node paths being identical across all clients.
		new_player_ui.name = str(peer_id)
		new_player_ui.player_name = player_info["name"]
		print("Adding Player Info for peer "+str(peer_id))
		
		# Adding it to the spawn path triggers the MultiplayerSpawner
		# This will automatically appear on all client screens.
		player_list.add_child(new_player_ui)
	
	


func on_launch_game_pressed() -> void:
	NetworkLobby.load_game.rpc("res://scenes/game.tscn")
