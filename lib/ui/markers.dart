import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoanywhere/controllers/login_controller.dart';
import 'package:geoanywhere/services/storage_service.dart';
import 'package:geoanywhere/controllers/marker_controller.dart';

class MarkersPage extends StatefulWidget {
  @override
  _MarkersPageState createState() => _MarkersPageState();
}

class _MarkersPageState extends State<MarkersPage> {
  final LoginSsoController loginController = Get.put(LoginSsoController());
  final StorageService storageService = Get.put(StorageService());
  final MarkerController markerController = Get.put(MarkerController());

  @override
  void initState() {
    super.initState();
    markerController.loadMarcas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Marcadores"),
        actions: [
          TextButton(
            onPressed: () async {
              await markerController.syncAllMarcas();
              markerController.loadMarcas();
            },
            child: const Text("Sincronizar"),
          ),
        ],
      ),
      body: Obx(() {
        if (markerController.isSyncing.value) {
          return _buildSyncDialog();
        }
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildExpansionTile(
                  icon: Icons.done_all_sharp,
                  title: "Totales (${markerController.marcas.length})",
                  filter: (marca) => true,
                ),
                _buildExpansionTile(
                  icon: Icons.sync,
                  title:
                      "Sincronizadas (${markerController.marcas.where((marca) => marca['p_sincronizado'] == 'Sincronizado').length})",
                  filter: (marca) => marca['p_sincronizado'] == 'Sincronizado',
                ),
                _buildExpansionTile(
                  icon: Icons.pending,
                  title:
                      "Pendientes (${markerController.marcas.where((marca) => marca['p_sincronizado'] != 'Sincronizado').length})",
                  filter: (marca) => marca['p_sincronizado'] != 'Sincronizado',
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSyncDialog() {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 10),
              Text(
                "Sincronizando marcas...",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                "Marcas sincronizadas: ${markerController.marcas.where((marca) => marca['p_sincronizado'] == 'Sincronizado').length} de ${markerController.marcas.length}",
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpansionTile({
    required IconData icon,
    required String title,
    required bool Function(Map<String, dynamic>) filter,
  }) {
    return Card(
      child: GetBuilder<MarkerController>(
        builder: (controller) {
          final filteredMarcas = controller.marcas.where(filter).toList();

          return ExpansionTile(
            shape: const Border(),
            leading: Icon(icon),
            title: Text(title),
            children: filteredMarcas.isEmpty
                ? [
                    const Center(
                        child: Padding(padding: EdgeInsets.all(8.0), child: Text("No hay marcas registradas.")))
                  ]
                : filteredMarcas.map((marca) => _buildMarcaCard(marca)).toList(),
          );
        },
      ),
    );
  }

  Widget _buildMarcaCard(Map<String, dynamic> marca) {
    return Card(
      color: Colors.white,
      child: ListTile(
        leading: Icon(
          marca['p_sentido'] == 0 ? Icons.login : Icons.logout,
          color: marca['p_sentido'] == 0 ? Colors.green : Colors.red,
        ),
        title: Text(marca['p_sentido'] == 0 ? "Entrada" : "Salida"),
        subtitle: Text(
          "Fecha: ${marca['p_fecha_hora']}\nUbicación: ${marca['p_lat']}, ${marca['p_long']}",
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Icon(
          marca['p_sincronizado'] == 'Sincronizado' ? Icons.check_circle : Icons.sync,
          color: marca['p_sincronizado'] == 'Sincronizado' ? Colors.green : Colors.orange,
        ),
        onLongPress: () => markerController.deleteMarca(marca['marca_id']),
      ),
    );
  }
}
