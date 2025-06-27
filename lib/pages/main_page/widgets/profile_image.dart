import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

Widget _buildProfileImage(String? photoUrl) {
  if (photoUrl != null && photoUrl.isNotEmpty) {
    return CircleAvatar(
      radius: 16,
      backgroundImage: NetworkImage(photoUrl),
      backgroundColor: Colors.grey[200],
    );
  } else {
    return SvgPicture.asset(
      'assets/icons/ProfileImage3.svg',
      width: 32,
      height: 32,
    );
  }
}
