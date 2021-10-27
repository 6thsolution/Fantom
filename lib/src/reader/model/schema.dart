part of 'model.dart';

class Schema extends Equatable {
  final bool? nullable;

  final String? type;

  final String? format;

  /// described as [default] in openapi documentation
  /// but [default] is a keyword in Dart.
  final Optional<Object?>? defaultValue;

  final bool? deprecated;

  /// described as [required] in openapi documentation
  /// but [required] is a keyword in Dart.
  final List<String>? requiredItems;

  /// described as [enum] in documentation.
  /// but [enum], is a keyword in Dart.
  final List<Object?>? enumerated;

  final Referenceable<Schema>? items;

  final Map<String, Referenceable<Schema>>? properties;

  final bool? uniqueItems;

  final Boolable<Referenceable<Schema>>? additionalProperties;

  const Schema({
    required this.nullable,
    required this.type,
    required this.format,
    required this.defaultValue,
    required this.deprecated,
    required this.requiredItems,
    required this.enumerated,
    required this.items,
    required this.properties,
    required this.uniqueItems,
    required this.additionalProperties,
  });

  /// empty schema
  factory Schema.empty() => Schema.fromMap(const {});

  factory Schema.fromMap(Map<String, dynamic> map) => Schema(
        nullable: map['nullable'],
        type: map['type'],
        format: map['format'],
        defaultValue:
            map.containsKey('default') ? Optional(map['default']) : null,
        deprecated: map['deprecated'],
        requiredItems: (map['required'] as List<dynamic>?)?.cast<String>(),
        enumerated: (map['enum'] as List<dynamic>?)?.cast<Object?>(),
        items: map['items'] == null
            ? null
            : Referenceable.fromMap(
                map['items'],
                builder: (e) => Schema.fromMap(e),
              ),
        properties: (map['properties'] as Map<String, dynamic>?)?.mapValues(
          (e) => Referenceable.fromMap(
            e,
            builder: (f) => Schema.fromMap(f),
          ),
        ),
        uniqueItems: map['uniqueItems'],
        additionalProperties: map['additionalProperties'] == null
            ? null
            : Boolable.fromMap(
                map['additionalProperties'],
                builder: (e) => Referenceable.fromMap(
                  e,
                  builder: (f) => Schema.fromMap(f),
                ),
              ),
      );

  @override
  List<Object?> get props => [
        nullable,
        type,
        format,
        defaultValue,
        deprecated,
        requiredItems,
        enumerated,
        items,
        properties,
        uniqueItems,
      ];
}