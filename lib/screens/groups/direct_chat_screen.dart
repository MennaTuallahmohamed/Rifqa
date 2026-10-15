import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'chat_media.dart' show ChatInputBar, ImageMessage, VoiceMessage;
import 'friend_service.dart';
import 'groups_screen.dart'
    show isDark, surfaceOf, lineOf, inkOf, mutedOf, scaffoldOf, hhmm, sameDay, dayLabel, FadeSlideIn;

class DirectChatScreen extends StatefulWidget {
  final String friendUid;
  final String friendName;

  const DirectChatScreen({
    super.key,
    required this.friendUid,
    required this.friendName,
  });

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final _service = FriendService.instance;
  final _controller = TextEditingController();
  late final Future<String> _chatId = _service.openDirectChat(widget.friendUid);

  Widget _dateChip(BuildContext context, DateTime d) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isDark(context) ? Colors.white10 : const Color(0xFFE6EBE8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(dayLabel(d), style: TextStyle(fontSize: 12, color: mutedOf(context))),
        ),
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _message(Map<String, dynamic> data, bool mine, String chatId) {
    final timestamp = data['createdAt'];
    final sentAt = timestamp is Timestamp ? timestamp.toDate() : null;
    final type = data['type']?.toString() ?? 'text';
    final mediaId = data['mediaId']?.toString() ?? '';
    final text = data['text']?.toString() ?? '';
    return Align(
      alignment: mine ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .78),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.fromLTRB(13, 9, 13, 6),
        decoration: BoxDecoration(
          color: mine ? AppColors.green : surfaceOf(context),
          borderRadius: BorderRadiusDirectional.only(
            topStart: const Radius.circular(18),
            topEnd: const Radius.circular(18),
            bottomStart: Radius.circular(mine ? 4 : 18),
            bottomEnd: Radius.circular(mine ? 18 : 4),
          ),
          border: mine ? null : Border.all(color: lineOf(context)),
          boxShadow: [
            BoxShadow(
              color: (mine ? AppColors.green : Colors.black).withValues(alpha: mine ? .2 : .05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (type == 'image' && mediaId.isNotEmpty)
              ImageMessage(
                groupId: 'direct_$chatId',
                mediaId: mediaId,
                loadBytes: () => _service.fetchDirectMedia(chatId, mediaId),
              ),
            if (type == 'voice' && mediaId.isNotEmpty)
              VoiceMessage(
                groupId: 'direct_$chatId',
                mediaId: mediaId,
                durationMs: (data['durationMs'] as num?)?.toInt() ?? 0,
                mine: mine,
                loadBytes: () => _service.fetchDirectMedia(chatId, mediaId),
              ),
            if (text.isNotEmpty)
              Text(
                text,
                style: TextStyle(color: mine ? Colors.white : inkOf(context), fontSize: 16, height: 1.4),
              ),
            if (sentAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  hhmm(sentAt),
                  style: TextStyle(
                    color: mine ? Colors.white70 : mutedOf(context),
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: scaffoldOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .18), blurRadius: 8, offset: const Offset(0, 3))],
                border: Border.all(color: Colors.white.withValues(alpha: .4), width: 1.2),
              ),
              child: CircleAvatar(
                radius: 19,
                backgroundColor: Colors.white24,
                child: Text(
                  widget.friendName.isEmpty ? '?' : widget.friendName.characters.first,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.friendName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  // عدد الرسائل مباشرة من الـ stream بدل النص الثابت
                  FutureBuilder<String>(
                    future: _chatId,
                    builder: (context, chatSnap) {
                      if (!chatSnap.hasData) {
                        return Text('محادثة خاصة',
                            style: TextStyle(color: Colors.white.withValues(alpha: .78), fontSize: 11));
                      }
                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _service.directMessages(chatSnap.data!),
                        builder: (context, msgSnap) {
                          final count = msgSnap.data?.docs.length;
                          return Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.lock_outline_rounded, size: 11, color: Colors.white70),
                            const SizedBox(width: 3),
                            Text('محادثة خاصة', style: TextStyle(color: Colors.white.withValues(alpha: .78), fontSize: 11)),
                            if (count != null) ...[
                              const SizedBox(width: 6),
                              const Text('•', style: TextStyle(fontSize: 10, color: Colors.white54)),
                              const SizedBox(width: 6),
                              Text('$count رسالة',
                                  style: TextStyle(color: Colors.white.withValues(alpha: .78), fontSize: 11)),
                            ],
                          ]);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<String>(
        future: _chatId,
        builder: (context, chatSnapshot) {
          if (chatSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'تعذر فتح المحادثة. تأكدي من اتصالك ومن تفعيل قواعد المحادثات في Firestore.\n${chatSnapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!chatSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.green));
          }
          final chatId = chatSnapshot.data!;
          return Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _service.directMessages(chatId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text('تعذر تحميل الرسائل'));
                    }
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.green),
                      );
                    }
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [AppColors.softGreen, AppColors.softGreen.withValues(alpha: .6)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: const Icon(
                                  Icons.forum_rounded,
                                  color: AppColors.green,
                                  size: 36,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'ابدئي الحديث مع ${widget.friendName}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                'ابعتي رسالة أو صورة، أو سجّلي فويس قصير.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data();
                        final t = data['createdAt'];
                        final sentAt = t is Timestamp ? t.toDate() : null;
                        final older = index + 1 < docs.length ? docs[index + 1].data() : null;
                        final olderTs = older?['createdAt'];
                        final olderAt = olderTs is Timestamp ? olderTs.toDate() : null;
                        final showDate = sentAt != null && (olderAt == null || !sameDay(sentAt, olderAt));
                        return FadeSlideIn(
                          index: 0,
                          base: const Duration(milliseconds: 180),
                          child: Column(children: [
                            if (showDate) _dateChip(context, sentAt),
                            _message(data, data['senderId'] == myUid, chatId),
                          ]),
                        );
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  decoration: BoxDecoration(
                    color: surfaceOf(context),
                    border: Border(top: BorderSide(color: lineOf(context))),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 14, offset: const Offset(0, -4))],
                  ),
                  child: ChatInputBar(
                    controller: _controller,
                    busy: false,
                    onSendText: (text) => _service.sendDirectMessage(chatId, text),
                    onSendImage: (bytes, caption) => _service.sendDirectImage(
                      chatId,
                      bytes,
                      caption: caption,
                    ),
                    onSendVoice: (bytes, durationMs) =>
                        _service.sendDirectVoice(chatId, bytes, durationMs),
                    onError: (message) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.all(14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}