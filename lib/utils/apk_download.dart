import 'package:url_launcher/url_launcher.dart';

/// Release APK published next to the web build.
const androidApkPath = 'peertask.apk';

Future<bool> launchAndroidApkDownload() {
  final uri = Uri.parse('${Uri.base.origin}/$androidApkPath');
  return launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
    webOnlyWindowName: '_blank',
  );
}
