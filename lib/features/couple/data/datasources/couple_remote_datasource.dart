import 'package:dio/dio.dart';
import 'package:lovesync_mobile/features/couple/data/models/couple_code_modal.dart';
import 'package:lovesync_mobile/features/couple/data/models/couple_day_modal.dart';
import 'package:lovesync_mobile/features/couple/data/models/couple_modal.dart';
import 'package:lovesync_mobile/features/couple/data/models/invitation_modal.dart';
import 'package:lovesync_mobile/features/couple/data/models/partner_modal.dart';

class CoupleRemoteDatasource {
  final Dio dio;
  CoupleRemoteDatasource(this.dio);

  Future<CoupleCodeModal> getMyCoupleCode() async {
    final response = await dio.get('/couples/code/me');
    return CoupleCodeModal.fromJson(response.data['data']);
  }

  Future<PartnerModal> getPartnerByCode(String code) async {
    final response = await dio.get('/couples/code/$code');
    return PartnerModal.fromJson(response.data['data']);
  }

  Future<CoupleModal> getMyCouple() async {
    final response = await dio.get('/couples/me');
    return CoupleModal.fromJson(response.data['data']);
  }

  Future<CoupleDayModal> getCoupleDays() async {
    final response = await dio.get('/couples/me/love-days');
    return CoupleDayModal.fromJson(response.data['data']);
  }

  Future<void> createCouple(String code) async {
    await dio.post('/couples/code/$code');
  }

  Future<List<InvitationModal>> getInvitationsPending() async {
    final response = await dio.get('/couples/invitations/PENDING');
    List<InvitationModal> invitations = (response.data['data'] as List)
        .map((invitation) => InvitationModal.fromJson(invitation))
        .toList();
    return invitations;
  }

  Future<void> acceptInvitation(String invitationId) async {
    await dio.patch('/couples/invitations/$invitationId/accept');
  }

  Future<void> rejectInvitation(String invitationId) async {
    await dio.patch('/couples/invitations/$invitationId/reject');
  }
}
