import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/article_model.dart';
import 'saved_state.dart';

class SavedCubit extends Cubit<SavedState> {
  static const String _storageKey = 'saved_articles';

  SavedCubit() : super(const SavedInitial()) {
    loadSavedArticles();
  }

  Future<void> loadSavedArticles() async {
    emit(const SavedLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString(_storageKey);
      if (savedStr != null) {
        final List<dynamic> jsonList = json.decode(savedStr);
        final articles = jsonList
            .map((json) => ArticleModel.fromJson(json))
            .toList();
        emit(SavedLoaded(articles));
      } else {
        emit(const SavedLoaded([]));
      }
    } catch (e) {
      emit(const SavedLoaded([]));
    }
  }

  Future<void> toggleSave(ArticleModel article) async {
    final currentState = state;
    if (currentState is SavedLoaded) {
      final list = List<ArticleModel>.from(currentState.articles);
      final index = list.indexWhere((item) => item.title == article.title);

      if (index != -1) {
        list.removeAt(index);
      } else {
        list.add(article);
      }

      emit(SavedLoaded(list));

      try {
        final prefs = await SharedPreferences.getInstance();
        final jsonList = list.map((item) => item.toJson()).toList();
        await prefs.setString(_storageKey, json.encode(jsonList));
      } catch (_) {
        // Handle error silently
      }
    }
  }

  bool isSaved(ArticleModel article) {
    final currentState = state;
    if (currentState is SavedLoaded) {
      return currentState.articles.any((item) => item.title == article.title);
    }
    return false;
  }
}
