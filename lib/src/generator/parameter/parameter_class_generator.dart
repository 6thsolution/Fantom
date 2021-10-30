import 'package:fantom/src/generator/components/component/generated_components.dart';
import 'package:fantom/src/generator/components/components_collection.dart';
import 'package:fantom/src/generator/schema/schema_class_generator.dart';
import 'package:fantom/src/mediator/mediator/schema/schema_mediator.dart';
import 'package:fantom/src/mediator/model/schema/schema_model.dart';
import 'package:fantom/src/reader/model/model.dart';

class ParameterClassGenerator {
  const ParameterClassGenerator({
    required this.schemaGenerator,
    required this.schemaMediator,
  });

  final SchemaClassGenerator schemaGenerator;
  final SchemaMediator schemaMediator;

  GeneratedParameterComponent generate(
    final OpenApi openApi,
    final Parameter parameter,
  ) {
    if (parameter.schema != null && parameter.content != null) {
      throw StateError('Parameter can not have both schema and content');
    } else if (parameter.content != null) {
      //TODO: complete this section
      throw UnimplementedError('parameter with Content value is not supported');
    } else {
      //TODO: find a way to name the generated class
      final name = parameter.name;

      final schema = parameter.schema!;
      final DataElement element = _findSchemaElement(
        openApi,
        schema,
        name,
      );

      if (element is ObjectDataElement) {
        final generatedSchema = schemaGenerator.generate(
          element,
          orName: name,
        );
        return GeneratedParameterComponent(
          source: parameter,
          schemaComponent: generatedSchema,
          fileContent: generatedSchema.fileContent,
          fileName: generatedSchema.fileName,
        );
      } else {
        return GeneratedParameterComponent(
          source: parameter,
          schemaComponent: UnGeneratableSchemaComponent(dataElement: element),
          fileContent: '',
          fileName: '',
        );
      }
    }
  }

  DataElement _findSchemaElement(
    OpenApi openApi,
    Referenceable<Schema> schema,
    String name,
  ) {
    if (schema.isReference) {
      final generatedComponent = getGeneratedComponentByRef(
        schema.reference.ref,
      );

      if (generatedComponent is GeneratedSchemaComponent) {
        return generatedComponent.dataElement;
      } else if (generatedComponent == null) {
        return schemaMediator.convert(
          openApi: openApi,
          schema: schema,
          name: name,
        );
      } else {
        throw StateError('Unexpected generated component type');
      }
    }

    return schemaMediator.convert(
      openApi: openApi,
      schema: schema,
      name: name,
    );
  }
}