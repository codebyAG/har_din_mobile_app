import 'package:flutter/foundation.dart';

import '../../data/datasources/local/local_store.dart';
import '../../domain/entities/content_entities.dart';

/// A design the user downloaded/favorited, recorded only by its id +
/// image URLs — enough to render a card and re-share it, without
/// needing the full `designs[]` payload still in memory.
class SavedDesignRecord {
  final String id;
  final String categoryId;
  final String thumbnailUrl;
  final String displayUrl;
  final DateTime savedAt;

  const SavedDesignRecord({
    required this.id,
    required this.categoryId,
    required this.thumbnailUrl,
    required this.displayUrl,
    required this.savedAt,
  });

  factory SavedDesignRecord.fromDesign(Design design) => SavedDesignRecord(
        id: design.id,
        categoryId: design.categoryId,
        thumbnailUrl: design.thumbnailUrl,
        displayUrl: design.displayUrl,
        savedAt: DateTime.now(),
      );

  factory SavedDesignRecord.fromJson(Map<String, dynamic> json) => SavedDesignRecord(
        id: json['id'] as String,
        categoryId: json['categoryId'] as String,
        thumbnailUrl: json['thumbnailUrl'] as String,
        displayUrl: json['displayUrl'] as String,
        savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'thumbnailUrl': thumbnailUrl,
        'displayUrl': displayUrl,
        'savedAt': savedAt.toIso8601String(),
      };

  /// Minimal [Design] good enough for re-sharing — only the fields
  /// ShareService/PreviewShareScreen actually read are real; the rest
  /// are harmless placeholders since this design is never re-fetched.
  Design toDesign() => Design(
        id: id,
        categoryId: categoryId,
        mediaType: 'image',
        scope: 'language',
        thumbnailUrl: thumbnailUrl,
        displayUrl: displayUrl,
        originalUrl: '',
        width: 0,
        height: 0,
        timeBand: 'always',
        tagIds: const [],
        slots: const {},
        sortOrder: 0,
        publishedAt: null,
        stats: const DesignStats(views: 0, shares: 0, downloads: 0),
      );
}

/// My Creations (§5) — downloaded/favorited designs, local storage only,
/// never sent to the server. Registered as a `ChangeNotifierProvider`.
class SavedDesignsController extends ChangeNotifier {
  final LocalStore _store;

  SavedDesignsController({LocalStore store = const LocalStore()}) : _store = store {
    _hydrate();
  }

  List<SavedDesignRecord> _downloaded = [];
  List<SavedDesignRecord> get downloaded => _downloaded;

  List<SavedDesignRecord> _favorites = [];
  List<SavedDesignRecord> get favorites => _favorites;

  Future<void> _hydrate() async {
    _downloaded = (await _store.getDownloadedDesigns()).map(SavedDesignRecord.fromJson).toList();
    _favorites = (await _store.getFavoriteDesigns()).map(SavedDesignRecord.fromJson).toList();
    notifyListeners();
  }

  bool isFavorite(String designId) => _favorites.any((r) => r.id == designId);

  Future<void> recordDownload(Design design) async {
    await _store.addDownloadedDesign(SavedDesignRecord.fromDesign(design).toJson());
    _downloaded = (await _store.getDownloadedDesigns()).map(SavedDesignRecord.fromJson).toList();
    notifyListeners();
  }

  Future<void> toggleFavorite(Design design) async {
    await _store.toggleFavoriteDesign(SavedDesignRecord.fromDesign(design).toJson());
    _favorites = (await _store.getFavoriteDesigns()).map(SavedDesignRecord.fromJson).toList();
    notifyListeners();
  }
}
