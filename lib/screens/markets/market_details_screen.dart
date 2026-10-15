import 'package:flutter/material.dart';

import '../../models/markets/market_place.dart';

class MarketDetailsScreen extends StatelessWidget {
  const MarketDetailsScreen({
    super.key,
    required this.market,
    this.isFavorite = false,
    this.onFavorite,
    this.onDirections,
  });

  final MarketPlace market;
  final bool isFavorite;
  final VoidCallback? onFavorite;
  final VoidCallback? onDirections;

  static const Color _green = Color(0xFF176B52);
  static const Color _greenDark = Color(0xFF0D4D3B);
  static const Color _gold = Color(0xFFD5AE5B);
  static const Color _background = Color(0xFFFAF7F0);
  static const Color _ink = Color(0xFF17322A);
  static const Color _muted = Color(0xFF6B7B74);
  static const Color _border = Color(0xFFEDE7D6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 290,
              pinned: true,
              stretch: true,
              backgroundColor: _green,
              foregroundColor: Colors.white,
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: _CircleButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: _CircleButton(
                    icon: isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    iconColor: isFavorite ? _gold : _greenDark,
                    onTap: onFavorite,
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHero(),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  20,
                  18,
                  36,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTitle(),

                    const SizedBox(height: 18),

                    _buildQuickActions(context),

                    const SizedBox(height: 24),

                    _SectionCard(
                      title: 'عن المكان',
                      icon: Icons.storefront_rounded,
                      child: Text(
                        market.description,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 13.5,
                          height: 1.8,
                        ),
                      ),
                    ),

                    if (market.tags.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _buildShoppingSection(),
                    ],

                    if (market.address != null &&
                        market.address!.trim().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: 'الموقع',
                        icon: Icons.location_on_rounded,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              market.address!,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 13,
                                height: 1.6,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _VerificationNote(
                              verified: market.hasCoordinates,
                              verifiedText:
                                  'الموقع متاح على الخريطة.',
                              reviewText:
                                  'الاتجاهات غير متاحة حتى يتم التحقق من إحداثيات المكان.',
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (market.openingHours != null &&
                        market.openingHours!.trim().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: 'مواعيد العمل',
                        icon: Icons.schedule_rounded,
                        child: Text(
                          market.openingHours!,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 13,
                            height: 1.6,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],

                    if (market.hasContactInfo) ...[
                      const SizedBox(height: 14),
                      _buildContactSection(),
                    ],

                    if (market.accessibilityVerified) ...[
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: 'سهولة الوصول',
                        icon: Icons.accessible_rounded,
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                market.hasWheelchairAccess
                                    ? 'تتوفر معلومات موثقة عن سهولة الوصول بالكراسي المتحركة.'
                                    : 'لا توجد إشارة موثقة حاليًا إلى توفر الوصول بالكراسي المتحركة.',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  color: _ink,
                                  fontSize: 13,
                                  height: 1.6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              market.hasWheelchairAccess
                                  ? Icons.check_circle_rounded
                                  : Icons.info_outline_rounded,
                              color: market.hasWheelchairAccess
                                  ? _green
                                  : _muted,
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    _buildFacilities(),

                    const SizedBox(height: 14),

                    _buildVerification(),

                    const SizedBox(height: 24),

                    _buildBottomDirectionsButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    final imageUrl = market.imageUrl;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrl != null && imageUrl.trim().isNotEmpty)
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return _heroPlaceholder();
            },
          )
        else
          _heroPlaceholder(),

        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Color(0xB3000000),
              ],
            ),
          ),
        ),

        Positioned(
          bottom: 20,
          right: 18,
          left: 18,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      market.categoryEmoji,
                      style: const TextStyle(fontSize: 17),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      market.categoryName,
                      style: const TextStyle(
                        color: _greenDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroPlaceholder() {
    return Container(
      color: _green,
      alignment: Alignment.center,
      child: Text(
        market.categoryEmoji,
        style: const TextStyle(
          fontSize: 80,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          market.name,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: _ink,
            fontSize: 25,
            height: 1.3,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              market.cityName,
              style: const TextStyle(
                color: _green,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.location_on_rounded,
              color: _gold,
              size: 18,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          market.shortDescription,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: _muted,
            fontSize: 13.5,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.favorite_border_rounded,
            label: 'حفظ',
            onTap: onFavorite,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickAction(
            icon: Icons.share_rounded,
            label: 'مشاركة',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'سيتم تفعيل مشاركة المكان لاحقًا.',
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickAction(
            icon: Icons.directions_rounded,
            label: 'الاتجاهات',
            enabled: market.hasCoordinates,
            onTap: market.hasCoordinates
                ? onDirections
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildShoppingSection() {
    return _SectionCard(
      title: 'ماذا ستجد هنا؟',
      icon: Icons.shopping_bag_rounded,
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 7,
        runSpacing: 7,
        children: market.tags.map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: _background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _border,
              ),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                color: _greenDark,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContactSection() {
    return _SectionCard(
      title: 'التواصل',
      icon: Icons.contact_phone_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (market.phone != null &&
              market.phone!.trim().isNotEmpty)
            _DetailRow(
              icon: Icons.phone_rounded,
              label: 'الهاتف',
              value: market.phone!,
            ),
          if (market.phone != null &&
              market.phone!.trim().isNotEmpty &&
              market.website != null &&
              market.website!.trim().isNotEmpty)
            const Divider(
              height: 22,
              color: _border,
            ),
          if (market.website != null &&
              market.website!.trim().isNotEmpty)
            _DetailRow(
              icon: Icons.language_rounded,
              label: 'الموقع الإلكتروني',
              value: market.website!,
            ),
        ],
      ),
    );
  }

  Widget _buildFacilities() {
    return _SectionCard(
      title: 'الخدمات',
      icon: Icons.grid_view_rounded,
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          if (market.hasFood)
            const _Facility(
              icon: Icons.restaurant_rounded,
              text: 'طعام',
            ),
          if (market.hasParking)
            const _Facility(
              icon: Icons.local_parking_rounded,
              text: 'مواقف',
            ),
          if (market.accessibilityVerified &&
              market.hasWheelchairAccess)
            const _Facility(
              icon: Icons.accessible_rounded,
              text: 'سهولة وصول',
            ),
          if (market.hasCoordinates)
            const _Facility(
              icon: Icons.map_rounded,
              text: 'موقع موضح',
            ),
          if (!market.hasFood &&
              !market.hasParking &&
              !(market.accessibilityVerified &&
                  market.hasWheelchairAccess) &&
              !market.hasCoordinates)
            const Text(
              'لا توجد معلومات خدمات موثقة متاحة حاليًا.',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: _muted,
                fontSize: 12.5,
                height: 1.6,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVerification() {
    final verified =
        market.verificationStatus ==
        MarketVerificationStatus.verified;

    return _SectionCard(
      title: 'حالة المعلومات',
      icon: Icons.verified_user_rounded,
      child: _VerificationNote(
        verified: verified,
        verifiedText:
            'تم التحقق من بيانات هذا المكان قبل عرضها.',
        reviewText:
            'بعض بيانات هذا المكان ما زالت قيد المراجعة، لذلك لن تُستخدم المعلومات غير المؤكدة في التوجيه.',
      ),
    );
  }

  Widget _buildBottomDirectionsButton() {
    return FilledButton.icon(
      onPressed:
          market.hasCoordinates ? onDirections : null,
      icon: const Icon(
        Icons.directions_rounded,
      ),
      label: Text(
        market.hasCoordinates
            ? 'الحصول على الاتجاهات'
            : 'الاتجاهات غير متاحة حاليًا',
      ),
      style: FilledButton.styleFrom(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        disabledBackgroundColor:
            _muted.withValues(alpha: 0.18),
        disabledForegroundColor: _muted,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  static const Color _green = Color(0xFF176B52);
  static const Color _ink = Color(0xFF17322A);
  static const Color _border = Color(0xFFEDE7D6);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 7),
              Icon(
                icon,
                color: _green,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  static const Color _green = Color(0xFF176B52);
  static const Color _muted = Color(0xFF6B7B74);
  static const Color _border = Color(0xFFEDE7D6);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? Colors.white : Colors.white54,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 6,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: enabled ? _green : _muted,
                size: 21,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  color: enabled ? _green : _muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  static const Color _green = Color(0xFF176B52);
  static const Color _ink = Color(0xFF17322A);
  static const Color _muted = Color(0xFF6B7B74);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 10.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Icon(
          icon,
          color: _green,
          size: 20,
        ),
      ],
    );
  }
}

class _Facility extends StatelessWidget {
  const _Facility({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  static const Color _green = Color(0xFF176B52);
  static const Color _greenDark = Color(0xFF0D4D3B);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: _green.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: _green,
            size: 16,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: _greenDark,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationNote extends StatelessWidget {
  const _VerificationNote({
    required this.verified,
    required this.verifiedText,
    required this.reviewText,
  });

  final bool verified;
  final String verifiedText;
  final String reviewText;

  static const Color _green = Color(0xFF176B52);
  static const Color _gold = Color(0xFFD5AE5B);
  static const Color _ink = Color(0xFF17322A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: verified
            ? _green.withValues(alpha: 0.07)
            : _gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              verified ? verifiedText : reviewText,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _ink,
                fontSize: 11.5,
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Icon(
            verified
                ? Icons.verified_rounded
                : Icons.fact_check_outlined,
            color: verified ? _green : _gold,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color? iconColor;

  static const Color _greenDark = Color(0xFF0D4D3B);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            color: iconColor ?? _greenDark,
            size: 21,
          ),
        ),
      ),
    );
  }
}