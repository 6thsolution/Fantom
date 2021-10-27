import 'dart:io';

import 'package:fantom/src/cli/commands/generate.dart';
import 'package:fantom/src/utils/process_manager.dart';
import 'package:pubspec_yaml/pubspec_yaml.dart' as p;
import 'package:plain_optional/plain_optional.dart' as o;
import 'package:pubspec_yaml/pubspec_yaml.dart';
import 'package:version/version.dart';

class FantomPackageInfo {
  final String name;
  final String generationPath;
  final PubspecInfo pubspecInfo;

  FantomPackageInfo({
    required this.name,
    required this.generationPath,
    required this.pubspecInfo,
  });

  String get modelsDirPath => '$libDir/models/';

  String get apisDirPath => libDir;

  String get libDir => '$generationPath/$name/lib/';

  factory FantomPackageInfo.fromConfig(
      GenerateAsStandAlonePackageConfig config) {
    return FantomPackageInfo(
      name: config.packageName,
      generationPath: config.outputModuleDir.path,
      pubspecInfo: PubspecInfo(
        version: Version(1, 0, 0),
        description: 'this is a very funny library',
        environment: {"sdk": ">=2.14.0 <3.0.0"},
        dependencies: [
          PackageDependencySpec.hosted(HostedPackageDependencySpec(
            package: 'dio',
            version: o.Optional('4.0.1'),
          )),
        ],
      ),
    );
  }
}

class PubspecInfo {
  final Version version;
  final String description;
  final Map<String, String> environment;
  final List<p.PackageDependencySpec> dependencies;

  PubspecInfo({
    required this.version,
    required this.description,
    required this.environment,
    required this.dependencies,
  });

  Map<String, dynamic> toJson() {
    return {
      "version": version.toString(),
      "decription": description,
      "environment": environment,
      "dependencies": dependencies,
    };
  }
}

/// creates a dart package and returns the lib directory of it
Future createDartPackage(FantomPackageInfo packageInfo) async {
  // create path where dart package should be created
  await runFromCmd('mkdir', args: ['-p', (packageInfo.generationPath)]);
  // create a dart package with package-simple template
  var packagePath = '${packageInfo.generationPath}/${packageInfo.name}';
  await runFromCmd(
    'dart',
    args: ['create', packagePath, '--template=package-simple', '--force'],
  );
  // delete default data in the newly created dart package
  await runFromCmd('rm', args: ['-rf', '$packagePath/lib']);
  await runFromCmd('rm', args: ['-rf', '$packagePath/example']);
  await runFromCmd('rm', args: ['-rf', '$packagePath/test']);
  // recreate lib folder in package
  await runFromCmd('mkdir', args: ['$packagePath/lib']);
  // rewrite pubspec.yaml file
  var projectPubspecFile = File('$packagePath/pubspec.yaml');
  var pubspec =
      p.PubspecYaml.loadFromYamlString(await projectPubspecFile.readAsString());
  var newPubspec = pubspec.copyWith(
    description: o.Optional(packageInfo.pubspecInfo.description),
    version: o.Optional(packageInfo.pubspecInfo.version.toString()),
    environment: packageInfo.pubspecInfo.environment,
    dependencies: packageInfo.pubspecInfo.dependencies,
  );
  projectPubspecFile.writeAsString(newPubspec.toYamlString());

  // write generated files in lib/
}