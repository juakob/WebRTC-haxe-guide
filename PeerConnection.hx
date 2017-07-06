package;
import haxe.Http;

/**
 * ...
 * @author Joaquin
 */
class PeerConnection
{
	static inline var CHANNEL_NAME:String = 'data';
	//this servers are use to get your public IP 
	var  iceServers:Array<Dynamic>=[{
					urls: 'stun:stun.l.google.com:19302'
				  }
				];
				
	public var onMessage:String->Void; 
	public var onConnect:Void->Void;
	var isInitiator: Bool = false;
	var dataChannelReady:Bool = false;
	var peerConnection:Dynamic;
	var dataChannel:Dynamic;
	var remoteDescriptionReady:Bool = false;
	var hostId:Int;

	public function new(isInitiator:Bool,onMessage:String->Void) 
	{
		this.onMessage = onMessage;
		//I'm I the one that initiates the comunication?
		this.isInitiator = isInitiator;
		
		connect();
	}
	
	function connect() 
	{
		peerConnection = untyped  __js__("new RTCPeerConnection({iceServers: {0}})",iceServers);
		peerConnection.onicecandidate = onLocalIceCandidate;
		peerConnection.iceconnectionstatechange = onIceConnectionStateChanged;
		peerConnection.ondatachannel = onDataChannel;
		if (this.isInitiator) {
		  this.openDataChannel(
			  this.peerConnection.createDataChannel(CHANNEL_NAME, {
			ordered: false
		  }));
		}
		if (this.isInitiator) {
		  this.setLocalDescriptionAndSend();
		}
	}
	function onLocalIceCandidate(event) {
		//this are the possible connections that we can make, generated by iceServers
		//null candidate is pass when all the servers where query
		 if (event.candidate == null) {
			 if(peerConnection.localDescription.type=="offer"){
					sendSdp(0, peerConnection.localDescription);
				 }else {
					 sendIceCandidate(hostId, peerConnection.localDescription);
				 } 
		} 
	}
	function onIceConnectionStateChanged(event) {
		trace('Connection state: ' + event.target.iceConnectionState);
	}
	function onDataChannel(event) {
		trace("onChannel");
		if (!this.isInitiator) {
			openDataChannel(event.channel);
		}
	}
	function openDataChannel(channel) {
		trace("create channel");
		dataChannel = channel;
		dataChannel.onopen = onDataChannelOpen;
		dataChannel.close = onDataChannelClose;
		dataChannel.onmessage = onDataChannelMessage;
	}
	public function send(aString:String) {
		if(dataChannelReady){
			dataChannel.send(aString);
		}
	}
	function onDataChannelOpen() {
		dataChannelReady = true;
		if (onConnect != null) {
			onConnect();
		}
		trace("channel Open");
	}
	function onDataChannelMessage(event) {
		onMessage(event.data);
	};

	function onDataChannelClose() {
		this.dataChannelReady = false;
		//TODO callback close
	}
	
	function setLocalDescriptionAndSend() {
		
		getDescription()
		  .then(function(localDescription) {
			peerConnection.setLocalDescription(localDescription);
		  },
		  function(error) {
			trace('onSdpError: ' + error.message);
		  });
	}
	function getDescription() {
		return this.isInitiator ?
		  peerConnection.createOffer() :
		  peerConnection.createAnswer();
	}
	
	//upload your sdp so other users can find it
	function sendSdp(userId:Int, sdp:Dynamic) {
		
		
		var sdpString:String = sdp.sdp;
		sdpString = StringTools.replace(sdpString, "\r\n", "$%"); //avoid losing \r\n, you will need them to reconstruct the RTCSessionDescription
		var site = new Http("{your server}/AddOffer.php?offer=" + sdpString); 
		site.async = true;
		site.request();
		
		
	}
	//upload my answer to a server 
	function sendIceCandidate(userId:Dynamic, candidate:Dynamic) {
		var sdpString:String = candidate.sdp;
		sdpString = StringTools.replace(sdpString, "\r\n", "$%");
		var site = new Http("{your server}/AddAnswer.php?answer="+sdpString+"&offerID="+hostId);
		site.async = true;
		site.request();
		trace("userId : "+userId);
		trace("candidate : " + candidate);
	}
	
	//call this to set the answer/offer that you get from your server
	public function setSdp(host:Int, sdp:String,type:String="offer") {
		hostId = host;
		
		sdp = StringTools.replace(sdp,"$%","\r\n");
		// Create session description from sdp data
		trace(sdp);
		var rsd = untyped  __js__("new RTCSessionDescription({sdp:{0},type:{1}})",sdp,type);
		// And set it as remote description for peer connection
		peerConnection.setRemoteDescription(rsd)
		  .then(function() {
			remoteDescriptionReady = true;
			trace('Got SDP from remote peer');
			
			// Got offer? send answer
			if (!isInitiator) {
			  setLocalDescriptionAndSend();
			}
		  },function(error) { trace(error); } );
	}
	
}
