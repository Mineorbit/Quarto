extends Control

@onready var ip_address_field = $Buttons/OnlineContainer/IP
@onready var username_field = $Buttons/Username

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	NetworkLobby.player_connected.connect(
		func(id,_player_info): 
			print("Connected: "+str(id))
			if id == NetworkLobby.own_id:
				enter_lobby()
	)


func enter_lobby():
	print("Entering Lobby")
	get_tree().change_scene_to_file("res://lobby.tscn")

func on_host_lobby_pressed() -> void:
	NetworkLobby.player_info["name"] = username_field.text
	var error = NetworkLobby.create_game()
	if error == null:
		enter_lobby()

func on_play_online_pressed() -> void:
	NetworkLobby.player_info["name"] = username_field.text
	print("Connecting as "+str(NetworkLobby.player_info["name"]))
	NetworkLobby.join_game(ip_address_field.text)
	
