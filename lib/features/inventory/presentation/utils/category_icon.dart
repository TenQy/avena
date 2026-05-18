import 'package:flutter/material.dart';

IconData categoryIcon(String name) {
  final value = name.toLowerCase();

  if (value.contains('alimento') ||
      value.contains('mascota') ||
      value.contains('perro') ||
      value.contains('gato')) {
    return Icons.pets_rounded;
  }

  if (value.contains('granel')) {
    return Icons.scale_rounded;
  }

  if (value.contains('dulce') ||
      value.contains('candy') ||
      value.contains('golosina')) {
    return Icons.cookie_rounded;
  }

  if (value.contains('especia') ||
      value.contains('chile') ||
      value.contains('hierba') ||
      value.contains('condimento')) {
    return Icons.grass_rounded;
  }

  if (value.contains('abarrote') || value.contains('basico')) {
    return Icons.shopping_basket_rounded;
  }

  if (value.contains('combustible') ||
      value.contains('carbon') ||
      value.contains('lena')) {
    return Icons.local_fire_department_rounded;
  }

  return Icons.category_rounded;
}
