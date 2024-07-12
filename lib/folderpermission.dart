import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> createFolder() async {
  var status = await Permission.manageExternalStorage.request();
  if (status.isGranted) {
      if (!Platform.isAndroid) {
        throw UnsupportedError('This feature is only available on Android');
      }

      // Get external storage directory
      Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        throw Exception('Failed to get external storage directory');
      }

      final pixDirectory = Directory('/storage/emulated/0/PR');

      if (await pixDirectory.exists()) {
        print('Folder already exists');
      } else {
        await pixDirectory.create();
        print('Folder created');
      }

  } else if (status.isPermanentlyDenied) {
    openAppSettings();
  }

}
