import '../../core/network/api_service.dart';
import '../models/article_model.dart';

class NewsRepository {
  final ApiService _apiService = ApiService();

  Future<List<ArticleModel>> fetchBreakingNews() async {
    try {
      final response = await _apiService.get(
        'top-headlines',
        queryParameters: {
          'country': 'us',
          'apiKey': 'e98175b4df1443beaa5c9014d5d9622c',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> articlesJson = response.data['articles'];
        return articlesJson.map((json) => ArticleModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load news');
      }
    } catch (e) {
      throw Exception('Error fetching news: $e');
    }
  }
}
