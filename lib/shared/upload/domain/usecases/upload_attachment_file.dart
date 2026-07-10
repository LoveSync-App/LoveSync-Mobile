import 'dart:io';

import 'package:lovesync_mobile/shared/upload/domain/repositories/upload_repository.dart';

class UploadAttachmentFile {
  const UploadAttachmentFile(this._repository);

  final UploadRepository _repository;

  Future<String> call(File file) => _repository.uploadAttachmentFile(file);
}
