import 'package:flutter/material.dart';
import 'package:template/core/themes/app_colors.dart';
import 'package:template/core/themes/app_typography.dart';
import 'package:template/features/ppodeuk_ppodeuk/models/space.dart';
import 'package:template/features/ppodeuk_ppodeuk/models/task.dart';

/// 공간 정보를 찾을 수 없을 때 사용하는 기본 공간
const kUnknownSpace = Space(
  id: '0',
  name: '알 수 없음',
  score: 0,
);

/// 공통 할 일 타일 위젯
class TaskListTile extends StatelessWidget {
  const TaskListTile({
    super.key,
    required this.task,
    required this.space,
    required this.onEdit,
    this.isUpdating = false,
    this.onTap,
    this.onCompletionChanged,
    this.showCompletionControl = true,
  });

  /// 표시할 할 일
  final Task task;

  /// 할 일이 속한 공간
  final Space space;

  /// 편집 버튼 콜백
  final VoidCallback onEdit;

  /// 진행 중일 때 로딩 상태 표시 여부
  final bool isUpdating;

  /// 전체 타일 탭 콜백
  final VoidCallback? onTap;

  /// 완료 상태 변경 콜백 (체크 표시를 숨기면 null)
  final ValueChanged<bool?>? onCompletionChanged;

  /// 완료 체크박스를 보여줄지 여부
  final bool showCompletionControl;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final startDate = task.startDate;

    return ListTile(
      onTap: onTap,
      leading: showCompletionControl
          ? AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: isUpdating
                  ? SizedBox(
                      key: ValueKey('task-loader-${task.id}-${task.hashCode}'),
                      width: 24,
                      height: 24,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Checkbox(
                      key: ValueKey('task-checkbox-${task.id}-${task.hashCode}'),
                      value: task.isCompleted,
                      onChanged: onCompletionChanged,
                    ),
            )
          : null,
      title: Text(
        task.name,
        style: AppTypography.body.copyWith(
          decoration:
              task.isCompleted ? TextDecoration.lineThrough : null,
          color:
              task.isCompleted ? colors.textSecondary : colors.textPrimary,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            '📍 ${space.name}',
            style: AppTypography.caption.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                '중요도: ${task.importance.displayName}',
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '주기: ${task.period.displayName}',
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            startDate != null
                ? '시작: ${_formatDate(startDate)}'
                : '시작: 미설정',
            style: AppTypography.caption.copyWith(
              color: startDate != null && _isOverdue(startDate)
                  ? colors.error
                  : colors.textSecondary,
            ),
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.edit, size: 20),
        onPressed: onEdit,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final formatted =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    if (target == today) {
      return '오늘 ($formatted)';
    } else if (target == today.add(const Duration(days: 1))) {
      return '내일 ($formatted)';
    } else if (target == today.subtract(const Duration(days: 1))) {
      return '어제 ($formatted)';
    }
    return formatted;
  }

  bool _isOverdue(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return target.isBefore(today);
  }
}
