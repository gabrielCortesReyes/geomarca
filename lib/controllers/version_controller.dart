import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionController extends GetxController {
  var appVersion = "".obs;

  @override
  void onInit() {
    super.onInit();
    getAppVersion();
  }

  Future<void> getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appVersion.value = "${packageInfo.version} (${packageInfo.buildNumber})";
  }
}
