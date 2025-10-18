// Định nghĩa ngoại lệ riêng
class MyCustomException implements Exception {
  final String message;

  MyCustomException(this.message);

  @override
  String toString() => "Lỗi : $message";
}
