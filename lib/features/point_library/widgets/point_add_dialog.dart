import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/lp_robot_colors.dart';

/// 添加点位对话框（对齐 Android [PointAddDialog]）。
class PointAddInput {
  const PointAddInput({
    required this.index,
    required this.label,
    required this.describe,
  });

  final int index;
  final String label;
  final String describe;
}

class PointAddDialog extends StatefulWidget {
  const PointAddDialog({super.key, required this.suggestedIndex});

  final int suggestedIndex;

  static Future<PointAddInput?> show(
    BuildContext context, {
    required int suggestedIndex,
  }) {
    return showDialog<PointAddInput>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PointAddDialog(suggestedIndex: suggestedIndex),
    );
  }

  @override
  State<PointAddDialog> createState() => _PointAddDialogState();
}

class _PointAddDialogState extends State<PointAddDialog> {
  late final TextEditingController _indexController;
  late final TextEditingController _labelController;
  late final TextEditingController _describeController;

  @override
  void initState() {
    super.initState();
    _indexController =
        TextEditingController(text: '${widget.suggestedIndex}');
    _labelController = TextEditingController();
    _describeController = TextEditingController();
  }

  @override
  void dispose() {
    _indexController.dispose();
    _labelController.dispose();
    _describeController.dispose();
    super.dispose();
  }

  void _submit() {
    final index = int.tryParse(_indexController.text.trim());
    if (index == null || index < 1) {
      _showError('请输入有效点编号');
      return;
    }
    final label = _labelController.text.trim();
    final describe = _describeController.text.trim();
    Navigator.of(context).pop(
      PointAddInput(
        index: index,
        label: label,
        describe: describe.isEmpty ? label : describe,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        '添加点位',
        style: TextStyle(color: LpRobotColors.textDark),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _fieldRow(
              label: '点编号',
              child: TextField(
                controller: _indexController,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _fieldRow(
              label: '名称',
              child: TextField(
                controller: _labelController,
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  hintText: '选填',
                ),
              ),
            ),
            const SizedBox(height: 12),
            _fieldRow(
              label: '描述',
              child: TextField(
                controller: _describeController,
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: LpRobotColors.primary,
          ),
          child: const Text('确定'),
        ),
      ],
    );
  }

  Widget _fieldRow({required String label, required Widget child}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: const TextStyle(fontSize: 15)),
        ),
        Expanded(child: child),
      ],
    );
  }
}
