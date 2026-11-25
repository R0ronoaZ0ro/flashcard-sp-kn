import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (picked == null) {
      return null;
    }

    return _saveImage(picked);
  }

  Future<String> _saveImage(XFile file) async {
    final directory =
    await getApplicationDocumentsDirectory();

    final imagesDirectory = Directory(
      path.join(directory.path, 'flashcard_images'),
    );

    if (!await imagesDirectory.exists()) {
      await imagesDirectory.create(
        recursive: true,
      );
    }

    final extension =
    path.extension(file.path);

    final filename =
        '${const Uuid().v4()}$extension';

    final destination = path.join(
      imagesDirectory.path,
      filename,
    );

    await File(file.path).copy(destination);

    return destination;
  }

  Future<void> deleteImage(String? imagePath) async {
    if (imagePath == null) return;

    final file = File(imagePath);

    if (await file.exists()) {
      await file.delete();
    }
  }
}
