class PromoBanner {
  final String id;

  /// Bundled fallback image — used when [imageUrl] is null.
  final String? imageAsset;

  /// Real `banners[].image_url` from the API — takes priority when set.
  final String? imageUrl;

  const PromoBanner({required this.id, this.imageAsset, this.imageUrl});
}
