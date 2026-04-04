import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class PhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Starts the phone verification process.
  /// [phoneNumber] must be in E.164 format (e.g., +94771234567).
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
    required Function(String verificationId) onCodeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
      forceResendingToken: forceResendingToken,
      timeout: const Duration(seconds: 60),
    );
  }

  /// Verifies the [smsCode] entered by the user against the [verificationId].
  Future<PhoneAuthCredential> getCredential({
    required String verificationId,
    required String smsCode,
  }) async {
    return PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }

  /// Signs in the user with the given [credential].
  Future<UserCredential> signInWithCredential(PhoneAuthCredential credential) async {
    return await _auth.signInWithCredential(credential);
  }
}
