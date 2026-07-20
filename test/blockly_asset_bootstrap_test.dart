import 'dart:io';

import 'package:flutter_application_1/blockly/lp_blockly_asset_bootstrap.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('Blockly 运行资源必须包含全部关键文件', () async {
    final root = await Directory.systemTemp.createTemp('lp_blockly_runtime_');
    addTearDown(() => root.delete(recursive: true));

    Future<void> write(String relative) async {
      final file = File(p.joinAll([root.path, ...relative.split('/')]));
      await file.parent.create(recursive: true);
      await file.writeAsString('// test');
    }

    await write('blockly/blockly_uncompressed.js');
    expect(
      await LpBlocklyAssetBootstrap.isRuntimeComplete(root.path),
      isFalse,
    );

    for (final relative in [
      'blockly/demos/code/index.html',
      'blockly/core/blockly.js',
      'blockly/blocks/customconfig.js',
      'blockly/demos/code/flutter_bound.js',
      'blockly/demos/code/code.js',
      'closure-library/closure/goog/base.js',
    ]) {
      await write(relative);
    }
    expect(
      await LpBlocklyAssetBootstrap.isRuntimeComplete(root.path),
      isTrue,
    );
  });
}
