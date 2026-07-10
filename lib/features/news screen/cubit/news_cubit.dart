import 'package:flutter_bloc/flutter_bloc.dart';
import '../news_repository.dart';
import 'news_state.dart';

class NewsCubit extends Cubit<NewsState> {
  final NewsRepository _newsRepository;

  NewsCubit(this._newsRepository) : super(NewsInitial());

  Future<void> loadNews() async {
    emit(NewsLoading());
    try {
      final articles = await _newsRepository.fetchBreakingNews();
      emit(NewsLoaded(articles));
    } catch (e) {
      emit(NewsError(e.toString()));
    }
  }
}
