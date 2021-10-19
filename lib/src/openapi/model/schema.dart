part of 'model.dart';

/// supports `3.1` and partially `>=3.0 <3.1`.
class Schema {
  /// this is only available on versions `>=3.0 <3.1`.
  final bool? nullable;

  /// on versions `>=3.0 <3.1` if this is not null then other fields are null.
  final Reference<Schema>? reference;

  /// on versions `>=3.0 <3.1` this can be null or single value.
  final Listable<String>? type;

  final String? format;

  /// described as [default] in openapi documentation
  /// but [default] is a keyword in Dart.
  final Object? defaultValue;

  final bool? deprecated;

  /// described as [required] in openapi documentation
  /// but [required] is a keyword in Dart.
  final List<String>? requiredItems;

  /// described as [enum] in documentation.
  /// but [enum], is a keyword in Dart.
  final List<Object?>? enumerated;

  final Schema? items;

  final Map<String, Schema>? properties;

  final bool? uniqueItems;

  const Schema({
    required this.nullable,
    required this.reference,
    required this.type,
    required this.format,
    required this.defaultValue,
    required this.deprecated,
    required this.requiredItems,
    required this.enumerated,
    required this.items,
    required this.properties,
    required this.uniqueItems,
  });

  factory Schema.fromMap(Map<String, dynamic> map) => Schema(
        nullable: map['nullable'],
        reference:
            Reference.isReferenceMap(map) ? Reference.fromMap(map) : null,
        type: map['type'] == null ? null : Listable.fromMap(map['type']),
        format: map['format'],
        defaultValue: map['default'],
        deprecated: map['deprecated'],
        requiredItems: (map['required'] as List<dynamic>?)?.cast<String>(),
        enumerated: (map['enum'] as List<dynamic>?)?.cast<Object?>(),
        items: map['items'] == null ? null : Schema.fromMap(map['items']),
        properties: (map['properties'] as Map<String, dynamic>?)?.mapValues(
          (e) => Schema.fromMap(e),
        ),
        uniqueItems: map['uniqueItems'],
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Schema &&
          runtimeType == other.runtimeType &&
          nullable == other.nullable &&
          reference == other.reference &&
          type == other.type &&
          format == other.format &&
          itemEquals(defaultValue, other.defaultValue) &&
          deprecated == other.deprecated &&
          listEquals(requiredItems, other.requiredItems) &&
          listEquals(enumerated, other.enumerated) &&
          items == other.items &&
          mapEquals(properties, other.properties) &&
          uniqueItems == other.uniqueItems;

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      nullable.hashCode ^
      reference.hashCode ^
      type.hashCode ^
      format.hashCode ^
      itemHash(defaultValue) ^
      deprecated.hashCode ^
      requiredItems.hashCode ^
      enumerated.hashCode ^
      items.hashCode ^
      mapHash(properties) ^
      uniqueItems.hashCode;
}
