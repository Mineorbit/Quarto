extends Node3D

@onready var card_field_label = preload("res://card/CardFieldLabel.tscn")
@onready var card_field_value = preload("res://card/CardFieldValue.tscn")
@onready var card_name_label = $SubViewport/CardInformation/Name


func initialize_card(card_name,card_values):
	print("Test")
	card_name_label.text = card_name
