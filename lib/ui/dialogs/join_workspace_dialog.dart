import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../l10n/app_localizations.dart';

import '../../utils/error_display.dart';

/// Pulls an invite token out of a raw code, a path URL, or a hash URL
/// such as `https://peertask.pages.dev/#/join/<token>`.
String? extractInviteToken(String raw) {
  final input = raw.trim();
  if (input.isEmpty) return null;

  final uri = Uri.tryParse(input);
  if (uri == null || !uri.hasScheme) {
    final parts = input.split(RegExp(r'[?#\s]')).first.split('/').where((part) => part.isNotEmpty);
    if (parts.isEmpty) return null;
    return parts.last;
  }

  final queryToken = uri.queryParameters['token'];
  if (queryToken != null && queryToken.isNotEmpty) return queryToken;

  if (uri.fragment.isNotEmpty) {
    final parts = uri.fragment.split('/').where((part) => part.isNotEmpty);
    if (parts.isNotEmpty) return parts.last;
  }

  if (uri.pathSegments.isNotEmpty) return uri.pathSegments.last;
  return null;
}

class JoinWorkspaceDialog extends StatefulWidget {
  const JoinWorkspaceDialog({super.key});

  @override
  State<JoinWorkspaceDialog> createState() => _JoinWorkspaceDialogState();
}

class _JoinWorkspaceDialogState extends State<JoinWorkspaceDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _linkController = TextEditingController();
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  void _submit(String? token) {
    if (_sent || token == null || token.isEmpty) return;
    _sent = true;
    Navigator.pop(context, token);
  }

  void _joinWithLink() {
    final token = extractInviteToken(_linkController.text);
    if (token == null) {
      context.showWarningMessage(AppLocalizations.of(context)!.inviteCode);
      return;
    }
    _submit(token);
  }

  void _onQRScanned(BarcodeCapture capture) {
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    _submit(extractInviteToken(raw));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final media = MediaQuery.sizeOf(context);
    final width = media.width > 460 ? 420.0 : media.width - 40;
    final tabHeight = (media.height * 0.42).clamp(220.0, 320.0);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.group_add_rounded, color: Color(0xFF172B4D)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.joinWorkspace,
                      style: const TextStyle(
                        color: Color(0xFF172B4D),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF172B4D),
              unselectedLabelColor: const Color(0xFF6B778C),
              indicatorColor: const Color(0xFF172B4D),
              tabs: [
                Tab(icon: const Icon(Icons.link_rounded), text: l10n.inviteLink),
                Tab(icon: const Icon(Icons.qr_code_scanner), text: l10n.scanQR),
              ],
            ),
            SizedBox(
              height: tabHeight,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLinkTab(l10n),
                  _tabController.index == 1 ? _buildQRScanTab(l10n) : const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _linkController,
            decoration: InputDecoration(
              labelText: l10n.inviteCode,
              prefixIcon: const Icon(Icons.link),
              border: const OutlineInputBorder(),
            ),
            minLines: 1,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _sent ? null : _joinWithLink,
            icon: const Icon(Icons.check),
            label: Text(l10n.joinWorkspace),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF172B4D),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.scanQROrCopy,
            style: const TextStyle(color: Color(0xFF6B778C), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildQRScanTab(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE4E7EB)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MobileScanner(
                  onDetect: _onQRScanned,
                  errorBuilder: (context, error, child) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        l10n.scanQROrCopy,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF6B778C)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.scanQRToJoin,
            style: const TextStyle(color: Color(0xFF6B778C), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
