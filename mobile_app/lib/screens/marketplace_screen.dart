import 'package:flutter/material.dart';
import '../ui/uniserve_ui.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PremiumScaffold(
      title: 'Marketplace',
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),

            // Header
            const UText('Find & Post Stuff', size: 20, weight: FontWeight.w900),
            const SizedBox(height: 6),
            Text(
              'Barang, service, delivery, makanan — semua boleh. '
              'Start browse dulu sementara orang lain belum banyak post.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: .75),
                height: 1.35,
              ),
            ),

            const SizedBox(height: 14),

            // Search bar (UI sahaja)
            _SearchBar(
              hintText: 'Search item / service (coming soon)',
              onTap: () {
                // nanti boleh link ke search screen
                // Navigator.pushNamed(context, '/marketplace-search');
              },
            ),

            const SizedBox(height: 14),

            // Quick actions
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    text: 'Post Item',
                    onTap: () =>
                        Navigator.pushNamed(context, '/marketplace-post'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SecondaryButton(
                    text: 'Browse',
                    icon: Icons.explore_rounded,
                    onTap: () {
                      // optional: scroll ke bawah / atau route browse
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Categories
            _SectionTitle(
              title: 'Categories',
              subtitle: 'Tap untuk filter (UI dulu)',
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  SizedBox(width: 2),
                  _CategoryChip(label: 'All', icon: Icons.grid_view_rounded),
                  _CategoryChip(
                      label: 'Services', icon: Icons.handyman_rounded),
                  _CategoryChip(
                      label: 'Food', icon: Icons.fastfood_rounded),
                  _CategoryChip(
                      label: 'Delivery', icon: Icons.local_shipping_rounded),
                  _CategoryChip(
                      label: 'Items', icon: Icons.shopping_bag_rounded),
                  _CategoryChip(
                      label: 'Rent', icon: Icons.home_work_rounded),
                  SizedBox(width: 8),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Featured / Trending
            _SectionTitle(
              title: 'Featured',
              subtitle: 'Highlight post paling hot (placeholder)',
              trailing: TextButton(
                onPressed: () {},
                child: const Text('See all'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 140,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  SizedBox(width: 2),
                  _FeaturedCard(
                    title: 'Laundry Pickup',
                    subtitle: 'Fast • Reliable',
                    badge: 'Coming Soon',
                    icon: Icons.local_laundry_service_rounded,
                  ),
                  _FeaturedCard(
                    title: 'Runner Service',
                    subtitle: 'UIA • Nearby',
                    badge: 'Coming Soon',
                    icon: Icons.directions_run_rounded,
                  ),
                  _FeaturedCard(
                    title: 'Home-cooked Food',
                    subtitle: 'Pre-order • Daily',
                    badge: 'Coming Soon',
                    icon: Icons.ramen_dining_rounded,
                  ),
                  SizedBox(width: 8),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Recent posts (Empty state)
            _SectionTitle(
              title: 'Recent posts',
              subtitle: 'Latest listing dekat sini',
            ),
            const SizedBox(height: 10),
            const _EmptyStateCard(
              title: 'No posts yet',
              subtitle:
                  'Jadi orang pertama post. Lepas tu listing orang lain akan muncul kat sini.',
              icon: Icons.inbox_rounded,
            ),

            const SizedBox(height: 14),

            // Tips / info card (bagi nampak ada isi)
            const _InfoTipCard(
              title: 'Tip cepat',
              bullets: [
                'Letak gambar clear + harga siap.',
                'Tulis lokasi (Mahallah / KICT / dll).',
                'Letak contact (WhatsApp/Telegram).',
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final String hintText;
  final VoidCallback? onTap;

  const _SearchBar({
    required this.hintText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded,
                color: theme.iconTheme.color?.withValues(alpha: 0.7)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hintText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.65),
                ),
              ),
            ),
            Icon(Icons.tune_rounded,
                color: theme.iconTheme.color?.withValues(alpha: 0.55)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const _SectionTitle({
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UText(title, size: 16, weight: FontWeight.w900),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _CategoryChip({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: theme.iconTheme.color?.withValues(alpha: 0.8)),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;

  const _FeaturedCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.25)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.18),
            theme.cardColor.withValues(alpha: 0.60),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.primary.withValues(alpha: 0.20),
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: theme.colorScheme.secondary.withValues(alpha: 0.18),
                ),
                child: Text(
                  badge,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _EmptyStateCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: theme.colorScheme.primary.withValues(alpha: 0.14),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTipCard extends StatelessWidget {
  final String title;
  final List<String> bullets;

  const _InfoTipCard({
    required this.title,
    required this.bullets,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.25)),
        color: theme.colorScheme.surface.withValues(alpha: .5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ...bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(Icons.check_circle_rounded,
                        size: 16,
                        color: theme.colorScheme.primary.withValues(alpha: 0.9)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      b,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.textTheme.bodySmall?.color?.withValues(alpha: 0.75),
                      ),
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
}

class _SecondaryButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: theme.cardColor.withValues(alpha: 0.55),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: theme.iconTheme.color?.withValues(alpha: 0.8)),
            const SizedBox(width: 8),
            Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
