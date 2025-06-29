// 역할 정보를 위한 Enum 클래스
enum Role {
  owner('owner'),
  editor('editor'),
  guest('guest');

  final String value;
  const Role(this.value);
}