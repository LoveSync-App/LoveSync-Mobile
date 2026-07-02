import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseGoogleIdentity {
  const FirebaseGoogleIdentity({
    required this.firebaseIdToken,
    required this.name,
    required this.avatar,
  });

  final String firebaseIdToken;
  final String name;
  final String avatar;
}

class GoogleAuthDatasource {
  GoogleAuthDatasource({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  bool _initialized = false;

  Future<FirebaseGoogleIdentity> signIn() async {
    if (!_initialized) {
      await _googleSignIn.initialize();
      _initialized = true;
    }

    final googleAccount = await _googleSignIn.authenticate();
    final googleAuthentication = googleAccount.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuthentication.idToken,
    );
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final firebaseUser = userCredential.user;
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'missing-firebase-user',
        message: 'Firebase không trả về người dùng.',
      );
    }

    final firebaseIdToken = await firebaseUser.getIdToken(true);
    if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-id-token',
        message: 'Không lấy được Firebase ID token.',
      );
    }

    final name = firebaseUser.displayName?.trim().isNotEmpty == true
        ? firebaseUser.displayName!.trim()
        : googleAccount.displayName?.trim().isNotEmpty == true
        ? googleAccount.displayName!.trim()
        : googleAccount.email.split('@').first;
    final avatar = firebaseUser.photoURL?.trim().isNotEmpty == true
        ? firebaseUser.photoURL!.trim()
        : googleAccount.photoUrl?.trim().isNotEmpty == true
        ? googleAccount.photoUrl!.trim()
        : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}';

    return FirebaseGoogleIdentity(
      firebaseIdToken: firebaseIdToken,
      name: name,
      avatar: avatar,
    );
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    if (!_initialized) {
      await _googleSignIn.initialize();
      _initialized = true;
    }
    await _googleSignIn.signOut();
  }
}
