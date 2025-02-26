import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geonaywhere/models/marker.dart';
import 'package:geonaywhere/models/user.dart';
import 'package:geonaywhere/utils/utils.dart';
import 'package:get/get.dart';
import 'package:geonaywhere/routers/routes.dart';
import 'package:geonaywhere/controllers/login_controller.dart';
import 'package:geonaywhere/controllers/location_controller.dart';
import 'package:geonaywhere/controllers/version_controller.dart';
import 'package:geonaywhere/controllers/marker_controller.dart';
import 'package:geonaywhere/services/mobile_service.dart';

class HomePage extends StatelessWidget {
  final LoginSsoController loginController = Get.put(LoginSsoController());
  final LocationController locationController = Get.put(LocationController());
  final VersionController versionController = Get.put(VersionController());
  final MarkerController markerController = Get.put(MarkerController());
  final HfMobileService mobileService = Get.put(HfMobileService());

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
            Column(
              children: [
                _buildButton("Entrada", Icons.login, Colors.green, () => _registrarMarca(0)),
                SizedBox(height: 16),
                _buildButton("Salida", Icons.logout, Colors.red, () => _registrarMarca(1)),
                SizedBox(height: 16),
                Obx(() {
                  if (markerController.marcas.isEmpty) {
                    return Center(child: Text("No hay marcas registradas."));
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: markerController.marcas.length,
                    itemBuilder: (context, index) {
                      final marca = markerController.marcas[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(marca['sentido'] == "Entrada" ? Icons.login : Icons.logout,
                              color: marca['sentido'] == "Entrada" ? Colors.green : Colors.red),
                          title: Text("${marca['sentido']}"),
                          subtitle: Text(
                            "Fecha: ${marca['fecha_hora']}\nUbicación: ${marca['latitud']}, ${marca['longitud']}",
                            style: TextStyle(fontSize: 12),
                          ),
                          trailing: marca['sincronizado'] == 'S'
                              ? Icon(Icons.check_circle, color: Colors.green)
                              : Icon(Icons.sync, color: Colors.orange),
                          onLongPress: () => markerController.deleteMarca(marca['marca_id']),
                        ),
                      );
                    },
                  );
                }),
              ],
            ),
            _buildFooter(),
          ],
        ),
      ),
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
          _buildDrawerItem(Icons.sync, "Sincronizar", () {}),
          _buildDrawerItem(Icons.location_on, "Ver Marcas", () => Get.toNamed(AppRoutes.markers)),
          _buildDrawerItem(Icons.info, "Acerca de", _buildAbout),
          Divider(),
          _buildDrawerItem(Icons.logout, "Cerrar Sesión", () {}),
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
            Text("Versión: 1.0.0"),
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

  Widget _buildButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon, color: Colors.white),
        label: Text(text, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        onPressed: onPressed,
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
      User userData = loginController.user.value!;

      Marker marker = Marker(
        pDeviceId: 0,
        pEmpresa: int.parse(userData.detalle?.orgId ?? "0"),
        pRut: userData.detalle?.username ?? "",
        pEquipo: int.parse(userData.detalle?.hfEquipId ?? "0"),
        pGeofenceId: int.parse(userData.detalle?.orgId ?? "0"),
        pFechaHora: formatDate(),
        pSentido: marca,
        pTipo: 0,
        pLat: locationController.latitude.value,
        pLong: locationController.longitude.value,
      );

      await mobileService.addMarca(marker, userData.token ?? "");

      Get.snackbar("Éxito", "Marca registrada correctamente!", snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      print(e);
      Get.snackbar("Error", "No se pudo obtener la ubicación",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
