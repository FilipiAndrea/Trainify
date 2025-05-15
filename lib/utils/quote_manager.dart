import 'package:shared_preferences/shared_preferences.dart';

class QuoteManager {
  static const String _quoteKey = 'saved_quote';
  static const String _authorKey = 'saved_author';
  static const String _timestampKey = 'saved_timestamp';

  static Future<void> saveQuote(String quote, String author) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_quoteKey, quote);
    await prefs.setString(_authorKey, author);
    await prefs.setString(_timestampKey, DateTime.now().toIso8601String());
  }

  static Future<Map<String, dynamic>?> getSavedQuote() async {
    final prefs = await SharedPreferences.getInstance();
    final timestampStr = prefs.getString(_timestampKey);

    if (timestampStr == null) return null;

    final timestamp = DateTime.parse(timestampStr);
    final now = DateTime.now();

    if (now.difference(timestamp).inHours > 24) {
      return null;
    }

    final quote = prefs.getString(_quoteKey);
    final author = prefs.getString(_authorKey);

    if (quote == null || author == null) return null;

    return {'quote': quote, 'author': author};
  }

  static Future<void> clearSavedQuote() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_quoteKey);
    await prefs.remove(_authorKey);
    await prefs.remove(_timestampKey);
  }
}
