import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nota_note/pages/memo_page/widgets/pdf_loading_page.dart';
import 'package:nota_note/theme/colors.dart';
import 'package:nota_note/viewmodels/pin_viewmodel.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:nota_note/pages/memo_page/widgets/quill_to_pdf_converter.dart';

class PopupMenuWidget extends ConsumerWidget {
  final VoidCallback onClose;
  final String groupId;
  final String noteId;
  final quill.QuillController quillController;
  final String role;

  const PopupMenuWidget({
    required this.onClose,
    required this.groupId,
    required this.noteId,
    required this.quillController,
    required this.role,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerParams = {'groupId': groupId, 'noteId': noteId};

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 181,
        height: 270,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: ShapeDecoration(
          color: const Color(0xFFF0F0F0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _buildMenuContent(context, ref, providerParams),
      ),
    );
  }

  Widget _buildMenuContent(
      BuildContext context, WidgetRef ref, Map<String, String> providerParams) {
    return StreamBuilder<bool>(
      stream: ref
          .read(pinViewModelProvider(providerParams).notifier)
          .getPinStatusStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading pin status'));
        }
        final pinStatus = snapshot.data ?? false;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMenuItem(
              icon: 'assets/icons/PushPin.svg',
              text: pinStatus ? '고정 해제하기' : '고정하기',
              iconColor: pinStatus ? const Color(0xFF61CFB2) : null,
              onTap: () => ref
                  .read(pinViewModelProvider(providerParams).notifier)
                  .togglePinStatus(),
            ),
            _buildMenuItem(
              icon: 'assets/icons/Files.svg',
              text: '복제하기',
              onTap: () {}, // TODO: Implement duplicate functionality
            ),
            _buildMenuItem(
              icon: 'assets/icons/FileArrowUp.svg',
              text: '이동하기',
              onTap: () {}, // TODO: Implement move functionality
            ),
            if (role == 'owner' || role == 'editor')
              _buildMenuItem(
                icon: 'assets/icons/Delete.svg',
                text: '삭제하기',
                textColor: const Color(0xFFFF2F2F),
                onTap: () {}, // TODO: Implement delete functionality
              ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Divider(),
            ),
            _buildMenuItem(
              icon: 'assets/icons/FilePdf.svg',
              text: '내보내기',
              onTap: () {
                onClose();
                // 로딩 및 PDF 생성 페이지로 이동
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PdfLoadingPage(
                      document: quillController.document,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuItem({
    required String icon,
    required String text,
    Color? iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            const SizedBox(width: 20),
            SvgPicture.asset(
              icon,
              width: 20,
              height: 20,
              color: iconColor,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: textColor ?? const Color(0xFF4C4C4C),
                fontSize: 16,
                fontFamily: 'Pretendard',
                height: 0.09,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
