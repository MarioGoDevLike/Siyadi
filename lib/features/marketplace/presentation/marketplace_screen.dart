import 'package:flutter/material.dart';

import '../../../core/widgets/feature_placeholder.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Marketplace',
      subtitle:
          'Permitted hunting equipment and accessories. Contact sellers — no checkout in MVP.',
      icon: Icons.storefront_outlined,
    );
  }
}
