import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

class JitsiService {
  static final JitsiService _instance = JitsiService._internal();
  factory JitsiService() => _instance;
  JitsiService._internal();

  late JitsiMeet _jitsiMeet;
  
  // Initialize the service
  void initialize() {
    _jitsiMeet = JitsiMeet();
  }

  // Default config - can be overridden
  Map<String, dynamic> get defaultConfig => {
    "disableInviteFunctions": false,
    "startWithVideoMuted": false,
    "startWithAudioMuted": true,
    "enableUserRolesBasedOnToken": true,
    "enableRecording": true,
    "liveStreamingEnabled": true,
    "fileRecordingsEnabled": true,
    "tokenAuth": true,
    "authenticationDomain": "meeting.apt.shiksha",
    "resolution": 720,
    "startScreenSharing": false,
    "disableSimulcast": false,
    "disableReactionsSounds": false,
    "disableReactions": false,
    "enableWelcomePage": false,
    "enableClosePage": false,
    "enablePreJoinPage": false,
    "toolbarButtons": [
      'microphone',
      'camera',
      'closedcaptions',
      'desktop',
      'fullscreen',
      'fodeviceselection',
      'hangup',
      'profile',
      'chat',
      'recording',
      'livestreaming',
      'etherpad',
      'sharedvideo',
      'settings',
      'raisehand',
      'videoquality',
      'filmstrip',
      'invite',
      'feedback',
      'stats',
      'shortcuts',
      'tileview',
      'videobackgroundblur',
      'download',
      'help',
      'mute-everyone',
      'security'
    ],
  };

  Map<String, dynamic> get defaultFeatureFlags => {
    "unsaferoomwarning.enabled": false,
    "security-options.enabled": true,
    "lobby-mode.enabled": true,
    "livestreaming.enabled": true,
    "recording.enabled": true,
    "transcription.enabled": true,
    "live-streaming.enabled": true,
    "calendar.enabled": true,
    "call-integration.enabled": true,
    "car-mode.enabled": false,
    "meeting-name.enabled": true,
    "meeting-password.enabled": true,
    "kick-out.enabled": true,
    "welcome-page.enabled": false,
    "close-captions.enabled": true,
    "prejoin-page.enabled": false,
    "video-share.enabled": true,
    "video-mute.enabled": true,
    "audio-mute.enabled": true,
    "chat.enabled": true,
    "invite.enabled": true,
    "add-people.enabled": true,
    "raisehand.enabled": true,
    "reactions.enabled": true,
    "camera.enabled": true,
    "desktop.enabled": true,
    "android.screensharing.enabled": true,
    "ios.screensharing.enabled": true,
    "filmstrip.enabled": true,
    "tile-view.enabled": true,
    "toolbox.enabled": true,
    "overflow-menu.enabled": true,
    "settings.enabled": true,
    "profile.enabled": true,
    "recording.enabled": true,
    "livestreaming.enabled": true,
    "localrecording.enabled": true,
    "fullscreen.enabled": true,
    "pip.enabled": true,
    "breakout-rooms.enabled": true,
    "whiteboard.enabled": true,
    "etherpad.enabled": true,
    "server-url-change.enabled": false,
    "embed-meeting.enabled": false,
    "deep-linking.enabled": false,
    "resolution": 720,
  };

  /// Start class and join meeting - for batches
  Future<bool> startClassAndJoin({
    required String batchId,
    required String batchName,
    String role = "teacher",
    String userId = "62d528a507a58b4519b109c1",
    BuildContext? context,
    JitsiMeetEventListener? eventListener,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://meet-api.apt.shiksha/api/Batches/startClass'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "role": role,
          "userId": userId,
          "batchId": batchId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        final token = data['token'];
        final displayName = data['user']['name'];
        final email = "${data['user']['loginId']}@apt.shiksha";
        final config = Map<String, dynamic>.from(data['configOverwrite'] ?? defaultConfig);
        final interfaceConfig = Map<String, dynamic>.from(data['interfaceConfigOverwrite'] ?? {});

        return await joinMeeting(
          roomName: batchName,
          token: token,
          displayName: displayName,
          email: email,
          configOverrides: config,
          featureFlags: interfaceConfig,
          context: context,
          eventListener: eventListener,
        );
      } else {
        debugPrint('Failed to start class. Status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        _showError(context, 'Failed to start class');
        return false;
      }
    } catch (e) {
      debugPrint('Error in startClassAndJoinBatch: $e');
      _showError(context, 'Error: $e');
      return false;
    }
  }

  /// Direct join meeting - for custom meetings
  Future<bool> joinMeeting({
    required String roomName,
    required String token,
    required String displayName,
    required String email,
    Map<String, dynamic>? configOverrides,
    Map<String, dynamic>? featureFlags,
    String serverURL = "https://meeting.apt.shiksha",
    BuildContext? context,
    JitsiMeetEventListener? eventListener,
  }) async {
    try {
      if (token.isEmpty || roomName.isEmpty) {
        debugPrint("Token or room name is missing");
        _showError(context, 'Missing token or room name');
        return false;
      }

      debugPrint('Room: $roomName');
      debugPrint('Token: $token');
      debugPrint('Display Name: $displayName');
      debugPrint('Email: $email');

      // Merge configs
      final finalConfig = {...defaultConfig, ...?configOverrides};
      final finalFeatureFlags = {...defaultFeatureFlags, ...?featureFlags};

      var options = JitsiMeetConferenceOptions(
        serverURL: serverURL,
        room: roomName,
        token: token,
        configOverrides: finalConfig,
        featureFlags: finalFeatureFlags,
        userInfo: JitsiMeetUserInfo(
          displayName: displayName,
          email: email,
        ),
      );

      // Use provided event listener or create default one
      final listener = eventListener ?? _createDefaultEventListener();

      await _jitsiMeet.join(options, listener);
      return true;
      
    } catch (e, stacktrace) {
      debugPrint('Error joining meeting: $e');
      debugPrint('Stacktrace: $stacktrace');
      _showError(context, 'Error joining meeting: $e');
      return false;
    }
  }

  /// Create a quick meeting without API call
  Future<bool> createQuickMeeting({
    required String roomName,
    required String displayName,
    String email = "",
    Map<String, dynamic>? configOverrides,
    Map<String, dynamic>? featureFlags,
    String serverURL = "https://meeting.apt.shiksha",
    BuildContext? context,
    JitsiMeetEventListener? eventListener,
  }) async {
    try {
      // Merge configs
      final finalConfig = {...defaultConfig, ...?configOverrides};
      final finalFeatureFlags = {...defaultFeatureFlags, ...?featureFlags};

      var options = JitsiMeetConferenceOptions(
        serverURL: serverURL,
        room: roomName,
        configOverrides: finalConfig,
        featureFlags: finalFeatureFlags,
        userInfo: JitsiMeetUserInfo(
          displayName: displayName,
          email: email,
        ),
      );

      // Use provided event listener or create default one
      final listener = eventListener ?? _createDefaultEventListener();

      await _jitsiMeet.join(options, listener);
      return true;
      
    } catch (e, stacktrace) {
      debugPrint('Error creating quick meeting: $e');
      debugPrint('Stacktrace: $stacktrace');
      _showError(context, 'Error creating meeting: $e');
      return false;
    }
  }

  /// Create default event listener
  JitsiMeetEventListener _createDefaultEventListener() {
    return JitsiMeetEventListener(
      conferenceJoined: (url) {
        debugPrint("conferenceJoined: url: $url");
      },
      participantJoined: (email, name, role, participantId) {
        debugPrint(
          "participantJoined: email: $email, name: $name, role: $role, "
              "participantId: $participantId",
        );
      },
      participantLeft: (participantId) {
        debugPrint("participantLeft: participantId: $participantId");
      },
      conferenceTerminated: (url, error) {
        debugPrint("conferenceTerminated: url: $url, error: $error");
      },
      audioMutedChanged: (muted) {
        debugPrint("audioMutedChanged: muted: $muted");
      },
      videoMutedChanged: (muted) {
        debugPrint("videoMutedChanged: muted: $muted");
      },
      endpointTextMessageReceived: (senderId, message) {
        debugPrint("endpointTextMessageReceived: senderId: $senderId, message: $message");
      },
      screenShareToggled: (participantId, sharing) {
        debugPrint("screenShareToggled: participantId: $participantId, sharing: $sharing");
      },
      chatMessageReceived: (senderId, message, isPrivate, timestamp) {
        debugPrint("chatMessageReceived: senderId: $senderId, message: $message, isPrivate: $isPrivate, timestamp: $timestamp");
      },
      chatToggled: (isOpen) {
        debugPrint("chatToggled: isOpen: $isOpen");
      },
      participantsInfoRetrieved: (participantsInfo) {
        debugPrint("participantsInfoRetrieved: $participantsInfo");
      },
      readyToClose: () {
        debugPrint("readyToClose");
      },
    );
  }

  /// Show error message if context is available
  void _showError(BuildContext? context, String message) {
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  /// Hang up current meeting
  Future<void> hangUp() async {
    try {
      await _jitsiMeet.hangUp();
    } catch (e) {
      debugPrint('Error hanging up: $e');
    }
  }

  /// Check if meeting is active
  // Note: This might not be available in all versions of the plugin
  // You might need to track meeting state manually
}