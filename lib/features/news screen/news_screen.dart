import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/article_model.dart';
import '../news details/news_details.dart';
import '../saved items/saved_screen.dart';
import '../search screen/search_screen.dart';
import '../support_chat/support_chat_screen.dart';
import 'cubit/news_cubit.dart';
import 'cubit/news_state.dart';
import 'news_repository.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NewsCubit(NewsRepository())..loadNews(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: _currentIndex == 0
                ? AppBar(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    leading: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.menu, color: Colors.black),
                      ),
                    ),
                    actions: [
                      IconButton(
                        onPressed: () {
                          final newsCubit = context.read<NewsCubit>();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BlocProvider.value(
                                value: newsCubit,
                                child: const SearchScreen(),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.search, color: Colors.black),
                      ),
                      IconButton(
                        onPressed: () {
                          //todo: show notification
                        },
                        icon: const Icon(
                          Icons.notifications_none,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  )
                : null,
            body: _buildBody(context),
            floatingActionButton: FloatingActionButton(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              tooltip: 'Chat with Us',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SupportChatScreen(),
                  ),
                );
              },
              child: const Icon(Icons.chat),
            ),
            bottomNavigationBar: _buildBottomNavigationBar(),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return SavedScreen(
          onBackToHome: () {
            setState(() {
              _currentIndex = 0;
            });
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHomeTab() {
    return BlocBuilder<NewsCubit, NewsState>(
      builder: (context, state) {
        if (state is NewsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.secondary),
          );
        } else if (state is NewsError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load news',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.read<NewsCubit>().loadNews(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (state is NewsLoaded) {
          final articles = state.articles;

          ArticleModel? breakingNewsArticle;
          List<ArticleModel> otherArticles = [];

          if (articles.isNotEmpty) {
            final indexWithImage = articles.indexWhere(
              (article) =>
                  article.urlImage != null && article.urlImage!.isNotEmpty,
            );

            if (indexWithImage != -1) {
              breakingNewsArticle = articles[indexWithImage];
              otherArticles = List.from(articles)..removeAt(indexWithImage);
            } else {
              breakingNewsArticle = articles.first;
              otherArticles = articles.sublist(1);
            }
          }

          return RefreshIndicator(
            color: AppColors.secondary,
            onRefresh: () => context.read<NewsCubit>().loadNews(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (breakingNewsArticle != null) ...[
                    _buildSectionHeader("Breaking News"),
                    const SizedBox(height: 12),
                    _buildBreakingNewsCard(breakingNewsArticle),
                    const SizedBox(height: 20),
                  ],
                  _buildCategories(),
                  const SizedBox(height: 20),
                  _buildSectionHeader("News For You"),
                  const SizedBox(height: 12),
                  _buildNewsList(otherArticles),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: () {},
          child: const Text("Show More", style: AppTextStyles.showStyle),
        ),
      ],
    );
  }

  Widget _buildBreakingNewsCard(ArticleModel? article) {
    if (article == null) return const SizedBox.shrink();

    final hasImage = article.urlImage != null && article.urlImage!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NewDetails(article: article)),
        );
      },
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: hasImage
                ? NetworkImage(article.urlImage!) as ImageProvider
                : const AssetImage('assets/images/sport.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    final categories = [
      {"name": "All", "icon": null},
      {"name": "Fashion", "icon": null},
      {"name": "Sport", "icon": null},
      {"name": "Education", "icon": null},
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = cat['name'] == "All";
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.secondary : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected
                      ? AppColors.secondary
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  if (cat['icon'] != null)
                    Icon(
                      cat['icon'] as IconData,
                      color: isSelected ? Colors.white : Colors.black54,
                      size: 18,
                    ),
                  if (cat['icon'] != null) const SizedBox(width: 4),
                  Text(
                    cat['name'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNewsList(List<ArticleModel> articles) {
    if (articles.isEmpty) {
      return const Center(child: Text("No news available"));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: articles.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = articles[index];
        final hasImage = item.urlImage != null && item.urlImage!.isNotEmpty;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NewDetails(article: item),
              ),
            );
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: hasImage
                    ? Image.network(
                        item.urlImage!,
                        width: 110,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 110,
                          height: 90,
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Container(
                        width: 110,
                        height: 90,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.author ?? 'Unknown Author',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.title ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        item.publichedAt ?? '',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return CurvedNavigationBar(
      backgroundColor: Colors.transparent,
      color: AppColors.primary,
      height: 70,
      index: _currentIndex,
      animationDuration: const Duration(milliseconds: 300),
      animationCurve: Curves.easeInOut,
      buttonBackgroundColor: Colors.orange,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      items: const [
        Icon(Icons.home, size: 30, color: Colors.white),
        Icon(Icons.bookmark, size: 30, color: Colors.white),
      ],
    );
  }
}
