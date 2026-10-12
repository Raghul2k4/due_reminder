import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final String iconKey;
  final int colorValue;
  final bool isCustom;
  final int sortOrder;
  final bool isArchived;

  const Category({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorValue,
    this.isCustom = false,
    this.sortOrder = 0,
    this.isArchived = false,
  });

  Category copyWith({
    String? id,
    String? name,
    String? iconKey,
    int? colorValue,
    bool? isCustom,
    int? sortOrder,
    bool? isArchived,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      isCustom: isCustom ?? this.isCustom,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_key': iconKey,
      'color_value': colorValue,
      'is_custom': isCustom ? 1 : 0,
      'sort_order': sortOrder,
      'is_archived': isArchived ? 1 : 0,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      iconKey: map['icon_key'] as String,
      colorValue: map['color_value'] as int,
      isCustom: (map['is_custom'] as int?) == 1,
      sortOrder: (map['sort_order'] as int?) ?? 0,
      isArchived: (map['is_archived'] as int?) == 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconKey': iconKey,
        'colorValue': colorValue,
        'isCustom': isCustom,
        'sortOrder': sortOrder,
        'isArchived': isArchived,
      };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        iconKey: json['iconKey'] as String? ?? json['icon_key'] as String? ?? 'other',
        colorValue: json['colorValue'] as int? ?? json['color_value'] as int? ?? 0xFF9E9E9E,
        isCustom: json['isCustom'] as bool? ?? (json['is_custom'] == 1),
        sortOrder: json['sortOrder'] as int? ?? json['sort_order'] as int? ?? 0,
        isArchived: json['isArchived'] as bool? ?? (json['is_archived'] == 1),
      );

  static const List<Category> builtInCategories = [
    Category(id: 'cat_home', name: 'Home', iconKey: 'home', colorValue: 0xFF4CAF50, sortOrder: 0),
    Category(id: 'cat_vehicle', name: 'Vehicle', iconKey: 'directions_car', colorValue: 0xFF2196F3, sortOrder: 1),
    Category(id: 'cat_finance', name: 'Finance', iconKey: 'attach_money', colorValue: 0xFFFF9800, sortOrder: 2),
    Category(id: 'cat_work', name: 'Work', iconKey: 'work', colorValue: 0xFF9C27B0, sortOrder: 3),
    Category(id: 'cat_health', name: 'Health', iconKey: 'local_hospital', colorValue: 0xFFE91E63, sortOrder: 4),
    Category(id: 'cat_documents', name: 'Documents', iconKey: 'description', colorValue: 0xFF607D8B, sortOrder: 5),
    Category(id: 'cat_shopping', name: 'Shopping', iconKey: 'shopping_cart', colorValue: 0xFF00BCD4, sortOrder: 6),
    Category(id: 'cat_education', name: 'Education', iconKey: 'school', colorValue: 0xFF3F51B5, sortOrder: 7),
    Category(id: 'cat_family', name: 'Family', iconKey: 'people', colorValue: 0xFFFF5722, sortOrder: 8),
    Category(id: 'cat_maintenance', name: 'Maintenance', iconKey: 'build', colorValue: 0xFF795548, sortOrder: 9),
    Category(id: 'cat_subscriptions', name: 'Subscriptions', iconKey: 'subscriptions', colorValue: 0xFF673AB7, sortOrder: 10),
    Category(id: 'cat_other', name: 'Other', iconKey: 'more_horiz', colorValue: 0xFF9E9E9E, sortOrder: 11),
  ];

  static Category get defaultCategory => builtInCategories.last;

  static IconData getIconData(String iconKey) {
    switch (iconKey) {
      case 'home':
        return Icons.home;
      case 'directions_car':
      case 'vehicle':
        return Icons.directions_car;
      case 'attach_money':
      case 'finance':
        return Icons.attach_money;
      case 'work':
        return Icons.work;
      case 'local_hospital':
      case 'health':
        return Icons.local_hospital;
      case 'description':
      case 'documents':
        return Icons.description;
      case 'shopping_cart':
      case 'shopping':
        return Icons.shopping_cart;
      case 'school':
      case 'education':
        return Icons.school;
      case 'people':
      case 'family':
        return Icons.people;
      case 'build':
      case 'maintenance':
        return Icons.build;
      case 'subscriptions':
        return Icons.subscriptions;
      case 'pets':
        return Icons.pets;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'flight':
        return Icons.flight;
      case 'restaurant':
        return Icons.restaurant;
      case 'checkroom':
        return Icons.checkroom;
      case 'devices':
        return Icons.devices;
      case 'more_horiz':
      case 'other':
      default:
        return Icons.category;
    }
  }
}
