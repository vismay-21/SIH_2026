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
  final _taskSearchController = TextEditingController();

  List<ServiceCategoryDto> _categories = [];
  ServiceCategoryDto? _selectedCategory;
  List<ServiceTaskDto> _tasks = [];
  final Set<String> _selectedTaskIds = {};

  bool _isLoadingCategories = true;
  DateTime? _date;
  TimeOfDay? _time;
  bool _isEmergency = false;
  bool _requiresVisitation = false;
  bool _isTasksExpanded = true;
  String _taskSearchQuery = '';
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
    _taskSearchController.dispose();
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
      _taskSearchController.clear();
      _taskSearchQuery = '';
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
    if (_selectedCategory == null || _locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category and enter a location.'),
        ),
      );
      return;
    }

    // Tasks are optional when visitation is enabled (worker will propose tasks)
    if (!_requiresVisitation && _selectedTaskIds.isEmpty && _tasks.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one task for this category.'),
        ),
      );
      return;
    }

    final enteredNotes = _descriptionController.text.trim();
    // Generate sensible default if description is left empty
    final effectiveDescription = enteredNotes.isNotEmpty
        ? enteredNotes
        : (_requiresVisitation
            ? 'Site visit requested for ${_selectedCategory!.name}'
            : (_selectedTaskIds.isNotEmpty
                ? _tasks
                    .where((t) => _selectedTaskIds.contains(t.id))
                    .map((t) => t.name)
                    .join(', ')
                : '${_selectedCategory!.name} service'));

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MaterialProcurementScreen(
          draft: GigDraft(
            category: _selectedCategory!.name,
            categoryId: _selectedCategory!.id,
            taskIds: _selectedTaskIds.isNotEmpty
                ? _selectedTaskIds.toList()
                : (_tasks.isNotEmpty ? [_tasks.first.id] : []),
            description: effectiveDescription,
            location: _locationController.text.trim(),
            date: _date,
            time: _time?.format(context),
            duration: 'Around 2 hours',
            isEmergency: _isEmergency,
            photoCount: _photoCount,
            instructions: enteredNotes,
            customerBuysMaterials: true,
            requiresVisitation: _requiresVisitation,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _tasks.where((t) {
      if (_taskSearchQuery.isEmpty) return true;
      return t.name.toLowerCase().contains(_taskSearchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Create a gig')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StepHeader(step: '1 of 3', title: 'Tell us about the work'),
            const SizedBox(height: 18),

            // 1. Service Category Dropdown
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
              const SizedBox(height: 14),

              // 2. Request a Site Visit First Toggle (Positioned directly below category)
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _requiresVisitation
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : AppColors.muted.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.home_repair_service_rounded,
                            color: _requiresVisitation
                                ? AppColors.primary
                                : AppColors.muted,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Request a site visit first',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Fixed ₹100 visit charge',
                                style: TextStyle(
                                  color: _requiresVisitation
                                      ? AppColors.primary
                                      : AppColors.muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _requiresVisitation,
                          onChanged: (value) =>
                              setState(() => _requiresVisitation = value),
                          activeThumbColor: AppColors.primary,
                        ),
                      ],
                    ),
                    if (_requiresVisitation) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'A worker will visit your location, inspect the scope, and propose specific tasks and pricing before you commit to the full job.',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 3. Collapsible Tasks Section with Search (when site visit is not active)
              if (_tasks.isNotEmpty && !_requiresVisitation) ...[
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      // Header Row (Collapsible toggle)
                      InkWell(
                        onTap: () => setState(
                          () => _isTasksExpanded = !_isTasksExpanded,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.checklist_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Select tasks',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              if (_selectedTaskIds.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_selectedTaskIds.length} selected',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 6),
                              Icon(
                                _isTasksExpanded
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                                color: AppColors.muted,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Collapsed Preview (Compact chip summary)
                      if (!_isTasksExpanded && _selectedTaskIds.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _tasks
                                  .where((t) => _selectedTaskIds.contains(t.id))
                                  .map(
                                    (t) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        border: Border.all(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        t.name,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),

                      // Expanded Content (Search bar + Scrollable List)
                      if (_isTasksExpanded) ...[
                        const Divider(height: 1),
                        // Search bar inside the tasks card
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                          child: TextField(
                            controller: _taskSearchController,
                            onChanged: (val) => setState(
                              () => _taskSearchQuery = val.trim().toLowerCase(),
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              hintText: 'Search tasks (e.g. tap, pipe, leak)...',
                              hintStyle: const TextStyle(
                                fontSize: 13,
                                color: AppColors.muted,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                size: 18,
                                color: AppColors.muted,
                              ),
                              suffixIcon: _taskSearchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear_rounded,
                                        size: 16,
                                      ),
                                      onPressed: () {
                                        _taskSearchController.clear();
                                        setState(() => _taskSearchQuery = '');
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: AppColors.border.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Constrained scrollable task list (prevents huge page scrolling)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 250),
                          child: filteredTasks.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                    child: Text(
                                      'No tasks match your search.',
                                      style: TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                )
                              : Scrollbar(
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    itemCount: filteredTasks.length,
                                    separatorBuilder: (context, index) => Divider(
                                      height: 1,
                                      color: AppColors.border.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                    itemBuilder: (context, index) {
                                      final task = filteredTasks[index];
                                      final isSelected = _selectedTaskIds.contains(
                                        task.id,
                                      );
                                      return InkWell(
                                        onTap: () {
                                          setState(() {
                                            if (isSelected) {
                                              if (_selectedTaskIds.length > 1) {
                                                _selectedTaskIds.remove(task.id);
                                              }
                                            } else {
                                              _selectedTaskIds.add(task.id);
                                            }
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                isSelected
                                                    ? Icons.check_circle_rounded
                                                    : Icons.circle_outlined,
                                                color: isSelected
                                                    ? AppColors.primary
                                                    : AppColors.muted,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  task.name,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w600
                                                        : FontWeight.w400,
                                                    color: isSelected
                                                        ? AppColors.text
                                                        : AppColors.muted,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ] else
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('No active service categories available.'),
              ),
            const SizedBox(height: 14),

            // 4. Merged Details & Instructions Box (Optional)
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Work details & instructions (optional)',
                hintText:
                    'Describe the work, access notes, or special instructions for workers...',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 14),

            // 5. Location Field
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'Area, landmark, or address',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // 6. When is the work needed? (Date & Time)
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
            const SizedBox(height: 8),

            // 7. Emergency switch
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _isEmergency,
              onChanged: (value) => setState(() => _isEmergency = value),
              title: const Text('This is an emergency job'),
              subtitle: const Text('We will prioritize faster matching.'),
              secondary: const Icon(Icons.warning_amber_rounded),
              activeThumbColor: AppColors.primary,
            ),
            const SizedBox(height: 8),

            // 8. Photos
            OutlinedButton.icon(
              onPressed: () =>
                  setState(() => _photoCount = (_photoCount + 1).clamp(0, 3)),
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(
                _photoCount == 0
                    ? 'Add photos (optional)'
                    : 'Photos added: $_photoCount/3',
              ),
            ),
            const SizedBox(height: 24),

            // 9. Continue button
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
