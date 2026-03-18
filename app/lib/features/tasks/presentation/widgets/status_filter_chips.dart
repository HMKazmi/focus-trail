import 'package:flutter/material.dart';

import '../../domain/entities/task_entity.dart';

class StatusFilterChips extends StatelessWidget {
  final TaskStatus? selected;
  final ValueChanged<TaskStatus?> onSelected;

  const StatusFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip(context, null, 'All'),
          const SizedBox(width: 8),
          ...TaskStatus.values.map((s) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _chip(context, s, s.label),
              )),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, TaskStatus? status, String label) {
    final isActive = selected == status;
    return FilterChip(
      selected: isActive,
      label: Text(label),
      onSelected: (_) => onSelected(isActive ? null : status),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
    );
  }
}
