import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/supabase/image_upload.dart';
import '../core/theme/app_colors.dart' show AppColors, kTransitionCurve, kTransitionDuration;
import '../core/theme/app_text_styles.dart';

/// A tappable tile that lets the user pick a photo from their gallery, uploads
/// it to Supabase Storage, and displays a thumbnail preview.
///
/// [folder] is the Storage path prefix (e.g. `coffees`, `roasters`).
/// [imageUrl] is the current URL (if any) to show as preview.
/// [onUploaded] fires with the public URL after a successful upload.
class PhotoPickerTile extends StatefulWidget {
  const PhotoPickerTile({
    super.key,
    required this.folder,
    this.imageUrl,
    required this.onUploaded,
    this.label = 'Add Photo',
    this.height = 160,
  });

  final String folder;
  final String? imageUrl;
  final ValueChanged<String> onUploaded;
  final String label;
  final double height;

  @override
  State<PhotoPickerTile> createState() => _PhotoPickerTileState();
}

class _PhotoPickerTileState extends State<PhotoPickerTile> {
  bool _isUploading = false;

  Future<void> _pick() async {
    setState(() => _isUploading = true);

    try {
      final url = await pickAndUploadImage(folder: widget.folder);
      if (url != null && mounted) {
        widget.onUploaded(url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isUploading ? null : _pick,
      child: AnimatedContainer(
        duration: kTransitionDuration,
        curve: kTransitionCurve,
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: _isUploading
            ? const Center(child: CircularProgressIndicator())
            : widget.imageUrl != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: widget.imageUrl!,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Change',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_a_photo_outlined,
                        size: 32,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.label,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
