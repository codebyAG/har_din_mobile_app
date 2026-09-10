/// Domain entities matching the Har Din v1 API contract (see
/// HAR-DIN-INTEGRATION.md). Committed to the repo per §14 — never
/// generated or fetched at runtime.
///
/// Pragmatic choice for this app's size: these double as the data
/// layer's DTOs (fromJson/toJson live here rather than in a separate
/// mapper class) instead of a full duplicate entity/model split — there
/// is exactly one data source and no divergent business shape to
/// decouple from. The layering that matters — screens depending on the
/// repository *interface*, never on ApiClient/LocalStore directly — is
/// enforced regardless.
library;

class VersionResponse {
  final int content;

  const VersionResponse({required this.content});

  factory VersionResponse.fromJson(Map<String, dynamic> json) =>
      VersionResponse(content: json['content'] as int);
}

class Language {
  final String code;
  final String label;

  const Language({required this.code, required this.label});

  factory Language.fromJson(Map<String, dynamic> json) => Language(
        code: json['code'] as String,
        label: json['label'] as String,
      );
}

/// `[start, endExclusive]` in local 24h time. Night wraps midnight
/// (e.g. `[20, 4]`) — callers must handle that, see TimeBandService.
class TimeBandRange {
  final int start;
  final int endExclusive;

  const TimeBandRange({required this.start, required this.endExclusive});

  factory TimeBandRange.fromJson(List<dynamic> json) => TimeBandRange(
        start: json[0] as int,
        endExclusive: json[1] as int,
      );

  bool contains(int hour) {
    if (start <= endExclusive) {
      return hour >= start && hour < endExclusive;
    }
    // Wraps midnight, e.g. night [20, 4].
    return hour >= start || hour < endExclusive;
  }
}

class HomeConfig {
  final String? carouselCategoryId;
  final List<String> categoryOrder;
  final Map<String, List<String>> timeBandCategories;

  const HomeConfig({
    required this.carouselCategoryId,
    required this.categoryOrder,
    required this.timeBandCategories,
  });

  factory HomeConfig.fromJson(Map<String, dynamic> json) => HomeConfig(
        carouselCategoryId: json['carousel_category_id'] as String?,
        categoryOrder: (json['category_order'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
        timeBandCategories: (json['time_band_categories'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as List<dynamic>).map((e) => e as String).toList())),
      );
}

class ApiBanner {
  final String id;
  final String imageUrl;
  final String target;
  final String targetRef;
  final int sortOrder;

  const ApiBanner({
    required this.id,
    required this.imageUrl,
    required this.target,
    required this.targetRef,
    required this.sortOrder,
  });

  factory ApiBanner.fromJson(Map<String, dynamic> json) => ApiBanner(
        id: json['id'] as String,
        imageUrl: json['image_url'] as String,
        target: json['target'] as String,
        targetRef: json['target_ref'] as String? ?? '',
        sortOrder: json['sort_order'] as int? ?? 0,
      );
}

class ApiCategory {
  final String id;
  final String? parentId;
  final String name;
  final String? iconUrl;
  final String? coverUrl;
  final String layout;
  final int sortOrder;

  const ApiCategory({
    required this.id,
    required this.parentId,
    required this.name,
    required this.iconUrl,
    required this.coverUrl,
    required this.layout,
    required this.sortOrder,
  });

  factory ApiCategory.fromJson(Map<String, dynamic> json) => ApiCategory(
        id: json['id'] as String,
        parentId: json['parent_id'] as String?,
        name: json['name'] as String,
        iconUrl: json['icon_url'] as String?,
        coverUrl: json['cover_url'] as String?,
        layout: json['layout'] as String? ?? 'grid',
        sortOrder: json['sort_order'] as int? ?? 0,
      );
}

class Tag {
  final String id;
  final String name;
  final List<String> terms;

  const Tag({required this.id, required this.name, required this.terms});

  factory Tag.fromJson(Map<String, dynamic> json) => Tag(
        id: json['id'] as String,
        name: json['name'] as String,
        terms: (json['terms'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
      );
}

class DesignStats {
  final int views;
  final int shares;
  final int downloads;

  const DesignStats({required this.views, required this.shares, required this.downloads});

  factory DesignStats.fromJson(Map<String, dynamic>? json) => DesignStats(
        views: json?['views'] as int? ?? 0,
        shares: json?['shares'] as int? ?? 0,
        downloads: json?['downloads'] as int? ?? 0,
      );
}

class Design {
  final String id;
  final String categoryId;
  final String mediaType;
  final String scope;
  final String thumbnailUrl;
  final String displayUrl;
  final String originalUrl;
  final int width;
  final int height;
  final String timeBand;
  final List<String> tagIds;
  final Map<String, dynamic> slots;
  final int sortOrder;
  final DateTime? publishedAt;
  final DesignStats stats;

  const Design({
    required this.id,
    required this.categoryId,
    required this.mediaType,
    required this.scope,
    required this.thumbnailUrl,
    required this.displayUrl,
    required this.originalUrl,
    required this.width,
    required this.height,
    required this.timeBand,
    required this.tagIds,
    required this.slots,
    required this.sortOrder,
    required this.publishedAt,
    required this.stats,
  });

  /// §7 — `always` is evergreen, not a literal clock band.
  bool matchesBand(String currentBand) => timeBand == 'always' || timeBand == currentBand;

  factory Design.fromJson(Map<String, dynamic> json) => Design(
        id: json['id'] as String,
        categoryId: json['category_id'] as String,
        mediaType: json['media_type'] as String? ?? 'image',
        scope: json['scope'] as String? ?? 'language',
        thumbnailUrl: json['thumbnail_url'] as String,
        displayUrl: json['display_url'] as String,
        originalUrl: json['original_url'] as String? ?? '',
        width: json['width'] as int? ?? 0,
        height: json['height'] as int? ?? 0,
        timeBand: json['time_band'] as String? ?? 'always',
        tagIds: (json['tag_ids'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
        slots: (json['slots'] as Map<String, dynamic>? ?? {}),
        sortOrder: json['sort_order'] as int? ?? 0,
        publishedAt:
            json['published_at'] != null ? DateTime.tryParse(json['published_at'] as String) : null,
        stats: DesignStats.fromJson(json['stats'] as Map<String, dynamic>?),
      );
}

class Occasion {
  final String id;
  final String name;
  final DateTime date;
  final String categoryId;
  final String community;
  final String? imageUrl;

  const Occasion({
    required this.id,
    required this.name,
    required this.date,
    required this.categoryId,
    required this.community,
    required this.imageUrl,
  });

  int daysUntil(DateTime from) {
    final today = DateTime(from.year, from.month, from.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.difference(today).inDays;
  }

  factory Occasion.fromJson(Map<String, dynamic> json) => Occasion(
        id: json['id'] as String,
        name: json['name'] as String,
        date: DateTime.parse(json['date'] as String),
        categoryId: json['category_id'] as String,
        community: json['community'] as String? ?? 'other',
        imageUrl: json['image_url'] as String?,
      );
}

class ContentPayload {
  final int version;
  final List<Language> languages;
  final Map<String, TimeBandRange> timeBands;
  final HomeConfig home;
  final List<ApiBanner> banners;
  final List<ApiCategory> categories;
  final List<Tag> tags;
  final List<Design> designs;
  final List<Occasion> occasions;

  const ContentPayload({
    required this.version,
    required this.languages,
    required this.timeBands,
    required this.home,
    required this.banners,
    required this.categories,
    required this.tags,
    required this.designs,
    required this.occasions,
  });

  factory ContentPayload.fromJson(Map<String, dynamic> json) => ContentPayload(
        version: json['version'] as int,
        languages: (json['languages'] as List<dynamic>? ?? [])
            .map((e) => Language.fromJson(e as Map<String, dynamic>))
            .toList(),
        timeBands: (json['time_bands'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, TimeBandRange.fromJson(v as List<dynamic>))),
        home: HomeConfig.fromJson(json['home'] as Map<String, dynamic>? ?? const {}),
        banners: (json['banners'] as List<dynamic>? ?? [])
            .map((e) => ApiBanner.fromJson(e as Map<String, dynamic>))
            .toList(),
        categories: (json['categories'] as List<dynamic>? ?? [])
            .map((e) => ApiCategory.fromJson(e as Map<String, dynamic>))
            .toList(),
        tags: (json['tags'] as List<dynamic>? ?? [])
            .map((e) => Tag.fromJson(e as Map<String, dynamic>))
            .toList(),
        designs: (json['designs'] as List<dynamic>? ?? [])
            // §7 — skip media types this build cannot render, don't assume.
            .map((e) => Design.fromJson(e as Map<String, dynamic>))
            .where((d) => d.mediaType == 'image')
            .toList(),
        occasions: (json['occasions'] as List<dynamic>? ?? [])
            .map((e) => Occasion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'version': version,
        'languages': languages.map((l) => {'code': l.code, 'label': l.label}).toList(),
        'time_bands':
            timeBands.map((k, v) => MapEntry(k, [v.start, v.endExclusive])),
        'home': {
          'carousel_category_id': home.carouselCategoryId,
          'category_order': home.categoryOrder,
          'time_band_categories': home.timeBandCategories,
        },
        'banners': banners
            .map((b) => {
                  'id': b.id,
                  'image_url': b.imageUrl,
                  'target': b.target,
                  'target_ref': b.targetRef,
                  'sort_order': b.sortOrder,
                })
            .toList(),
        'categories': categories
            .map((c) => {
                  'id': c.id,
                  'parent_id': c.parentId,
                  'name': c.name,
                  'icon_url': c.iconUrl,
                  'cover_url': c.coverUrl,
                  'layout': c.layout,
                  'sort_order': c.sortOrder,
                })
            .toList(),
        'tags': tags.map((t) => {'id': t.id, 'name': t.name, 'terms': t.terms}).toList(),
        'designs': designs
            .map((d) => {
                  'id': d.id,
                  'category_id': d.categoryId,
                  'media_type': d.mediaType,
                  'scope': d.scope,
                  'thumbnail_url': d.thumbnailUrl,
                  'display_url': d.displayUrl,
                  'original_url': d.originalUrl,
                  'width': d.width,
                  'height': d.height,
                  'time_band': d.timeBand,
                  'tag_ids': d.tagIds,
                  'slots': d.slots,
                  'sort_order': d.sortOrder,
                  'published_at': d.publishedAt?.toIso8601String(),
                  'stats': {
                    'views': d.stats.views,
                    'shares': d.stats.shares,
                    'downloads': d.stats.downloads,
                  },
                })
            .toList(),
        'occasions': occasions
            .map((o) => {
                  'id': o.id,
                  'name': o.name,
                  'date': o.date.toIso8601String().split('T').first,
                  'category_id': o.categoryId,
                  'community': o.community,
                  'image_url': o.imageUrl,
                })
            .toList(),
      };
}
