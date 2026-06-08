import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/robot_path_layout.dart';
import '../../core/robot_paths.dart';

/// 用户工程目录 `files/projects/{name}/` 扫描。
class ProjectCatalog {
  ProjectCatalog._();

  static Future<List<ProjectEntry>> listUserProjects() async {
    final root = Directory(await RobotPaths.projectsDir());
    if (!await root.exists()) {
      await root.create(recursive: true);
      return const [];
    }

    final entries = <ProjectEntry>[];
    await for (final entity in root.list()) {
      if (entity is! Directory) continue;
      final name = p.basename(entity.path);
      if (name.startsWith('.')) continue;

      final xmlFile = File(p.join(entity.path, '$name.xml'));
      final rp4File = File(
        p.join(entity.path, '$name${RobotPathLayout.gcodeExtension}'),
      );
      final xmlStat = await xmlFile.stat();
      DateTime? rp4Modified;
      if (await rp4File.exists()) {
        rp4Modified = (await rp4File.stat()).modified;
      }

      entries.add(
        ProjectEntry(
          name: name,
          xmlPath: xmlFile.path,
          hasXml: await xmlFile.exists(),
          hasRp4: await rp4File.exists(),
          modified: rp4Modified ?? xmlStat.modified,
        ),
      );
    }

    entries.sort((a, b) => b.modified.compareTo(a.modified));
    return entries;
  }

  static Future<String?> readProjectXml(String projectName) async {
    final file = await RobotPaths.projectXmlFile(projectName);
    if (!await file.exists()) return null;
    return file.readAsString();
  }
}

class ProjectEntry {
  const ProjectEntry({
    required this.name,
    required this.xmlPath,
    required this.hasXml,
    required this.hasRp4,
    required this.modified,
  });

  final String name;
  final String xmlPath;
  final bool hasXml;
  final bool hasRp4;
  final DateTime modified;
}
