extends Node

# Autoloader (singleton) to manage network setup

enum AvailableNetworks {ENET, NORAY}
var selected_network: AvailableNetworks = AvailableNetworks.ENET # default to Enet

var _loading_scene = preload("res://scenes/loading.tscn")
var _active_loading_scene

var _enet_network = preload("res://scenes/network/enet_network.tscn")
var _noray_network = preload("res://scenes/network/noray_network.tscn")
var _network = _enet_network

var is_hosting_game = false
var active_host_ip = ""
var active_game_id = ""

func noray_enabled(is_enabled: bool = false):
	print("Setting network type to Noray: %s" % is_enabled)
	
	if is_enabled:
		selected_network = AvailableNetworks.NORAY
		_network = _noray_network
	else:
		selected_network = AvailableNetworks.ENET
		_network = _enet_network

	print("Selected Network: %s" % selected_network)

func host_game(host_ip: String):
	print("Host game")
	show_loading()
	is_hosting_game = true
	var active_network = _network.instantiate()
	add_child(active_network)
	active_host_ip = host_ip
	active_network.create_server_peer(host_ip)

func join_game(host_ip: String, game_id: String = ""):
	print("Join game, host_ip: %s, game_id: %s" % [host_ip, game_id])
	show_loading()

	var active_network = _network.instantiate()
	add_child(active_network)
	active_network.create_client_peer(host_ip, game_id)
	
func show_loading():
	print("Show loading")
	_active_loading_scene = _loading_scene.instantiate()
	add_child(_active_loading_scene)
	
func hide_loading():
	print("Hide loading")
	if _active_loading_scene != null:
		remove_child(_active_loading_scene)
		_active_loading_scene.queue_free()
