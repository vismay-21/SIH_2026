import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';

class MaterialBillUploadScreen extends StatefulWidget {
  const MaterialBillUploadScreen({super.key, required this.jobTitle});

  final String jobTitle;

  @override
  State<MaterialBillUploadScreen> createState() =>
      _MaterialBillUploadScreenState();
}

class _MaterialBillUploadScreenState extends State<MaterialBillUploadScreen> {
  final List<Map<String, dynamic>> _items = [
    {'name': 'Brass 1-inch Ball Valve', 'cost': 320},
    {'name': 'Heavy Duty Teflon Seal Tape (x2)', 'cost': 60},
  ];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  bool _receiptAttached = true;

  int get _totalCost =>
      _items.fold<int>(0, (sum, item) => sum + (item['cost'] as int));

  void _addItem() {
    final name = _nameController.text.trim();
    final cost = int.tryParse(_costController.text.trim());

    if (name.isEmpty || cost == null || cost <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid material name and cost.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _items.add({'name': name, 'cost': cost});
      _nameController.clear();
      _costController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _submitBill() {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one material item.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Material bill of ₹$_totalCost submitted for customer audit.',
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(context).pop(_totalCost);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Material Bill & Receipts',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          // Job Banner
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Associated Job',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.jobTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Policy notice (SRS 7.2)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Per SRS 7.2: Itemized receipts ensure zero hidden markups. Material costs are audited and added to the customer payout.',
                    style: TextStyle(fontSize: 12, height: 1.3),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const SectionTitle('Add Material Item'),
          const SizedBox(height: 8),

          // Add item input
          SurfaceCard(
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Material / Part Name',
                    hintText: 'e.g. PVC Elbow 1-inch',
                    prefixIcon: Icon(Icons.build_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _costController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Actual Price (₹)',
                    hintText: 'e.g. 150',
                    prefixIcon: Icon(Icons.currency_rupee_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add to Bill'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const SectionTitle('Itemized Materials List'),
          const SizedBox(height: 8),

          ..._items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  item['name'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₹${item['cost']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: AppColors.danger,
                      ),
                      onPressed: () => _removeItem(idx),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 12),

          // Total Box
          SurfaceCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Material Claim',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                Text(
                  '₹$_totalCost',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const SectionTitle('Receipt Proof Photo'),
          const SizedBox(height: 8),

          // Receipt Upload Mock
          InkWell(
            onTap: () {
              setState(() => _receiptAttached = !_receiptAttached);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _receiptAttached ? 'Receipt attached.' : 'Receipt removed.',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _receiptAttached
                      ? AppColors.success
                      : AppColors.border,
                  width: _receiptAttached ? 2 : 1,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _receiptAttached
                          ? Icons.check_circle_rounded
                          : Icons.add_a_photo_outlined,
                      color: _receiptAttached
                          ? AppColors.success
                          : AppColors.muted,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _receiptAttached
                          ? 'Receipt Photo Attached (bill_hardware_01.jpg)'
                          : 'Tap to capture or upload shop receipt',
                      style: TextStyle(
                        color: _receiptAttached
                            ? AppColors.success
                            : AppColors.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: _submitBill,
            icon: const Icon(Icons.check_rounded),
            label: Text(
              'Submit Material Bill (₹$_totalCost)',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
