import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

class LocationController extends GetxController {
  var latitude = 0.0.obs;
  var longitude = 0.0.obs;
  var isLoading = false.obs;
  var hasError = false.obs;

  @override
  void onInit() {
    getLocation();
    super.onInit();
  }

  Future<void> getLocation() async {
    isLoading.value = true;
    hasError.value = false;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar("Mensaje", "El servicio de ubicación está deshabilitado");
        hasError.value = true;
        isLoading.value = false;
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar("Permiso denegado", "Debes habilitar la ubicación.");
          hasError.value = true;
          isLoading.value = false;
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar("Mensaje", "Debes habilitar la ubicación en Configuración.");
        hasError.value = true;
        isLoading.value = false;
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      latitude.value = position.latitude;
      longitude.value = position.longitude;
    } catch (e) {
      Get.snackbar("Mensaje", "No se pudo obtener la ubicación.");
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }
}
