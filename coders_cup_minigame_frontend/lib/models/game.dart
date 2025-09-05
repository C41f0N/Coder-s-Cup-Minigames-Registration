import 'package:coders_cup_minigame_frontend/models/form_field.dart';

class Game {
  String id;
  String name;
  int limit;
  List<FormField> formFields = [];

  Game({required this.id, required this.name, required this.limit});
}
