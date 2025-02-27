import 'dart:convert';
import 'package:geoanywhere/models/marker.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HfMobileService extends GetxService {
  final storage = const FlutterSecureStorage();

  static const String apiUrl = "https://atmtzdev.mihumanforce.cl/geomarcasv2";
  static const String apiKeyTimeZone = "L2N02YJHHF2A";
  static const String apiTimeZoneUrl = "https://vip.timezonedb.com";
  static const String apiUrlFace = "https://atmtzdev.mihumanforce.cl/face-api";
  static const String apiKeyManage = "8GjgfyoPkaxQMMBXsa4n4zYdZZi9T6pr";
  static const String apiUrlManage = "https://atmtzdev.mihumanforce.cl/manage-utils";
  static const String apiKeyManageBearer = "nCKJQ5j21FhNoxjYCUCQsIz68RhV8YAtt";

  Future<Map<String, dynamic>> _handleError(http.Response response) async {
    return {"status": response.statusCode, "body": jsonDecode(response.body), "message": response.reasonPhrase};
  }

  Future<Map<String, dynamic>> activateHash(Map<String, dynamic> datos) async {
    try {
      final response = await http.put(
        Uri.parse("$apiUrl/geomarks/activatehash"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(datos),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return await _handleError(response);
      }
    } catch (e) {
      return {"error": "Error de conexión: $e"};
    }
  }

  Future<String?> getTimeZoneByCoords(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse("$apiTimeZoneUrl/v2.1/get-time-zone?key=$apiKeyTimeZone&format=json&by=position&lat=$lat&lng=$lon"),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey("formatted")) {
          String date = data["formatted"];
          return date;
        }
      } else {
        return null;
      }
    } catch (e) {
      print("Error de Conexión");
    }
    return null;
  }

  Future<Map<String, dynamic>> addMarca(Marker marker, String token) async {
    try {
      final response = await http.post(
        Uri.parse("$apiUrl/marks/addMark"),
        headers: {"Content-Type": "application/json", "x-access-token": token},
        body: jsonEncode(marker.toJson()),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        String? newToken = await regenToken();
        if (newToken != null) {
          return await addMarca(marker, newToken);
        } else {
          return {"error": "Token expirado, reingrese a la aplicación"};
        }
      } else {
        return await _handleError(response);
      }
    } catch (e) {
      return {"error": "Error de conexión: $e"};
    }
  }

  Future<Map<String, dynamic>> sincronizar(Map<String, dynamic> datos, String token) async {
    try {
      final response = await http.post(
        Uri.parse("$apiUrl/sincronizar/"),
        headers: {"Content-Type": "application/json", "x-access-token": token},
        body: jsonEncode(datos),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return await _handleError(response);
      }
    } catch (e) {
      return {"error": "Error de conexión: $e"};
    }
  }

  Future<Map<String, dynamic>> checkCode(String appCode, String appVersion, String deviceId, String token) async {
    try {
      final response = await http.get(
        Uri.parse("$apiUrl/geomarks/checkCode/app_code=$appCode/app_version=$appVersion/device_id=$deviceId/"),
        headers: {"Content-Type": "application/json", "x-access-token": token},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return await _handleError(response);
      }
    } catch (e) {
      return {"error": "Error de conexión: $e"};
    }
  }

  Future<Map<String, dynamic>> getSsoToken(String clientCode) async {
    try {
      final response = await http.get(
        Uri.parse("$apiUrlFace/mobile/access/sso/ext_code=$clientCode"),
        headers: {"Content-Type": "application/json", "Authorization": apiKeyManageBearer},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return await _handleError(response);
      }
    } catch (e) {
      return {"error": "Error de conexión: $e"};
    }
  }

  Future<Map<String, dynamic>> validateSsoToken(String sessionId, String customerCode) async {
    try {
      final response = await http.get(
        Uri.parse("$apiUrlFace/mobile/access/sso/validation?customer_code=$customerCode&session_id=$sessionId"),
        headers: {"Content-Type": "application/json", "Authorization": apiKeyManageBearer},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return await _handleError(response);
      }
    } catch (e) {
      return {"error": "Error de conexión: $e"};
    }
  }

  Future<Map<String, dynamic>> insertLog(List<dynamic> logs) async {
    try {
      final response = await http.post(
        Uri.parse("$apiUrlFace/logs/insert"),
        headers: {"Content-Type": "application/json", "Authorization": apiKeyManage},
        body: jsonEncode({"p_logs": logs}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return await _handleError(response);
      }
    } catch (e) {
      return {"error": "Error de conexión: $e"};
    }
  }

  Future<Map<String, dynamic>> getPublicKey(String username) async {
    try {
      final response = await http.get(
        Uri.parse("$apiUrlManage/get-public-key/$username"),
        headers: {"Content-Type": "application/json", "Authorization": apiKeyManage},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return await _handleError(response);
      }
    } catch (e) {
      return {"error": "Error de conexión: $e"};
    }
  }

  Future<void> setData(String key, dynamic data) async {
    await storage.write(key: key, value: jsonEncode(data));
  }

  Future<dynamic> getData(String key) async {
    String? value = await storage.read(key: key);
    return value != null ? jsonDecode(value) : null;
  }

  Future<String?> regenToken() async {
    try {
      final response = await http.get(
        Uri.parse("$apiUrlFace/mobile/access/regentoken"),
        headers: {"Content-Type": "application/json", "Authorization": apiKeyManageBearer},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey("token")) {
          String newToken = data["token"];
          //loginController.user.value = loginController.user.value?.copyWith(token: newToken);
          return newToken;
        }
      }
    } catch (e) {
      print("Mensaje regenerando token: $e");
    }
    return null;
  }
}
