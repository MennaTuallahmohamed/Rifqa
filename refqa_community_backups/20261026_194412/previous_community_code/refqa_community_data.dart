import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// The first release is an in-memory UI prototype.
/// Do not treat demo users, counts, moderation or friend requests as live data.
enum RefqaPostType { question, tip, information }

enum RefqaTopic { all, haramain, hajj, umrah, markets }

extension RefqaPostTypeTitle on RefqaPostType {
  String get title => switch (this) {
        RefqaPostType.question => 'سؤال',
        RefqaPostType.tip => 'نصيحة',
        RefqaPostType.information => 'معلومة',
      };
}

extension RefqaTopicTitle on RefqaTopic {
  String get title => switch (this) {
        RefqaTopic.all => 'الكل',
        RefqaTopic.haramain => 'الحرمين',
        RefqaTopic.hajj => 'الحج',
        RefqaTopic.umrah => 'العمرة',
        RefqaTopic.markets => 'الأسواق',
      };
}

class RefqaComment {
  RefqaComment({
    required this.author,
    required this.text,
    required this.avatar,
    this.location = 'مكة المكرمة',
    this.time = 'منذ ساعتين',
    this.trusted = false,
    this.likes = 0,
  });

  final String author;
  final String text;
  final String avatar;
  final String location;
  final String time;
  final bool trusted;
  int likes;
}

class RefqaPost {
  RefqaPost({
    required this.id,
    required this.author,
    required this.avatar,
    required this.location,
    required this.time,
    required this.body,
    required this.type,
    required this.topic,
    this.image,
    List<Uint8List>? imageBytes,
    this.verified = false,
    this.pending = false,
    this.likes = 0,
    this.extraDemoCommentCount = 0,
    List<RefqaComment>? comments,
  }) : imageBytes = imageBytes ?? <Uint8List>[],
       comments = comments ?? [];

  final String id;
  final String author;
  final String avatar;
  final String location;
  final String time;
  final String body;
  final RefqaPostType type;
  final RefqaTopic topic;
  final String? image;
  final List<Uint8List> imageBytes; // local preview only
  final bool verified;
  final bool pending;
  int likes;
  bool liked = false;
  bool saved = false;
  bool reported = false;
  final int extraDemoCommentCount;
  final List<RefqaComment> comments;
  int get commentCount => comments.length + extraDemoCommentCount;
}

class RefqaFriendRequest {
  RefqaFriendRequest({required this.name, required this.city, required this.avatar});
  final String name;
  final String city;
  final String avatar;
}

/// Safe preview-only state, reset when the Flutter app is restarted.
class RefqaCommunityData extends ChangeNotifier {
  RefqaCommunityData._();
  static final RefqaCommunityData instance = RefqaCommunityData._();
  static const assetRoot = 'assets/refqa_community/';

  final List<RefqaPost> posts = [
    RefqaPost(
      id: 'q-101',
      author: 'سالم الهاشمي',
      avatar: '${assetRoot}avatar_landmark.jpg',
      location: 'مكة المكرمة',
      time: 'منذ 3 ساعات',
      type: RefqaPostType.question,
      topic: RefqaTopic.haramain,
      body: 'هل توجد مواصلات مباشرة من الحرم إلى جبل النور؟ وما أفضل وقت للزيارة؟',
      image: '${assetRoot}jabal_al_noor.jpg',
      likes: 112,
      extraDemoCommentCount: 36,
      verified: true,
      comments: [
        RefqaComment(
          author: 'أم عبدالله',
          avatar: '${assetRoot}avatar_female.jpg',
          text: 'توجد خيارات من سيارات الأجرة والتطبيقات، والأفضل التأكد من الموقع والازدحام قبل الانطلاق.',
          likes: 28,
          trusted: true,
        ),
        RefqaComment(
          author: 'نورة',
          avatar: '${assetRoot}avatar_female.jpg',
          text: 'زرت المنطقة الأسبوع الماضي، وكان الجو ألطف في الصباح الباكر.',
          time: 'منذ ساعة',
          likes: 16,
        ),
      ],
    ),
    RefqaPost(
      id: 't-102',
      author: 'أم عبدالله',
      avatar: '${assetRoot}avatar_female.jpg',
      location: 'المدينة المنورة',
      time: 'منذ 5 ساعات',
      type: RefqaPostType.tip,
      topic: RefqaTopic.haramain,
      body: 'أنصح بالتخطيط لزيارة الروضة مسبقًا عبر التصاريح الرسمية، والوصول مبكرًا لتجنب الاستعجال والازدحام.',
      image: '${assetRoot}masjid_nabawi.jpg',
      likes: 96,
      extraDemoCommentCount: 24,
    ),
    RefqaPost(
      id: 'i-103',
      author: 'فريق رفقة',
      avatar: '${assetRoot}avatar_clock.jpg',
      location: 'مكة المكرمة',
      time: 'منذ يوم واحد',
      type: RefqaPostType.information,
      topic: RefqaTopic.umrah,
      body: 'تأكّد من مواعيد الزيارة والتصاريح الرسمية قبل التوجّه إلى المواقع التي تتطلب حجزًا.',
      image: '${assetRoot}rawdah.jpg',
      verified: true,
      likes: 210,
      extraDemoCommentCount: 62,
    ),
  ];

  final List<RefqaFriendRequest> requests = [
    RefqaFriendRequest(name: 'أحمد الكبري', city: 'الرياض', avatar: '${assetRoot}avatar_male.jpg'),
    RefqaFriendRequest(name: 'فاطمة الغامدي', city: 'جدة', avatar: '${assetRoot}avatar_female.jpg'),
    RefqaFriendRequest(name: 'محمد العتيبي', city: 'الدمام', avatar: '${assetRoot}avatar_male.jpg'),
  ];

  final Set<String> requestedFriends = {};
  final Set<String> confirmedFriends = {};
  final Set<String> blockedAuthors = {};
  final List<String> acceptedFriends = [];

  void toggleLike(RefqaPost post) {
    post.liked = !post.liked;
    post.likes += post.liked ? 1 : -1;
    notifyListeners();
  }

  void toggleSave(RefqaPost post) {
    post.saved = !post.saved;
    notifyListeners();
  }

  void addPost({
    required String text,
    required RefqaPostType type,
    required RefqaTopic topic,
    String location = 'مكة المكرمة',
    List<Uint8List> images = const [],
  }) {
    posts.insert(
      0,
      RefqaPost(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        author: 'أنتِ',
        avatar: '${assetRoot}avatar_female.jpg',
        location: location.isEmpty ? 'بدون موقع' : location,
        time: 'الآن',
        body: text,
        type: type,
        topic: topic,
        pending: true,
        imageBytes: images,
      ),
    );
    notifyListeners();
  }

  void addComment(RefqaPost post, String value) {
    final text = value.trim();
    if (text.isEmpty) return;
    post.comments.add(RefqaComment(
      author: 'أنتِ',
      text: text,
      avatar: '${assetRoot}avatar_female.jpg',
      time: 'الآن',
    ));
    notifyListeners();
  }

  void requestFriend(String author) {
    if (confirmedFriends.contains(author)) return;
    if (requestedFriends.contains(author)) {
      requestedFriends.remove(author);
    } else {
      requestedFriends.add(author);
    }
    notifyListeners();
  }

  void acceptRequest(RefqaFriendRequest request) {
    requests.remove(request);
    acceptedFriends.add(request.name);
    confirmedFriends.add(request.name);
    notifyListeners();
  }

  void rejectRequest(RefqaFriendRequest request) {
    requests.remove(request);
    notifyListeners();
  }

  void blockAuthor(String author) {
    blockedAuthors.add(author);
    notifyListeners();
  }

  void reportPost(RefqaPost post) {
    post.reported = true;
    notifyListeners();
  }
}
