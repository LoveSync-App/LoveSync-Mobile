import 'package:flutter/material.dart';
import 'package:lovesync_mobile/features/couple/domain/entities/invitation.dart';
import 'package:skeletonizer/skeletonizer.dart';

class CoupleConfirmationPage extends StatefulWidget {
  const CoupleConfirmationPage({super.key});

  @override
  State<StatefulWidget> createState() => _coupleConfirmationPageState();
}

class _coupleConfirmationPageState extends State<CoupleConfirmationPage> {
  bool isLoading = false;

  List<Invitation> invitations = [
    Invitation(
      invitationId: '1',
      partnerName: 'Nguyễn Văn A',
      partnerAvatar:
          'https://i.pinimg.com/550x/0a/2f/68/0a2f68448ab64c7fb67e75ef410de163.jpg',
    ),
    Invitation(
      invitationId: '2',
      partnerName: 'Trần Thị B',
      partnerAvatar:
          'https://i.pinimg.com/550x/0a/2f/68/0a2f68448ab64c7fb67e75ef410de163.jpg',
    ),
    Invitation(
      invitationId: '1',
      partnerName: 'Nguyễn Văn A',
      partnerAvatar:
          'https://i.pinimg.com/550x/0a/2f/68/0a2f68448ab64c7fb67e75ef410de163.jpg',
    ),
    Invitation(
      invitationId: '2',
      partnerName: 'Trần Thị B',
      partnerAvatar:
          'https://i.pinimg.com/550x/0a/2f/68/0a2f68448ab64c7fb67e75ef410de163.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
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
        child: ListView.builder(
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
                  onPressed: () {},
                  child: Text('Từ Chối'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade500,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(onPressed: () {}, child: Text('Đồng Ý')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
