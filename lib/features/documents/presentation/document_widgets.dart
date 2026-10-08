import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../../app/providers.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/due_dates.dart';
import '../../../core/utils/permissions.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/illustrations.dart';
import '../../../shared/models/models.dart';

String fileSize(int bytes) => bytes >= 1024 * 1024
    ? '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB'
    : '${(bytes / 1024).toStringAsFixed(1)} KB';

class DocumentTile extends ConsumerWidget {
  final Document document;
  const DocumentTile({super.key, required this.document});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(dueItemDetailProvider(document.dueItemId)),
        user = ref.watch(currentUserProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => DocumentPreview(document: document),
          ),
        ),
        child: Row(
          children: [
            IllustratedIcon(
              size: 40,
              icon: document.fileType == 'pdf'
                  ? Icons.picture_as_pdf_outlined
                  : document.mimeType.startsWith('image/')
                  ? Icons.image_outlined
                  : Icons.description_outlined,
              color: document.fileType == 'pdf'
                  ? const Color(0xFFD95765)
                  : const Color(0xFF6C63FF),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.filename,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item?.title ?? 'Related obligation',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${document.fileType.toUpperCase()} · ${fileSize(document.fileSize)}\n${document.uploadedBy} · ${DueDates.format(document.uploadedAt)}',
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Document actions',
              onSelected: (v) async {
                if (v == 'download') {
                  await downloadDocument(context, ref, document);
                } else if (v == 'replace') {
                  await glassSheet(
                    context,
                    UploadSheet(
                      itemId: document.dueItemId,
                      replaceId: document.id,
                    ),
                  );
                } else if (v == 'remove') {
                  if (await confirmAction(
                        context,
                        'Remove this document?',
                        'The removal will be recorded in the activity history.',
                        confirm: 'Remove document',
                      ) &&
                      context.mounted) {
                    await runAction(
                      context,
                      () => ref
                          .read(workspaceProvider.notifier)
                          .act((r, a) => r.removeDocument(a, document.id)),
                      success: 'Document removed',
                    );
                  }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'download', child: Text('Download')),
                if (item != null && Permissions.update(user, item))
                  const PopupMenuItem(value: 'replace', child: Text('Replace')),
                if (item != null &&
                    Permissions.manage(user, item.organisationId) &&
                    !item.isClosed)
                  const PopupMenuItem(value: 'remove', child: Text('Remove')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> downloadDocument(
  BuildContext context,
  WidgetRef ref,
  Document doc,
) async {
  await runAction(context, () async {
    final bytes = await ref
        .read(repositoryProvider)
        .readDocument(ref.read(currentUserProvider), doc);
    await FilePicker.platform.saveFile(
      dialogTitle: 'Save document',
      fileName: doc.filename,
      bytes: bytes,
    );
  });
}

class UploadSheet extends ConsumerStatefulWidget {
  final String? itemId, replaceId;
  const UploadSheet({super.key, this.itemId, this.replaceId});
  @override
  ConsumerState<UploadSheet> createState() => _UploadState();
}

class _UploadState extends ConsumerState<UploadSheet> {
  String? selected;
  PlatformFile? file;
  bool busy = false;
  double progress = 0;
  @override
  void initState() {
    super.initState();
    selected = widget.itemId;
  }

  Future<void> pick() async {
    try {
      final r = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx', 'txt'],
        withData: true,
      );
      if (r == null) return;
      final f = r.files.single;
      if (f.size > 20 * 1024 * 1024 || f.size == 0) {
        throw const ValidationFailure(
          'Choose a file between 1 byte and 20 MB.',
        );
      }
      if (mounted) setState(() => file = f);
    } catch (e) {
      if (mounted) feedback(context, friendlyError(e));
    }
  }

  Future<void> upload() async {
    if (selected == null || file == null) {
      feedback(context, 'Choose a DueItem and a document.');
      return;
    }
    if (file!.bytes == null) {
      feedback(context, 'Could not read this file. Please select it again.');
      return;
    }
    setState(() => busy = true);
    final ok = await runAction(
      context,
      () => ref
          .read(workspaceProvider.notifier)
          .act(
            (r, a) => r.uploadDocument(
              a,
              selected!,
              file!.name,
              file!.bytes!,
              replaceId: widget.replaceId,
              onProgress: (v) {
                if (mounted) setState(() => progress = v);
              },
            ),
          ),
      success: 'Document uploaded',
    );
    if (mounted) {
      if (ok) {
        Navigator.pop(context);
      } else {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.replaceId == null
              ? 'Upload supporting document'
              : 'Replace document',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        const Text('Keep evidence with the obligation it supports.'),
        const SizedBox(height: 24),
        if (widget.itemId == null)
          GlassDropdown<String>(
            label: 'Related DueItem',
            required: true,
            value: selected,
            options: {
              for (final i
                  in ref
                      .watch(dueItemsProvider)
                      .where((i) => i.status != DueStatus.archived))
                i.id: i.title,
            },
            onChanged: busy ? null : (v) => setState(() => selected = v),
          ),
        GlassCard(
          child: Column(
            children: [
              const Icon(Icons.cloud_upload_outlined, size: 38),
              const SizedBox(height: 12),
              Text(
                file?.name ?? 'Select a document',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                file == null
                    ? 'PDF, JPG, PNG, DOC, DOCX, TXT · 20 MB max'
                    : '${file!.extension?.toUpperCase()} · ${fileSize(file!.size)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 16),
              SecondaryButton(
                label: file == null ? 'Browse files' : 'Choose another',
                onPressed: busy ? null : pick,
              ),
            ],
          ),
        ),
        if (busy) ...[
          const SizedBox(height: 20),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 8),
          Text(
            'Uploading ${(progress * 100).round()}%',
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Upload document',
          loading: busy,
          onPressed: upload,
        ),
        if (!busy)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
      ],
    ),
  );
}

class DocumentPreview extends ConsumerStatefulWidget {
  final Document document;
  const DocumentPreview({super.key, required this.document});
  @override
  ConsumerState<DocumentPreview> createState() => _PreviewState();
}

class _PreviewState extends ConsumerState<DocumentPreview> {
  late Future<Uint8List> bytes;
  @override
  void initState() {
    super.initState();
    bytes = ref
        .read(repositoryProvider)
        .readDocument(ref.read(currentUserProvider), widget.document);
  }

  @override
  Widget build(BuildContext context) => DueDeskScaffold(
    title: widget.document.filename,
    actions: [
      IconButton(
        tooltip: 'Download document',
        onPressed: () => downloadDocument(context, ref, widget.document),
        icon: const Icon(Icons.download_outlined),
      ),
    ],
    child: FutureBuilder<Uint8List>(
      future: bytes,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorState(
            error: snapshot.error!,
            onRetry: () => setState(
              () => bytes = ref
                  .read(repositoryProvider)
                  .readDocument(ref.read(currentUserProvider), widget.document),
            ),
          );
        }
        if (!snapshot.hasData) return const LoadingSkeleton();
        final data = snapshot.data!;
        if (widget.document.fileType == 'pdf') {
          return PdfViewer.data(data, sourceName: widget.document.filename);
        }
        if (widget.document.mimeType.startsWith('image/')) {
          return InteractiveViewer(
            child: Image.memory(
              data,
              errorBuilder: (_, e, st) => const EmptyState(
                title: 'Unable to preview',
                message: 'Download this file to open it in another app.',
              ),
            ),
          );
        }
        if (widget.document.fileType == 'txt') {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: SelectableText(utf8.decode(data, allowMalformed: true)),
          );
        }
        return EmptyState(
          title: 'Ready to download',
          message: 'Open Word documents in your preferred app.',
          icon: Icons.description_outlined,
          action: 'Download',
          onAction: () => downloadDocument(context, ref, widget.document),
        );
      },
    ),
  );
}
