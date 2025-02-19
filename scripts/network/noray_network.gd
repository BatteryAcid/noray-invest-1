extends Node

var host = "ec2-34-221-170-98.us-west-2.compute.amazonaws.com"
var port = 8890
var _current_host_oid = ""

func _ready():
	# TODO: right now this signal is only for client, the server one is in multiplayer_manager, refactor?
	if !NetworkManager.is_hosting_game:
		Noray.on_connect_nat.connect(_handle_nat_connect)
		Noray.on_connect_relay.connect(_handle_relay_connect)

func create_server_peer():
	print("Create server peer, calling to register with Noray...")
	await _register_with_noray()
	print("Calling to start Noray host...")
	_start_noray_host()

func _register_with_noray():
	print("Register with Noray...")
	var err = OK
	
	# Connect to noray
	err = await Noray.connect_to_host(host, port)
	if err != OK:
		print("Failed to connect %s" % err)
		return err # Failed to connect

	# Register host
	Noray.register_host()
	await Noray.on_pid

	# Register remote address
	# This is where noray will direct traffic
	err = await Noray.register_remote()
	if err != OK:
		print("Failed to register %s" % err)
		return err # Failed to register
	
	print("Finished Noray registration")

func _start_noray_host():
	print("Starting Noray host...")
	var err = OK
	
	var noray_network_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	noray_network_peer.create_server(Noray.local_port)
	multiplayer.multiplayer_peer = noray_network_peer # TODO: is this line required?
	
	if err != OK:
		print("Failed to listen on port %s" % err)
		return false # Failed to listen on port

func create_client_peer(hosts_oid):
	print("Create client peer, calling to register with Noray...")
	_current_host_oid = hosts_oid
	await _register_with_noray()
	
	print("Create client peer for Noray through NAT with OID: %s" % hosts_oid)
	# Try connecting using NAT punchthrough
	Noray.connect_nat(hosts_oid)

func _handle_nat_connect(address: String, port: int) -> Error:
	print("Handle nat connect...")
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
	#print("networkid: %s" % multiplayer.get_unique_id())
	
 	# Do a handshake
	var udp = PacketPeerUDP.new()
	udp.bind(Noray.local_port)
	udp.set_dest_address(address, port)

	var err = await PacketHandshake.over_packet_peer(udp, 16)
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

	# TODO: will probably need this??
	multiplayer.multiplayer_peer = peer

	return OK
