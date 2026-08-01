extends AspectRatioContainer

# These variables should be added to the MultiplayerSynchronizer's replication list
@export var deck_info_name: String = "CardDeck":
	set(value):
		deck_info_name = value
		$CardDeckName.text = value


func load(deck_name):
	print("Loading Deck Info for "+str(deck_name))
	var deck_path = "user://card_packs/"+deck_name
	var deck_metafile_path = deck_path+"/meta.txt"
	if FileAccess.file_exists(deck_metafile_path):
		var meta_file = FileAccess.open(deck_metafile_path, FileAccess.READ)
		var file_deck_name = meta_file.get_line()
		deck_info_name = file_deck_name
