extends Node

signal network_client_connected
signal network_server_disconnected

var port = 8890
var _current_host_oid = ""

func _ready():
	if !NetworkManager.is_hosting_game:
		setup_client_noray_connection_signals()
	else:
		setup_host_noray_connection_signals()

func create_server_peer(network_connection_configs: NetworkConnectionConfigs):
	print("Create Noray server peer")
	await _register_with_noray(network_connection_configs.host_ip)
	_start_noray_host()

func create_client_peer(network_connection_configs: NetworkConnectionConfigs):
	print("Create Noray client peer")
	
	# Stash the host_oid to use in the Noray connection signals
	_current_host_oid = network_connection_configs.game_id
	await _register_with_noray(network_connection_configs.host_ip)
	
	setup_client_enet_connection_signals()
	
	print("Kickoff Noray connection through NAT punchthrough with OID: %s" % network_connection_configs.game_id)
	Noray.connect_nat(network_connection_configs.game_id)

func _register_with_noray(host_ip: String):
	print("Register with Noray hosted at: %s" % host_ip)
	var err = OK
	
	# Connect to noray
	err = await Noray.connect_to_host(host_ip, port)
	if err != OK:
		print("Failed to connect to Noray for registration at %s:%s!" % [host_ip, port, err])
		return err # Failed to connect

	# Register host
	Noray.register_host()
	await Noray.on_pid

	# Capture game_id to display on host client for sharing with others.
	print("Noray oid: %s" % Noray.oid)
	NetworkManager.active_game_id = Noray.oid

	# Register remote address
	# This is where noray will direct traffic
	err = await Noray.register_remote()
	if err != OK:
		print("Failed to register remote %s" % err)
		return err # Failed to register
	
	print("Finished Noray registration")

func _start_noray_host():
	print("Starting Noray host")
	var err = OK
	
	var noray_network_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	noray_network_peer.create_server(Noray.local_port)
	multiplayer.multiplayer_peer = noray_network_peer
	
	if err != OK:
		print("Failed to listen on port %s" % err)
		return false # Failed to listen on port

func _handle_nat_connect(address: String, port: int) -> Error:
	print("Attempting to connect client via NAT...")
	var err = await _handle_connect(address, port)
	if err != OK:
		print("NAT connection failed from client, trying Relay instead...")
		Noray.connect_relay(_current_host_oid)
		return OK
	else:
		print("NAT punchthrough successful!")
	return err

func _handle_relay_connect(address: String, port: int) -> Error:
	return await _handle_connect(address, port)
	
func _handle_connect(address: String, port: int) -> Error:
	print("Client handle connect to %s:%s, Noray.local_port: %s" % [address, port, Noray.local_port])
	# print("NetworkId: %s" % multiplayer.get_unique_id())
	
 	# Do a handshake
	var udp = PacketPeerUDP.new()
	udp.bind(Noray.local_port)
	udp.set_dest_address(address, port)

	var err = await PacketHandshake.over_packet_peer(udp, 8)
	udp.close()

	if err != OK:
		print("Client packet handshake failure %s" % err)
		return err

	# Connect to host
	var peer = ENetMultiplayerPeer.new()
	err = peer.create_client(address, port, 0, 0, 0, Noray.local_port)

	if err != OK:
		print("Create client failure %s" % err)
		return err

	multiplayer.multiplayer_peer = peer

	return OK

# Noray host signal for when clients connect
func _handle_noray_client_connect(address: String, port: int) -> Error:
	print("Noray host handle connect: %s:%s" % [address, port])
	var peer = get_tree().get_multiplayer().multiplayer_peer as ENetMultiplayerPeer
	var err = await PacketHandshake.over_enet(peer.host, address, port)

	if err != OK:
		print("Noray packet handshake failure %s" % err)
		return err

	return OK

func _connected_to_server():
	print("Noray client connected to server/host, on peer %s with auth: %s" % [multiplayer.get_unique_id(), get_multiplayer_authority()])
	if not is_multiplayer_authority():
		# Once our peer has a confirmed connection to the server/host, emit the connected signals
		# to prepare for game play. Right now it just loads the game scene on the client.
		network_client_connected.emit()

func _noray_server_disconnected():
	print("Server disconnected!")
	network_server_disconnected.emit()

func setup_host_noray_connection_signals():
	Noray.on_connect_nat.connect(_handle_noray_client_connect)
	Noray.on_connect_relay.connect(_handle_noray_client_connect)

func setup_client_noray_connection_signals():
	Noray.on_connect_nat.connect(_handle_nat_connect)
	Noray.on_connect_relay.connect(_handle_relay_connect)

func setup_client_enet_connection_signals():
	multiplayer.connected_to_server.connect(_connected_to_server)
	multiplayer.server_disconnected.connect(_noray_server_disconnected)
	#multiplayer.peer_connected.connect(_noray_client_connected) # Right now there's no reason to use this...
