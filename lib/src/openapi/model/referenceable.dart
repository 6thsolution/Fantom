part of 'model.dart';

class Referenceable<T extends Object> {
  /// should not be a collection.
  final T? _value;

  final Reference<T>? _reference;

  const Referenceable.value(T value)
      : _value = value,
        _reference = null;

  const Referenceable.reference(Reference<T> reference)
      : _value = null,
        _reference = reference;

  bool get isValue => _value != null;

  T get value => _value!;

  T? get valueOrNull => _value;

  bool get isReference => _reference != null;

  Reference<T> get reference => _reference!;

  Reference<T>? get referenceOrNull => _reference;

  R match<R extends Object?>({
    required R Function(T value) value,
    required R Function(Reference<T> reference) reference,
  }) =>
      _value != null ? value(_value!) : reference(_reference!);

  factory Referenceable.fromMap(
    Map<String, dynamic> map, {
    required T Function(Map<String, dynamic> map) builder,
  }) =>
      Reference.isReferenceMap(map)
          ? Referenceable<T>.reference(Reference<T>.fromMap(map))
          : Referenceable<T>.value(builder(map));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Referenceable<T> &&
          runtimeType == other.runtimeType &&
          _value == other._value &&
          _reference == other._reference;

  @override
  int get hashCode =>
      runtimeType.hashCode ^ _value.hashCode ^ _reference.hashCode;
}