import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geonaywhere/services/mobile_service.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:geonaywhere/models/user.dart';

class LoginSsoController extends GetxController with WidgetsBindingObserver {
  final storage = const FlutterSecureStorage();
  final HfMobileService _hfMobileService = Get.find<HfMobileService>();

  Rx<User?> user = User().obs;

  var isLogged = false.obs;
  var isLoading = false.obs;
  var loadingMessage = "".obs;

  var token = "".obs;
  var sessionId = "".obs;
  var customerCode = "".obs;
  var clientCode = "".obs;

  var logJson = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    //initAutoLogin();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      validateSsoToken();
    }
  }

  Future<void> initAutoLogin() async {
    await logEvent('Iniciando auto-login');
    await storage.write(key: 'sync', value: 'false');
    await autoLogin();
  }

  Future<void> logEvent(String message, [dynamic value]) async {
    final log = {
      "mensaje": message,
      "valor": value,
      "fecha": DateFormat('yyyyMMdd HH:mm:ss').format(DateTime.now()),
    };

    logJson.add(log);
    await storage.write(key: 'logs', value: jsonEncode(logJson));
  }

  Future<void> login() async {
    if (clientCode.value.isEmpty) {
      Get.snackbar("Error", "Ingrese el código para empezar");
      return;
    }

    isLoading.value = true;
    loadingMessage.value = 'Preparando el inicio de sesión...';

    await logEvent('Llamado al servicio getSsoToken');

    try {
      final data = await _hfMobileService.getSsoToken(clientCode.value);
      await logEvent('Servicio getSsoToken llamado correctamente', data);

      if (data["retorno"] != 1) {
        final match = RegExp(r'\[MSG-(\d{1,3})\]').firstMatch(data["mensaje"]);
        final errorCode = match != null ? match.group(1) : '00G';

        Get.snackbar("Error Inicio de Sesión", "Favor comuníquese con el administrador. (0x$errorCode)");
        callServiceLog();
        return;
      }

      token.value = data["detalle"]["sso_token"];
      sessionId.value = data["detalle"]["sso_session_id"];
      customerCode.value = data["detalle"]["customer"];

      await storage.write(key: 'sessionId', value: sessionId.value);
      await storage.write(key: 'customerCode', value: customerCode.value);
      await storage.write(key: 'token', value: token.value);

      user.value = User(
        token: token.value,
        sessionId: sessionId.value,
        customerCode: customerCode.value,
        ssoToken: data["detalle"]["sso_token"],
        ssoSessionId: data["detalle"]["sso_session_id"],
      );

      isLogged.value = true;

      await logEvent('Abriendo navegador con URL', data["detalle"]["sso_url"]);
      await launchUrl(Uri.parse(data["detalle"]["sso_url"]));

      final usuario = {
        'token': token.value,
        'sessionId': sessionId.value,
        'customerCode': customerCode.value,
        'clientCode': clientCode.value,
      };
      await storage.write(key: 'usuario', value: jsonEncode(usuario));
    } catch (e) {
      await logEvent('Error en getSsoToken', e.toString());

      if (e.toString().contains("500")) {
        Get.snackbar("Error", "Comuniquese con el administrador de la aplicación. (GEOSSO0x010)");
      } else if (e.toString().contains("404")) {
        Get.snackbar("Error", "Comuniquese con el administrador de la aplicación. (GEOSSO0x020)");
      } else {
        Get.snackbar("Error", "Verifique su conexión a internet y vuelva a intentar. (GEOSSO0x030)");
      }
      callServiceLog();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> autoLogin() async {
    isLoading.value = true;
    await logEvent('Obteniendo información de usuario almacenado');
    String? userData = await storage.read(key: 'usuario');

    if (userData != null) {
      var usuario = jsonDecode(userData);
      if (usuario['token'] != null && usuario['token'].toString().isNotEmpty) {
        token.value = usuario['token'];
        sessionId.value = usuario['sessionId'];
        customerCode.value = usuario['customerCode'];
        clientCode.value = usuario['clientCode'] ?? '';

        isLogged.value = true;
        await logEvent('Datos de sesión encontrados. Intentando validación automática.');

        var connectivityResult = await Connectivity().checkConnectivity();
        bool isConnected = connectivityResult != ConnectivityResult.none;

        if (isConnected) {
          final data = await _hfMobileService.getSsoToken(clientCode.value);
          await logEvent('Servicio getSsoToken llamado correctamente', data);

          if (data["retorno"] != 1) {
            final match = RegExp(r'\[MSG-(\d{1,3})\]').firstMatch(data["mensaje"]);
            final errorCode = match != null ? match.group(1) : '00G';

            Get.snackbar("Error Inicio de Sesión", "Favor comuníquese con el administrador. (0x$errorCode)");
            callServiceLog();
            return;
          }

          token.value = data["detalle"]["sso_token"];
          sessionId.value = data["detalle"]["sso_session_id"];
          customerCode.value = data["detalle"]["customer"];

          await storage.write(key: 'sessionId', value: sessionId.value);
          await storage.write(key: 'customerCode', value: customerCode.value);
          await storage.write(key: 'token', value: token.value);

          isLogged.value = true;

          await logEvent('Abriendo navegador con URL', data["detalle"]["sso_url"]);
          await launchUrl(Uri.parse(data["detalle"]["sso_url"]));

          final usuario = {
            'token': token.value,
            'sessionId': sessionId.value,
            'customerCode': customerCode.value,
            'clientCode': clientCode.value,
          };
          await storage.write(key: 'usuario', value: jsonEncode(usuario));
        } else {
          Get.offAllNamed('/home');
          isLoading.value = false;
        }
        return;
      }
    }
    isLogged.value = false;
    await logEvent('No se encontró sesión de usuario');
  }

  Future<void> validateSsoToken() async {
    await logEvent('Validando sesión con validateSsoToken');

    try {
      final data = await _hfMobileService.validateSsoToken(sessionId.value, customerCode.value);

      user.value = user.value?.copyWith(
        retorno: data["retorno"],
        mensaje: data["mensaje"],
        detalle: Detalle.fromJson(data["detalle"]),
        token: data["token"],
      );

      if (data["retorno"] != 1) {
        Get.snackbar("Error", "Sesión no válida, por favor inicie sesión de nuevo.");
        await storage.deleteAll();
        isLogged.value = false;
        return;
      }

      token.value = data["token"];

      final usuario = {
        'token': token.value,
        'sessionId': sessionId.value,
        'customerCode': customerCode.value,
        'clientCode': clientCode.value,
        'detalle': data["detalle"],
      };
      await storage.write(key: 'usuario', value: jsonEncode(usuario));

      await logEvent('Sesión validada exitosamente');
      Get.offAllNamed('/home');
    } catch (e) {
      Get.snackbar("Error", "Error al validar sesión.");
      await logEvent('Error en validateSsoToken', e.toString());
    }
  }

  Future<void> callServiceLog() async {
    await logEvent('Llamado a servicio de logs');
    try {
      await _hfMobileService.insertLog(logJson);
    } catch (e) {
      Get.snackbar("Error", "Error al enviar logs.");
      await logEvent('Error en insertLog', e.toString());
    }
  }
}
