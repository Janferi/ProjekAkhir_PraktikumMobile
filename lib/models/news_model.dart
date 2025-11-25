class NewsArticle {
  final String title;
  final String? description;
  final String? urlToImage;
  final String publishedAt;
  final String? author;
  final String? sourceName;
  final String url;

  NewsArticle({
    required this.title,
    this.description,
    this.urlToImage,
    required this.publishedAt,
    this.author,
    this.sourceName,
    required this.url,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? 'Judul Tidak Tersedia',
      description: json['description'],
      urlToImage: json['urlToImage'],
      publishedAt: json['publishedAt'] ?? '',
      author: json['author'],
      sourceName: json['source']?['name'],
      url: json['url'] ?? '',
    );
  }
}

class NewsResponse {
  final String status;
  final int totalResults;
  final List<NewsArticle> articles;

  NewsResponse({
    required this.status,
    required this.totalResults,
    required this.articles,
  });

  factory NewsResponse.fromJson(Map<String, dynamic> json) {
    var articlesList = json['articles'] as List;
    List<NewsArticle> articles = articlesList
        .map((article) => NewsArticle.fromJson(article))
        .toList();

    return NewsResponse(
      status: json['status'] ?? 'error',
      totalResults: json['totalResults'] ?? 0,
      articles: articles,
    );
  }
}
