import 'package:flutter/material.dart';
import 'package:template/core/themes/app_colors.dart';
import 'package:template/core/themes/app_typography.dart';
import 'package:template/features/ppodeuk_ppodeuk/models/ppodeuk.dart';

/// 뽀득뽀득 항목 위젯
class PpodeukItem extends StatelessWidget {
  /// [PpodeukItem] 생성자
  const PpodeukItem({
    required this.ppodeuk,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  /// 뽀득뽀득 항목
  final Ppodeuk ppodeuk;

  /// 완료 토글 콜백
  final VoidCallback onToggle;

  /// 수정 콜백
  final VoidCallback onEdit;

  /// 삭제 콜백
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: ppodeuk.isDone,
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          ppodeuk.title,
          style: AppTypography.body.copyWith(
            decoration: ppodeuk.isDone ? TextDecoration.lineThrough : null,
            color: ppodeuk.isDone ? colors.textSecondary : colors.textPrimary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
