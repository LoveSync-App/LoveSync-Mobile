import 'dart:io';

import 'package:lovesync_mobile/shared/upload/domain/repositories/upload_repository.dart';

class UploadFile {
  final UploadRepository repository;
  UploadFile(this.repository);

  Future<String> call(File file) async {
    return await repository.uploadFile(file);
  }
}
