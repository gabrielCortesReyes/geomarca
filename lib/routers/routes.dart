import 'package:geoanywhere/ui/login.dart';
import 'package:geoanywhere/ui/home.dart';
import 'package:geoanywhere/ui/markers.dart';
import 'package:get/get.dart';

abstract class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String markers = '/markers';

  static final List<GetPage<dynamic>> routes = [
    GetPage(
      name: login,
      page: () => LoginPage(),
    ),
    GetPage(
      name: home,
      page: () => HomePage(),
    ),
    GetPage(
      name: markers,
      page: () => MarkersPage(),
    ),
  ];
}
