import 'package:image_picker/image_picker.dart';

enum PhotoSource { camera, gallery }

abstract interface class PhotoPicker {
  Future<String?> pick(PhotoSource source);
}

class DevicePhotoPicker implements PhotoPicker {
  DevicePhotoPicker({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<String?> pick(PhotoSource source) async {
    final image = await _picker.pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 2048,
      maxHeight: 2048,
      requestFullMetadata: false,
    );
    return image?.path;
  }
}
