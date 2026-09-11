import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoService {
  static final DeviceInfoPlugin _plugin = DeviceInfoPlugin();

  static Future<String> displayName() async {
    try {
      if (Platform.isAndroid) {
        final info = await _plugin.androidInfo;
        final model = info.model.trim();
        return model.isEmpty ? 'Android device' : '$model (Android)';
      }
      if (Platform.isIOS) {
        final info = await _plugin.iosInfo;
        final model = info.utsname.machine.trim();
        return model.isEmpty ? 'iPhone (iOS)' : '$model (iOS)';
      }
    } catch (_) {
      // Login can continue if device metadata is unavailable.
    }
    return 'Mobile device';
  }
}
