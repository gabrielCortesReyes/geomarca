import 'package:geonaywhere/controllers/login_controller.dart';
import 'package:geonaywhere/services/mobile_service.dart';
import 'package:geonaywhere/services/storage_service.dart';
import 'package:get/get.dart';

class InitialBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<HfMobileService>(HfMobileService());
    Get.put<LoginSsoController>(LoginSsoController());
    Get.put<StorageService>(StorageService());
  }
}

class LoggedInBindings extends Bindings {
  @override
  void dependencies() {}
}
