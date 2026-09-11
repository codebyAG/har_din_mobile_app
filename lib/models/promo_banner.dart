/// A `banners[]` entry. Real `image_url` only — there is no bundled
/// fallback banner; when the API has none, the carousel simply isn't shown.
class PromoBanner {
  final String id;
  final String imageUrl;

  const PromoBanner({required this.id, required this.imageUrl});
}
