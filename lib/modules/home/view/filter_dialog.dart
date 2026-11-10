import 'package:document_companion/local_database/models/tag_model.dart';
import 'package:document_companion/modules/home/bloc/folder_bloc.dart';
import 'package:document_companion/modules/home/bloc/tag_bloc.dart';
import 'package:flutter/material.dart';

class FilterDialog extends StatefulWidget {
  const FilterDialog({super.key});

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _dateType; // 'created' or 'modified'
  final Set<String> _selectedTagIds = {};

  @override
  void initState() {
    super.initState();
    // Load current filter state
    _startDate = folderBloc.filterStartDate;
    _endDate = folderBloc.filterEndDate;
    _dateType = folderBloc.filterDateType ?? 'created';
    _selectedTagIds.addAll(folderBloc.selectedTagIds);
    tagBloc.fetchTags();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _startDate!.isAfter(_endDate!)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _applyQuickFilter(String filter) {
    final now = DateTime.now();
    setState(() {
      switch (filter) {
        case 'today':
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'this_week':
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          _startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
          _endDate = now;
          break;
        case 'this_month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = now;
          break;
        case 'all_time':
          _startDate = null;
          _endDate = null;
          break;
      }
    });
  }

  Future<void> _applyFilter() async {
    folderBloc.applyDateFilter(
      startDate: _startDate,
      endDate: _endDate,
      dateType: _dateType,
    );
    await folderBloc.applyTagFilter(_selectedTagIds);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _clearFilter() async {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedTagIds.clear();
    });
    folderBloc.clearDateFilter();
    await folderBloc.clearTagFilter();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Folders',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Date Type Selection
            Text('Filter by:', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'created', label: Text('Created Date')),
                ButtonSegment(value: 'modified', label: Text('Modified Date')),
              ],
              selected: {_dateType ?? 'created'},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _dateType = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 24),

            // Quick Filters
            Text(
              'Quick Filters:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickFilterChip(
                  label: 'Today',
                  onTap: () => _applyQuickFilter('today'),
                ),
                _QuickFilterChip(
                  label: 'This Week',
                  onTap: () => _applyQuickFilter('this_week'),
                ),
                _QuickFilterChip(
                  label: 'This Month',
                  onTap: () => _applyQuickFilter('this_month'),
                ),
                _QuickFilterChip(
                  label: 'All Time',
                  onTap: () => _applyQuickFilter('all_time'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Date Range Selection
            Text('Date Range:', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectStartDate(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Date',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _startDate != null
                                ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                : 'Select date',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectEndDate(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'End Date',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _endDate != null
                                ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                : 'Select date',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tag Filter Section
            Text(
              'Filter by Tags:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<TagModel>>(
              stream: tagBloc.tagsStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final tags = snapshot.data ?? [];
                  if (tags.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No tags available. Create tags in settings.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    children: tags.map((tag) {
                      final isSelected = _selectedTagIds.contains(tag.id);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(tag.name),
                          avatar: Container(
                            width: 16,
                            height: 16,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: _parseColor(tag.color),
                              shape: BoxShape.circle,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTagIds.add(tag.id);
                              } else {
                                _selectedTagIds.remove(tag.id);
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),
                  );
                }
                return const SizedBox(
                  height: 40,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearFilter,
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _applyFilter,
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    return Color(int.parse(hex.replaceAll('#', '0xFF')));
  }
}

class _QuickFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickFilterChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}
