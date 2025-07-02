import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nota_note/viewmodels/memo_active_users_viewmodel.dart';

class ActiveUsersWidget extends ConsumerWidget {
  final String groupId;
  final String noteId;

  const ActiveUsersWidget({
    super.key,
    required this.groupId,
    required this.noteId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeUserIds = ref.watch(memoActiveUsersViewModelProvider({
      'groupId': groupId,
      'noteId': noteId,
    }));
    final firestore = FirebaseFirestore.instance;

    return Row(
      children: [
        if (activeUserIds.isNotEmpty)
          Row(
            children: activeUserIds.take(2).map((userId) {
              return Padding(
                padding: const EdgeInsets.only(right: -10.0),
                child: FutureBuilder<DocumentSnapshot>(
                  future: firestore.collection('users').doc(userId).get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      print('Loading photoUrl for userId: $userId');
                      return const CircleAvatar(
                        radius: 12,
                        backgroundColor: Color(0xFF61CFB2),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      print('Error fetching photoUrl for userId: $userId - ${snapshot.error}');
                      return const CircleAvatar(
                        radius: 12,
                        backgroundColor: Color(0xFF61CFB2),
                        child: Icon(
                          Icons.person,
                          size: 16,
                          color: Colors.white,
                        ),
                      );
                    }
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      print('No user data found for userId: $userId');
                      return const CircleAvatar(
                        radius: 12,
                        backgroundColor: Color(0xFF61CFB2),
                        child: Icon(
                          Icons.person,
                          size: 16,
                          color: Colors.white,
                        ),
                      );
                    }
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    final photoUrl = data['photoUrl'] as String?;
                    print('Fetched photoUrl for userId: $userId - $photoUrl');
                    return CircleAvatar(
                      radius: 12,
                      backgroundColor: const Color(0xFF61CFB2),
                      backgroundImage: photoUrl != null
                          ? CachedNetworkImageProvider(
                        photoUrl,
                      )
                          : null,
                      child: photoUrl == null
                          ? const Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.white,
                      )
                          : null,
                    );
                  },
                ),
              );
            }).toList(),
          ),
        if (activeUserIds.length > 2)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              '+${activeUserIds.length - 2}',
              style: const TextStyle(
                color: Color(0xFF7F7F7F),
                fontSize: 12,
                fontFamily: 'Pretendard',
                height: 1.2,
              ),
            ),
          ),
      ],
    );
  }
}