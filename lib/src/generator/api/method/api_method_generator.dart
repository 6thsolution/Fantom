import 'package:fantom/src/generator/api/method/body_parser.dart';
import 'package:fantom/src/generator/api/method/params_parser.dart';
import 'package:fantom/src/generator/api/method/response_parser.dart';
import 'package:fantom/src/generator/components/component/generated_components.dart';
import 'package:fantom/src/generator/name/utils.dart';
import 'package:fantom/src/generator/name/name_generator.dart';
import 'package:fantom/src/reader/model/model.dart';
import 'package:recase/recase.dart';

// ignore_for_file: unused_element
// ignore_for_file: unused_local_variable
// TODO: add test for this class
class ApiMethodGenerator {
  final OpenApi openApi;
  final MethodParamsParser methodParamsParser;
  final MethodBodyParser methodBodyParser;
  final MethodResponseParser methodResponseParser;
  final NameGenerator nameGenerator;

  ApiMethodGenerator({
    required this.openApi,
    required this.methodParamsParser,
    required this.methodBodyParser,
    required this.methodResponseParser,
    required this.nameGenerator,
  });

  String generateMethods() {
    if (openApi.paths.paths.isEmpty) return '';

    // buffer to store generated data
    final buffer = StringBuffer();

    // iterating over paths
    for (final path in openApi.paths.paths.entries) {
      final pathParams = path.value.parameters;

      final pathGeneratedComponentParams = pathParams
          ?.map(
            (param) => methodParamsParser.getGeneratedParameterComponent(
              path.key.pascalCase,
              param,
            ),
          )
          .toList();

      if (path.value.operations.isNotEmpty) {
        buffer.writeln('//${path.key}');
      }

      // iterating over operations of the path
      for (final operation in path.value.operations.entries) {
        final operationDetail = OperationDetail(
          path: path.key,
          operationType: operation.key,
          operationId: operation.value.operationId,
        );

        final methodName = nameGenerator.generateMethodName(operationDetail);

        buffer.writeln(
          _generateOperation(
            path.key,
            methodName,
            operation,
            pathGeneratedComponentParams,
          ),
        );
      }
    }

    return buffer.toString();
  }

  String _generateOperation(
    String pathUrl,
    String methodName,
    MapEntry<String, Operation> operation,
    List<GeneratedParameterComponent>? pathParameterComponents,
  ) {
    final operationParamComponents = operation.value.parameters == null
        ? null
        : methodParamsParser.parseParams(
            methodName,
            operation.value.parameters!,
            pathParameterComponents: pathParameterComponents,
          );

    final operationBodyComponent = operation.value.requestBody == null
        ? null
        : methodBodyParser.parseRequestBody(
            operation.value.requestBody!,
            methodName,
          );

    final methodHasParameter =
        (operationParamComponents?.isNotEmpty ?? false) &&
            operationBodyComponent != null;

    //TODO: update this with response parser
    final operationResponsesComponents = null;

    final StringBuffer buffer = StringBuffer();

    // Steps:
    // -------
    // 1. generate method return type
    // ->"Future"<- methodName(params)
    // 2. generate method name
    // Future ->"methodName"<- (params)
    // 3. generate method parameters
    // Future methodName ->"(params)"<-

    // TODO: update Future with method response
    buffer.writeln(_generateMethodSyntax(methodName));
    if (methodHasParameter) {
      if (operationParamComponents != null) {
        buffer.writeln(_generateParameters(operationParamComponents));
      }
      if (operationBodyComponent != null) {
        buffer.writeln(_generateRequestBody(operationBodyComponent));
      }
    }

    buffer.writeln(_generateContentTypeParameters());

    buffer.writeln(_generateEndMethodSyntax());

    // -------
    // 4. generate parsed path - get paths from params and parse them
    // final path = '/user/{id}';
    buffer.writeln(_generatePathUrl(pathUrl));

    final generatedPathParams = operationParamComponents
        ?.where((param) => param.source.location == 'path')
        .toList();

    // path = path.replaceFirst('{id}', '123');
    if (generatedPathParams?.isNotEmpty ?? false) {
      buffer.writeln(_generateReplacePathParameters(generatedPathParams));
    }

    // 5. generate query parameters
    final generatedQueryParams = operationParamComponents
        ?.where((param) => param.source.location == 'query')
        .toList();

    // final queryParams = {'id': '123' , 'name': 'John'};
    if (generatedQueryParams?.isNotEmpty ?? false) {
      buffer.writeln(_generateInitialQueryParameters(generatedQueryParams));
    }

    // 6. generate header parameters
    final generatedHeaderParams = operationParamComponents
        ?.where((param) => param.source.location == 'header')
        .toList();

    // final headerParams = {'accept': 'json'};
    if (generatedHeaderParams?.isNotEmpty ?? false) {
      buffer.writeln(_generateInitialHeaderParameters(generatedHeaderParams));
    }

    // 7. generate body parameters
    // final bodyJson = body.toJson();
    if (operationBodyComponent != null) {
      buffer.writeln(_generateInitialBody(operationBodyComponent));
    }

    // -------
    // 8. create request option for headers and content type
    // final option =  Options(
    //  method: POSt,
    //  headers : headerParams,
    //  contentType : contentType,
    // );
    buffer.writeln(
      _generateRequestOptions(
        operation.key,
        generatedHeaderParams,
      ),
    );

    // 9. generate request
    // final response = await dio.request(
    //  parsedPath,
    //  queryParameters: queryParams,
    //  options: option,
    //  data: bodyJson,
    // );
    buffer.writeln(_generateDioRequest());
    // 10. generate evaluated response
    // we should think about this
    // we should deserialize response.data to Generated response component type
    // return evaluateResponse(response);
    buffer.writeln(_generateEvaluateResponse());
    // -------

    buffer.writeln('}');

    return buffer.toString();
  }

  String _generateContentTypeParameters() => 'String? contentType,';

  String _generateMethodSyntax(String methodName) => 'Future $methodName({';

  String _generateEndMethodSyntax() => '}) async {';

  //TODO: add default values for parameters
  String _generateParameters(
    List<GeneratedParameterComponent> methodParams,
  ) {
    final StringBuffer buffer = StringBuffer();

    for (final param in methodParams) {
      final type = param.isSchema
          ? param.schemaComponent!.dataElement.type
          : param.contentManifest!.manifest.name;
      final name = param.source.name;
      final isRequired = param.source.isRequired == true;

      buffer.writeln('${isRequired ? 'required' : ''} $type $name,');
    }

    return buffer.toString();
  }

  String _generateRequestBody(
    GeneratedRequestBodyComponent requestBody,
  ) {
    // TODO(payam): please check if requestBody.isGenerated first because if not contentManifest is null
    final type = requestBody.contentManifest!.manifest.name;
    // TODO: check this in tests for duplicated naming
    final name = 'body';
    final isRequired = requestBody.source.isRequired == true;
    return '${isRequired ? 'required' : ''} $type $name,';
  }

  //TODO(payam): update response of this method
  String _generateResponses(Responses responses) {
    return """

    """;
  }

  String _generatePathUrl(String pathUrl) => 'final path = $pathUrl;';

  // path = path.replaceFirst('{id}', '123');
  String _generateReplacePathParameters(
      List<GeneratedParameterComponent>? generatedPathParams) {
    if (generatedPathParams?.isEmpty ?? true) return '';

    final StringBuffer buffer = StringBuffer();

    buffer.write('path = path');

    for (final param in generatedPathParams!) {
      final name = param.source.name;
      buffer.writeln('.replaceFirst(\'{$name}\', $name)');
    }

    buffer.writeln(';');

    return buffer.toString();
  }

  // final queryParams = {'id': '123' , 'name': 'John'};
  String _generateInitialQueryParameters(
    List<GeneratedParameterComponent>? generatedQueryParams,
  ) {
    if (generatedQueryParams?.isEmpty ?? true) return '';

    final StringBuffer buffer = StringBuffer();

    buffer.write('final queryParams = {');

    for (final param in generatedQueryParams!) {
      final name = param.source.name;
      buffer.writeln('\'$name\': $name,');
    }

    buffer.writeln('};');

    return buffer.toString();
  }

  // final headerParams = {'accept': 'json'};
  String _generateInitialHeaderParameters(
    List<GeneratedParameterComponent>? generatedHeaderParams,
  ) {
    if (generatedHeaderParams?.isEmpty ?? true) return '';

    final StringBuffer buffer = StringBuffer();

    buffer.write('final headerParams = {');

    for (final param in generatedHeaderParams!) {
      final name = param.source.name;
      buffer.writeln('\'$name\': $name,');
    }

    buffer.writeln('};');

    return buffer.toString();
  }

  // final bodyJson = body.toJson();
  // TODO: Test this method
  String _generateInitialBody(
    GeneratedRequestBodyComponent operationBodyComponent,
  ) {
    // TODO(payam): please check if operationBodyComponent.isGenerated first if not contentManifest will be null
    final type = operationBodyComponent.contentManifest!.manifest.name;
    // TODO: check type if its primitive just return it otherwise return toJson
    final name = 'body';
    return 'final nameJson = $name.toJson();';
  }

  // final option =  Options(
  //   method: POSt,
  //   contentType : contentType,
  //   headers : headerParams,
  // );
  String _generateRequestOptions(
    String method,
    List<GeneratedParameterComponent>? generatedHeaderParams,
  ) {
    final StringBuffer buffer = StringBuffer();

    buffer.write('final option = Options(');

    buffer.writeln('method: ${method.constantCase},');

    buffer.writeln('contentType: contentType,');

    if (generatedHeaderParams?.isNotEmpty ?? false) {
      buffer.writeln('headers: headerParams,');
    }

    buffer.writeln(');');

    return buffer.toString();
  }

  // final response = await dio.request(
  //  path,
  //  queryParameters: queryParams,
  //  options: option,
  //  data: bodyJson,
  // );
  String _generateDioRequest() {
    final StringBuffer buffer = StringBuffer();

    buffer.write('final response = await dio.request(path, ');

    buffer.writeln('queryParameters: queryParams,');

    buffer.writeln('options: option,');

    buffer.writeln('data: bodyJson,');

    buffer.writeln(');');

    return buffer.toString();
  }

  // return evaluateResponse(response);
  // TODO: complete this method and test it
  String _generateEvaluateResponse() {
    final StringBuffer buffer = StringBuffer();

    buffer.write('return response;');

    return buffer.toString();
  }
}
