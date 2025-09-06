import 'package:coders_cup_minigame_frontend/models/response_field.dart';

class Response {
  String name;
  String email;
  List<ResponseField> responses;

  Response({required this.name, required this.email, required this.responses});
}
