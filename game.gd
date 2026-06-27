extends Node

@onready var cardstack = $World/Stack
@export var CardTemplate: PackedScene

enum {UP,DOWN}
var card_spacing = 0.065

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
	var game_cards = []
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

func deal():
	pass

func _ready():
	load_cardpack("Testpack")
	
func start_game():
	print("Spiel gestartet")
