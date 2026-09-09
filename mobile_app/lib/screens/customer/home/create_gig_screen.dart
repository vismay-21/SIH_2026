import 'package:flutter/material.dart';

import '../../../models/api/api_models.dart';
import '../../../models/gig_draft.dart';
import '../../../repositories/catalogue_repository.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';
import 'material_procurement_screen.dart';

class CreateGigScreen extends StatefulWidget {
  const CreateGigScreen({super.key});

  @override
  State<CreateGigScreen> createState() => _CreateGigScreenState();
}

class _CreateGigScreenState extends State<CreateGigScreen> {
  final _catalogueRepo = CatalogueRepository();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _instructionsController = TextEditingController();

  List<ServiceCategoryDto> _categories = [];
  ServiceCategoryDto? _selectedCategory;
  List<ServiceTaskDto> _tasks = [];
  final Set<String> _selectedTaskIds = {};

  bool _isLoadingCategories = true;
  DateTime? _date;
  TimeOfDay? _time;
  String _duration = 'Around 2 hours';
  bool _isEmergency = false;
  int _photoCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _catalogueRepo.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
        if (categories.isNotEmpty) {
          _selectCategory(categories.first);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _selectCategory(ServiceCategoryDto category) async {
    setState(() {
      _selectedCategory = category;
      _selectedTaskIds.clear();
      _tasks = [];
    });
    try {
      final tasks = await _catalogueRepo.getTasks(category.id);
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        if (tasks.isNotEmpty) {
          _selectedTaskIds.add(tasks.first.id);
        }
      });
    } catch (_) {
      // Fallback
    }
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      initialDate: _date ?? DateTime.now(),
    );
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _selectTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 17, minute: 0),
    );
    if (selected != null) setState(() => _time = selected);
  }

  void _continue() {
    if (_selectedCategory == null ||
        _descriptionController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a category, description, and location.'),
        ),
      );
      return;
    }

    if (_selectedTaskIds.isEmpty && _tasks.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one task for this category.'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MaterialProcurementScreen(
          draft: GigDraft(
            category: _selectedCategory!.name,
            categoryId: _selectedCategory!.id,
            taskIds: _selectedTaskIds.toList(),
            description: _descriptionController.text.trim(),
            location: _locationController.text.trim(),
            date: _date,
            time: _time?.format(context),
            duration: _duration,
            isEmergency: _isEmergency,
            photoCount: _photoCount,
            instructions: _instructionsController.text.trim(),
            customerBuysMaterials: true,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create a gig')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StepHeader(step: '1 of 3', title: 'Tell us about the work'),
            const SizedBox(height: 18),
            if (_isLoadingCategories)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_categories.isNotEmpty) ...[
              DropdownButtonFormField<ServiceCategoryDto>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Service category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem<ServiceCategoryDto>(
                    value: cat,
                    child: Text(cat.name),
                  );
                }).toList(),
                onChanged: (cat) {
                  if (cat != null) _selectCategory(cat);
                },
              ),
              if (_tasks.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Select tasks to include:',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _tasks.map((task) {
                    final isSelected = _selectedTaskIds.contains(task.id);
                    return FilterChip(
                      label: Text('${task.name} (₹${task.basePrice.toInt()})'),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedTaskIds.add(task.id);
                          } else {
                            if (_selectedTaskIds.length > 1) {
                              _selectedTaskIds.remove(task.id);
                            }
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ] else
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('No active service categories available.'),
              ),
            const SizedBox(height: 14),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'What needs to be done?',
                hintText: 'Describe the work clearly for workers.',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'Area, landmark, or address',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 18),
            const SectionTitle('When is the work needed?'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _PickerTile(
                    icon: Icons.calendar_today_outlined,
                    label: _date == null ? 'Select date' : _formatDate(_date!),
                    onTap: _selectDate,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PickerTile(
                    icon: Icons.schedule_outlined,
                    label: _time == null
                        ? 'Select time'
                        : _time!.format(context),
                    onTap: _selectTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _duration,
              decoration: const InputDecoration(
                labelText: 'Expected duration',
                prefixIcon: Icon(Icons.timelapse_rounded),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Around 1 hour',
                  child: Text('Around 1 hour'),
                ),
                DropdownMenuItem(
                  value: 'Around 2 hours',
                  child: Text('Around 2 hours'),
                ),
                DropdownMenuItem(value: 'Half day', child: Text('Half day')),
                DropdownMenuItem(value: 'Full day', child: Text('Full day')),
              ],
              onChanged: (value) => setState(() => _duration = value!),
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _isEmergency,
              onChanged: (value) => setState(() => _isEmergency = value),
              title: const Text('This is an emergency job'),
              subtitle: const Text('We will prioritize faster matching.'),
              secondary: const Icon(Icons.warning_amber_rounded),
            ),
            const SizedBox(height: 12),
            const SectionTitle('Helpful details'),
            const SizedBox(height: 8),
            TextField(
              controller: _instructionsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Additional instructions (optional)',
                hintText: 'Access notes, preferred tools, or other details',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.info_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () =>
                  setState(() => _photoCount = (_photoCount + 1).clamp(0, 3)),
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(
                _photoCount == 0
                    ? 'Add photos'
                    : 'Photos added: $_photoCount/3',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: PrimaryAction(
                label: 'Continue to materials',
                icon: Icons.arrow_forward_rounded,
                onPressed: _continue,
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
      Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Ink(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 19),
          const SizedBox(width: 8),
          Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    ),
  );
}

String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
