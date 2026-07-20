import 'dart:io';

import 'package:flutter/material.dart';

class MessageComposer extends StatelessWidget {
  const MessageComposer({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onPickFile,
    required this.onPickImage,
    required this.onLocation,
    required this.selectedAttachments,
    required this.onRemoveAttachment,
    this.isSending = false,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onPickFile;
  final VoidCallback onPickImage;
  final VoidCallback onLocation;
  final List<File> selectedAttachments;
  final ValueChanged<File> onRemoveAttachment;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedAttachments.isNotEmpty) ...[
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedAttachments.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final attachment = selectedAttachments[index];
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _AttachmentPreview(file: attachment),
                        Positioned(
                          top: -8,
                          right: -8,
                          child: IconButton.filled(
                            onPressed: isSending
                                ? null
                                : () => onRemoveAttachment(attachment),
                            icon: const Icon(Icons.close, size: 14),
                            style: IconButton.styleFrom(
                              minimumSize: const Size(24, 24),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: const Color(0xFFA03B56),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                IconButton(
                  onPressed: isSending ? null : onPickFile,
                  icon: selectedAttachments.isEmpty
                      ? const Icon(Icons.file_upload_outlined)
                      : Badge(
                          label: Text(selectedAttachments.length.toString()),
                          child: const Icon(Icons.file_upload_outlined),
                        ),
                  color: const Color(0xFFA03B56),
                ),
                IconButton(
                  onPressed: isSending ? null : onPickImage,
                  icon: selectedAttachments.isEmpty
                      ? const Icon(Icons.add_photo_alternate_outlined)
                      : Badge(
                          label: Text(selectedAttachments.length.toString()),
                          child: const Icon(Icons.add_photo_alternate_outlined),
                        ),
                  color: const Color(0xFFA03B56),
                ),
                IconButton(
                  onPressed: isSending ? null : onLocation,
                  icon: const Icon(Icons.location_on_outlined),
                  color: const Color(0xFFA03B56),
                  tooltip: 'Chia sẻ vị trí',
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: !isSending,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Nhắn gì đó...',
                      hintStyle: const TextStyle(color: Color(0xFF9AA0A6)),
                      filled: true,
                      fillColor: const Color(0xFFF6F1F4),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 46,
                  height: 46,
                  child: FilledButton(
                    onPressed: isSending ? null : onSend,
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: const Color(0xFFA03B56),
                      shape: const CircleBorder(),
                    ),
                    child: isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final isImage = _isImageFile(fileName);

    if (isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(file, width: 64, height: 64, fit: BoxFit.cover),
      );
    }

    return Container(
      width: 120,
      height: 64,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F1F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5D9DF)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.insert_drive_file_outlined,
            color: Color(0xFFA03B56),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fileName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF24272A),
                fontSize: 11,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isImageFile(String fileName) {
    final lowerName = fileName.toLowerCase();
    return lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.png') ||
        lowerName.endsWith('.gif') ||
        lowerName.endsWith('.webp');
  }
}
