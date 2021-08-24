import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DataSaver {
  List<double> _points = [];
  static const int MAX_LENGTH = 100000;
  File? _file;
  Directory? externalStorageDir;


  DataSaver() {
    getExternalStorageDirectory().then((value) {
      externalStorageDir = value;
    });
  }

  void add(double point) {
    _points.add(point);
    _savePoint(point);
  }

  void close() {
    _file = null;
  }

  Future<void> _savePoint(double p) async {
    if (_file == null || _points.length > MAX_LENGTH) {
      _file = new File("${externalStorageDir!.path}/mindWave_${DateTime.now().toString()}.txt");
      _file!.writeAsString('\n${p}', mode: FileMode.append);
    } else {
      _file!.writeAsString('\n${p}', mode: FileMode.append);
    }
  }

  Future<String> _saveToDownloads(String name) async {
    if (_file != null) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        if (await Permission.storage.request().isDenied) {
          return "Not granted";
        }
      }

      var filePath = "${(await getExternalStorageDirectory())!.path}/${name}";
      var file = File(filePath);
      await file.create(recursive: true);
      await _file!.copy(filePath);
      return "Saved to ${filePath}";
    }
    return "No data yet";
  }

}