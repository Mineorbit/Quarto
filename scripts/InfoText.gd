extends Label


@rpc("any_peer", "call_local", "reliable")
func declare_winner(player_id):
	var player_text = ""
	if player_id == Game.get_own_player_id():
		player_text = "You win!"
	else:
		player_text = "Player "+str(player_id + 1)+" wins!"	
		
	set_info(player_text)

@rpc("any_peer", "call_local", "reliable")
func set_turn_text(player_id):
	var player_text = ""
	if player_id == Game.get_own_player_id():
		player_text = "It's your turn!"
	else:
		player_text = "It's player "+str(player_id + 1)+"'s turn!"
	
	set_info(player_text)

@rpc("any_peer", "call_local", "reliable")
func set_info(new_text):
	text = new_text
	print("New Info: "+new_text)
