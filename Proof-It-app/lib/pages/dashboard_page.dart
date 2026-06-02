import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:main/API/api_service.dart';
import '../models/data_models.dart';
import '../data/mock_database.dart';
import 'project_detail_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<List<Map<String, dynamic>>> _projectsFuture;

  String _selectedFilter = 'Total';

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  void _fetchProjects() {
    setState(() {
      _projectsFuture = ApiService.getProjects().then(
        (data) => List<Map<String, dynamic>>.from(data),
      );
    });
  }

  void _showAddProjectDialog() {
    final title = TextEditingController();
    final desc = TextEditingController();
    final loc = TextEditingController();
    DateTime date = DateTime.now().add(const Duration(days: 7));
    String status = "Upcoming";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDst) => AlertDialog(
          title: const Text("Create New Project"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(
                    labelText: "Project Title",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: desc,
                  decoration: const InputDecoration(
                    labelText: "Description",
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: loc,
                  decoration: const InputDecoration(
                    labelText: "Location",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Deadline:",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(DateFormat('dd MMM yyyy').format(date)),
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (d != null) setDst(() => date = d);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Status",
                    border: OutlineInputBorder(),
                  ),
                  value: status,
                  isExpanded: true,
                  items: ["Upcoming", "On Progress", "Completed"]
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setDst(() => status = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (title.text.trim().isEmpty || desc.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Title dan Description wajib diisi!"),
                    ),
                  );
                  return;
                }

                try {
                  bool success = await ApiService.addProject(
                    title.text.trim(),
                    desc.text.trim(),
                    status,
                    loc.text.trim(),
                    DateTime.now().toIso8601String(),
                    date.toIso8601String(),
                  );

                  if (success && mounted) {
                    Navigator.pop(context);
                    _fetchProjects();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Project Created!")),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
                }
              },
              child: const Text("Create"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthSession.currentUser!;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _projectsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 50),
                  const SizedBox(height: 10),
                  Text(
                    "Gagal memuat data dari database:\n${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          );
        }

        final rawData = snapshot.data ?? [];

        final List<EventModel> allEvents = rawData.map((row) {
          DateTime parsedDate;
          try {
            parsedDate = row['end_date'] != null
                ? DateTime.parse(row['end_date'].toString())
                : DateTime.now();
          } catch (e) {
            parsedDate = DateTime.now();
          }

          return EventModel(
            row['id']?.toString() ?? '',
            row['title']?.toString() ?? 'No Title',
            row['description']?.toString() ?? '',
            row['status']?.toString() ?? 'Upcoming',
            parsedDate,
            row['location']?.toString() ?? '',
            'pic@test.com',
            [],
          );
        }).toList();

        final totalCount = allEvents.length;
        final activeCount = allEvents
            .where((e) => e.status == 'On Progress' || e.status == 'Upcoming')
            .length;
        final completedCount = allEvents
            .where((e) => e.status == 'Completed')
            .length;

        List<EventModel> displayEvents = [];
        if (_selectedFilter == 'Total') {
          displayEvents = List.from(allEvents);
        } else if (_selectedFilter == 'Active') {
          displayEvents = allEvents
              .where((e) => e.status == 'On Progress' || e.status == 'Upcoming')
              .toList();
        } else if (_selectedFilter == 'Completed') {
          displayEvents = allEvents
              .where((e) => e.status == 'Completed')
              .toList();
        }

        int getStatusPriority(String status) {
          if (status == 'On Progress') return 1;
          if (status == 'Upcoming') return 2;
          if (status == 'Completed') return 3;
          return 4;
        }

        displayEvents.sort((a, b) {
          return getStatusPriority(
            a.status,
          ).compareTo(getStatusPriority(b.status));
        });

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.indigo, Colors.blueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome back, ${user.username}!",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Track your projects, manage tasks, and prove your work effectively.",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  _statCard(
                    "All Projects",
                    "$totalCount",
                    Colors.blue,
                    Icons.folder,
                    'Total',
                  ),
                  const SizedBox(width: 15),
                  _statCard(
                    "My Active",
                    "$activeCount",
                    Colors.orange,
                    Icons.work,
                    'Active',
                  ),
                  const SizedBox(width: 15),
                  _statCard(
                    "Completed",
                    "$completedCount",
                    Colors.green,
                    Icons.check_circle,
                    'Completed',
                  ),
                ],
              ),
              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedFilter == 'Total'
                        ? "All Projects"
                        : "$_selectedFilter Projects",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (user.role != UserRole.Member)
                    ElevatedButton.icon(
                      onPressed: _showAddProjectDialog,
                      icon: const Icon(Icons.add),
                      label: const Text("New Project"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 15),

              if (displayEvents.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text(
                      "Tidak ada proyek di kategori ini.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: displayEvents
                      .map((e) => _buildProjectCard(e, user))
                      .toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(
    String label,
    String value,
    Color color,
    IconData icon,
    String filterType,
  ) {
    bool isSelected = _selectedFilter == filterType;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = filterType;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCard(EventModel e, User user) {
    Color statusColor = Colors.blue;
    if (e.status == 'Upcoming') statusColor = Colors.orange;
    if (e.status == 'Completed') statusColor = Colors.green;

    return Container(
      width: 350,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Chip(
                label: Text(
                  e.status,
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
                backgroundColor: statusColor,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              if (user.role != UserRole.Member)
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.grey),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Hapus Proyek"),
                        content: Text(
                          "Apakah Anda yakin ingin menghapus proyek '${e.title}'? Tindakan ini tidak dapat dibatalkan.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("Batal"),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              try {
                                bool isSuccess = await ApiService.deleteProject(
                                  e.id,
                                );
                                if (isSuccess) {
                                  _fetchProjects();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Proyek berhasil dihapus.",
                                        ),
                                      ),
                                    );
                                  }
                                } else {
                                  throw Exception("Gagal menghapus di server");
                                }
                              } catch (error) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Error: $error")),
                                  );
                                }
                              }
                            },
                            child: const Text(
                              "Hapus",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            e.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 5),
          Text(
            e.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 5),
              Text(
                DateFormat('dd MMM yyyy').format(e.date),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProjectDetailPage(event: e)),
              ).then((_) => _fetchProjects()),
              child: const Text("View Details"),
            ),
          ),
        ],
      ),
    );
  }
}
