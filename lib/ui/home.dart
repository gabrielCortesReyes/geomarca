import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geoanywhere/models/marker.dart';
import 'package:geoanywhere/models/user.dart';
import 'package:geoanywhere/services/storage_service.dart';
import 'package:geoanywhere/utils/utils.dart';
import 'package:get/get.dart';
import 'package:geoanywhere/routers/routes.dart';
import 'package:geoanywhere/controllers/login_controller.dart';
import 'package:geoanywhere/controllers/location_controller.dart';
import 'package:geoanywhere/controllers/version_controller.dart';
import 'package:geoanywhere/controllers/marker_controller.dart';
import 'package:geoanywhere/services/mobile_service.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LoginSsoController loginController = Get.put(LoginSsoController());
  final LocationController locationController = Get.put(LocationController());
  final VersionController versionController = Get.put(VersionController());
  final MarkerController markerController = Get.put(MarkerController());
  final HfMobileService mobileService = Get.put(HfMobileService());
  final StorageService storageService = Get.put(StorageService());
  bool isLoadingEntrada = false;
  bool isLoadingSalida = false;

  @override
  void initState() {
    super.initState();
    //_checkConnectivityAndSync();
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) async {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        await markerController.syncAllMarcas();
        markerController.loadMarcas();
      } else {
        print("No hay conexión a Internet. No se sincronizarán las marcas.");
      }
    });
  }

  Future<void> _checkConnectivityAndSync() async {
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult != ConnectivityResult.none) {
      await markerController.syncAllMarcas();
      markerController.loadMarcas();
    } else {
      print("No hay conexión a Internet. No se sincronizarán las marcas.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: Image.asset("assets/images/logo_atmz.png", height: 50),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Get.toNamed(AppRoutes.markers),
            icon: Icon(Icons.location_on),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Bienvenido", style: TextStyle(fontSize: 24)),
                    Obx(() {
                      final userData = loginController.user.value;
                      return Text(
                        userData?.detalle?.nombre ?? "",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      );
                    }),
                  ],
                ),
              ],
            ),
            _buildButtons(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        _buildButton("Entrada", Icons.login, Colors.green, isLoadingEntrada, () => _registrarMarca(0)),
        SizedBox(height: 10),
        _buildButton("Salida", Icons.logout, Colors.red, isLoadingSalida, () => _registrarMarca(1)),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/images/logo_atmz.png", height: 80),
                SizedBox(height: 10),
                Obx(() {
                  final userData = loginController.user.value;
                  return Text(userData?.detalle?.nombre ?? "Bienvenido", style: TextStyle(fontWeight: FontWeight.bold));
                }),
              ],
            ),
          ),
          _buildDrawerItem(Icons.sync, "Sincronizar", () => _alertSync()),
          _buildDrawerItem(Icons.location_on, "Ver Marcas", () => Get.toNamed(AppRoutes.markers)),
          _buildDrawerItem(Icons.info, "Acerca de", _buildAbout),
        ],
      ),
    );
  }

  void _buildAbout() {
    Get.dialog(
      AlertDialog(
        title: Image.asset("assets/images/logo_atmz.png", height: 50),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            Text("Empresa: Automatiza"),
            Text("App: Geoanywhere SSO"),
            Text("Versión: ${versionController.appVersion.value}"),
            Text("Fecha: ${getCurrentDateTime()}"),
            SizedBox(height: 10),
            Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Lat: ${locationController.latitude.value.toStringAsFixed(6)}"),
                  Text("Lon: ${locationController.longitude.value.toStringAsFixed(6)}"),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  void _alertSync() async {
    final marcasNoSync = await storageService.getMarcasNoSync();
    if (marcasNoSync.length == 0) {
      Get.snackbar("Mensaje", "No hay marcas pendientes de sincronizar", snackPosition: SnackPosition.BOTTOM);
      return;
    }
    Get.dialog(
      AlertDialog(
        title: Text("Sincronizar"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("¿Desea sincronizar las marcas?"),
            Text("${marcasNoSync.length} marcas pendientes de sincronizar"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Cerrar"),
          ),
          TextButton(
            onPressed: () => markerController.syncAllMarcas(),
            child: Text("Sincronizar"),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text, IconData icon, Color color, bool isLoading, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isLoading ? Colors.grey : color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: isLoading ? CircularProgressIndicator(color: Colors.white) : Icon(icon, color: Colors.white),
        label: Text(text, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        onPressed: isLoading ? null : onPressed,
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: TextStyle(fontSize: 16)),
      onTap: onTap,
    );
  }

  Widget _buildFooter() {
    return Obx(
      () => Column(
        children: [
          Text("Geoanywhere SSO © ${DateTime.now().year} Automatiza"),
          Text("Versión: ${versionController.appVersion.value}"),
          Text("Todos los derechos reservados"),
        ],
      ),
    );
  }

  Future<void> _registrarMarca(int marca) async {
    try {
      setState(() {
        if (marca == 0) {
          isLoadingEntrada = true;
        } else {
          isLoadingSalida = true;
        }
      });

      User? userData = loginController.user.value;
      if (userData == null || userData.token == null) {
        Get.snackbar("Mensaje", "Usuario no autenticado", backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      var connectivityResult = await Connectivity().checkConnectivity();
      String? formatedDate = connectivityResult != ConnectivityResult.none
          ? await mobileService.getTimeZoneByCoords(locationController.latitude.value, locationController.longitude.value)
          : formatDate();

      Marker marker = Marker(
        pDeviceId: 0,
        pEmpresa: int.parse(userData.detalle?.orgId ?? "0"),
        pRut: userData.detalle?.username ?? "",
        pEquipo: int.parse(userData.detalle?.hfEquipId ?? "0"),
        pGeofenceId: int.parse(userData.detalle?.orgId ?? "0"),
        pFechaHora: formatedDate!,
        pSentido: marca,
        pTipo: 0,
        pLat: locationController.latitude.value,
        pLong: locationController.longitude.value,
      );

      int marcaId = await storageService.insertMarca(marker.toJson());
      if (connectivityResult != ConnectivityResult.none) {
        var response = await mobileService.addMarca(marker, userData.token!);
        if (response["retorno"] == 1) {
          await storageService.updateMarcaSync(marcaId);
          Get.snackbar("Éxito", "Marca registrada correctamente!");
        } else {
          Get.snackbar("Error", "Token expirado, marca guardada localmente", backgroundColor: Colors.orange);
        }
      } else {
        Get.snackbar("Mensaje", "Sin conexión, marca guardada localmente", backgroundColor: Colors.orange);
      }
    } finally {
      setState(() {
        if (marca == 0) {
          isLoadingEntrada = false;
        } else {
          isLoadingSalida = false;
        }
      });
    }
  }
}
