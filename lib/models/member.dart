class Member {
  String name;
  String hashTag; // 원래 email 쓰고 있었는데 email 등록은 가입 시 선택사항이므로 해시태그를 사용하자
  String imageUrl;
  String role;
  bool isEditable;

  Member({
    required this.name,
    required this.hashTag,
    required this.imageUrl,
    required this.role,
    required this.isEditable,
  });
}