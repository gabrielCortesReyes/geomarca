import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  final RxBool isConnected = false.obs;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void onInit() {
    super.onInit();
    _checkInternetConnection();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      _checkInternetConnection();
    });
  }

  Future<void> _checkInternetConnection() async {
    final result = await _connectivity.checkConnectivity();
    if (result.isNotEmpty && result.first != ConnectivityResult.none) {
      bool hasInternet = await _hasInternetAccess();
      isConnected.value = hasInternet;
      if (hasInternet) {
        print("✅ Conexión a Internet disponible, iniciando sincronización...");
      } else {
        print("⚠️ Conectado a una red, pero sin acceso a Internet.");
      }
    } else {
      print("❌ No hay conexión a ninguna red.");
      isConnected.value = false;
    }
  }

  Future<bool> _hasInternetAccess() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasInternet() async {
    try {
      final response = await http.get(Uri.parse('https://www.google.com'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }
}
