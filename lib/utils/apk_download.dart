import 'package:url_launcher/url_launcher.dart';

/// Release APK published next to the web build.
const androidApkPath = 'peertask.apk';

Future<bool> launchAndroidApkDownload() {
  return launchUrl(
    Uri.base.resolve(androidApkPath),
    mode: LaunchMode.externalApplication,
  );
}
