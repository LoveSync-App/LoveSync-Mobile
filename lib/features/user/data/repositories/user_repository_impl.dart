import 'package:lovesync_mobile/features/user/data/datasources/user_remote_datasource.dart';
import 'package:lovesync_mobile/features/user/data/models/user_response_model.dart';
import 'package:lovesync_mobile/features/user/domain/entities/user_response.dart';
import 'package:lovesync_mobile/features/user/domain/repositories/user_repository.dart';

class UserRepositoryImpl extends UserRepository {
  final UserRemoteDatasource userRemoteDatasource;
  UserRepositoryImpl(this.userRemoteDatasource);

  @override
  Future<UserResponse> getUserInfo() async {
    final userResponseModel = await userRemoteDatasource.getUserInfo();
    return UserResponse(
      id: userResponseModel.id,
      email: userResponseModel.email,
      name: userResponseModel.name,
      phone: userResponseModel.phone,
      status: userResponseModel.status,
      avatar: userResponseModel.avatar,
    );
  }

  @override
  Future<UserResponse> updateMe({
    required String name,
    required String phone,
    required String avatar,
  }) async {
    final userResponseModel = await userRemoteDatasource.updateMe(
      name: name,
      phone: phone,
      avatar: avatar,
    );
    return _mapToEntity(userResponseModel);
  }

  @override
  Future<UserResponse> deleteMe() async {
    final userResponseModel = await userRemoteDatasource.deleteMe();
    return _mapToEntity(userResponseModel);
  }

  @override
  Future<void> postRegisterToken(String token) {
    return userRemoteDatasource.postRegisterToken(token);
  }

  UserResponse _mapToEntity(UserResponseModel userResponseModel) {
    return UserResponse(
      id: userResponseModel.id,
      email: userResponseModel.email,
      name: userResponseModel.name,
      phone: userResponseModel.phone,
      status: userResponseModel.status,
      avatar: userResponseModel.avatar,
    );
  }
}
