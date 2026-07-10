import '../../models/article_model.dart';

abstract class SavedState {
  const SavedState();
}

class SavedInitial extends SavedState {
  const SavedInitial();
}

class SavedLoading extends SavedState {
  const SavedLoading();
}

class SavedLoaded extends SavedState {
  final List<ArticleModel> articles;
  const SavedLoaded(this.articles);
}
