extends Node

var _loading_scene = preload("res://scenes/loading.tscn")
var _active_loading_scene

#var _enet_network = preload("res://scenes/network/enet_network.tscn")
# TODO: make this a toggle
var _network = preload("res://scenes/network/noray_network.tscn")

var is_hosting_game = false

# TODO: 
#func _select_network():
#	print("Select network...")

func host_game():
	print("Host game")
	show_loading()
	is_hosting_game = true
	var active_network = _network.instantiate()
	add_child(active_network)
	active_network.create_server_peer()

func join_game(hosts_oid):
	print("Join game")
	show_loading()

	var active_network = _network.instantiate()
	add_child(active_network)
	active_network.create_client_peer(hosts_oid)
	
func show_loading():
	print("Show loading")
	_active_loading_scene = _loading_scene.instantiate()
	add_child(_active_loading_scene)
	
func hide_loading():
	print("Hide loading")
	if _active_loading_scene != null:
		remove_child(_active_loading_scene)
		_active_loading_scene.queue_free()
