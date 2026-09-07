import 'package:flutter/material.dart';

import '../../../models/gig_draft.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';
import 'labour_price_preview_screen.dart';

class MaterialProcurementScreen extends StatefulWidget {
  const MaterialProcurementScreen({super.key, required this.draft});

  final GigDraft draft;

  @override
  State<MaterialProcurementScreen> createState() =>
      _MaterialProcurementScreenState();
}

class _MaterialProcurementScreenState extends State<MaterialProcurementScreen> {
  late bool _customerBuysMaterials = widget.draft.customerBuysMaterials;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Materials')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StepHeader(step: '2 of 3', title: 'Who buys the materials?'),
            const SizedBox(height: 10),
            const Text(
              'Labour is priced separately. Choose how tools and materials will be handled.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 15,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 22),
            _ChoiceCard(
              selected: _customerBuysMaterials,
              icon: Icons.shopping_cart_outlined,
              title: 'Customer purchases materials',
              description:
                  'You arrange and pay for the materials before the work begins.',
              onTap: () => setState(() => _customerBuysMaterials = true),
            ),
            const SizedBox(height: 12),
            _ChoiceCard(
              selected: !_customerBuysMaterials,
              icon: Icons.handyman_outlined,
              title: 'Worker purchases materials',
              description:
                  'The worker buys what is needed and uploads a bill or photo for you to view.',
              onTap: () => setState(() => _customerBuysMaterials = false),
            ),
            const SizedBox(height: 24),
            SurfaceCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'You can review legitimate material bills after the work. Material cost is never included in the labour range.',
                      style: TextStyle(color: AppColors.muted, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: PrimaryAction(
                label: 'See labour price range',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LabourPricePreviewScreen(
                      draft: GigDraft(
                        category: widget.draft.category,
                        description: widget.draft.description,
                        location: widget.draft.location,
                        date: widget.draft.date,
                        time: widget.draft.time,
                        duration: widget.draft.duration,
                        isEmergency: widget.draft.isEmergency,
                        photoCount: widget.draft.photoCount,
                        instructions: widget.draft.instructions,
                        customerBuysMaterials: _customerBuysMaterials,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step, required this.title});

  final String step;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        step,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: selected ? AppColors.primary : AppColors.muted,
            size: 25,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(color: AppColors.muted, height: 1.3),
                ),
              ],
            ),
          ),
          Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: selected ? AppColors.primary : AppColors.muted,
          ),
        ],
      ),
    ),
  );
}
