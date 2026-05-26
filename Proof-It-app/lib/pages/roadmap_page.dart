import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/data_models.dart';
import '../data/mock_database.dart';
import 'package:main/API/api_roadmap.dart';

abstract class RoadmapRow {}

class ProjectHeaderRow extends RoadmapRow {
  final String projectName;
  ProjectHeaderRow(this.projectName);
}

class TaskRow extends RoadmapRow {
  final RoadmapTask task;
  TaskRow(this.task);
}

class RoadmapPage extends StatefulWidget {
  final String? initialProjectId;
  const RoadmapPage({super.key, this.initialProjectId});
  @override
  State<RoadmapPage> createState() => _RoadmapPageState();
}

class _RoadmapPageState extends State<RoadmapPage> {
  final RoadmapApiService _apiService = RoadmapApiService();

  String _filter = "All";
  final double _dayWidth = 15.0;
  final double _rowHeight = 55.0;
  final int _totalDays = 365;

  DateTime _viewStartDate = DateTime.now().subtract(const Duration(days: 90));

  bool _isLoading = true;
  List<EventModel> _projects = [];
  List<RoadmapTask> _tasks = [];

  final ScrollController _headerScroll = ScrollController();
  final ScrollController _bodyScroll = ScrollController();
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialProjectId != null) _filter = widget.initialProjectId!;
    _fetchData();

    _headerScroll.addListener(() {
      if (_isSyncing) return;
      _isSyncing = true;
      _bodyScroll.jumpTo(_headerScroll.offset);
      _isSyncing = false;
    });
    _bodyScroll.addListener(() {
      if (_isSyncing) return;
      _isSyncing = true;
      _headerScroll.jumpTo(_bodyScroll.offset);
      _isSyncing = false;
    });
  }

  @override
  void dispose() {
    _headerScroll.dispose();
    _bodyScroll.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final user = AuthSession.currentUser!;
      final response = await _apiService.fetchRoadmap(user.id, user.role.name);
      final List<dynamic> projRes = response['projects'] ?? [];
      _projects = projRes.map((row) {
        final endDateStr = row['end_date']?.toString();
        final endDate = endDateStr != null
            ? DateTime.tryParse(endDateStr) ??
                  DateTime.now().add(const Duration(days: 30))
            : DateTime.now().add(const Duration(days: 30));

        return EventModel(
          row['id'].toString(),
          row['title'] ?? 'No Title',
          row['description'] ?? '',
          row['status'] ?? '',
          endDate,
          row['location'] ?? '',
          '',
          [],
        );
      }).toList();
      final List<dynamic> taskRes = response['tasks'] ?? [];
      _tasks = taskRes.map((row) {
        final startDate =
            DateTime.tryParse(row['start_date']?.toString() ?? '') ??
            DateTime.now();
        final endDate =
            DateTime.tryParse(row['end_date']?.toString() ?? '') ??
            DateTime.now().add(const Duration(days: 7));

        return RoadmapTask(
          id: row['id'].toString(),
          projectId: row['project_id'].toString(),
          title: row['title'] ?? 'No Task Name',
          description: row['description'] ?? '',
          status: row['status'] ?? 'To Do',
          start: startDate,
          end: endDate,
          progress: double.tryParse(row['progress']?.toString() ?? '0') ?? 0.0,
        );
      }).toList();

      if (_tasks.isNotEmpty) {
        final earliest = _tasks
            .map((t) => t.start)
            .reduce((a, b) => a.isBefore(b) ? a : b);
        _viewStartDate = earliest.subtract(const Duration(days: 14));
      }

      print(
        '[Roadmap] projects=${_projects.length} tasks=${_tasks.length} viewStart=$_viewStartDate',
      );
    } catch (e) {
      print('[Roadmap] fetch error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetch roadmap: $e')));
      }
    }
    setState(() => _isLoading = false);
  }

  Color _getTaskColor(RoadmapTask t) {
    if (t.status == 'Done') return Colors.green;
    if (DateTime.now().isAfter(t.end) && t.status != 'Done') return Colors.red;
    if (t.progress >= 0.5) return Colors.amber;
    return Colors.purple.shade300;
  }

  // DIALOG: ADD / EDIT TASK
  void _showTaskDialog({RoadmapTask? task}) {
    final isEdit = task != null;
    final title = TextEditingController(text: isEdit ? task.title : "");
    final desc = TextEditingController(text: isEdit ? task.description : "");

    DateTime start = isEdit ? task.start : DateTime.now();
    DateTime end = isEdit
        ? task.end
        : DateTime.now().add(const Duration(days: 7));
    String status = isEdit ? task.status : "To Do";
    double progress = isEdit ? task.progress : 0.0;

    String selectedProjId = _filter != "All"
        ? _filter
        : (_projects.isNotEmpty ? _projects.first.id : "");

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDst) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isEdit ? "View/Edit Task" : "Add New Task"),
              if (isEdit)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getTaskColor(task),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isEdit && _filter == "All")
                    DropdownButton<String>(
                      value: selectedProjId,
                      isExpanded: true,
                      items: _projects
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.id,
                              child: Text(e.title),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setDst(() => selectedProjId = v!),
                    ),
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: "Task Name"),
                  ),
                  TextField(
                    controller: desc,
                    decoration: const InputDecoration(labelText: "Description"),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: start,
                            firstDate: DateTime(2023),
                            lastDate: DateTime(2030),
                          );
                          if (d != null) setDst(() => start = d);
                        },
                        child: Text(
                          "Start: ${DateFormat('dd MMM').format(start)}",
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: end,
                            firstDate: DateTime(2023),
                            lastDate: DateTime(2030),
                          );
                          if (d != null) setDst(() => end = d);
                        },
                        child: Text("End: ${DateFormat('dd MMM').format(end)}"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Progress: ${(progress * 100).toInt()}% (Scroll to update)",
                  ),
                  Slider(
                    value: progress,
                    onChanged: (v) {
                      setDst(() {
                        progress = v;
                        if (v == 1.0)
                          status = "Done";
                        else if (v > 0)
                          status = "In Progress";
                        else
                          status = "To Do";
                      });
                    },
                  ),
                  DropdownButton<String>(
                    value: status,
                    isExpanded: true,
                    items: ["To Do", "In Progress", "Done"]
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setDst(() => status = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (isEdit)
              TextButton(
                onPressed: () async {
                  try {
                    await _apiService.deleteTask(task.id);

                    if (mounted) {
                      Navigator.pop(context);
                      _fetchData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Task berhasil dihapus")),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Gagal menghapus: $e")),
                      );
                    }
                  }
                },
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final Map<String, dynamic> taskPayload = {
                    if (isEdit) 'id': task.id,
                    'project_id': selectedProjId,
                    'title': title.text,
                    'description': desc.text,
                    'status': status,
                    'progress': progress,
                    'start_date': start.toIso8601String(),
                    'end_date': end.toIso8601String(),
                  };

                  await _apiService.saveTask(taskPayload);
                  if (mounted) {
                    Navigator.pop(context);
                    _fetchData();
                  }
                } catch (e) {
                  if (mounted)
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              },
              child: Text(isEdit ? "Save Changes" : "Create Task"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final screenWidth = MediaQuery.of(context).size.width;
    final double leftColumnWidth = screenWidth > 600
        ? 250.0
        : screenWidth * 0.35;
    final double titleFontSize = screenWidth > 600 ? 13.0 : 10.0;
    final double headerFontSize = screenWidth > 600 ? 11.0 : 9.0;

    List<RoadmapRow> rows = [];
    if (_filter == "All") {
      for (var proj in _projects) {
        final projTasks = _tasks.where((t) => t.projectId == proj.id).toList();
        if (projTasks.isNotEmpty) {
          rows.add(ProjectHeaderRow(proj.title));
          rows.addAll(projTasks.map((t) => TaskRow(t)));
        }
      }
    } else {
      final proj = _projects.firstWhere(
        (p) => p.id == _filter,
        orElse: () => EventModel('', '', '', '', DateTime.now(), '', '', []),
      );
      final projTasks = _tasks.where((t) => t.projectId == _filter).toList();
      if (projTasks.isNotEmpty) {
        rows.add(ProjectHeaderRow(proj.title));
        rows.addAll(projTasks.map((t) => TaskRow(t)));
      }
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskDialog(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 50,
            color: Colors.white,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              children: [
                _buildFilterChip("All Projects", "All"),
                ..._projects.map((p) => _buildFilterChip(p.title, p.id)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
            child: Wrap(
              spacing: 16.0,
              runSpacing: 8.0,
              children: [
                _buildLegendItem(Colors.green, "Done"),
                _buildLegendItem(Colors.amber, "Progress ≥ 50%"),
                _buildLegendItem(Colors.purple.shade300, "To Do / < 50%"),
                _buildLegendItem(Colors.red, "Overdue"),
              ],
            ),
          ),
          const Divider(height: 1),
          Row(
            children: [
              Container(
                width: leftColumnWidth,
                height: 40,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 10),
                color: Colors.grey.shade100,
                child: const Text(
                  "Task / Project",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _headerScroll,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: SizedBox(
                    width: _dayWidth * _totalDays,
                    height: 40,
                    child: Stack(
                      children: [
                        for (int i = 0; i < _totalDays; i += 30)
                          Positioned(
                            left: i * _dayWidth,
                            top: 10,
                            child: Text(
                              DateFormat(
                                'MMM yyyy',
                              ).format(_viewStartDate.add(Duration(days: i))),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: leftColumnWidth,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Column(
                      children: rows.map((row) {
                        if (row is ProjectHeaderRow) {
                          return Container(
                            height: _rowHeight,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 10),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Text(
                              row.projectName.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: headerFontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo.shade700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          );
                        } else if (row is TaskRow) {
                          final t = row.task;
                          return InkWell(
                            onTap: () => _showTaskDialog(task: t),
                            child: Container(
                              height: _rowHeight,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(
                                left: 10,
                                right: 5,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade100,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      t.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: titleFontSize),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getTaskColor(t),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "${(t.progress * 100).toInt()}%",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      }).toList(),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _bodyScroll,
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: SizedBox(
                        width: _dayWidth * _totalDays,
                        height: rows.length * _rowHeight,
                        child: Stack(
                          children: [
                            for (int i = 0; i < _totalDays; i += 7)
                              Positioned(
                                left: i * _dayWidth,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 1,
                                  color: Colors.grey.shade200,
                                ),
                              ),
                            ...rows.asMap().entries.map((entry) {
                              final i = entry.key;
                              final row = entry.value;
                              if (row is ProjectHeaderRow) {
                                return Positioned(
                                  top: i * _rowHeight,
                                  left: 0,
                                  right: 0,
                                  height: _rowHeight,
                                  child: Container(
                                    color: Colors.indigo.shade50.withOpacity(
                                      0.3,
                                    ),
                                  ),
                                );
                              } else if (row is TaskRow) {
                                final t = row.task;
                                final rawOffset =
                                    t.start.difference(_viewStartDate).inDays *
                                    _dayWidth;
                                final startOffset = rawOffset.clamp(
                                  0.0,
                                  double.infinity,
                                );
                                final rawWidth =
                                    t.end.difference(t.start).inDays *
                                    _dayWidth;
                                final clippedWidth =
                                    (rawWidth +
                                            rawOffset.clamp(
                                              double.negativeInfinity,
                                              0.0,
                                            ))
                                        .clamp(_dayWidth, double.infinity);
                                return Positioned(
                                  top: i * _rowHeight + 12,
                                  left: startOffset,
                                  child: InkWell(
                                    onTap: () => _showTaskDialog(task: t),
                                    child: Container(
                                      width: clippedWidth,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: _getTaskColor(t),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox();
                            }),
                            Positioned(
                              left:
                                  DateTime.now()
                                      .difference(_viewStartDate)
                                      .inDays *
                                  _dayWidth,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: 2,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildFilterChip(String label, String id) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: _filter == id,
        onSelected: (v) => setState(() => _filter = id),
        selectedColor: Colors.indigo.shade100,
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
