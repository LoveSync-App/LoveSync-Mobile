import 'package:lovesync_mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:lovesync_mobile/features/auth/domain/entities/login_response.dart';
import 'package:lovesync_mobile/features/auth/domain/entities/register_response.dart';
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
      avatar: loginResponseModel.user.avatar,
      accessToken: loginResponseModel.accessToken,
      refreshToken: loginResponseModel.refreshToken,
      e2eeSetupRequired: loginResponseModel.user.e2eeSetupRequired,
    );
  }

  @override
  Future<LoginResponse> loginWithGoogle({
    required String firebaseIdToken,
    required String name,
    required String avatar,
  }) async {
    final model = await remoteDatasource.loginWithGoogle(
      firebaseIdToken: firebaseIdToken,
      name: name,
      avatar: avatar,
    );
    return LoginResponse(
      id: model.user.id,
      name: model.user.name,
      email: model.user.email,
      avatar: model.user.avatar,
      accessToken: model.accessToken,
      refreshToken: model.refreshToken,
      e2eeSetupRequired: model.user.e2eeSetupRequired,
    );
  }

  @override
  Future<RegisterResponse> register(
    String email,
    String password,
    String passwordConfirm,
    String name,
  ) async {
    final registerResponseModel = await remoteDatasource.register(
      email,
      password,
      passwordConfirm,
      name,
    );
    return RegisterResponse(
      id: registerResponseModel.id,
      name: registerResponseModel.name,
      email: registerResponseModel.email,
      avatar: registerResponseModel.avatar,
    );
  }
}
