import 'dart:io';
import 'package:flutter/material.dart';

/// Full-screen image preview dialog
void showImagePreview(BuildContext context, String imagePath) {
  showDialog(
    context: context,
    builder: (context) => ImagePreviewDialog(imagePath: imagePath),
  );
}

/// Image preview dialog widget
class ImagePreviewDialog extends StatelessWidget {
  const ImagePreviewDialog({
    super.key,
    required this.imagePath,
  });

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Receipt Preview'),
        ),
        body: Center(
          child: InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 1.0,
            maxScale: 3.0,
            child: Image.file(
              File(imagePath),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact receipt attachment row — shows a pill with receipt icon + filename.
/// Opens full-screen preview on tap. Does NOT show the image inline.
class ReceiptAttachmentRow extends StatelessWidget {
  const ReceiptAttachmentRow({
    super.key,
    required this.imagePath,
    this.onRemove,
  });

  final String imagePath;
  final VoidCallback? onRemove;

  String get _fileName => imagePath.split('/').last;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () => showImagePreview(context, imagePath),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: cs.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Receipt Attached',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _fileName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Tap hint
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility_outlined, size: 16, color: cs.primary),
                    const SizedBox(width: 4),
                    Text(
                      'View',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 18, color: cs.error),
                  onPressed: onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: 'Remove receipt',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Thumbnail card with preview capability (used in gallery / detail views)
class ImageThumbnailCard extends StatelessWidget {
  const ImageThumbnailCard({
    super.key,
    required this.imagePath,
    this.onRemove,
    this.onPreview,
    this.height = 120,
    this.width = double.infinity,
  });

  final String imagePath;
  final VoidCallback? onRemove;
  final VoidCallback? onPreview;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      alignment: Alignment.topRight,
      children: [
        GestureDetector(
          onTap: onPreview ?? () => showImagePreview(context, imagePath),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: height,
              width: width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.file(
                File(imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        // Zoom-in overlay — Positioned must be a direct Stack child
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.zoom_in,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.remove_circle),
              color: cs.error,
              onPressed: onRemove,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: cs.error,
              ),
            ),
          ),
      ],
    );
  }
}

/// Simple receipt upload button
class ReceiptUploadButton extends StatelessWidget {
  const ReceiptUploadButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_a_photo_rounded),
      label: const Text('Attach Receipt'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// Image gallery preview (multiple images)
class ImageGalleryPreview extends StatefulWidget {
  const ImageGalleryPreview({
    super.key,
    required this.imagePaths,
    this.onRemove,
  });

  final List<String> imagePaths;
  final Function(int)? onRemove;

  @override
  State<ImageGalleryPreview> createState() => _ImageGalleryPreviewState();
}

class _ImageGalleryPreviewState extends State<ImageGalleryPreview> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.imagePaths.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attached Images (${_currentIndex + 1}/${widget.imagePaths.length})',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Stack(
          alignment: Alignment.center,
          children: [
            ImageThumbnailCard(
              imagePath: widget.imagePaths[_currentIndex],
              onRemove: widget.onRemove != null
                  ? () => widget.onRemove!(_currentIndex)
                  : null,
            ),
            if (widget.imagePaths.length > 1) ...[
              Positioned(
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: _currentIndex > 0
                      ? () => setState(() => _currentIndex--)
                      : null,
                ),
              ),
              Positioned(
                right: 8,
                child: IconButton(
                  icon:
                      const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  onPressed: _currentIndex < widget.imagePaths.length - 1
                      ? () => setState(() => _currentIndex++)
                      : null,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
