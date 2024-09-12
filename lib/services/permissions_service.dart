import 'package:permission_handler/permission_handler.dart';

class PermissionsService {
  Future<void> requestPermissions() async {
    await _requestPermission(Permission.camera);
    await _requestPermission(Permission.photos); // For iOS
    await _requestPermission(Permission.storage); // For Android
    await _requestPermission(Permission.notification);
  }

  Future<void> _requestPermission(Permission permission) async {
    var status = await permission.status;
    if (!status.isGranted) {
      await permission.request();
    }
  }
}