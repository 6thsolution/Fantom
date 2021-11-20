import 'dart:io';

import 'package:fantom/src/generator/components/component/generated_components.dart';
import 'package:fantom/src/generator/components/components_registrey.dart';
import 'package:fantom/src/generator/schema/schema_class_generator.dart';
import 'package:fantom/src/generator/schema/schema_from_json_generator.dart';
import 'package:fantom/src/generator/schema/schema_to_json_generator.dart';
import 'package:fantom/src/mediator/mediator/schema/schema_mediator.dart';
import 'package:fantom/src/mediator/model/schema/schema_model.dart';
import 'package:fantom/src/reader/model/model.dart';
import 'package:fantom/src/utils/logger.dart';
import 'package:recase/recase.dart';
import 'package:sealed_writer/sealed_writer.dart';

typedef Content = Map<String, MediaType>;

enum ContentOwner { response, requestBody, parameter, unknown }

/// is a ManifestGenerator that creates objects that can be used by ComponentGenerators to generate components
///
/// NOTE: an openapi content object in our sdk is represented by a Map<String, MediaType>
class ContentManifestCreator {
  ContentManifestCreator({
    required this.openApi,
    required this.schemaMediator,
    required this.schemaClassGenerator,
  });

  List<GeneratedSchemaComponent> _generatedComponents = [];
  Map<String, DataElement> _mapOfDataElements = {};
  Map<String, ManifestItem> _mapOfManifestItems = {};
  final OpenApi openApi;
  final SchemaMediator schemaMediator;
  final SchemaClassGenerator schemaClassGenerator;

  ContentManifest? generateContentType({
    required String typeName,
    required String subTypeName,
    required String generatedSchemaTypeName,
    required Content? content,
    ContentOwner contentOwner = ContentOwner.unknown,
  }) {
    // resseting processed data
    _generatedComponents = [];
    _mapOfDataElements = {};
    _mapOfManifestItems = {};

    // if content is null we cannot create any Type for it
    if (content == null) {
      return null;
    }

    // we need to replace */* with any in our content-types since it cannot be used in code generation
    final removed = content.remove('*/*');
    if (removed != null) {
      content['any'] = removed;
    }

    final className = ReCase(typeName).pascalCase;
    _mapOfManifestItems = content.map(
      (contentType, mediaType) {
        final subClassName =
            '${ReCase(subTypeName).pascalCase}${ReCase(_getContentTypeShortName(_fixName(contentType))).pascalCase}';
        final subClassShortName = _fixName(contentType);
        return MapEntry(
          contentType,
          ManifestItem(
            name: subClassName,
            shortName: subClassShortName,
            equality: ManifestEquality.identity,
            fields: [
              _createFieldFrom(
                mediaTypeName: contentType,
                mediaType: mediaType,
                generatedSchemaSeedName: generatedSchemaTypeName,
              ),
            ],
          ),
        );
      },
    );
    if (contentOwner == ContentOwner.requestBody) {
      final subClassName =
          '${ReCase(subTypeName).pascalCase}${ReCase(_getContentTypeShortName(_fixName('custom'))).pascalCase}';
      final subClassShortName = _fixName('custom');
      _mapOfManifestItems['custom'] = ManifestItem(
        name: subClassName,
        shortName: subClassShortName,
        equality: ManifestEquality.identity,
        fields: [
          ManifestField(
            name: 'dioBody',
            type: ManifestType(name: 'dynamic', isNullable: false),
          )
        ],
      );
    }
    final manifest = Manifest(
      name: className,
      items: _mapOfManifestItems.values.toList(),
      params: [],
      fields: [],
    );
    return ContentManifest(
      manifest: manifest,
      extensionMethods: createExtensions(
        className,
        _mapOfDataElements,
        contentOwner,
      ),
      generatedComponents: _generatedComponents,
    );
  }

  String createExtensions(
    String parentClassName,
    Map<String, DataElement> content,
    ContentOwner contentOwner,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('\n');
    buffer.writeln('extension ${parentClassName}Ext on $parentClassName{');
    // fromJson method for class Type that is generated by ContentManifestCreator
    for (var entry in content.entries) {
      var dataElement = entry.value;
      var contentType = entry.key;
      var manifestItem = _mapOfManifestItems[entry.key];
      if (contentType == 'application/json') {
        buffer.writeln('static $parentClassName fromJson(dynamic json) {');
        var manifestField = manifestItem!.fields[0];
        var manifestFieldName = manifestField.name;
        final schemaFromGen = SchemaFromJsonGenerator();
        final application = schemaFromGen.generateApplication(dataElement);
        buffer.writeln('final jsonDeserializer =  $application;');
        buffer.writeln(
          'return $parentClassName.${ReCase(manifestItem.shortName).camelCase}($manifestFieldName: jsonDeserializer(json));',
        );
        buffer.writeln('  }');
      }
    }

    // toJson method for class Type that is generated by ContentManifestCreator

    for (var entry in content.entries) {
      var dataElement = entry.value;
      var contentType = entry.key;
      if (contentType == 'application/json') {
        var returnType = 'dynamic';
        if (dataElement.isObjectDataElement) {
          returnType = 'Map<String,dynamic>';
        } else if (dataElement.isArrayDataElement) {
          returnType = 'List<Map<String,dynamic>>';
        } else {
          returnType = dataElement.type;
        }
        buffer.writeln('$returnType toJson() {');
        final schemaToGen = SchemaToJsonGenerator();
        final application = schemaToGen.generateApplication(dataElement);
        buffer.writeln('final jsonSerializer =  $application;');
        buffer.writeln('final object =  asApplicationJson.applicationJson;');
        buffer.writeln('return jsonSerializer(object);');
        buffer.writeln('  }');
      }
    }
    // fromXml method for class Type that is generated by ContentManifestCreator
    for (var entry in content.entries) {
      // ignore_for_file: unused_local_variable
      var dataElement = entry.value;
      var contentType = entry.key;
      var manifestItem = _mapOfManifestItems[entry.key];
      if (contentType == 'application/xml') {
        //TODO(alireza): implement fromXml later to return a type of $parentClassName
        buffer.writeln('static dynamic fromXml(String xml) {');
        buffer.writeln("return '';");
        buffer.writeln('  }');
      }
    }
    // toXml method for class Type that is generated by ContentManifestCreator
    for (var entry in content.entries) {
      var dataElement = entry.value;
      var contentType = entry.key;
      if (contentType == 'application/xml') {
        //TODO(alireza): implement toXml later to return a type of $parentClassName
        buffer.writeln('String toXml() {');
        buffer.writeln("return 'fake string xml data';");
        buffer.writeln('  }');
      }
    }
    // getContentType method for class Type that is generated by ContentManifestCreator
    buffer.writeln('String? get contentType {');
    for (var contentType in content.keys) {
      final checkerName =
          'is${ReCase(_fixName(contentType)).pascalCase}'; // like isApplicationJson, isApplicationXml
      buffer.writeln('if ($checkerName) {');
      buffer.writeln("return '$contentType' ;");
      buffer.writeln('}');
    }
    buffer.writeln('else {');

    buffer.writeln("return null ;");
    buffer.writeln('}');
    buffer.writeln('}');

    //generate fromContent method for class Type that is generated by ContentManifestCreator
    buffer.writeln(
        'static $parentClassName fromContentType(String? contentType, dynamic data){');
    for (var contentType in content.keys) {
      buffer.writeln("if (contentType == '$contentType') {");
      final methodName = ReCase(_fixName(contentType)).camelCase;
      final argName = methodName;
      final dataElement = content[contentType]!;
      final schemaFromGen = SchemaFromJsonGenerator();
      final application = schemaFromGen.generateApplication(dataElement);
      buffer.writeln('final jsonDeserializer =  $application;');
      buffer.writeln(
          "return $parentClassName.$methodName($argName: jsonDeserializer(data));");
      buffer.writeln('}');
    }
    buffer.writeln(
        "throw Exception('could not create a $parentClassName from contenttype = \$contentType & data =\\n\$data\\n');");
    buffer.writeln('}');
    // body getter method for class Type that is generated by ContentManifestCreator
    if (contentOwner == ContentOwner.requestBody) {
      buffer.writeln('dynamic toBody() {');
      for (var contentType in _mapOfManifestItems.keys) {
        final seed = ReCase(_fixName(contentType)).pascalCase;
        final isName = 'is$seed'; // like isApplicationJson
        final asName = 'as$seed'; // like asApplicationJson
        final manifestItem = _mapOfManifestItems[contentType]!;
        final valueName = manifestItem.fields[0].name;
        buffer.writeln('if ($isName) {');
        buffer.writeln("final value = $asName.$valueName;");
        if (contentType == 'application/json') {
          final dataElement = content[contentType]!;
          final schemaToJson = SchemaToJsonGenerator();
          schemaToJson.generateApplication(dataElement);
          final application = schemaToJson.generateApplication(dataElement);
          buffer.writeln('final jsonDeserializer =  $application;');
          buffer.writeln('return jsonDeserializer(value);');
        } else if (contentType == 'application/xml') {
          buffer.writeln('return value.toString();');
        } else if (contentType == 'multipart/form-data') {
          final dataElement = content[contentType]!;
          final schemaToJson = SchemaToJsonGenerator();
          schemaToJson.generateApplication(dataElement);
          final application = schemaToJson.generateApplication(dataElement);
          buffer.writeln('final jsonDeserializer =  $application;');
          buffer.writeln('final map = jsonDeserializer(value);');
          buffer.write('return FormData.fromMap(map);');
        } else if (contentType == 'text/plain') {
          //TODO(alireza): implement
          buffer.writeln('throw UnimplementedError();');
        } else if (contentType == 'custom') {
          buffer.writeln('return value;');
        }
        buffer.writeln('}');
      }
      buffer.writeln(
          "throw Exception('could not convert $parentClassName to an object that can be used as request-body by dio');");
      buffer.writeln('}');
    }

    // generate toUriParam method for the class Type that is generated by ContentManifestCreator
    if (contentOwner == ContentOwner.parameter) {
      final file = File('');
      buffer.write(
          'UriParam toUriParam(String name, String style, bool explode) {');
      for (var contentType in content.keys) {
        final seed = ReCase(_fixName(contentType)).pascalCase;
        final checkerName = 'is$seed'; // like isApplicationJson
        final asName = 'as$seed'; // like asApplicationJson
        final valueName = seed.camelCase;
        buffer.writeln('if ($checkerName) {');
        buffer.writeln("final value = $asName.$valueName;");
        final dataElement = content[contentType]!;
        if (contentType == 'application/json' ||
            contentType == 'application/xml') {
          final schemaToJson = SchemaToJsonGenerator();
          schemaToJson.generateApplication(dataElement);
          final application = schemaToJson.generateApplication(dataElement);
          buffer.writeln('final jsonDeserializer =  $application;');
          buffer.writeln('final paramValue = jsonDeserializer(value);');
          if (dataElement.isObjectDataElement) {
            buffer.writeln(
                'return UriParam.object(name, paramValue, style, explode);');
          } else if (dataElement.isArrayDataElement) {
            buffer.writeln(
                'return UriParam.array(name, paramValue, style, explode);');
          } else {
            buffer.writeln(
                'return UriParam.primitive(name, paramValue, style, explode);');
          }
        } else if (contentType == 'text/plain') {
          buffer.writeln('return UriParam.primitive(name, value, style);');
        }
        buffer.writeln('}');
      }
      buffer.writeln(
          "throw Exception('fantom cannot create a UriParam from type -> \$runtimeType');");
      buffer.writeln('}');
    }
    buffer.writeln('}');
    buffer.writeln('\n');

    return buffer.toString();
  }

  ManifestField _createFieldFrom({
    required String mediaTypeName,
    required MediaType mediaType,
    required String generatedSchemaSeedName,
  }) {
    final refOrSchema = mediaType.schema;
    String fieldName = ReCase(_fixName(mediaTypeName)).camelCase;
    late String typeName;
    late bool isNullable;
    if (refOrSchema == null) {
      fieldName = 'value';
      typeName = 'dynamic';
      isNullable = false;
    } else {
      late GeneratedSchemaComponent component;
      if (refOrSchema.isReference) {
        Log.debug(refOrSchema.reference.ref);
        component = getGeneratedComponentByRef(refOrSchema.reference.ref)
            as GeneratedSchemaComponent;
      } else {
        // our schema object first needs to be generated and registered
        component = _createSchemaClassFrom(
          refOrSchema,
          '${ReCase(generatedSchemaSeedName).pascalCase}${ReCase(_getContentTypeShortName(_fixName(mediaTypeName))).pascalCase}'
              .pascalCase,
        );
        _generatedComponents.add(component);
      }
      _mapOfDataElements[mediaTypeName] = component.dataElement;

      typeName = component.dataElement.type;
      isNullable = component.dataElement.isNullable;
    }

    return ManifestField(
      name: fieldName,
      type: ManifestType(
        name: typeName,
        isNullable: isNullable,
      ),
    );
  }

  GeneratedSchemaComponent _createSchemaClassFrom(
    Referenceable<Schema> schema,
    String name,
  ) {
    var dataElement = schemaMediator.convert(
      openApi: openApi,
      schema: schema,
      name: name,
    );
    if (dataElement.isGeneratable) {
      return schemaClassGenerator.generate(dataElement.asObjectDataElement);
    } else {
      return UnGeneratableSchemaComponent(dataElement: dataElement);
    }
  }

  String _getContentTypeShortName(String contentType) {
    var name = contentType;
    if (contentType == 'application/json') {
      name = 'Json';
    } else if (contentType == 'application/xml') {
      name = 'Xml';
    } else if (contentType == 'multipart/form-data') {
      name = 'Multipart';
    } else if (contentType == 'text/plain') {
      name = 'TextPlain';
    } else if (contentType == 'application/x-www-form-urlencoded') {
      name = 'FormData';
    } else if (contentType == 'any') {
      name = 'Any';
    } else if (contentType.startsWith('image/')) {
      name = 'Image';
    }
    return name;
  }

  String _fixName(String value) => ReCase(value).camelCase.replaceAll('*', '');
}

/// holds the data that can be used by ComponentGenerators to generate components
class ContentManifest {
  ContentManifest({
    required this.manifest,
    required this.extensionMethods,
    required this.generatedComponents,
  });

  final Manifest manifest;
  final String extensionMethods;
  final List<GeneratedComponent> generatedComponents;
}
