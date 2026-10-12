import 'package:flutter/material.dart';
import '../../data/models/category.dart';
import '../../data/repositories/category_repository.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryRepository _repository;

  List<Category> _categories = [];
  Map<String, int> _categoryCounts = {};
  bool _isLoading = false;
  String? _errorMessage;

  CategoryProvider([CategoryRepository? repository]) : _repository = repository ?? CategoryRepository();

  List<Category> get categories => List.unmodifiable(_categories);
  Map<String, int> get categoryCounts => Map.unmodifiable(_categoryCounts);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadCategories({bool includeArchived = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await _repository.getAllCategories(includeArchived: includeArchived);
      _categoryCounts = await _repository.getCategoryReminderCounts();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Category?> createCategory(String name, String iconKey, int colorValue) async {
    try {
      final created = await _repository.createCategory(
        name: name,
        iconKey: iconKey,
        colorValue: colorValue,
      );
      await loadCategories();
      return created;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Category?> updateCategory(Category category) async {
    try {
      final updated = await _repository.updateCategory(category);
      await loadCategories();
      return updated;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteCategory(String id, {bool reassignToOther = true}) async {
    try {
      await _repository.deleteCategory(id, reassignToOther: reassignToOther);
      await loadCategories();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
