extends Panel

# These variables should be added to the MultiplayerSynchronizer's replication list
@export var player_name: String = "Connecting...":
	set(value):
		player_name = value
		$PlayerName.text = value
