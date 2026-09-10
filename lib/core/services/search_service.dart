import '../../domain/entities/content_entities.dart';

/// Filters the already-downloaded payload — there is no search endpoint,
/// deliberately (§9). `Tag.terms` already contains every language's name
/// plus aliases, lowercased, which is how "deepavali" finds Diwali.
class SearchService {
  SearchService._();

  static List<Design> search(String query, List<Design> designs, List<Tag> tags) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return designs;

    final matchedTagIds = tags
        .where((t) => t.terms.any((term) => term.toLowerCase().contains(q)))
        .map((t) => t.id)
        .toSet();

    return designs.where((d) => d.tagIds.any(matchedTagIds.contains)).toList();
  }
}
