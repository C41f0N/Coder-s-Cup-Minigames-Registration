import 'package:flutter/material.dart';

bool isLandscape(BuildContext context) {
  final size = MediaQuery.of(context).size;
  return size.width > size.height;
}

bool isPortrait(BuildContext context) {
  final size = MediaQuery.of(context).size;
  return size.height > size.width;
}
