import 'dart:io';

abstract class UploadRepository {
  Future<String> uploadFile(File file);
  Future<String> uploadAttachmentFile(File file);
}
