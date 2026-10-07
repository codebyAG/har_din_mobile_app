import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// The "Premium में आपको क्या मिलेगा?" artwork: heading, subtitle and the
/// 8-benefit grid, shown under the banner.
class PremiumFeaturesImage extends StatelessWidget {
  static const String asset = 'assets/premiumpage/premeium_grid_section.png';

  // The artwork is 1066px wide and its cards sit 22px in from each edge, so
  // the cards span 1022px of it. Scale the image so those cards line up with
  // the banner's side padding instead of being inset a second time.
  static const double _imageWidth = 1066;
  static const double _cardsWidth = 1022;

  // Last card ends at ~1385px of the 1476px height; trim most of the empty
  // strip below it so there's no big gap before the plans.
  static const double _imageHeight = 1476;
  static const double _visibleHeight = 1405;

  const PremiumFeaturesImage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final contentWidth = screenWidth - AppSpacing.screenPadding * 2;
    final imageWidth = contentWidth * _imageWidth / _cardsWidth;
    return ClipRect(
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: _visibleHeight / _imageHeight,
        child: Image.asset(
          asset,
          width: imageWidth,
          fit: BoxFit.fitWidth,
          // The source PNG is ~1.7 MB — decode at display size.
          cacheWidth: (imageWidth * dpr).round(),
          semanticLabel:
              'Premium mein aapko kya milega: apna naam aur photo, hazaaron '
              'premium status, har tyohaar ka special collection, famous baba '
              'aur speakers, video status, high quality download, bina ads ke, '
              'har din kuch naya',
        ),
      ),
    );
  }
}
