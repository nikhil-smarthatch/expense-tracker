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
          actions: [
            IconButton(
              icon: const Icon(Icons.zoom_in),
              tooltip: 'Zoom in',
              onPressed: () {
                // Pinch to zoom is handled by InteractiveViewer
              },
            ),
          ],
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

/// Thumbnail card with preview capability
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
        if (onRemove != null)
          Padding(
            padding: const EdgeInsets.all(4),
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
        // Preview icon overlay
        Padding(
          padding: const EdgeInsets.all(8),
          child: Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.zoom_in,
                color: Colors.white,
                size: 20,
              ),
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
