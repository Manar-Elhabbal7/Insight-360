import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../models/article_model.dart';
import '../saved items/cubit/saved_cubit.dart';
import '../saved items/cubit/saved_state.dart';

class NewDetails extends StatelessWidget {
  final ArticleModel article;

  const NewDetails({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final hasImage = article.urlImage != null && article.urlImage!.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          BlocBuilder<SavedCubit, SavedState>(
            builder: (context, state) {
              final isSaved = context.read<SavedCubit>().isSaved(article);
              return IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: isSaved ? AppColors.secondary : Colors.black,
                  size: 28,
                ),
                onPressed: () {
                  context.read<SavedCubit>().toggleSave(article);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isSaved
                            ? 'Removed from Bookmarks'
                            : 'Saved to Bookmarks',
                      ),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Photo First
            Hero(
              tag: article.title ?? '',
              child: ClipRRect(
                child: hasImage
                    ? Image.network(
                        article.urlImage!,
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: double.infinity,
                          height: 250,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                            size: 50,
                          ),
                        ),
                      )
                    : Container(
                        width: double.infinity,
                        height: 250,
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.image,
                          color: Colors.grey,
                          size: 50,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Text Details Container
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Metadata: Author & Published Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (article.author != null && article.author!.isNotEmpty)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              article.author!,
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        article.publichedAt ?? '',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. Title
                  Text(
                    article.title ?? '',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Divider
                  Divider(color: Colors.grey.shade300, thickness: 1),
                  const SizedBox(height: 16),

                  // 3. Content
                  Text(
                    article.description ??
                        'No content available for this article.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade800,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
