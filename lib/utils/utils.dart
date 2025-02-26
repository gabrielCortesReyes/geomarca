//obtener la fecha y hora actual
import 'package:intl/intl.dart';

String getCurrentDateTime() {
  return DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now());
}

String formatDate() {
  return DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
}
