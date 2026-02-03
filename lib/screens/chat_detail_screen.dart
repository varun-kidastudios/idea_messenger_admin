import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../providers/chats_provider.dart';
import '../services/media_decoder_service.dart';
import '../theme_constants.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String userId;
  final Chat chat;

  const ChatDetailScreen({
    super.key,
    required this.userId,
    required this.chat,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final MediaDecoderService _mediaDecoder = MediaDecoderService();
  final Map<String, AudioPlayer> _audioPlayers = {};
  final Map<String, bool> _audioPlayingStates = {};
  final Map<String, Duration> _audioDurations = {};
  final Map<String, Duration> _audioPositions = {};

  @override
  void dispose() {
    for (var player in _audioPlayers.values) {
      player.dispose();
    }
    super.dispose();
  }

  void _showFullScreenImage(Uint8List imageBytes) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (context) => CupertinoPageScaffold(
          backgroundColor: CupertinoColors.black,
          navigationBar: CupertinoNavigationBar(
            backgroundColor: CupertinoColors.black.withOpacity(0.5),
            border: null,
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.xmark, color: CupertinoColors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          child: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.memory(imageBytes, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleAudioPlayback(Message message) async {
    if (message.mediaContent == null) return;
    final messageId = message.id;
    final isPlaying = _audioPlayingStates[messageId] ?? false;

    if (isPlaying) {
      await _audioPlayers[messageId]?.pause();
      setState(() => _audioPlayingStates[messageId] = false);
    } else {
      if (!_audioPlayers.containsKey(messageId)) {
        final audioPath = await _mediaDecoder.decodeAudioToFile(
          message.mediaContent!,
          filename: 'audio_$messageId',
        );

        if (audioPath != null) {
          final player = AudioPlayer();
          _audioPlayers[messageId] = player;
          player.onDurationChanged.listen((d) => setState(() => _audioDurations[messageId] = d));
          player.onPositionChanged.listen((p) => setState(() => _audioPositions[messageId] = p));
          player.onPlayerComplete.listen((_) => setState(() {
            _audioPlayingStates[messageId] = false;
            _audioPositions[messageId] = Duration.zero;
          }));

          await player.play(DeviceFileSource(audioPath));
          setState(() => _audioPlayingStates[messageId] = true);
        }
      } else {
        await _audioPlayers[messageId]?.resume();
        setState(() => _audioPlayingStates[messageId] = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(
      chatMessagesStreamProvider(
        ChatIdentifier(userId: widget.userId, chatId: widget.chat.id),
      ),
    );

    return CupertinoPageScaffold(
      backgroundColor: AdminTheme.surfaceGrey,
      navigationBar: CupertinoNavigationBar(
        middle: Column(
          children: [
            Text(widget.chat.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text(widget.chat.categoryName.toUpperCase(), 
              style: TextStyle(fontSize: 10, color: Color(widget.chat.categoryColor), fontWeight: FontWeight.w800)),
          ],
        ),
        backgroundColor: AdminTheme.surfaceWhite,
        border: null,
      ),
      child: SafeArea(
        bottom: false,
        child: messagesAsync.when(
          data: (messages) {
            if (messages.isEmpty) return _buildEmptyState();
            return _buildMessageList(messages);
          },
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (error, stack) => _buildErrorState(error),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.chat_bubble_2, size: 64, color: AdminTheme.textLightGrey),
          const SizedBox(height: 16),
          Text('No messages in this chat', style: AdminTheme.subHeading),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<Message> messages) {
    return CustomScrollView(
      reverse: true, // Show latest at bottom but scrollable
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Reverse the index because we are using reverse: true on the scroll view usually, 
                // but for messages we actually want them in chronological order or handled specifically.
                // Let's keep it simple: index 0 is first message.
                final message = messages[messages.length - 1 - index];
                return _buildMessageBubble(message);
              },
              childCount: messages.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isUser = message.isMe;
    final dateFormat = DateFormat('h:mm a');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? AdminTheme.primaryBlue : AdminTheme.surfaceWhite,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: AdminTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.hasImage) ...[
                    if (message.multiMediaContent != null && message.multiMediaContent!.isNotEmpty)
                      _buildMultiImageContent(message.multiMediaContent!)
                    else if (message.mediaContent != null)
                      _buildImageContent(message.mediaContent!),
                    if (message.text.isNotEmpty) const SizedBox(height: 8),
                  ],
                  if (message.hasVoice && message.mediaContent != null) ...[
                    _buildAudioPlayer(message),
                    if (message.text.isNotEmpty) const SizedBox(height: 8),
                  ],
                  if (message.text.isNotEmpty)
                    Text(
                      message.text,
                      style: AdminTheme.body.copyWith(
                        color: isUser ? CupertinoColors.white : AdminTheme.textBlack,
                        fontSize: 15,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(message.timestamp),
                    style: AdminTheme.caption.copyWith(
                      fontSize: 9,
                      color: isUser ? CupertinoColors.white.withOpacity(0.6) : AdminTheme.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            if (message.tags.isNotEmpty || message.keywords.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                child: Wrap(
                  spacing: 4,
                  children: [
                    ...message.tags.map((t) => _buildChip(t, isUser)),
                    ...message.keywords.map((k) => _buildChip('🔑 $k', isUser)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String text, bool isUser) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AdminTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.textLightGrey.withOpacity(0.3)),
      ),
      child: Text(text, style: AdminTheme.caption.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildImageContent(String base64) {
    final bytes = _mediaDecoder.decodeImage(base64);
    if (bytes == null) return const Text('Error loading image');
    return GestureDetector(
      onTap: () => _showFullScreenImage(bytes),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(bytes, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildMultiImageContent(List<String> images) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = (constraints.maxWidth - 4) / 2;
        return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: images.take(4).map((img) => SizedBox(
            width: size,
            height: size,
            child: _buildImageContent(img),
          )).toList(),
        );
      },
    );
  }

  Widget _buildAudioPlayer(Message message) {
    final id = message.id;
    final isPlaying = _audioPlayingStates[id] ?? false;
    final pos = _audioPositions[id] ?? Duration.zero;
    final dur = _audioDurations[id] ?? Duration.zero;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: message.isMe ? CupertinoColors.white.withOpacity(0.2) : AdminTheme.surfaceGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _toggleAudioPlayback(message),
            child: Icon(
              isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
              color: message.isMe ? CupertinoColors.white : AdminTheme.primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Voice Note', 
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, 
                color: message.isMe ? CupertinoColors.white : AdminTheme.textBlack)),
              Text('${pos.inSeconds}s / ${dur.inSeconds}s', 
                style: TextStyle(fontSize: 10, 
                color: message.isMe ? CupertinoColors.white.withOpacity(0.7) : AdminTheme.textGrey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(dynamic error) {
    return Center(child: Text(error.toString(), style: AdminTheme.caption));
  }
}
