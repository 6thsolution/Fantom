part of 'model.dart';

class PathItem {
  final Operation? get;

  final Operation? put;

  final Operation? post;

  final Operation? delete;

  final Operation? options;

  final Operation? head;

  final Operation? patch;

  final Operation? trace;

  final List<Referenceable<Parameter>>? parameters;

  const PathItem({
    required this.get,
    required this.put,
    required this.post,
    required this.delete,
    required this.options,
    required this.head,
    required this.patch,
    required this.trace,
    required this.parameters,
  });

  factory PathItem.fromMap(Map<String, dynamic> map) => PathItem(
        get: map['get'] == null ? null : Operation.fromMap(map['get']),
        put: map['put'] == null ? null : Operation.fromMap(map['put']),
        post: map['post'] == null ? null : Operation.fromMap(map['post']),
        delete: map['delete'] == null ? null : Operation.fromMap(map['delete']),
        options:
            map['options'] == null ? null : Operation.fromMap(map['options']),
        head: map['head'] == null ? null : Operation.fromMap(map['head']),
        patch: map['patch'] == null ? null : Operation.fromMap(map['patch']),
        trace: map['trace'] == null ? null : Operation.fromMap(map['trace']),
        parameters: (map['parameters'] as List<dynamic>?)?.mapToList(
          (e) => Referenceable.fromMap(
            e,
            builder: (m) => Parameter.fromMap(m),
          ),
        ),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PathItem &&
          runtimeType == other.runtimeType &&
          get == other.get &&
          put == other.put &&
          post == other.post &&
          delete == other.delete &&
          options == other.options &&
          head == other.head &&
          patch == other.patch &&
          trace == other.trace &&
          listEquals(parameters, other.parameters);

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      get.hashCode ^
      put.hashCode ^
      post.hashCode ^
      delete.hashCode ^
      options.hashCode ^
      head.hashCode ^
      patch.hashCode ^
      trace.hashCode ^
      listHash(parameters);
}
