import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/strings.dart';
import '../widgets/custom_dialog.dart';

class PermissionUtils {
  PermissionUtils._();

  // Check if microphone permission is granted
  static Future<bool> hasMicrophonePermission() async {
    return await Permission.microphone.status.isGranted;
  }

  // Request microphone permission
  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  // Check if storage permission is granted
  static Future<bool> hasStoragePermission() async {
    return await Permission.storage.status.isGranted;
  }

  // Request storage permission
  static Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  // Check if camera permission is granted
  static Future<bool> hasCameraPermission() async {
    return await Permission.camera.status.isGranted;
  }

  // Request camera permission
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  // Check if notification permission is granted
  static Future<bool> hasNotificationPermission() async {
    return await Permission.notification.status.isGranted;
  }

  // Request notification permission
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  // Check and request microphone permission with dialog
  static Future<bool> checkAndRequestMicrophone(BuildContext context) async {
    if (await hasMicrophonePermission()) {
      return true;
    }

    // Show rationale dialog
    final shouldRequest = await _showPermissionRationale(
      context,
      title: Strings.microphonePermission,
      content: 'แอปต้องการสิทธิ์ใช้ไมโครโฟนเพื่อรับฟังคำสั่งเสียงของคุณ',
      icon: Icons.mic,
    );

    if (!shouldRequest) return false;

    final granted = await requestMicrophonePermission();

    if (!granted) {
      await _showPermissionDenied(
        context,
        title: Strings.microphonePermissionDenied,
        content: 'กรุณาอนุญาตการใช้ไมโครโฟนในการตั้งค่าแอป',
      );
    }

    return granted;
  }

  // Check and request storage permission with dialog
  static Future<bool> checkAndRequestStorage(BuildContext context) async {
    if (await hasStoragePermission()) {
      return true;
    }

    final shouldRequest = await _showPermissionRationale(
      context,
      title: Strings.storagePermission,
      content: 'แอปต้องการสิทธิ์เข้าถึงที่เก็บข้อมูลเพื่อบันทึกไฟล์',
      icon: Icons.folder,
    );

    if (!shouldRequest) return false;

    final granted = await requestStoragePermission();

    if (!granted) {
      await _showPermissionDenied(
        context,
        title: Strings.storagePermissionDenied,
        content: 'กรุณาอนุญาตการเข้าถึงที่เก็บข้อมูลในการตั้งค่าแอป',
      );
    }

    return granted;
  }

  // Check and request camera permission with dialog
  static Future<bool> checkAndRequestCamera(BuildContext context) async {
    if (await hasCameraPermission()) {
      return true;
    }

    final shouldRequest = await _showPermissionRationale(
      context,
      title: Strings.cameraPermission,
      content: 'แอปต้องการสิทธิ์ใช้กล้องเพื่อถ่ายรูป',
      icon: Icons.camera_alt,
    );

    if (!shouldRequest) return false;

    final granted = await requestCameraPermission();

    if (!granted) {
      await _showPermissionDenied(
        context,
        title: 'ไม่อนุญาตให้ใช้กล้อง',
        content: 'กรุณาอนุญาตการใช้กล้องในการตั้งค่าแอป',
      );
    }

    return granted;
  }

  // Check and request notification permission
  static Future<bool> checkAndRequestNotification(BuildContext context) async {
    if (await hasNotificationPermission()) {
      return true;
    }

    final shouldRequest = await _showPermissionRationale(
      context,
      title: Strings.notificationPermission,
      content: 'แอปต้องการสิทธิ์การแจ้งเตือนเพื่อส่งข้อความสำคัญให้คุณ',
      icon: Icons.notifications,
    );

    if (!shouldRequest) return false;

    final granted = await requestNotificationPermission();
    return granted;
  }

  // Check multiple permissions at once
  static Future<Map<Permission, bool>> checkMultiplePermissions(
      List<Permission> permissions,
      ) async {
    final Map<Permission, bool> results = {};

    for (final permission in permissions) {
      results[permission] = await permission.status.isGranted;
    }

    return results;
  }

  // Request multiple permissions at once
  static Future<Map<Permission, bool>> requestMultiplePermissions(
      List<Permission> permissions,
      ) async {
    final Map<Permission, bool> results = {};

    for (final permission in permissions) {
      final status = await permission.request();
      results[permission] = status.isGranted;
    }

    return results;
  }

  // Show permission rationale dialog
  static Future<bool> _showPermissionRationale(
      BuildContext context, {
        required String title,
        required String content,
        IconData? icon,
      }) async {
    return await ConfirmDialog.show(
      context,
      title: title,
      content: content,
      confirmText: Strings.grantPermission,
      cancelText: Strings.denyPermission,
      icon: icon,
    );
  }

  // Show permission denied dialog
  static Future<void> _showPermissionDenied(
      BuildContext context, {
        required String title,
        required String content,
      }) async {
    final shouldOpenSettings = await ConfirmDialog.show(
      context,
      title: title,
      content: '$content\n\nคุณต้องการเปิดการตั้งค่าเพื่ออนุญาตสิทธิ์หรือไม่?',
      confirmText: 'เปิดการตั้งค่า',
      cancelText: Strings.cancel,
      icon: Icons.settings,
    );

    if (shouldOpenSettings) {
      await openAppSettings();
    }
  }

  // Open app settings
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }

  // Check if permission is permanently denied
  static Future<bool> isPermissionPermanentlyDenied(Permission permission) async {
    final status = await permission.status;
    return status.isPermanentlyDenied;
  }

  // Get permission status text
  static String getPermissionStatusText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'อนุญาตแล้ว';
      case PermissionStatus.denied:
        return 'ไม่อนุญาต';
      case PermissionStatus.restricted:
        return 'ถูกจำกัด';
      case PermissionStatus.limited:
        return 'อนุญาตบางส่วน';
      case PermissionStatus.permanentlyDenied:
        return 'ไม่อนุญาตถาวร';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }

  // Get required permissions for voice features
  static List<Permission> getVoicePermissions() {
    return [Permission.microphone];
  }

  // Get required permissions for file operations
  static List<Permission> getFilePermissions() {
    return [Permission.storage];
  }

  // Get required permissions for camera features
  static List<Permission> getCameraPermissions() {
    return [Permission.camera, Permission.storage];
  }

  // Check all app permissions
  static Future<Map<String, bool>> checkAllAppPermissions() async {
    final results = <String, bool>{};

    results['microphone'] = await hasMicrophonePermission();
    results['storage'] = await hasStoragePermission();
    results['camera'] = await hasCameraPermission();
    results['notification'] = await hasNotificationPermission();

    return results;
  }

  // Show permission settings dialog
  static Future<void> showPermissionSettings(BuildContext context) async {
    final permissions = await checkAllAppPermissions();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('สิทธิ์การใช้งาน'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPermissionTile('ไมโครโฟน', permissions['microphone'] ?? false),
            _buildPermissionTile('ที่เก็บข้อมูล', permissions['storage'] ?? false),
            _buildPermissionTile('กล้อง', permissions['camera'] ?? false),
            _buildPermissionTile('การแจ้งเตือน', permissions['notification'] ?? false),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ปิด'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('ตั้งค่า'),
          ),
        ],
      ),
    );
  }

  // Build permission tile widget
  static Widget _buildPermissionTile(String title, bool granted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            granted ? Icons.check_circle : Icons.cancel,
            color: granted ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
          Text(
            granted ? 'อนุญาต' : 'ไม่อนุญาต',
            style: TextStyle(
              color: granted ? Colors.green : Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}