import 'dart:io';

import 'package:image_picker/image_picker.dart';

import 'supabase_config.dart';

final _picker = ImagePicker();

/// Picks an image from the gallery, uploads it to the `photos` bucket in
/// Supabase Storage, and returns the public URL.
///
/// [folder] is the storage path prefix, e.g. `coffees`, `roasters`, or
/// `check-ins`. Files are stored as `{userId}/{folder}/{timestamp}.{ext}`.
///
/// Returns `null` if the user cancels the picker.
Future<String?> pickAndUploadImage({required String folder}) async {
  final picked = await _picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 1200,
    imageQuality: 85,
  );
  if (picked == null) return null;

  final userId = supabase.auth.currentUser?.id;
  if (userId == null) throw Exception('Must be signed in to upload photos.');

  final file = File(picked.path);
  final ext = picked.path.split('.').last;
  final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
  final storagePath = '$userId/$folder/$fileName';

  await supabase.storage.from('photos').upload(storagePath, file);

  return supabase.storage.from('photos').getPublicUrl(storagePath);
}
