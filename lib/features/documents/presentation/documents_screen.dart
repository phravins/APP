import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../shared/widgets/due_widgets.dart';
import 'document_widgets.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  final bool upload;
  const DocumentsScreen({super.key, this.upload = false});
  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsState();
}

class _DocumentsState extends ConsumerState<DocumentsScreen> {
  String query = '';
  String? type, itemId, uploader, category;
  @override
  void initState() {
    super.initState();
    if (widget.upload) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) glassSheet(context, const UploadSheet());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(dueItemsProvider);
    final docs =
        ref
            .watch(documentsProvider)
            .where(
              (d) =>
                  d.filename.toLowerCase().contains(query.toLowerCase()) &&
                  (type == null || d.fileType == type) &&
                  (itemId == null || d.dueItemId == itemId) &&
                  (uploader == null || d.uploadedBy == uploader) &&
                  (category == null ||
                      items.any(
                        (i) => i.id == d.dueItemId && i.categoryId == category,
                      )),
            )
            .toList()
          ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    return WorkspaceBody(
      child: PageBody(
        onRefresh: () => ref.read(workspaceProvider.notifier).refresh(),
        children: [
          ScreenHeading(
            title: 'Documents',
            subtitle: 'The evidence behind every obligation.',
            trailing: IconButton.filled(
              style: AppIconButtonStyles.filled(),
              tooltip: 'Upload document',
              onPressed: () => glassSheet(context, const UploadSheet()),
              icon: const Icon(Icons.add_rounded),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search documents…',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => query = v),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.outlined(
                style: AppIconButtonStyles.outlined(
                  Theme.of(context).colorScheme,
                ),
                tooltip: 'Filter documents',
                onPressed: () => glassSheet(
                  context,
                  StatefulBuilder(
                    builder: (context, setSheetState) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Filter documents',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 24),
                        GlassDropdown<String?>(
                          label: 'File type',
                          value: type,
                          options: {
                            null: 'Any type',
                            for (final t
                                in ref
                                    .read(documentsProvider)
                                    .map((d) => d.fileType)
                                    .toSet())
                              t: t.toUpperCase(),
                          },
                          onChanged: (v) {
                            setState(() => type = v);
                            setSheetState(() {});
                          },
                        ),
                        GlassDropdown<String?>(
                          label: 'DueItem',
                          value: itemId,
                          options: {
                            null: 'Any DueItem',
                            for (final i in items) i.id: i.title,
                          },
                          onChanged: (v) {
                            setState(() => itemId = v);
                            setSheetState(() {});
                          },
                        ),
                        GlassDropdown<String?>(
                          label: 'Category',
                          value: category,
                          options: {
                            null: 'Any category',
                            for (final c in ref.read(categoriesProvider))
                              c.id: c.name,
                          },
                          onChanged: (v) {
                            setState(() => category = v);
                            setSheetState(() {});
                          },
                        ),
                        GlassDropdown<String?>(
                          label: 'Uploaded by',
                          value: uploader,
                          options: {
                            null: 'Anyone',
                            for (final u
                                in ref
                                    .read(documentsProvider)
                                    .map((d) => d.uploadedBy)
                                    .toSet())
                              u: u,
                          },
                          onChanged: (v) {
                            setState(() => uploader = v);
                            setSheetState(() {});
                          },
                        ),
                        PrimaryButton(
                          label: 'Done',
                          onPressed: () => Navigator.pop(context),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              type = null;
                              itemId = null;
                              uploader = null;
                              category = null;
                            });
                            setSheetState(() {});
                          },
                          child: const Text('Reset filters'),
                        ),
                      ],
                    ),
                  ),
                ),
                icon: const Icon(Icons.tune),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '${docs.length} supporting documents',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          if (docs.isEmpty)
            EmptyState(
              title: 'Keep the proof close.',
              message:
                  'Attach evidence to a DueItem so it is there when you need it.',
              icon: Icons.folder_open_outlined,
              action: 'Upload document',
              onAction: () => glassSheet(context, const UploadSheet()),
            ),
          for (final d in docs) DocumentTile(document: d),
        ],
      ),
    );
  }
}
