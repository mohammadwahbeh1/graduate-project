import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebRTCSignaling {
  late RTCPeerConnection _peerConnection;
  final WebSocketChannel channel;
  String targetId;
  late MediaStream? remoteStream;
  bool isInitiator = false;
  bool isCallStarted = false;

  WebRTCSignaling(this.channel, this.targetId) {
    channel.stream.listen((message) {
      handleMessage(jsonDecode(message));
    });
  }

  void updateTargetId(String newTargetId) {
    targetId = newTargetId;
  }

  Future<void> initialize() async {
    await Helper.selectAudioOutput('speaker');

    Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
      'iceCandidatePoolSize': 10,
    };

    _peerConnection = await createPeerConnection(configuration, {
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': false
      },
      'optional': [
        {'DtlsSrtpKeyAgreement': true},
      ],
    });

    _setupPeerConnectionListeners();
  }

  void _setupPeerConnectionListeners() {
    _peerConnection.onConnectionState = (state) {
      print('Connection state changed to: ${state.toString()}');
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          print('The peer connection is now connected!');
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          _handleConnectionFailure();
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          print('The peer connection is disconnected.');
          break;
        default:
          print('Connection state: $state');
      }
    };

    _peerConnection.onIceConnectionState = (RTCIceConnectionState state) {
      print('ICE connection state: $state');
    };

    _peerConnection.onIceGatheringState = (state) {
      print('ICE Gathering State: ${state.toString()}');
    };

    _peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
      _sendSignalingMessage('candidate', {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      }, targetId);
    };

    _peerConnection.onTrack = (RTCTrackEvent event) {
      if (event.track.kind == 'audio') {
        remoteStream = event.streams[0];
        _enableAudioPlayback(event.track, remoteStream!);
      }
    };
  }

  void _enableAudioPlayback(MediaStreamTrack track, MediaStream stream) {
    track.enabled = true;
    stream.getAudioTracks().forEach((audioTrack) {
      audioTrack.enabled = true;
    });
    _playRemoteAudio(stream);
  }

  Future<void> startCall(MediaStream localStream, String callTargetId) async {
    if (isCallStarted) return;
    isCallStarted = true;

    updateTargetId(callTargetId);

    // Enable local audio tracks
    localStream.getAudioTracks().forEach((track) {
      track.enabled = true;
    });

    // Add audio transceiver
    await _peerConnection.addTransceiver(
        track: localStream.getAudioTracks().first,
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(
            direction: TransceiverDirection.SendRecv,
            streams: [localStream]
        )
    );

    try {
      RTCSessionDescription offer = await _peerConnection.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': false
      });

      await _peerConnection.setLocalDescription(offer);
      _sendSignalingMessage('offer', offer.toMap(), targetId);
    } catch (e) {
      print('Error creating offer: $e');
      isCallStarted = false;
    }
  }

  Future<void> handleMessage(Map<String, dynamic> message) async {
    if (message['type'] != 'webrtc') return;

    final subtype = message['subtype'];
    final data = message['data'];

    try {
      switch (subtype) {
        case 'offer':
          await _handleOffer(data, message['fromUserId']);
          break;

        case 'answer':
          await _handleAnswer(data);
          break;

        case 'candidate':
          await _handleCandidate(data);
          break;
      }
    } catch (e) {
      print('Error during signaling: $e');
    }
  }

  Future<void> _handleOffer(Map<String, dynamic> data, String fromUserId) async {
    print('Processing offer');
    await _peerConnection.setRemoteDescription(
        RTCSessionDescription(data['sdp'], data['type'])
    );

    RTCSessionDescription answer = await _peerConnection.createAnswer();
    await _peerConnection.setLocalDescription(answer);
    _sendSignalingMessage('answer', answer.toMap(), fromUserId);
  }

  Future<void> _handleAnswer(Map<String, dynamic> data) async {
    print('Processing answer');
    if (_peerConnection.signalingState != RTCSignalingState.RTCSignalingStateStable) {
      await _peerConnection.setRemoteDescription(
          RTCSessionDescription(data['sdp'], data['type'])
      );
    }
  }

  Future<void> _handleCandidate(Map<String, dynamic> data) async {
    print('Processing ICE candidate');
    if (data['candidate'] != null) {
      await _peerConnection.addCandidate(
          RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex']
          )
      );
    }
  }

  void _handleConnectionFailure() {
    print('Connection failed - attempting reconnection');
    isCallStarted = false;
    // Implement reconnection logic here if needed
  }

  void _sendSignalingMessage(String type, dynamic data, String targetId) {
    final message = {
      'type': 'webrtc',
      'subtype': type,
      'targetId': targetId,
      'data': data,
    };
    print('Sending WebRTC message: $message');
    channel.sink.add(jsonEncode(message));
  }

  void _playRemoteAudio(MediaStream stream) {
    stream.getAudioTracks().forEach((track) {
      print('Playing audio from remote track');
      track.enabled = true;
    });
  }

  Future<void> stopCall() async {
    isCallStarted = false;

    try {
      if (_peerConnection != null) {
        await _peerConnection.close();

        Map<String, dynamic> configuration = {
          'iceServers': [
            {'urls': 'stun:stun.l.google.com:19302'},
          ],
          'sdpSemantics': 'unified-plan',
          'iceCandidatePoolSize': 10,
        };

        _peerConnection = await createPeerConnection(configuration, {
          'mandatory': {
            'OfferToReceiveAudio': true,
            'OfferToReceiveVideo': false
          },
          'optional': [
            {'DtlsSrtpKeyAgreement': true},
          ],
        });

        _setupPeerConnectionListeners();
      }

      // Safely handle remoteStream
      if (remoteStream != null) {
        remoteStream!.getTracks().forEach((track) => track.stop());
      }

      print('Call stopped and connection reset');
    } catch (e) {
      print('Error during stopCall: $e');
    }
  }
  Future<void> dispose() async {
    isCallStarted = false;
    await _peerConnection.close();
    channel.sink.close();
    if (remoteStream != null) {
      remoteStream!.dispose();
    }
  }
}

