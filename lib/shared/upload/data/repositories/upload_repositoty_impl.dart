import 'dart:io';

import 'package:lovesync_mobile/shared/upload/data/datasources/upload_remote_datasource.dart';
import 'package:lovesync_mobile/shared/upload/domain/repositories/upload_repository.dart';

class UploadRepositotyImpl extends UploadRepository {
  final UploadRemoteDatasource uploadRemoteDatasource;
  UploadRepositotyImpl(this.uploadRemoteDatasource);

  @override
  Future<String> uploadFile(File file) async {
    return await uploadRemoteDatasource.uploadFile(file.path);
  }

  @override
  Future<String> uploadAttachmentFile(File file) {
    return uploadRemoteDatasource.uploadAttachmentFile(file.path);
  }
}
