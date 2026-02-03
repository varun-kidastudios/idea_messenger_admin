import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  voice,
  file,
}

class Message {
  final String id;
  final String text;
  final MessageType type;
  final DateTime timestamp;
  final bool isMe;
  final String? mediaContent; // Base64 encoded
  final List<String>? multiMediaContent; // Multiple Base64 strings
  final List<String> tags;
  final List<String> keywords;

  Message({
    required this.id,
    required this.text,
    required this.type,
    required this.timestamp,
    required this.isMe,
    this.mediaContent,
    this.multiMediaContent,
    List<String>? tags,
    List<String>? keywords,
  })  : tags = tags ?? [],
        keywords = keywords ?? [];

  factory Message.fromMap(String id, Map<String, dynamic> data) {
    DateTime timestamp;
    try {
      if (data['timestamp'] is String) {
        timestamp = DateTime.parse(data['timestamp']);
      } else if (data['timestamp'] is Timestamp) {
        timestamp = (data['timestamp'] as Timestamp).toDate();
      } else {
        timestamp = DateTime.now();
      }
    } catch (e) {
      timestamp = DateTime.now();
      print('DEBUG: Error parsing timestamp for message $id: $e');
    }

    return Message(
      id: id,
      text: data['text'] ?? '',
      type: _parseMessageType(data['type']),
      timestamp: timestamp,
      isMe: data['isMe'] ?? false,
      mediaContent: data['mediaContent'],
      multiMediaContent: data['multiMediaContent'] != null
          ? List<String>.from(data['multiMediaContent'])
          : null,
      tags: data['tags'] != null ? List<String>.from(data['tags']) : [],
      keywords: data['keywords'] != null ? List<String>.from(data['keywords']) : [],
    );
  }

  static MessageType _parseMessageType(dynamic typeValue) {
    if (typeValue is String) {
      switch (typeValue) {
        case 'text':
          return MessageType.text;
        case 'image':
          return MessageType.image;
        case 'voice':
          return MessageType.voice;
        case 'file':
          return MessageType.file;
        default:
          return MessageType.text;
      }
    }
    return MessageType.text;
  }

  bool get hasMedia => mediaContent != null || (multiMediaContent != null && multiMediaContent!.isNotEmpty);
  
  bool get hasImage => type == MessageType.image && hasMedia;
  
  bool get hasVoice => type == MessageType.voice && hasMedia;
}
