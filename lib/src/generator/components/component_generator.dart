import 'package:fantom/src/generator/components/component/generated_components.dart';
import 'package:fantom/src/generator/components/components_collection.dart';
import 'package:fantom/src/generator/parameter/parameter_class_generator.dart';
import 'package:fantom/src/generator/schema/schema_class_generator.dart';
import 'package:fantom/src/generator/utils/reference_finder.dart';
import 'package:fantom/src/mediator/mediator/schema/schema_mediator.dart';
import 'package:fantom/src/mediator/model/schema/schema_model.dart';
import 'package:fantom/src/reader/model/model.dart';

class ComponentsGenerator {
  ComponentsGenerator({
    required this.schemaMediator,
    required this.schemaClassGenerator,
    required this.parameterClassGenerator,
  });

  final SchemaMediator schemaMediator;

  final SchemaClassGenerator schemaClassGenerator;
  final ParameterClassGenerator parameterClassGenerator;

  factory ComponentsGenerator.createDefault(OpenApi openApi) {
    final schemaMediator = SchemaMediator();
    final schemaGenerator = SchemaClassGenerator();
    return ComponentsGenerator(
      schemaMediator: schemaMediator,
      schemaClassGenerator: schemaGenerator,
      parameterClassGenerator: ParameterClassGenerator(
        schemaGenerator: schemaGenerator,
        schemaMediator: schemaMediator,
      ),
    );
  }

  void generateAndRegisterComponents(OpenApi openApi) {
    List<Map<String, GeneratedComponent>> allGeneratedComponents = [];

    final schemaComponents = _generateSchemas(
      openApi,
      openApi.components!.schemas!,
    );

    final parameterComponents = _generateParameters(
      openApi,
      openApi.components!.parameters!,
    );

    allGeneratedComponents.addAll([
      schemaComponents,
      parameterComponents,
    ]);
    
    for (var map in allGeneratedComponents) {
      map.forEach((ref, component) {
        registerGeneratedComponent(ref, component);
      });
    }
  }

  Map<String, GeneratedComponent> _generateSchemas(
    OpenApi openApi,
    Map<String, Referenceable<Schema>> schemas,
  ) {
    return schemas.map((ref, schema) {
      var dataElement =
          schemaMediator.convert(openApi: openApi, schema: schema, name: ref);
      return MapEntry(ref, dataElement);
    }).map((ref, element) {
      late GeneratedComponent component;
      if (element is ObjectDataElement) {
        component = schemaClassGenerator.generate(element);
      } else {
        component = UnGeneratableSchemaComponent(dataElement: element);
      }
      return MapEntry(ref, component);
    });
  }

  Map<String, GeneratedParameterComponent> _generateParameters(
    OpenApi openApi,
    Map<String, Referenceable<Parameter>> parameters,
  ) {
    final referenceFinder = ReferenceFinder(openApi: openApi);
    return parameters.map(
      (key, value) {
        return MapEntry(
          key,
          parameterClassGenerator.generate(
            openApi,
            value.isValue
                ? value.value
                : referenceFinder.findParameter(value.reference),
          ),
        );
      },
    );
  }
}
