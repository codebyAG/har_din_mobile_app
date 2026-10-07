import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/premium/premium_banner.dart';
import '../widgets/premium/premium_cta.dart';
import '../widgets/premium/premium_features_image.dart';
import '../widgets/premium/premium_header.dart';
import '../widgets/premium/premium_plan_card.dart';

enum _Plan { monthly, yearly }

/// "HarDin Premium" — banner, what Premium adds, plan choice and the CTA.
/// Pricing/payment is UI-only for now; [_onActivate] is the hook.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  // Matches the cream background baked into the features artwork so the
  // image blends into the page with no visible edge.
  static const Color _screenBackground = Color(0xFFFCFAF5);

  _Plan _plan = _Plan.yearly;

  void _onActivate() {
    // Payment isn't integrated yet — this is the hook for the billing flow.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Premium जल्द ही शुरू होगा')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: PremiumHeader()),
                  const SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    sliver: SliverToBoxAdapter(child: PremiumBanner()),
                  ),
                  const SliverPadding(
                    padding: EdgeInsets.only(top: AppSpacing.md),
                    sliver: SliverToBoxAdapter(child: PremiumFeaturesImage()),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      AppSpacing.sm,
                      AppSpacing.screenPadding,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Apna Plan Choose Karein',
                        style: AppTextStyles.sectionHeading(),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      AppSpacing.lg,
                      AppSpacing.screenPadding,
                      AppSpacing.xxl,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: PremiumPlanCard(
                                title: '1 Mahina',
                                price: '₹49',
                                caption: 'प्रति महीना',
                                selected: _plan == _Plan.monthly,
                                onTap: () =>
                                    setState(() => _plan = _Plan.monthly),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: PremiumPlanCard(
                                title: '12 Mahine',
                                price: '₹399',
                                caption: 'सिर्फ ₹33 प्रति महीना',
                                badge: 'Best Value',
                                selected: _plan == _Plan.yearly,
                                onTap: () =>
                                    setState(() => _plan = _Plan.yearly),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Sticky bottom bar — stays visible while the page scrolls.
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.md,
                AppSpacing.screenPadding,
                AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.card,
                border: const Border(top: BorderSide(color: AppColors.border)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: PremiumCTA(onPressed: _onActivate),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
