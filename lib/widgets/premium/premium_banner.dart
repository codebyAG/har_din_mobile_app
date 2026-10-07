import 'package:flutter/material.dart';

/// Premium banner artwork as a rounded card below the top bar.
class PremiumBanner extends StatelessWidget {
  static const String asset = 'assets/premiumpage/hardin_premium_banner.png';

  const PremiumBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.asset(
        asset,
        width: double.infinity,
        fit: BoxFit.fitWidth,
        // The source PNG is 1774px wide (~2 MB) — decode at screen size.
        cacheWidth: (width * dpr).round(),
        semanticLabel: 'HarDin Premium — Roz ke Status ko banaye aur bhi khaas',
      ),
    );
  }
}
