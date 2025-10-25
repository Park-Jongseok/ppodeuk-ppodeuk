import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:template/core/themes/app_colors.dart';
import 'package:template/core/themes/app_typography.dart';
import 'package:template/features/ppodeuk_ppodeuk/controllers/ppodeuk_controller.dart';

/// 뽀득뽀득 메인 화면
class PpodeukScreen extends ConsumerWidget {
  /// [PpodeukScreen] 생성자
  const PpodeukScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ppodeuks = ref.watch(ppodeukControllerProvider);
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('뽀득뽀득'),
      ),
      body: ppodeuks.isEmpty
          ? Center(
              child: Text(
                '뽀득뽀득 항목이 없습니다.\n+ 버튼을 눌러 추가해보세요!',
                style: AppTypography.body.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ppodeuks.length,
              itemBuilder: (context, index) {
                final ppodeuk = ppodeuks[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Checkbox(
                      value: ppodeuk.isDone,
                      onChanged: (_) {
                        ref
                            .read(ppodeukControllerProvider.notifier)
                            .togglePpodeuk(ppodeuk.id);
                      },
                    ),
                    title: Text(
                      ppodeuk.title,
                      style: AppTypography.body.copyWith(
                        decoration: ppodeuk.isDone
                            ? TextDecoration.lineThrough
                            : null,
                        color: ppodeuk.isDone
                            ? colors.textSecondary
                            : colors.textPrimary,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _showEditDialog(
                            context,
                            ref,
                            ppodeuk.id,
                            ppodeuk.title,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () {
                            ref
                                .read(ppodeukControllerProvider.notifier)
                                .removePpodeuk(ppodeuk.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 뽀득뽀득 추가'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '뽀득뽀득 내용을 입력하세요'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref
                    .read(ppodeukControllerProvider.notifier)
                    .addPpodeuk(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: Text('add'.tr()),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    String id,
    String currentTitle,
  ) {
    final controller = TextEditingController(text: currentTitle);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('뽀득뽀득 수정'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '뽀득뽀득 내용을 입력하세요'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref
                    .read(ppodeukControllerProvider.notifier)
                    .updatePpodeuk(id, controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('수정'),
          ),
        ],
      ),
    );
  }
}
