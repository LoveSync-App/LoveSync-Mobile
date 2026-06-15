import 'package:lovesync_mobile/features/user/data/datasources/user_remote_datasource.dart';
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
      avatar: userResponseModel.avatar,
    );
  }
  
  @override
  Future<void> postRegisterToken(String token) {
    return userRemoteDatasource.postRegisterToken(token);
  }
}
