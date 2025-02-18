extends Control

const GAME_SCENE = "res://scenes/game.tscn"

func _ready():
	print("Main menu ready...")
	if OS.has_feature("dedicated_server"):
		print("Calling host game...")
		NetworkManager.host_game()
		get_tree().call_deferred(&"change_scene_to_packed", preload(GAME_SCENE))

func host_game():
	print("Host game pressed")
	NetworkManager.host_game()
	get_tree().call_deferred(&"change_scene_to_packed", preload(GAME_SCENE))
	
func join_game():
	print("Join game pressed %s" % $Menu/LineEdit.text)
	if $Menu/LineEdit.text && $Menu/LineEdit.text != "":
		NetworkManager.join_game($Menu/LineEdit.text)
		get_tree().call_deferred(&"change_scene_to_packed", preload(GAME_SCENE))
	
func exit_game():
	get_tree().quit(0)
