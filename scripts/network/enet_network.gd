extends Node

const SERVER_PORT = 8080
# const SERVER_IP = "127.0.0.1"

func create_server_peer(no_op: String):
	var enet_network_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	enet_network_peer.create_server(SERVER_PORT)
	multiplayer.multiplayer_peer = enet_network_peer
	
func create_client_peer(hosts_ip_to_connect: String, no_op: String):
	var enet_network_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	enet_network_peer.create_client(hosts_ip_to_connect, SERVER_PORT)
	multiplayer.multiplayer_peer = enet_network_peer
