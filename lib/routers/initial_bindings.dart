import 'package:geoanywhere/controllers/login_controller.dart';
import 'package:geoanywhere/services/mobile_service.dart';
import 'package:geoanywhere/services/storage_service.dart';
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
