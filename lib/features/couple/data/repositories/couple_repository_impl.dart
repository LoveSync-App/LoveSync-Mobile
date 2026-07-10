import 'package:lovesync_mobile/features/couple/data/datasources/couple_remote_datasource.dart';
import 'package:lovesync_mobile/features/couple/data/models/couple_code_modal.dart';
import 'package:lovesync_mobile/features/couple/data/models/couple_modal.dart';
import 'package:lovesync_mobile/features/couple/data/models/invitation_modal.dart';
import 'package:lovesync_mobile/features/couple/data/models/partner_modal.dart';
import 'package:lovesync_mobile/features/couple/domain/entities/couple.dart';
import 'package:lovesync_mobile/features/couple/domain/entities/couple_code.dart';
import 'package:lovesync_mobile/features/couple/domain/entities/couple_day.dart';
import 'package:lovesync_mobile/features/couple/domain/entities/invitation.dart';
import 'package:lovesync_mobile/features/couple/domain/entities/partner.dart';
import 'package:lovesync_mobile/features/couple/domain/repositories/couple_repository.dart';

import '../models/couple_day_modal.dart';

class CoupleRepositoryImpl implements CoupleRepository {
  final CoupleRemoteDatasource remoteDatasource;

  CoupleRepositoryImpl(this.remoteDatasource);

  @override
  Future<CoupleCode> getMyCoupleCode() async {
    CoupleCodeModal result = await remoteDatasource.getMyCoupleCode();
    return CoupleCode(userId: result.userId, code: result.code);
  }

  @override
  Future<Partner> getPartnerByCode(String code) async {
    PartnerModal result = await remoteDatasource.getPartnerByCode(code);
    return Partner(
      id: result.partnerId,
      name: result.partnerName,
      avatar: result.partnerAvatar,
      email: result.partnerEmail,
      phone: result.partnerPhone,
    );
  }

  @override
  Future<Couple> getMyCouple() async {
    CoupleModal result = await remoteDatasource.getMyCouple();
    return Couple(
      coupleId: result.coupleId,
      userId: result.userId,
      userName: result.userName,
      userAvatar: result.userAvatar,
      userEmail: result.userEmail,
      partnerId: result.partnerId,
      partnerName: result.partnerName,
      partnerAvatar: result.partnerAvatar,
      partnerEmail: result.partnerEmail,
    );
  }

  @override
  Future<CoupleDay> getCoupleDays() async {
    CoupleDayModal result = await remoteDatasource.getCoupleDays();
    return CoupleDay(loveDays: result.loveDays);
  }

  @override
  Future<void> createCouple(String code) async {
    return await remoteDatasource.createCouple(code);
  }

  @override
  Future<void> unlinkCouple() {
    return remoteDatasource.unlinkCouple();
  }

  @override
  Future<void> acceptInvitation(String invitationId) async {
    await remoteDatasource.acceptInvitation(invitationId);
  }

  @override
  Future<List<Invitation>> getInvitationsPending() async {
    List<InvitationModal> result = await remoteDatasource
        .getInvitationsPending();
    return result
        .map(
          (invitation) => Invitation(
            invitationId: invitation.invitationId,
            partnerName: invitation.partnerName,
            partnerAvatar: invitation.partnerAvatar,
          ),
        )
        .toList();
  }

  @override
  Future<void> rejectInvitation(String invitationId) async {
    await remoteDatasource.rejectInvitation(invitationId);
  }
}
