import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lovesync_mobile/app_routes.dart';
import 'package:lovesync_mobile/core/network/dio_client.dart';
import 'package:lovesync_mobile/features/couple/data/datasources/couple_remote_datasource.dart';
import 'package:lovesync_mobile/features/couple/data/repositories/couple_repository_impl.dart';
import 'package:lovesync_mobile/features/couple/domain/entities/invitation.dart';
import 'package:lovesync_mobile/features/couple/domain/usecases/get_invitation_pending.dart';
import 'package:lovesync_mobile/features/couple/domain/usecases/patch_accept_invitation.dart';
import 'package:lovesync_mobile/features/couple/domain/usecases/patch_reject_invitation.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class CoupleConfirmationPage extends StatefulWidget {
  const CoupleConfirmationPage({super.key});

  @override
  State<StatefulWidget> createState() => _coupleConfirmationPageState();
}

class _coupleConfirmationPageState extends State<CoupleConfirmationPage> {
  bool isLoading = false;

  List<Invitation> invitations = [];

  late final GetInvitationPending _getInvitationPending;
  late final PatchAcceptInvitation _patchAcceptInvitation;
  late final PatchRejectInvitation _patchRejectInvitation;

  @override
  void initState() {
    super.initState();

    _getInvitationPending = GetInvitationPending(
      CoupleRepositoryImpl(
        CoupleRemoteDatasource(context.read<DioClient>().dio),
      ),
    );

    _patchAcceptInvitation = PatchAcceptInvitation(
      CoupleRepositoryImpl(
        CoupleRemoteDatasource(context.read<DioClient>().dio),
      ),
    );

    _patchRejectInvitation = PatchRejectInvitation(
      CoupleRepositoryImpl(
        CoupleRemoteDatasource(context.read<DioClient>().dio),
      ),
    );

    _fetchInvitations();
  }

  Future<void> _fetchInvitations() async {
    setState(() {
      isLoading = true;
    });

    try {
      final result = await _getInvitationPending();
      setState(() {
        invitations = result;
      });
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thông Báo',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.pink,
          ),
        ),
        centerTitle: true,
      ),
      body: Skeletonizer(
        enabled: isLoading,
        child: (invitations.isEmpty)
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_off,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Không có lời mời nào',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: invitations.length,
                itemBuilder: (context, index) {
                  return _buildContent(invitations[index]);
                },
              ),
      ),
    );
  }

  Widget _buildContent(Invitation invitation) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(invitation.partnerAvatar),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invitation.partnerName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Đã chấp nhận lời mời kết đôi của bạn!',
                      style: TextStyle(fontSize: 16),
                      softWrap: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await _patchRejectInvitation.call(
                        invitation.invitationId,
                      );
                      _fetchInvitations();
                    } on DioException catch (e) {
                      if (e.response?.statusCode == 400) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lời mời đã hết hạn')),
                        );
                        _fetchInvitations();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã có lỗi xảy ra')),
                        );
                      }
                    }
                  },
                  child: Text('Từ Chối'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade500,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await _patchAcceptInvitation.call(
                        invitation.invitationId,
                      );
                      if (mounted) {
                        context.go(AppRoutes.couple);
                      }
                    } on DioException catch (e) {
                      if (e.response?.statusCode == 400) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lời mời đã hết hạn')),
                        );
                        _fetchInvitations();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã có lỗi xảy ra')),
                        );
                      }
                    }
                  },
                  child: Text('Đồng Ý'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
