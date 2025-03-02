import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoanywhere/controllers/login_controller.dart';

class LoginPage extends StatelessWidget {
  final LoginSsoController controller = Get.put(LoginSsoController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset("assets/images/logo_atmz.png", height: 100),
              const SizedBox(height: 20),
              const Text(
                "Bienvenido a",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              const Text(
                "GeoAnywhere SSO",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              const SizedBox(height: 40),
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Código Cliente",
                  hintText: "Ingrese su código cliente",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.business, color: Colors.blueAccent),
                ),
                onChanged: (value) => controller.clientCode.value = value,
              ),
              const SizedBox(height: 20),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: controller.isLoading.value ? null : controller.login,
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.login, color: Colors.white),
                              SizedBox(width: 10),
                              Text(
                                "Iniciar Sesión",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
