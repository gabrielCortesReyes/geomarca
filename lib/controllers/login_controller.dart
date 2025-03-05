import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geoanywhere/services/connectivity_service.dart';
import 'package:geoanywhere/services/mobile_service.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:geoanywhere/models/user.dart';

class LoginSsoController extends GetxController with WidgetsBindingObserver {
  final storage = const FlutterSecureStorage();
  final HfMobileService _hfMobileService = Get.find<HfMobileService>();
  final ConnectivityService connectivityService = Get.put(ConnectivityService());

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
    initAutoLogin();
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
    return;
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
      Get.snackbar("Mensaje", "Ingrese el código para empezar", snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isLoading.value = true;
    loadingMessage.value = 'Preparando el inicio de sesión...';

    await logEvent('Llamado al servicio getSsoToken');

    try {
      bool isconnected = await connectivityService.hasInternet();
      if (isconnected) {
        final data = await _hfMobileService.getSsoToken(clientCode.value);
        await logEvent('Servicio getSsoToken llamado correctamente', data);

        if (data["retorno"] != 1) {
          final match = RegExp(r'\[MSG-(\d{1,3})\]').firstMatch(data["mensaje"]);
          final errorCode = match != null ? match.group(1) : '00G';

          Get.snackbar("Mensaje Inicio de Sesión", "Favor comuníquese con el administrador. (0x$errorCode)", snackPosition: SnackPosition.BOTTOM);
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
      } else {
        Get.snackbar("Mensaje", "No tienes conexión a internet, Vuelve a intentarlo mas tarde", snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      await logEvent('Error en getSsoToken', e.toString());

      if (e.toString().contains("500")) {
        Get.snackbar("Mensaje", "Comuniquese con el administrador de la aplicación. (GEOSSO0x010)", snackPosition: SnackPosition.BOTTOM);
      } else if (e.toString().contains("404")) {
        Get.snackbar("Mensaje", "Comuniquese con el administrador de la aplicación. (GEOSSO0x020)", snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar("Mensaje", "Verifique su conexión a internet y vuelva a intentar. (GEOSSO0x030)", snackPosition: SnackPosition.BOTTOM);
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
        bool hasInternet = await connectivityService.hasInternet();
        if (hasInternet) {
          final data = await _hfMobileService.getSsoToken(clientCode.value);
          await logEvent('Servicio getSsoToken llamado correctamente', data);

          if (data["retorno"] != 1) {
            final match = RegExp(r'\[MSG-(\d{1,3})\]').firstMatch(data["mensaje"]);
            final errorCode = match != null ? match.group(1) : '00G';

            Get.snackbar("Mensaje Inicio de Sesión", "Favor comuníquese con el administrador. (0x$errorCode)", snackPosition: SnackPosition.BOTTOM);
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

          return;
        } else {
          Get.snackbar("Mensaje", "No tienes conexión a internet, Los datos se guardaran localmente", snackPosition: SnackPosition.BOTTOM);
          user.value = User.fromJson(jsonDecode(userData));
          print(user.value);
          Get.offAllNamed('/home');
          isLoading.value = false;
        }
        await logEvent('Conexión a internet detectada');
      } else {
        Get.offAllNamed('/home');
        isLoading.value = false;
      }
    } else {
      isLogged.value = false;
      await logEvent('No se encontró sesión de usuario');
    }
    isLoading.value = false;
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
        Get.snackbar("Mensaje", "Sesión no válida, por favor inicie sesión de nuevo.", snackPosition: SnackPosition.BOTTOM);
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
      await logEvent('Error en validateSsoToken', e.toString());
    }
  }

  Future<void> callServiceLog() async {
    await logEvent('Llamado a servicio de logs');
    try {
      await _hfMobileService.insertLog(logJson);
    } catch (e) {
      await logEvent('Error en insertLog', e.toString());
    }
  }
}
