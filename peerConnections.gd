extends Node

# Create the two peers
var peer: WebRTCPeerConnection

var selfConnectionInfo = {
	"session_description": {},
	"ice_candidates": []
}

var remoteConnectionInfo = {
	"session_description": {},
	"ice_candidates": []
}

# And a negotiated channel for each each peer
@onready var chatChannel: WebRTCDataChannel

# copied from docs for labels
enum ConnectionState {STATE_NEW, STATE_CONNECTING, STATE_CONNECTED, STATE_DISCONNECTED, STATE_FAILED, STATE_CLOSED}
enum GatheringState {GATHERING_STATE_NEW, GATHERING_STATE_GATHERING, GATHERING_STATE_COMPLETE}
enum SignalingState {SIGNALING_SATE_STABLE, SIGNALING_STATE_HAVE_LOCAL_OFFER, SIGNALING_STATE_HAVE_REMOTE_OFFER, SIGNALING_STATE_HAVE_LOCAL_PRANSWER, SIGNALING_STATE_HAVE_REMOTE_PRANSWER, SIGNALING_STATE_CLOSED}

func _process(_delta):
	# display statuses for peers
	if peer:
		%peerConnectionStateValue.text = "%s" % ConnectionState.keys()[peer.get_connection_state()]
		%peerGatheringStateValue.text = "%s" % GatheringState.keys()[peer.get_gathering_state()]
		%peerSignalingStateValue.text = "%s" % SignalingState.keys()[peer.get_signaling_state()]

		# poll for data in channel
		peer.poll()

	# Check for messages
	if chatChannel&&chatChannel.get_ready_state() == chatChannel.STATE_OPEN and chatChannel.get_available_packet_count() > 0:
		var newMessage = chatChannel.get_packet().get_string_from_utf8()
		print("Received:", newMessage)
		var messageLabel = Label.new()
		messageLabel.text = newMessage
		%Chat.add_child(messageLabel)

	if peer&&peer.get_gathering_state() == GatheringState.GATHERING_STATE_COMPLETE&&peer.get_connection_state() != ConnectionState.STATE_CLOSED:
		%sdp.text = JSON.stringify(selfConnectionInfo)
	else:
		%sdp.text = ""

func createOffer() -> void:
	if peer:
		if peer.get_connection_state() == ConnectionState.STATE_CLOSED:
			printerr("connection is closed")
		else:
			peer.create_offer()
	else:
		printerr("peer does not exist")

func readOffer() -> void:
	selfConnectionInfo = JSON.parse_string( %sdpOffer.text)
	if selfConnectionInfo.session_description.is_empty():
		printerr("peer has no session description from p2")
	else:
		peer.set_remote_description(selfConnectionInfo.session_description.type, selfConnectionInfo.session_description.sdp)

	if selfConnectionInfo.ice_candidates.is_empty():
		printerr("peer has no ice candidates from p2")
	else:
		for iceCandidate in selfConnectionInfo.ice_candidates:
			peer.add_ice_candidate(iceCandidate.media, int(iceCandidate.index), iceCandidate.name)

func readAnswer() -> void:
	remoteConnectionInfo = JSON.parse_string( %sdpAnswer.text)
	if remoteConnectionInfo.session_description.is_empty():
		printerr("peer has no session description from p2")
	else:
		peer.set_remote_description(remoteConnectionInfo.session_description.type, remoteConnectionInfo.session_description.sdp)

	if remoteConnectionInfo.ice_candidates.is_empty():
		printerr("peer has no ice candidates from p2")
	else:
		for iceCandidate in remoteConnectionInfo.ice_candidates:
			peer.add_ice_candidate(iceCandidate.media, int(iceCandidate.index), iceCandidate.name)

func createPeer() -> void:
	if !peer:
		peer = WebRTCPeerConnection.new()
		peer.session_description_created.connect(peer.set_local_description)
		peer.session_description_created.connect(
			func(type, sdp):
				print(
					"\nsession description created\nTYPE\n%s\nSDP\n%s"% [type, sdp.replace("\n", "")]
				)
				selfConnectionInfo.session_description={"type": type, "sdp": sdp}
		)
		peer.ice_candidate_created.connect(
			func(media, index: int, iceName):
				print(
					"\nice candidate created\nMEDIA\n%s\nINDEX\n%s\nNAME\n%s"% [media, index, iceName]
				)
				selfConnectionInfo.ice_candidates.append({
					"media": media,
					"index": index,
					"name": iceName
				})
		)

	peer.initialize()

	# must be identical for both peers
	chatChannel = peer.create_data_channel("chat", {"id": 1, "negotiated": true})

func closePeer() -> void:
	if peer:
		peer.close()

func sendMessage() -> void:
	if peer&&peer.get_connection_state() == ConnectionState.STATE_CONNECTED:
		if chatChannel.get_ready_state() == chatChannel.STATE_OPEN:
			var textToSend = %ChatMessage.text
			print("sent this to peer:%s" % textToSend)
			chatChannel.put_packet(textToSend.to_utf8_buffer())
			var messageLabel = Label.new()
			messageLabel.text = textToSend
			messageLabel.modulate = "#ababab"
			%Chat.add_child(messageLabel)
		else:
			printerr("Data channel is" + str(chatChannel.get_ready_state()))
	else:
		printerr("chat channel is not open")
	%ChatMessage.text = ""
