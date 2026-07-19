import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

enum E2eeRecoveryCodeMode { create, recover }

Future<String?> showE2eeRecoveryCodeSheet({
  required BuildContext context,
  required E2eeRecoveryCodeMode mode,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    showDragHandle: false,
    builder: (context) => _E2eeRecoveryCodeSheet(mode: mode),
  );
}

class _E2eeRecoveryCodeSheet extends StatefulWidget {
  const _E2eeRecoveryCodeSheet({required this.mode});

  final E2eeRecoveryCodeMode mode;

  @override
  State<_E2eeRecoveryCodeSheet> createState() => _E2eeRecoveryCodeSheetState();
}

class _E2eeRecoveryCodeSheetState extends State<_E2eeRecoveryCodeSheet> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _codeController.text.trim();
    final confirm = _confirmController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      _showMessage('Mã khôi phục phải gồm đúng 6 số.');
      return;
    }
    if (widget.mode == E2eeRecoveryCodeMode.create && code != confirm) {
      _showMessage('Mã nhập lại không khớp.');
      return;
    }
    Navigator.of(context).pop(code);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.mode == E2eeRecoveryCodeMode.create;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(22, 20, 22, bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFE7ED),
                  ),
                  child: const Icon(
                    Icons.enhanced_encryption_rounded,
                    color: Color(0xFFA03B56),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isCreate ? 'Tạo mã khôi phục' : 'Nhập mã khôi phục',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isCreate
                  ? 'Mã 6 số này dùng để khóa private key của bạn. Hãy ghi nhớ vì server không lưu mã này.'
                  : 'Thiết bị này cần mã 6 số để mở private key và đọc tin nhắn đã mã hóa.',
              style: const TextStyle(color: Color(0xFF62676D), height: 1.35),
            ),
            const SizedBox(height: 20),
            Center(
              child: Pinput(
                controller: _codeController,
                length: 6,
                autofocus: true,
                keyboardType: TextInputType.number,
                obscureText: true,
              ),
            ),
            if (isCreate) ...[
              const SizedBox(height: 16),
              const Text(
                'Nhập lại mã',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Center(
                child: Pinput(
                  controller: _confirmController,
                  length: 6,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                ),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA03B56),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(isCreate ? 'Tạo khóa mã hóa' : 'Khôi phục khóa'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nếu mất mã này, các tin nhắn cũ đã mã hóa sẽ không thể khôi phục.',
              style: TextStyle(
                color: Colors.orange.shade800,
                fontSize: 12,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
