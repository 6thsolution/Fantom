part of 'model.dart';

class Response {
  final Map<String, Header> headers;

  final Map<MimeType, Content> content;

  const Response({
    required this.headers,
    required this.content,
  });
}
