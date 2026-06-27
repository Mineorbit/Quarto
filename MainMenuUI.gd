extends Control

@onready var ip_address_field = $Buttons/OnlineContainer/IP
@onready var username_field = $Buttons/Username

const LOBBY_UID = "uid://dw10bco65qepe"

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
	get_tree().change_scene_to_file(LOBBY_UID)

func on_host_lobby_pressed() -> void:
	NetworkLobby.player_info["name"] = username_field.text
	NetworkLobby.create_game()

func on_play_online_pressed() -> void:
	NetworkLobby.player_info["name"] = username_field.text
	print("Connecting as "+str(NetworkLobby.player_info["name"]))
	NetworkLobby.join_game(ip_address_field.text)
	


func on_open_carddeck_button_pressed() -> void:
	var path = "user://card_packs/"
	# Convert the user:// path to an absolute system path
	var absolute_path = ProjectSettings.globalize_path(path)
	# Open the folder in the OS file manager
	OS.shell_open(absolute_path)
