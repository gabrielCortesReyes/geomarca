import 'package:flutter/material.dart';
import 'package:geoanywhere/models/marker.dart';
import 'package:get/get.dart';
import 'package:geoanywhere/services/storage_service.dart';
import 'package:geoanywhere/controllers/login_controller.dart';
import 'package:geoanywhere/services/mobile_service.dart';

class MarkerController extends GetxController {
  final StorageService storageService = Get.find<StorageService>();
  final LoginSsoController loginController = Get.find<LoginSsoController>();
  final HfMobileService mobileService = Get.find<HfMobileService>();
  var marcas = <Map<String, dynamic>>[].obs;
  RxBool isSyncing = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadMarcas();
  }

  Future<void> loadMarcas() async {
    marcas.value = await storageService.getMarcas();
  }

  Future<void> markAsSynced(int id) async {
    await storageService.updateMarcaSync(id);
    loadMarcas();
  }

  Future<void> deleteMarca(int id) async {
    await storageService.deleteMarca(id);
    loadMarcas();
  }

  Future<void> syncAllMarcas() async {
    try {
      isSyncing.value = true;
      final marcasNoSync = await storageService.getMarcasNoSync();
      if (marcasNoSync.length == 0) {
        Get.snackbar("Mensaje", "No hay marcas pendientes de sincronizar", snackPosition: SnackPosition.BOTTOM);
        return;
      }
      for (final marca in marcasNoSync) {
        int marcaId = marca["marca_id"];

        Marker marker = Marker(
          pDeviceId: 0,
          pEmpresa: marca["p_empresa"],
          pRut: marca["p_rut"],
          pEquipo: marca["p_equipo"],
          pGeofenceId: marca["p_geofence_id"],
          pFechaHora: marca["p_fecha_hora"],
          pSentido: marca["p_sentido"],
          pTipo: marca["p_tipo"],
          pLat: marca["p_lat"],
          pLong: marca["p_long"],
        );

        Map<String, dynamic> response = await mobileService.addMarca(marker, loginController.user.value?.token ?? "");

        if (response.containsKey("retorno") && response["retorno"] == 1) {
          await storageService.updateMarcaSync(marcaId);
          loadMarcas();
        }
      }
      Get.snackbar("Mensaje", "Marcas sincronizadas correctamente",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Mensaje", "No se pudo sincronizar las marcas", snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSyncing.value = false;
    }
  }
}
