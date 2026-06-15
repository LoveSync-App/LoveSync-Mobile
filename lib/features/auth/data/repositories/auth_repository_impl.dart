import 'package:lovesync_mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:lovesync_mobile/features/auth/domain/entities/login_response.dart';
import 'package:lovesync_mobile/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl extends AuthRepository {
  final AuthRemoteDatasource remoteDatasource;
  AuthRepositoryImpl(this.remoteDatasource);

  @override
  Future<LoginResponse> login(String email, String password) async {
    final loginResponseModel = await remoteDatasource.login(email, password);
    return LoginResponse(
      id: loginResponseModel.user.id,
      name: loginResponseModel.user.name,
      email: loginResponseModel.user.email,
      accessToken: loginResponseModel.accessToken,
    );
  }
}
