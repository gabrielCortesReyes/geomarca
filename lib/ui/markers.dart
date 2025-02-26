import 'package:flutter/material.dart';
import 'package:geonaywhere/routers/routes.dart';
import 'package:get/get.dart';
import 'package:geonaywhere/controllers/login_controller.dart';

class MarkersPage extends StatelessWidget {
  final LoginSsoController controller = Get.put(LoginSsoController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Marcadores"),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text("Sincronizar"),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                ExpansionTile(
                  leading: Icon(Icons.done_all_sharp),
                  title: Text("Totales"),
                  children: [
                    Text("Sinconizadas"),
                  ],
                ),
                ExpansionTile(
                  leading: Icon(Icons.sync),
                  title: Text("Sinconizadas"),
                  children: [
                    Text("Pendientes"),
                  ],
                ),
                ExpansionTile(
                  leading: Icon(Icons.pending),
                  title: Text("Pendientes"),
                  children: [
                    Text("Marcadores"),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
