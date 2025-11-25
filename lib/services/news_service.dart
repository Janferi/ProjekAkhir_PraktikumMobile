import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tugasakhir/models/news_model.dart';

class NewsService {
  static const String _baseUrl = 'https://newsapi.org/v2/everything';
  static const String _apiKey = '793cbe2d00104da79928e19c76c528fc';

  static Future<List<NewsArticle>> fetchHealthNews() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl?q=kesehatan&language=id&apiKey=$_apiKey&pageSize=10',
        ),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final newsResponse = NewsResponse.fromJson(jsonData);
        return newsResponse.articles;
      } else {
        throw Exception('Failed to load news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching news: $e');
    }
  }
}
