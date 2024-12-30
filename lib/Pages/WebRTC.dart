// web_rtc_signaling.dart
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
  bool isRemoteAudioMuted = false;
  bool isAvailable = true;
  Function(bool isActive)? onRemoteAudioStateChange;

  WebRTCSignaling(this.channel, this.targetId) {
    channel.stream.listen((message) {
      handleMessage(jsonDecode(message));
    });
  }

  void updateTargetId(String newTargetId) {
    targetId = newTargetId;
  }

  void setAvailability(bool available) {
    isAvailable = available;
    channel.sink.add(jsonEncode({
      'type': 'status',
      'status': available ? 'available' : 'unavailable'
    }));
  }

  Future<void> initialize({Function(bool isActive)? onRemoteAudioStateChange}) async {
    this.onRemoteAudioStateChange = onRemoteAudioStateChange;
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
    setAvailability(true);
  }

  void _setupPeerConnectionListeners() {
    _peerConnection.onConnectionState = (state) {
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          _handleConnectionFailure();
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          break;
        default:
          break;
      }
    };

    _peerConnection.onIceConnectionState = (RTCIceConnectionState state) {
    };

    _peerConnection.onIceGatheringState = (state) {
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
        event.track.onMute = () {
          if (onRemoteAudioStateChange != null) {
            onRemoteAudioStateChange!(false);
          }
        };
        event.track.onUnMute = () {
          if (onRemoteAudioStateChange != null) {
            onRemoteAudioStateChange!(true);
          }
        };
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
    if (!isAvailable) {
      return;
    }

    if (isCallStarted) return;
    isCallStarted = true;

    updateTargetId(callTargetId);

    localStream.getAudioTracks().forEach((track) {
      track.enabled = true;
    });

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
      isCallStarted = false;
    }
  }

  Future<void> handleMessage(Map<String, dynamic> message) async {
    if (message['type'] != 'webrtc') return;

    if (!isAvailable && message['subtype'] == 'offer') {
      _sendSignalingMessage('reject', {
        'reason': 'unavailable'
      }, message['fromUserId']);
      return;
    }

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
        case 'reject':
          _handleReject(data);
          break;
      }
    } catch (e) {
    }
  }

  void _handleReject(Map<String, dynamic> data) {
    stopCall();
  }

  Future<void> _handleOffer(Map<String, dynamic> data, String fromUserId) async {
    await _peerConnection.setRemoteDescription(
        RTCSessionDescription(data['sdp'], data['type'])
    );
    RTCSessionDescription answer = await _peerConnection.createAnswer();
    await _peerConnection.setLocalDescription(answer);
    _sendSignalingMessage('answer', answer.toMap(), fromUserId);
  }

  Future<void> _handleAnswer(Map<String, dynamic> data) async {
    if (_peerConnection.signalingState != RTCSignalingState.RTCSignalingStateStable) {
      await _peerConnection.setRemoteDescription(
          RTCSessionDescription(data['sdp'], data['type'])
      );
    }
  }

  Future<void> _handleCandidate(Map<String, dynamic> data) async {
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
    isCallStarted = false;
  }

  void _sendSignalingMessage(String type, dynamic data, String targetId) {
    final message = {
      'type': 'webrtc',
      'subtype': type,
      'targetId': targetId,
      'data': data,
    };
    channel.sink.add(jsonEncode(message));
  }

  void _playRemoteAudio(MediaStream stream) {
    stream.getAudioTracks().forEach((track) {
      track.enabled = true;
    });
  }

  Future<void> stopCall() async {
    isCallStarted = false;

    try {
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

      if (remoteStream != null) {
        remoteStream!.getTracks().forEach((track) => track.stop());
      }
    } catch (e) {
    }
  }

  void toggleRemoteAudio() {
    if (remoteStream != null) {
      isRemoteAudioMuted = !isRemoteAudioMuted;
      remoteStream!.getAudioTracks().forEach((track) {
        track.enabled = !isRemoteAudioMuted;
      });
    }
  }

  Future<void> dispose() async {
    isCallStarted = false;
    isAvailable = false;
    await _peerConnection.close();
    channel.sink.close();
    if (remoteStream != null) {
      remoteStream!.dispose();
    }
  }
}