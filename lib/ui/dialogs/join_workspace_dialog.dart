import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../l10n/app_localizations.dart';

import '../../utils/error_display.dart';
class JoinWorkspaceDialog extends StatefulWidget {
  final Function(String token) onJoinWithToken;

  const JoinWorkspaceDialog({
    super.key,
    required this.onJoinWithToken,
  });

  @override
  State<JoinWorkspaceDialog> createState() => _JoinWorkspaceDialogState();
}

class _JoinWorkspaceDialogState extends State<JoinWorkspaceDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _linkController = TextEditingController();
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  String? _extractToken(String input) {
    // Extract token from full URL or use as-is if already a token
    final uri = Uri.tryParse(input);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    return input.trim();
  }

  Future<void> _joinWithLink() async {
    final token = _extractToken(_linkController.text);
    if (token == null || token.isEmpty) {
      final l10n = AppLocalizations.of(context);
      context.showWarningMessage('Please enter a valid invite link');
      return;
    }

    setState(() => _isJoining = true);

    try {
      await widget.onJoinWithToken(token);
      if (mounted) {
        Navigator.pop(context);
        final l10n = AppLocalizations.of(context);
        context.showSuccessMessage(l10n?.joinedSuccessfully ?? 'Successfully joined workspace!');
      }
    } catch (e) {
      setState(() => _isJoining = false);
      if (mounted) {
        context.showErrorSnackBar(e);
      }
    }
  }

  void _onQRScanned(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue != null) {
      final token = _extractToken(barcode!.rawValue!);
      if (token != null) {
        widget.onJoinWithToken(token);
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.login, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Join Workspace',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: Colors.green,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.green,
              tabs: const [
                Tab(icon: Icon(Icons.link), text: 'Invite Link'),
                Tab(icon: Icon(Icons.qr_code_scanner), text: 'Scan QR'),
              ],
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLinkTab(),
                  _buildQRScanTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Enter Invite Link',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _linkController,
            decoration: const InputDecoration(
              labelText: 'Invite link or token',
              hintText: 'http://localhost:3000/join/abc123 or abc123',
              prefixIcon: Icon(Icons.link),
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isJoining ? null : _joinWithLink,
            icon: _isJoining
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check),
            label: Text(_isJoining ? 'Joining...' : 'Join Workspace'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.green[700], size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Paste the invite link you received or scan the QR code',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRScanTab() {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: MobileScanner(
                onDetect: _onQRScanned,
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Point your camera at the QR code',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
