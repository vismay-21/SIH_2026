import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_theme.dart';
import 'sample_photos.dart';

/// Reusable image display widget supporting data URIs, HTTP URLs, and local fallbacks.
class AppImageWidget extends StatelessWidget {
  const AppImageWidget({
    super.key,
    required this.photo,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final String photo;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (photo.trim().isEmpty) {
      return _buildPlaceholder();
    }

    if (photo.startsWith('data:image/')) {
      try {
        final commaIdx = photo.indexOf(',');
        final base64Data = commaIdx != -1 ? photo.substring(commaIdx + 1) : photo;
        final Uint8List bytes = base64Decode(base64Data.trim());
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => _buildPlaceholder(),
        );
      } catch (_) {
        return _buildPlaceholder();
      }
    }

    if (photo.startsWith('http://') || photo.startsWith('https://')) {
      return Image.network(
        photo,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: width,
            height: height,
            color: Colors.grey.shade100,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 24),
      ),
    );
  }
}

/// A compact photo thumbnail with optional delete button and tap-to-zoom.
class AppPhotoThumbnail extends StatelessWidget {
  const AppPhotoThumbnail({
    super.key,
    required this.photo,
    this.size = 76,
    this.onTap,
    this.onDelete,
    this.heroTag,
  });

  final String photo;
  final double size;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: AppImageWidget(
                photo: photo,
                fit: BoxFit.cover,
                width: size,
                height: size,
              ),
            ),
          ),
        ),
        if (onDelete != null)
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Horizontal gallery displaying attached photos with zoom dialog and optional add/delete actions.
class AppPhotoGallery extends StatelessWidget {
  const AppPhotoGallery({
    super.key,
    required this.photos,
    this.thumbnailSize = 76,
    this.onDelete,
    this.onAddMore,
    this.maxPhotos = 5,
  });

  final List<String> photos;
  final double thumbnailSize;
  final void Function(int index)? onDelete;
  final VoidCallback? onAddMore;
  final int maxPhotos;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty && onAddMore == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: thumbnailSize + 12,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.only(top: 6, bottom: 6, right: 6),
        itemCount: photos.length + (onAddMore != null && photos.length < maxPhotos ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index < photos.length) {
            return AppPhotoThumbnail(
              photo: photos[index],
              size: thumbnailSize,
              onDelete: onDelete != null ? () => onDelete!(index) : null,
              onTap: () {
                PhotoViewerDialog.show(
                  context,
                  photos: photos,
                  initialIndex: index,
                );
              },
            );
          }

          // Add More button
          return InkWell(
            onTap: onAddMore,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: thumbnailSize,
              height: thumbnailSize,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  style: BorderStyle.solid,
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Add',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Fullscreen zoomable lightbox dialog with swipeable navigation between photos.
class PhotoViewerDialog extends StatefulWidget {
  const PhotoViewerDialog({
    super.key,
    required this.photos,
    this.initialIndex = 0,
  });

  final List<String> photos;
  final int initialIndex;

  static void show(
    BuildContext context, {
    required List<String> photos,
    int initialIndex = 0,
  }) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (_) => PhotoViewerDialog(
        photos: photos,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  State<PhotoViewerDialog> createState() => _PhotoViewerDialogState();
}

class _PhotoViewerDialogState extends State<PhotoViewerDialog> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.photos.length;

    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            // Swipeable Interactive Viewer
            PageView.builder(
              controller: _pageController,
              itemCount: total,
              onPageChanged: (idx) => setState(() => _currentIndex = idx),
              itemBuilder: (context, index) {
                return Center(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    clipBehavior: Clip.none,
                    child: AppImageWidget(
                      photo: widget.photos[index],
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),

            // Top Header: Title & Close Button
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.75),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Issue Photo ${_currentIndex + 1} of $total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Arrows (if multiple photos)
            if (total > 1)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, color: Colors.white70, size: 36),
                      onPressed: _currentIndex > 0
                          ? () => _pageController.previousPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                              )
                          : null,
                    ),
                    const SizedBox(width: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / $total',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 36),
                      onPressed: _currentIndex < total - 1
                          ? () => _pageController.nextPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                              )
                          : null,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Helper bottom sheet to pick a photo from Camera, Gallery, or Curated Samples.
Future<void> showPhotoSourcePicker(
  BuildContext context, {
  required void Function(String photoData) onPhotoSelected,
  String title = 'Add Issue Photo',
  String subtitle = 'Attach photos of the issue to help workers understand the work required.',
  String presetsTitle = 'Sample Issue Presets (Demo)',
  String presetsSubtitle = 'Choose sample leak, electrical, or crack photo',
  String dialogTitle = 'Select Sample Photo',
  List<Map<String, String>>? customPresets,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // Option 1: Camera
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                ),
                title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Use device camera', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final picker = ImagePicker();
                    final file = await picker.pickImage(
                      source: ImageSource.camera,
                      maxWidth: 1024,
                      maxHeight: 1024,
                      imageQuality: 85,
                    );
                    if (file != null) {
                      final bytes = await file.readAsBytes();
                      final base64Str = base64Encode(bytes);
                      final mime = file.mimeType ?? 'image/jpeg';
                      onPhotoSelected('data:$mime;base64,$base64Str');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Camera error: $e')),
                      );
                    }
                  }
                },
              ),

              // Option 2: Choose from Gallery
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Pick from photos on this device', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final picker = ImagePicker();
                    final file = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1024,
                      maxHeight: 1024,
                      imageQuality: 85,
                    );
                    if (file != null) {
                      final bytes = await file.readAsBytes();
                      final base64Str = base64Encode(bytes);
                      final mime = file.mimeType ?? 'image/jpeg';
                      onPhotoSelected('data:$mime;base64,$base64Str');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gallery error: $e')),
                      );
                    }
                  }
                },
              ),

              // Option 3: Choose from Sample Presets (Instant 1-Click for Demo)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.orange),
                ),
                title: Text(presetsTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(presetsSubtitle, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showSamplePresetDialog(
                    context,
                    onPhotoSelected,
                    dialogTitle: dialogTitle,
                    presets: customPresets,
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showSamplePresetDialog(
  BuildContext context,
  void Function(String photoData) onPhotoSelected, {
  String dialogTitle = 'Select Sample Photo',
  List<Map<String, String>>? presets,
}) {
  final list = presets ?? SampleIssuePhotos.presets;
  showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(dialogTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 12),
            itemBuilder: (context, index) {
              final preset = list[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: AppImageWidget(
                    photo: preset['data']!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  preset['name']!,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                subtitle: Text(
                  preset['description']!,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onPhotoSelected(preset['data']!);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
}
