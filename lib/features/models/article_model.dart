class ArticleModel {
  String? author;
  String? title;
  String? description;
  String? urlImage;
  String? publichedAt;

  ArticleModel({
    this.author,
    this.title,
    this.description,
    this.urlImage,
    this.publichedAt,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      title: json['title'],
      author: json['author'],
      description: json['description'],
      publichedAt: json['publishedAt'],
      urlImage: json['urlToImage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'author': author,
      'description': description,
      'publishedAt': publichedAt,
      'urlToImage': urlImage,
    };
  }
}
