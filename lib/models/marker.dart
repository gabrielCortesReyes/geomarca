import 'dart:convert';

class Marker {
  int pDeviceId;
  int pEmpresa;
  String pRut;
  int pEquipo;
  int pGeofenceId;
  String pFechaHora;
  int pSentido;
  int pTipo;
  double pLat;
  double pLong;

  Marker({
    required this.pDeviceId,
    required this.pEmpresa,
    required this.pRut,
    required this.pEquipo,
    required this.pGeofenceId,
    required this.pFechaHora,
    required this.pSentido,
    required this.pTipo,
    required this.pLat,
    required this.pLong,
  });

  factory Marker.fromJson(Map<String, dynamic> json) {
    return Marker(
      pDeviceId: json["p_device_id"],
      pEmpresa: json["p_empresa"],
      pRut: json["p_rut"],
      pEquipo: json["p_equipo"],
      pGeofenceId: json["p_geofence_id"],
      pFechaHora: json["p_fecha_hora"],
      pSentido: json["p_sentido"],
      pTipo: json["p_tipo"],
      pLat: json["p_lat"].toDouble(),
      pLong: json["p_long"].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "p_device_id": pDeviceId,
      "p_empresa": pEmpresa,
      "p_rut": pRut,
      "p_equipo": pEquipo,
      "p_geofence_id": pGeofenceId,
      "p_fecha_hora": pFechaHora,
      "p_sentido": pSentido,
      "p_tipo": pTipo,
      "p_lat": pLat,
      "p_long": pLong,
    };
  }

  static Marker fromJsonString(String str) => Marker.fromJson(json.decode(str));

  String toJsonString() => json.encode(toJson());
}

class MarkerDB {
  final int? marcaId;
  final int usuarioId;
  final String fechaHora;
  final String fechaHoraCel;
  final int sentido;
  final int tipo;
  final double latitud;
  final double longitud;
  final String result;
  final int equipoId;
  final String sincronizado;

  MarkerDB({
    this.marcaId,
    required this.usuarioId,
    required this.fechaHora,
    required this.fechaHoraCel,
    required this.sentido,
    required this.tipo,
    required this.latitud,
    required this.longitud,
    required this.result,
    required this.equipoId,
    this.sincronizado = 'N',
  });

  Map<String, dynamic> toMap() {
    return {
      'marca_id': marcaId,
      'usuario_id': usuarioId,
      'fecha_hora': fechaHora,
      'fecha_hora_cel': fechaHoraCel,
      'sentido': sentido,
      'tipo': tipo,
      'latitud': latitud,
      'longitud': longitud,
      'result': result,
      'equipo_id': equipoId,
      'sincronizado': sincronizado,
    };
  }

  factory MarkerDB.fromMap(Map<String, dynamic> map) {
    return MarkerDB(
      marcaId: map['marca_id'],
      usuarioId: map['usuario_id'],
      fechaHora: map['fecha_hora'],
      fechaHoraCel: map['fecha_hora_cel'],
      sentido: map['sentido'],
      tipo: map['tipo'],
      latitud: map['latitud'],
      longitud: map['longitud'],
      result: map['result'],
      equipoId: map['equipo_id'],
      sincronizado: map['sincronizado'],
    );
  }
}
