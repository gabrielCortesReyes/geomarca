import 'dart:convert';

User userFromJson(String str) => User.fromJson(json.decode(str));
String userToJson(User data) => json.encode(data.toJson());

class User {
  int? retorno;
  String? mensaje;
  Detalle? detalle;
  String? token;
  String? sessionId;
  String? customerCode;
  String? ssoToken;
  String? ssoSessionId;

  User({
    this.retorno,
    this.mensaje,
    this.detalle,
    this.token,
    this.sessionId,
    this.customerCode,
    this.ssoToken,
    this.ssoSessionId,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        retorno: json["retorno"],
        mensaje: json["mensaje"],
        detalle: json["detalle"] != null ? Detalle.fromJson(json["detalle"]) : null,
        token: json["token"],
      );

  Map<String, dynamic> toJson() => {
        "retorno": retorno,
        "mensaje": mensaje,
        "detalle": detalle?.toJson(),
        "token": token,
      };

  /// Método copyWith para actualizar datos sin perder los valores anteriores
  User copyWith({
    int? retorno,
    String? mensaje,
    Detalle? detalle,
    String? token,
    String? sessionId,
    String? customerCode,
    String? ssoToken,
    String? ssoSessionId,
  }) {
    return User(
      retorno: retorno ?? this.retorno,
      mensaje: mensaje ?? this.mensaje,
      detalle: detalle ?? this.detalle,
      token: token ?? this.token,
      sessionId: sessionId ?? this.sessionId,
      customerCode: customerCode ?? this.customerCode,
      ssoToken: ssoToken ?? this.ssoToken,
      ssoSessionId: ssoSessionId ?? this.ssoSessionId,
    );
  }
}

class Detalle {
  String userId;
  String orgId;
  String hfEquipId;
  String username;
  String nombre;
  String email;

  Detalle({
    required this.userId,
    required this.orgId,
    required this.hfEquipId,
    required this.username,
    required this.nombre,
    required this.email,
  });

  factory Detalle.fromJson(Map<String, dynamic> json) => Detalle(
        userId: json["user_id"],
        orgId: json["org_id"],
        hfEquipId: json["hf_equip_id"],
        username: json["username"],
        nombre: json["nombre"],
        email: json["email"],
      );

  Map<String, dynamic> toJson() => {
        "user_id": userId,
        "org_id": orgId,
        "hf_equip_id": hfEquipId,
        "username": username,
        "nombre": nombre,
        "email": email,
      };
}
