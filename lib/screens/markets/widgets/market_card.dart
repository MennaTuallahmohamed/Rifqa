import 'package:flutter/material.dart';

import '../../../models/markets/market_place.dart';

class MarketCard extends StatelessWidget {
  const MarketCard({
    super.key,
    required this.market,
    required this.isFavorite,
    required this.onFavorite,
    required this.onDetails,
    required this.onDirections,
  });

  final MarketPlace market;
  final bool isFavorite;

  final VoidCallback onFavorite;
  final VoidCallback onDetails;
  final VoidCallback onDirections;

  static const Color _green = Color(0xFF176B52);
  static const Color _greenDark = Color(0xFF0D4D3B);
  static const Color _gold = Color(0xFFD5AE5B);
  static const Color _background = Color(0xFFFAF7F0);
  static const Color _ink = Color(0xFF17322A);
  static const Color _muted = Color(0xFF6B7B74);
  static const Color _border = Color(0xFFEDE7D6);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildImage(),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              15,
              16,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),

                const SizedBox(height: 10),

                Text(
                  market.shortDescription,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12.5,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 12),

                _buildInformation(),

                if (market.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildTags(),
                ],

                const SizedBox(height: 15),

                _buildActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return SizedBox(
      height: 165,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _marketImage(),

          Positioned(
            top: 12,
            right: 12,
            child: _FavoriteButton(
              selected: isFavorite,
              onTap: onFavorite,
            ),
          ),

          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
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
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    market.categoryName,
                    style: const TextStyle(
                      color: _greenDark,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (market.isRecommended)
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _gold,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                      color: _greenDark,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'مقترح لك',
                      style: TextStyle(
                        color: _greenDark,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _marketImage() {
    final imageUrl = market.imageUrl;

    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return _imagePlaceholder();
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return _imagePlaceholder();
      },
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: _background,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            market.categoryEmoji,
            style: const TextStyle(
              fontSize: 44,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'صورة المكان ستظهر هنا',
            style: TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                market.name,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 17,
                  height: 1.3,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      market.cityName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _green,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.location_on_rounded,
                    color: _gold,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInformation() {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 7,
      runSpacing: 7,
      children: [
        if (market.isPopular)
          const _InfoBadge(
            icon: Icons.local_fire_department_rounded,
            label: 'شائع',
          ),

        if (market.hasFood)
          const _InfoBadge(
            icon: Icons.restaurant_rounded,
            label: 'طعام',
          ),

        if (market.hasParking)
          const _InfoBadge(
            icon: Icons.local_parking_rounded,
            label: 'مواقف',
          ),

        if (market.accessibilityVerified &&
            market.hasWheelchairAccess)
          const _InfoBadge(
            icon: Icons.accessible_rounded,
            label: 'سهولة وصول',
          ),

        if (market.hasCoordinates)
          const _InfoBadge(
            icon: Icons.map_rounded,
            label: 'على الخريطة',
          ),
      ],
    );
  }

  Widget _buildTags() {
    final visibleTags = market.tags.take(4).toList();

    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 6,
      runSpacing: 6,
      children: visibleTags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: _background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            tag,
            style: const TextStyle(
              color: _greenDark,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: market.hasCoordinates
                ? onDirections
                : null,
            icon: const Icon(
              Icons.directions_rounded,
              size: 18,
            ),
            label: const Text('الاتجاهات'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _green,
              disabledForegroundColor:
                  _muted.withValues(alpha: 0.55),
              side: BorderSide(
                color: market.hasCoordinates
                    ? _green.withValues(alpha: 0.35)
                    : _border,
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),

        const SizedBox(width: 9),

        Expanded(
          child: FilledButton.icon(
            onPressed: onDetails,
            icon: const Icon(
              Icons.arrow_back_rounded,
              size: 18,
            ),
            label: const Text('التفاصيل'),
            style: FilledButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  static const Color _greenDark = Color(0xFF0D4D3B);
  static const Color _gold = Color(0xFFD5AE5B);

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
            selected
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: selected ? _gold : _greenDark,
            size: 21,
          ),
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  static const Color _green = Color(0xFF176B52);
  static const Color _greenDark = Color(0xFF0D4D3B);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: _green.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: _green,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: _greenDark,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}