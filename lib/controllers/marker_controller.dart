import 'package:get/get.dart';
import 'package:geonaywhere/services/storage_service.dart';

class MarkerController extends GetxController {
  final StorageService storageService = Get.find<StorageService>();
  var marcas = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadMarcas();
  }

  void loadMarcas() async {
    marcas.value = await storageService.getMarcas();
  }

  Future<void> addMarca({
    required String fechaHora,
    required double latitud,
    required double longitud,
    required int tipo,
  }) async {
    await storageService.insertMarca({
      'tipo': tipo,
      'fecha_hora': fechaHora,
      'fecha_hora_cel': fechaHora,
      'latitud': latitud,
      'longitud': longitud,
      'sincronizado': 'N',
    });
    loadMarcas();
  }

  Future<void> markAsSynced(int id) async {
    await storageService.updateMarcaSync(id);
    loadMarcas();
  }

  Future<void> deleteMarca(int id) async {
    await storageService.deleteMarca(id);
    loadMarcas();
  }
}
