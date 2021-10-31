import 'package:equatable/equatable.dart';

/// holder for default value
class DefaultValue with EquatableMixin {
  /// default value
  final Object? value;

  const DefaultValue({
    required this.value,
  });

  @override
  List<Object?> get props => [
        value,
      ];

  @override
  String toString() => 'DefaultValue{value: $value}';
}

/// information for an enum or constant value
class EnumerationInfo with EquatableMixin {
  /// values of enum
  ///
  /// ex. ['hello', 'hi', null]
  final List<Object?> values;

  const EnumerationInfo({
    required this.values,
  });

  @override
  List<Object?> get props => [
        values,
      ];

  @override
  String toString() => 'EnumerationInfo{values: $values}';
}

/// base data element:
///
/// - [BooleanDataElement]
/// - [ObjectDataElement]
/// - [ArrayDataElement]
/// - [NumberDataElement]
/// - [IntegerDataElement]
/// - [StringDataElement]
/// - [UntypedDataElement]
abstract class DataElement {
  const DataElement();

  /// if is present is used for code generated model name,
  /// and is referenced in schema map.
  String? get name;

  /// if is nullable
  ///
  /// note for schema:
  /// A true value adds "null" to the allowed type specified by the type
  /// keyword, only if type is explicitly defined within the same Schema Object.
  /// Other Schema Object constraints retain their defined behavior,
  /// and therefore may disallow the use of null as a value.
  /// A false value leaves the specified or default type unmodified.
  /// The default value is false.
  bool get isNullable;

  /// if is deprecated
  bool get isDeprecated;

  /// default value if present
  DefaultValue? get defaultValue;

  /// if present provides enumeration information,
  /// if not present means no enumeration.
  EnumerationInfo? get enumeration;

  /// type with nullability sign
  ///
  /// ex. String, String?,
  /// List<String>, List<String?>, List<String?>?,
  /// User, User?,
  ///
  /// it can be null if we have an unnamed object
  String? get type;

  /// [BooleanDataElement]
  const factory DataElement.boolean({
    required String? name,
    required bool isNullable,
    required bool isDeprecated,
    required DefaultValue? defaultValue,
    required EnumerationInfo? enumeration,
  }) = BooleanDataElement;

  /// [ObjectDataElement]
  const factory DataElement.object({
    required String? name,
    required bool isNullable,
    required bool isDeprecated,
    required DefaultValue? defaultValue,
    required EnumerationInfo? enumeration,
    required List<ObjectProperty> properties,
    required DataElement? additionalProperties,
  }) = ObjectDataElement;

  /// [ArrayDataElement]
  const factory DataElement.array({
    required String? name,
    required bool isNullable,
    required bool isDeprecated,
    required DefaultValue? defaultValue,
    required EnumerationInfo? enumeration,
    required DataElement items,
    required bool isUniqueItems,
  }) = ArrayDataElement;

  /// [IntegerDataElement]
  const factory DataElement.integer({
    required String? name,
    required bool isNullable,
    required bool isDeprecated,
    required DefaultValue? defaultValue,
    required EnumerationInfo? enumeration,
  }) = IntegerDataElement;

  /// [NumberDataElement]
  const factory DataElement.number({
    required String? name,
    required bool isNullable,
    required bool isDeprecated,
    required DefaultValue? defaultValue,
    required EnumerationInfo? enumeration,
    required bool isFloat,
  }) = NumberDataElement;

  /// [StringDataElement]
  const factory DataElement.string({
    required String? name,
    required bool isNullable,
    required bool isDeprecated,
    required DefaultValue? defaultValue,
    required EnumerationInfo? enumeration,
    required StringDataElementFormat format,
  }) = StringDataElement;

  /// [UntypedDataElement]
  const factory DataElement.untyped({
    required String? name,
    required bool isDeprecated,
    required DefaultValue? defaultValue,
    required EnumerationInfo? enumeration,
  }) = UntypedDataElement;
}

/// bool
class BooleanDataElement with EquatableMixin implements DataElement {
  @override
  final String? name;

  @override
  final bool isNullable;

  @override
  final bool isDeprecated;

  @override
  final DefaultValue? defaultValue;

  @override
  final EnumerationInfo? enumeration;

  const BooleanDataElement({
    required this.name,
    required this.isNullable,
    required this.isDeprecated,
    required this.defaultValue,
    required this.enumeration,
  });

  @override
  String get type {
    return 'bool'.withNullability(isNullable);
  }

  @override
  List<Object?> get props => [
        name,
        isNullable,
        isDeprecated,
        defaultValue,
        enumeration,
      ];

  @override
  String toString() => 'BooleanDataElement{name: $name, '
      'isNullable: $isNullable, isDeprecated: $isDeprecated, '
      'defaultValue: $defaultValue, enumeration: $enumeration}';
}

/// dart object property.
///
/// ex. required String? id;
class ObjectProperty with EquatableMixin {
  /// property name
  final String name;

  /// element type
  final DataElement item;

  /// if property is required
  final bool isRequired;

  const ObjectProperty({
    required this.name,
    required this.item,
    required this.isRequired,
  });

  /// is not required
  bool get isNotRequired => !isRequired;

  @override
  List<Object?> get props => [
        name,
        item,
        isRequired,
      ];

  @override
  String toString() => 'ObjectProperty{name: $name, item: $item, '
      'isRequired: $isRequired}';
}

/// format of [ObjectDataElement].
enum ObjectDataElementFormat {
  /// dart object, like User.
  ///
  /// can or can not accept additional fields.
  /// should check [ObjectDataElement.isAdditionalPropertiesAllowed].
  ///
  /// properties can be empty.
  /// should check [ObjectDataElement.properties].
  object,

  /// Map<String, *>.
  ///
  /// must accept additional fields.
  /// [ObjectDataElement.isAdditionalPropertiesAllowed] is true.
  map,

  /// dart object which can have additional fields
  /// like a map.
  ///
  /// must accept additional fields.
  /// [ObjectDataElement.isAdditionalPropertiesAllowed] is true.
  mixed,
}

/// dart-object or Map<String, *>.
///
/// ex. User, Person?.
/// ex. Map<String, User>, Map<String, String>?.
///
/// note for schema:
/// additionalProperties:
/// Value can be boolean or object.
/// Consistent with JSON Schema, additionalProperties defaults to true.
///
/// note for json schema:
/// properties:
/// The value of "properties" MUST be an object.
/// Each value of this object MUST be a valid JSON Schema.
/// Omitting this keyword has the same assertion behavior as an empty object.
/// additionalProperties:
/// The value of "additionalProperties" MUST be a valid JSON Schema.
/// Validation with "additionalProperties" applies only to the child values
/// of instance names that do not appear in the annotation results of
/// either "properties" or "patternProperties".
/// Omitting this keyword has the same assertion behavior as an empty schema.
///
/// so for additional properties:
/// if null then equivalent to true.
/// if false then no additional is allowed.
/// if true then equivalent to empty schema.
/// if schema then should be parsed.
class ObjectDataElement with EquatableMixin implements DataElement {
  /// objects can not be name-less
  @override
  final String? name;

  @override
  final bool isNullable;

  @override
  final bool isDeprecated;

  @override
  final DefaultValue? defaultValue;

  @override
  final EnumerationInfo? enumeration;

  /// properties
  final List<ObjectProperty> properties;

  /// additionalProperties
  ///
  /// if is null then means that additional properties is note allowed.
  final DataElement? additionalProperties;

  const ObjectDataElement({
    required this.name,
    required this.isNullable,
    required this.isDeprecated,
    required this.defaultValue,
    required this.enumeration,
    required this.properties,
    required this.additionalProperties,
  });

  /// if is additional properties allowed.
  bool get isAdditionalPropertiesAllowed => additionalProperties != null;

  /// format.
  ///
  /// see: [ObjectDataElementFormat].
  ObjectDataElementFormat get format {
    // is null or untyped:
    if (additionalProperties is UntypedDataElement?) {
      return ObjectDataElementFormat.object;
    } else {
      if (properties.isEmpty) {
        return ObjectDataElementFormat.map;
      } else {
        return ObjectDataElementFormat.mixed;
      }
    }
  }

  @override
  String? get type {
    if ((additionalProperties is UntypedDataElement?) ||
        (properties.isNotEmpty)) {
      // object and mixed:
      final name = this.name;
      if (name == null) {
        return null;
      } else {
        return name.withNullability(isNullable);
      }
    } else {
      // map:
      final sub = additionalProperties!.type;
      if (sub == null) {
        return null;
      } else {
        return 'Map<String, $sub>'.withNullability(isNullable);
      }
    }
  }

  /// the type of map used,
  /// this is more general than [type].
  String? get mapType {
    if (additionalProperties == null) {
      return null;
    } else {
      final sub = additionalProperties!.type;
      if (sub == null) {
        return null;
      } else {
        return 'Map<String, $sub>'.withNullability(isNullable);
      }
    }
  }

  @override
  List<Object?> get props => [
        name,
        isNullable,
        isDeprecated,
        defaultValue,
        enumeration,
        properties,
        additionalProperties,
      ];

  @override
  String toString() => 'ObjectDataElement{name: $name, '
      'isNullable: $isNullable, isDeprecated: $isDeprecated, '
      'defaultValue: $defaultValue, enumeration: $enumeration, '
      'properties: $properties, '
      'additionalProperties: $additionalProperties}';
}

/// List<*> or Set<*>
///
/// note for schema: items MUST be present if the type is array.
class ArrayDataElement with EquatableMixin implements DataElement {
  @override
  final String? name;

  @override
  final bool isNullable;

  @override
  final bool isDeprecated;

  @override
  final DefaultValue? defaultValue;

  @override
  final EnumerationInfo? enumeration;

  /// element type
  final DataElement items;

  /// if is list or set ?
  final bool isUniqueItems;

  const ArrayDataElement({
    required this.name,
    required this.isNullable,
    required this.isDeprecated,
    required this.defaultValue,
    required this.enumeration,
    required this.items,
    required this.isUniqueItems,
  });

  @override
  String? get type {
    final sub = items.type;
    if (sub == null) {
      return null;
    } else {
      final base = isUniqueItems ? 'Set' : 'List';
      return '$base<$sub>'.withNullability(isNullable);
    }
  }

  @override
  List<Object?> get props => [
        name,
        isNullable,
        isDeprecated,
        defaultValue,
        enumeration,
        items,
        isUniqueItems,
      ];

  @override
  String toString() => 'ArrayDataElement{name: $name, '
      'isNullable: $isNullable, isDeprecated: $isDeprecated, '
      'defaultValue: $defaultValue, enumeration: $enumeration, '
      'items: $items, isUniqueItems: $isUniqueItems}';
}

/// int.
class IntegerDataElement with EquatableMixin implements DataElement {
  @override
  final String? name;

  @override
  final bool isNullable;

  @override
  final bool isDeprecated;

  @override
  final DefaultValue? defaultValue;

  @override
  final EnumerationInfo? enumeration;

  const IntegerDataElement({
    required this.name,
    required this.isNullable,
    required this.isDeprecated,
    required this.defaultValue,
    required this.enumeration,
  });

  @override
  String get type {
    return 'int'.withNullability(isNullable);
  }

  @override
  List<Object?> get props => [
        name,
        isNullable,
        isDeprecated,
        defaultValue,
        enumeration,
      ];

  @override
  String toString() => 'NumberDataElement{name: $name, '
      'isNullable: $isNullable, isDeprecated: $isDeprecated, '
      'defaultValue: $defaultValue, enumeration: $enumeration}';
}

/// num, double.
class NumberDataElement with EquatableMixin implements DataElement {
  @override
  final String? name;

  @override
  final bool isNullable;

  @override
  final bool isDeprecated;

  @override
  final DefaultValue? defaultValue;

  @override
  final EnumerationInfo? enumeration;

  /// is double or num ?
  final bool isFloat;

  const NumberDataElement({
    required this.name,
    required this.isNullable,
    required this.isDeprecated,
    required this.defaultValue,
    required this.enumeration,
    required this.isFloat,
  });

  @override
  String get type {
    final base = isFloat ? 'double' : 'num';
    return base.withNullability(isNullable);
  }

  @override
  List<Object?> get props => [
        name,
        isNullable,
        isDeprecated,
        defaultValue,
        enumeration,
        isFloat,
      ];

  @override
  String toString() => 'NumberDataElement{name: $name, '
      'isNullable: $isNullable, isDeprecated: $isDeprecated, '
      'defaultValue: $defaultValue, enumeration: $enumeration, '
      'format: $isFloat}';
}

/// format of [StringDataElement].
enum StringDataElementFormat {
  /// string
  plain,

  /// base 64
  byte,

  /// binary stream or list
  binary,

  /// date
  date,

  /// date-time
  dateTime,
}

/// String.
class StringDataElement with EquatableMixin implements DataElement {
  @override
  final String? name;

  @override
  final bool isNullable;

  @override
  final bool isDeprecated;

  @override
  final DefaultValue? defaultValue;

  @override
  final EnumerationInfo? enumeration;

  /// format.
  ///
  /// see: [StringDataElementFormat].
  final StringDataElementFormat format;

  const StringDataElement({
    required this.name,
    required this.isNullable,
    required this.isDeprecated,
    required this.defaultValue,
    required this.enumeration,
    required this.format,
  });

  @override
  String get type {
    final String base;
    if (format == StringDataElementFormat.binary) {
      base = 'Stream<int>';
    } else {
      base = 'String';
    }
    return base.withNullability(isNullable);
  }

  @override
  List<Object?> get props => [
        name,
        isNullable,
        isDeprecated,
        defaultValue,
        enumeration,
        format,
      ];

  @override
  String toString() => 'StringDataElement{name: $name, '
      'isNullable: $isNullable, isDeprecated: $isDeprecated, '
      'defaultValue: $defaultValue, enumeration: $enumeration, '
      'format: $format}';
}

/// dynamic
///
/// NOTE: type will be `null` not `'dynamic'`.
class UntypedDataElement with EquatableMixin implements DataElement {
  @override
  final String? name;

  @override
  final bool isNullable = true;

  @override
  final bool isDeprecated;

  @override
  final DefaultValue? defaultValue;

  @override
  final EnumerationInfo? enumeration;

  const UntypedDataElement({
    required this.name,
    required this.isDeprecated,
    required this.defaultValue,
    required this.enumeration,
  });

  @override
  String? get type {
    return null;
  }

  @override
  List<Object?> get props => [
        name,
        isNullable,
        isDeprecated,
        defaultValue,
        enumeration,
      ];

  @override
  String toString() => 'UntypedDataElement{name: $name, '
      'isNullable: $isNullable, isDeprecated: $isDeprecated, '
      'defaultValue: $defaultValue, enumeration: $enumeration}';
}

/// matching data elements
extension DataElementMatchingExt on DataElement {
  R match<R extends Object?>({
    required R Function(BooleanDataElement boolean) boolean,
    required R Function(ObjectDataElement object) object,
    required R Function(ArrayDataElement array) array,
    required R Function(IntegerDataElement integer) integer,
    required R Function(NumberDataElement number) number,
    required R Function(StringDataElement string) string,
    required R Function(UntypedDataElement untyped) untyped,
  }) {
    final element = this;
    if (element is BooleanDataElement) {
      return boolean(element);
    } else if (element is ObjectDataElement) {
      return object(element);
    } else if (element is ArrayDataElement) {
      return array(element);
    } else if (element is IntegerDataElement) {
      return integer(element);
    } else if (element is NumberDataElement) {
      return number(element);
    } else if (element is StringDataElement) {
      return string(element);
    } else if (element is UntypedDataElement) {
      return untyped(element);
    } else {
      throw AssertionError();
    }
  }

  R matchOrElse<R extends Object?>({
    R Function(BooleanDataElement boolean)? boolean,
    R Function(ObjectDataElement object)? object,
    R Function(ArrayDataElement array)? array,
    R Function(IntegerDataElement integer)? integer,
    R Function(NumberDataElement number)? number,
    R Function(StringDataElement string)? string,
    R Function(UntypedDataElement untyped)? untyped,
    required R Function(DataElement element) orElse,
  }) {
    final element = this;
    if (element is BooleanDataElement) {
      return boolean != null ? boolean(element) : orElse(element);
    } else if (element is ObjectDataElement) {
      return object != null ? object(element) : orElse(element);
    } else if (element is ArrayDataElement) {
      return array != null ? array(element) : orElse(element);
    } else if (element is IntegerDataElement) {
      return integer != null ? integer(element) : orElse(element);
    } else if (element is NumberDataElement) {
      return number != null ? number(element) : orElse(element);
    } else if (element is StringDataElement) {
      return string != null ? string(element) : orElse(element);
    } else if (element is UntypedDataElement) {
      return untyped != null ? untyped(element) : orElse(element);
    } else {
      throw AssertionError();
    }
  }
}

/// casting data elements
extension DataElementCastingExt on DataElement {
  bool get isBooleanDataElement => this is BooleanDataElement;

  bool get isObjectDataElement => this is ObjectDataElement;

  bool get isArrayDataElement => this is ArrayDataElement;

  bool get isNumberDataElement => this is NumberDataElement;

  bool get isStringDataElement => this is StringDataElement;

  bool get isUntypedDataElement => this is UntypedDataElement;

  BooleanDataElement get asBooleanDataElement => this as BooleanDataElement;

  ObjectDataElement get asObjectDataElement => this as ObjectDataElement;

  ArrayDataElement get asArrayDataElement => this as ArrayDataElement;

  NumberDataElement get asNumberDataElement => this as NumberDataElement;

  StringDataElement get asStringDataElement => this as StringDataElement;

  UntypedDataElement get asUntypedDataElement => this as UntypedDataElement;
}

/// internal utilities for strings
extension _StringExt on String {
  /// add nullability if needed.
  String withNullability(bool isNullable) => isNullable ? '$this?' : this;
}
