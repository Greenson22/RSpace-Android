import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class PathService {
  Future<String> get perpuskuDataPath async {
    final directory = await getApplicationDocumentsDirectory();
    return path.join(directory.path, 'PerpusKu');
  }
}
