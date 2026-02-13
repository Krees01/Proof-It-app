import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const ProofItApp());
}

// ==========================================
// 1. DATA MODELS
// ==========================================

enum UserRole { Admin, PIC, Member }

class User {
  String id;
  String username;
  String email;
  String password;
  UserRole role;

  User({required this.id, required this.username, required this.email, required this.password, required this.role});
}

class EventModel {
  String id;
  String title;
  String description;
  String status;
  DateTime date; 
  String location;
  String picEmail; 
  List<String> teamEmails; 
  List<String> attachments; 

  EventModel(this.id, this.title, this.description, this.status, this.date, this.location, this.picEmail, this.teamEmails, {this.attachments = const []});
}

class RoadmapTask {
  String id;
  String projectId;
  String title;
  String description;
  String status; // 'To Do', 'In Progress', 'Done'
  DateTime start;
  DateTime end;
  double progress; // 0.0 - 1.0

  RoadmapTask({required this.id, required this.projectId, required this.title, required this.description, required this.status, required this.start, required this.end, this.progress = 0.0});
}

// ==========================================
// 2. MOCK DATABASE
// ==========================================

class MockDatabase {
  // USERS
  static final List<User> _users = [
    User(id: "1", username: "Super Admin", email: "admin@proofit.com", password: "123", role: UserRole.Admin),
    User(id: "2", username: "Siti Manager", email: "pic@proofit.com", password: "123", role: UserRole.PIC),
    User(id: "3", username: "Andi Staff", email: "andi@proofit.com", password: "123", role: UserRole.Member),
    User(id: "4", username: "Budi Senior", email: "budi@proofit.com", password: "123", role: UserRole.Member),
  ];

  // PROJECTS
  static final List<EventModel> _events = [
    EventModel("1", "Grand Launching App", "Event besar peluncuran.", "Upcoming", DateTime.now().add(const Duration(days: 30)), "Grand Ballroom", "pic@proofit.com", ["pic@proofit.com", "andi@proofit.com"], attachments: ["venue.jpg"]),
    EventModel("2", "Internal Training", "Pelatihan React Native.", "On Progress", DateTime.now().add(const Duration(days: 5)), "Meeting Room A", "pic@proofit.com", ["pic@proofit.com", "budi@proofit.com"]),
  ];

  // ROADMAP TASKS
  static final List<RoadmapTask> _tasks = [
    RoadmapTask(id: "1", projectId: "1", title: "Sewa Tempat", description: "Bayar DP", status: "Done", start: DateTime.now().subtract(const Duration(days: 10)), end: DateTime.now().subtract(const Duration(days: 5)), progress: 1.0),
    RoadmapTask(id: "2", projectId: "1", title: "Cetak Banner", description: "Vendor X", status: "In Progress", start: DateTime.now().subtract(const Duration(days: 2)), end: DateTime.now().add(const Duration(days: 5)), progress: 0.6),
    RoadmapTask(id: "3", projectId: "2", title: "Siapkan Modul", description: "PDF Modul", status: "To Do", start: DateTime.now(), end: DateTime.now().add(const Duration(days: 3)), progress: 0.0),
    RoadmapTask(id: "4", projectId: "2", title: "Kontrak Trainer", description: "Harus sign kemarin", status: "In Progress", start: DateTime.now().subtract(const Duration(days: 15)), end: DateTime.now().subtract(const Duration(days: 1)), progress: 0.2),
  ];

  // --- METHODS ---
  static User? login(String email, String pass) {
    try { return _users.firstWhere((u) => u.email == email && u.password == pass); } catch (e) { return null; }
  }

  static List<EventModel> getEvents() => _events;
  static EventModel? getEventById(String id) { try { return _events.firstWhere((e)=>e.id == id); } catch(e){ return null; }}
  
  static List<RoadmapTask> getAllTasks() => _tasks;
  static List<RoadmapTask> getTasksByProject(String pid) => _tasks.where((t) => t.projectId == pid).toList();

  static List<User> getUsers() => _users;
  static User? getUserByEmail(String email) { try { return _users.firstWhere((u)=>u.email == email); } catch(e){ return null; }}

  // CRUD
  static void addEvent(EventModel e) => _events.add(e);
  static void updateEvent(String id, EventModel newEvent) { int i = _events.indexWhere((e)=>e.id==id); if(i!=-1) _events[i] = newEvent; }
  static void deleteEvent(String id) { _events.removeWhere((e)=>e.id==id); _tasks.removeWhere((t)=>t.projectId==id); }

  static void addTask(RoadmapTask t) => _tasks.add(t);
  
  // UPDATE TASK FULL (For Edit Feature)
  static void updateTask(RoadmapTask t) { 
    int i = _tasks.indexWhere((x)=>x.id==t.id); 
    if(i!=-1) _tasks[i] = t; 
  }
  
  static void deleteTask(String id) => _tasks.removeWhere((t)=>t.id==id);

  static void addUser(User u) => _users.add(u);
  static void updateUser(User u) { int i = _users.indexWhere((x)=>x.id==u.id); if(i!=-1) _users[i] = u; }
}

class AuthSession { static User? currentUser; }

// ==========================================
// 3. MAIN APP
// ==========================================

class ProofItApp extends StatelessWidget {
  const ProofItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Proof It!',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF4F5F7),
        fontFamily: 'Segoe UI',
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

// ==========================================
// 4. LOGIN SCREEN
// ==========================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();

  void _login() {
    final user = MockDatabase.login(_email.text, _pass.text);
    if (user != null) {
      AuthSession.currentUser = user;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainLayout()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Login Gagal! Coba: admin@proofit.com / 123")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified, size: 60, color: Colors.indigo),
              const SizedBox(height: 20),
              const Text("Proof It!", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("Project Management Simplified", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              TextField(controller: _email, decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email), border: OutlineInputBorder())),
              const SizedBox(height: 15),
              TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: "Password", prefixIcon: Icon(Icons.lock), border: OutlineInputBorder())),
              const SizedBox(height: 25),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _login, style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white), child: const Text("LOGIN"))),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 5. MAIN LAYOUT
// ==========================================

class MainLayout extends StatefulWidget {
  final int initialIndex;
  const MainLayout({super.key, this.initialIndex = 0});
  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _idx;

  @override
  void initState() {
    super.initState();
    _idx = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthSession.currentUser!;
    return Scaffold(
      body: Column(
        children: [
          // TOP BAR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.verified, color: Colors.indigo),
                const SizedBox(width: 10),
                const Text("Proof It!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
                const Spacer(),
                IconButton(onPressed: (){}, icon: const Icon(Icons.notifications_none)),
                const SizedBox(width: 10),
                CircleAvatar(backgroundColor: Colors.indigo, radius: 16, child: Text(user.username[0], style: const TextStyle(color: Colors.white))),
                const SizedBox(width: 10),
                PopupMenuButton(
                  child: Row(children: [Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold)), const Icon(Icons.arrow_drop_down)]),
                  itemBuilder: (c) => [
                    PopupMenuItem(child: const Text("Logout"), onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()))),
                  ]
                )
              ],
            ),
          ),
          
          // CONTENT
          Expanded(
            child: IndexedStack(
              index: _idx,
              children: const [
                DashboardPage(),
                RoadmapPage(),
                TeamPage(),
              ],
            ),
          )
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: "Dashboard"),
          NavigationDestination(icon: Icon(Icons.calendar_view_week), label: "Roadmap"),
          NavigationDestination(icon: Icon(Icons.people), label: "Team"),
        ],
      ),
    );
  }
}

// ==========================================
// 6. DASHBOARD PAGE
// ==========================================

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  void _refresh() => setState(() {});

  void _showAddProjectDialog() {
    final title = TextEditingController();
    final desc = TextEditingController();
    final loc = TextEditingController();
    DateTime date = DateTime.now().add(const Duration(days: 7));
    String status = "Upcoming";

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (context, setDst) => AlertDialog(
        title: const Text("Create New Project"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: "Project Title")),
              TextField(controller: desc, decoration: const InputDecoration(labelText: "Description")),
              TextField(controller: loc, decoration: const InputDecoration(labelText: "Location")),
              const SizedBox(height: 10),
              Row(children: [
                const Text("Deadline: "),
                TextButton(onPressed: () async {
                  final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime.now(), lastDate: DateTime(2030));
                  if(d!=null) setDst(()=> date = d);
                }, child: Text(DateFormat('dd MMM yyyy').format(date)))
              ]),
              DropdownButton<String>(
                value: status,
                isExpanded: true,
                items: ["Upcoming", "On Progress"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setDst(()=> status = v!),
              )
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              MockDatabase.addEvent(EventModel(DateTime.now().millisecondsSinceEpoch.toString(), title.text, desc.text, status, date, loc.text, AuthSession.currentUser!.email, [AuthSession.currentUser!.email]));
              Navigator.pop(context);
              _refresh();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Project Created!")));
            }, 
            child: const Text("Create")
          )
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthSession.currentUser!;
    final events = MockDatabase.getEvents();
    final myEvents = user.role == UserRole.Admin 
        ? events 
        : events.where((e) => e.teamEmails.contains(user.email)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BANNER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.indigo, Colors.blueAccent], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Welcome back, ${user.username}!", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("Track your projects, manage tasks, and prove your work effectively.", style: TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // STATISTICS
          Row(
            children: [
              _statCard("Total Projects", "${events.length}", Colors.blue, Icons.folder),
              const SizedBox(width: 15),
              _statCard("My Active", "${myEvents.length}", Colors.orange, Icons.work),
              const SizedBox(width: 15),
              _statCard("Completed", "0", Colors.green, Icons.check_circle),
            ],
          ),
          const SizedBox(height: 30),

          // HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Recent Projects", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              if (user.role != UserRole.Member)
                ElevatedButton.icon(
                  onPressed: _showAddProjectDialog,
                  icon: const Icon(Icons.add), label: const Text("New Project"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                )
            ],
          ),
          const SizedBox(height: 15),

          // GRID
          if (events.isEmpty) 
            const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No projects found.")))
          else
            Wrap(
              spacing: 20, runSpacing: 20,
              children: events.map((e) => _buildProjectCard(e, user)).toList(),
            )
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(EventModel e, User user) {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Chip(label: Text(e.status, style: const TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: e.status == 'Upcoming' ? Colors.orange : Colors.blue, padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
              if (user.role != UserRole.Member)
                 IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.grey), onPressed: (){ MockDatabase.deleteEvent(e.id); _refresh(); })
            ],
          ),
          const SizedBox(height: 10),
          Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 5),
          Text(e.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey), const SizedBox(width: 5),
              Text(DateFormat('dd MMM yyyy').format(e.date), style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectDetailPage(event: e))).then((_) => _refresh()),
              child: const Text("View Details")
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// 7. PROJECT DETAIL PAGE
// ==========================================

class ProjectDetailPage extends StatefulWidget {
  final EventModel event;
  const ProjectDetailPage({super.key, required this.event});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  late EventModel _evt;

  @override
  void initState() {
    super.initState();
    _evt = widget.event;
  }

  void _refresh() => setState(() {});

  void _showEditDialog() {
    final title = TextEditingController(text: _evt.title);
    final desc = TextEditingController(text: _evt.description);
    final loc = TextEditingController(text: _evt.location);
    DateTime date = _evt.date;
    final emailCtrl = TextEditingController();

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (context, setDst) => AlertDialog(
        title: const Text("Edit Project Details"),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: title, decoration: const InputDecoration(labelText: "Project Name")),
                TextField(controller: desc, maxLines: 3, decoration: const InputDecoration(labelText: "Description")),
                TextField(controller: loc, decoration: const InputDecoration(labelText: "Location")),
                const SizedBox(height: 10),
                Row(children: [
                  const Text("Deadline: "),
                  TextButton(onPressed: () async {
                    final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2023), lastDate: DateTime(2030));
                    if(d!=null) setDst(()=> date = d);
                  }, child: Text(DateFormat('dd MMM yyyy').format(date)))
                ]),
                const Divider(),
                const Text("Manage Team (Add by Email)", style: TextStyle(fontWeight: FontWeight.bold)),
                Row(children: [
                  Expanded(child: TextField(controller: emailCtrl, decoration: const InputDecoration(hintText: "Enter user email"))),
                  IconButton(icon: const Icon(Icons.add_circle, color: Colors.indigo), onPressed: (){
                    if(emailCtrl.text.isNotEmpty && !_evt.teamEmails.contains(emailCtrl.text)) {
                      setDst(() { _evt.teamEmails.add(emailCtrl.text); emailCtrl.clear(); });
                    }
                  })
                ]),
                Wrap(
                  spacing: 5,
                  children: _evt.teamEmails.map((e) => Chip(
                    label: Text(e),
                    onDeleted: () => setDst(() => _evt.teamEmails.remove(e)),
                  )).toList(),
                )
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: (){
            final newEvt = EventModel(_evt.id, title.text, desc.text, _evt.status, date, loc.text, _evt.picEmail, _evt.teamEmails, attachments: _evt.attachments);
            MockDatabase.updateEvent(_evt.id, newEvt);
            setState(() => _evt = newEvt);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Project Updated!")));
          }, child: const Text("Save Changes"))
        ],
      )
    ));
  }

  void _addAttachment() {
    setState(() { _evt.attachments.add("file_${DateTime.now().second}.jpg"); });
    MockDatabase.updateEvent(_evt.id, _evt);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("File Attached!")));
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthSession.currentUser!;
    final canEdit = user.role == UserRole.Admin || user.role == UserRole.PIC;

    return Scaffold(
      appBar: AppBar(title: Text(_evt.title), elevation: 1, backgroundColor: Colors.white, foregroundColor: Colors.black),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (canEdit)
              Align(alignment: Alignment.centerRight, child: ElevatedButton.icon(onPressed: _showEditDialog, icon: const Icon(Icons.edit), label: const Text("Edit Project"), style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white))),
            
            const SizedBox(height: 10),
            Row(children: [
              _infoTile(Icons.calendar_today, "Deadline", DateFormat('dd MMM yyyy').format(_evt.date)),
              const SizedBox(width: 10),
              _infoTile(Icons.location_on, "Location", _evt.location),
              const SizedBox(width: 10),
              _infoTile(Icons.person, "PIC", _evt.picEmail),
            ]),
            const SizedBox(height: 24),

            const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)), child: Text(_evt.description, style: const TextStyle(fontSize: 16, height: 1.5))),
            const SizedBox(height: 24),

            const Text("Team Members", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(spacing: 10, runSpacing: 10, children: _evt.teamEmails.map((e) {
              final u = MockDatabase.getUserByEmail(e);
              return Chip(avatar: CircleAvatar(child: Text(e[0].toUpperCase())), label: Text(u?.username ?? e), backgroundColor: Colors.white, side: BorderSide(color: Colors.grey.shade300));
            }).toList()),
            const SizedBox(height: 24),

            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text("Attachments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton.icon(onPressed: _addAttachment, icon: const Icon(Icons.upload_file), label: const Text("Add File"))
            ]),
            Container(
              height: 100, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
              child: _evt.attachments.isEmpty 
                  ? const Center(child: Text("No attachments yet."))
                  : ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.all(10), itemCount: _evt.attachments.length, itemBuilder: (c, i) => Container(width: 80, margin: const EdgeInsets.only(right: 10), decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.insert_drive_file, color: Colors.indigo, size: 30))),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: const Text("Project Roadmap")), body: RoadmapPage(initialProjectId: _evt.id)))); },
                icon: const Icon(Icons.map), label: const Text("View Project Roadmap"),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String val) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icon, size: 16, color: Colors.grey), const SizedBox(width: 5), Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))]),
          const SizedBox(height: 5),
          Text(val, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}

// ==========================================
// 8. ROADMAP PAGE (ADD & EDIT TASK UPDATED)
// ==========================================

class RoadmapPage extends StatefulWidget {
  final String? initialProjectId;
  const RoadmapPage({super.key, this.initialProjectId});
  @override
  State<RoadmapPage> createState() => _RoadmapPageState();
}

class _RoadmapPageState extends State<RoadmapPage> {
  String _filter = "All";
  final double _dayWidth = 40.0;
  final double _rowHeight = 60.0;
  final DateTime _viewStartDate = DateTime.now().subtract(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    if(widget.initialProjectId != null) _filter = widget.initialProjectId!;
  }

  void _refresh() => setState(() {});

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
    DateTime end = isEdit ? task.end : DateTime.now().add(const Duration(days: 7));
    String status = isEdit ? task.status : "To Do";
    double progress = isEdit ? task.progress : 0.0;
    
    // Grouping: Select Project (If adding new)
    String selectedProjId = _filter != "All" ? _filter : (MockDatabase.getEvents().isNotEmpty ? MockDatabase.getEvents().first.id : "");

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (context, setDst) => AlertDialog(
        title: Text(isEdit ? "Edit Task" : "Add New Task"),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isEdit && _filter == "All") 
                  DropdownButton<String>(
                    value: selectedProjId, isExpanded: true,
                    items: MockDatabase.getEvents().map((e) => DropdownMenuItem(value: e.id, child: Text(e.title))).toList(),
                    onChanged: (v) => setDst(() => selectedProjId = v!),
                  ),
                TextField(controller: title, decoration: const InputDecoration(labelText: "Task Name")),
                TextField(controller: desc, decoration: const InputDecoration(labelText: "Description")),
                const SizedBox(height: 15),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  TextButton(onPressed: () async { final d = await showDatePicker(context: context, initialDate: start, firstDate: DateTime(2023), lastDate: DateTime(2030)); if(d!=null) setDst(()=>start=d); }, child: Text("Start: ${DateFormat('dd MMM').format(start)}")),
                  TextButton(onPressed: () async { final d = await showDatePicker(context: context, initialDate: end, firstDate: DateTime(2023), lastDate: DateTime(2030)); if(d!=null) setDst(()=>end=d); }, child: Text("End: ${DateFormat('dd MMM').format(end)}")),
                ]),
                const SizedBox(height: 10),
                const Text("Progress (Scroll to update)"),
                Slider(value: progress, onChanged: (v){ setDst((){ progress = v; if(v==1.0) status = "Done"; else if(v>0) status = "In Progress"; else status = "To Do"; }); }),
                DropdownButton<String>(
                   value: status, isExpanded: true,
                   items: ["To Do", "In Progress", "Done"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                   onChanged: (v) => setDst(() => status = v!),
                )
              ],
            ),
          ),
        ),
        actions: [
          if (isEdit) TextButton(onPressed: (){ MockDatabase.deleteTask(task.id); Navigator.pop(context); _refresh(); }, child: const Text("Delete", style: TextStyle(color: Colors.red))),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: (){
            if (isEdit) {
              // UPDATE EXISTING
              task.title = title.text;
              task.description = desc.text;
              task.start = start;
              task.end = end;
              task.status = status;
              task.progress = progress;
              MockDatabase.updateTask(task);
            } else {
              // ADD NEW
              MockDatabase.addTask(RoadmapTask(id: DateTime.now().toString(), projectId: selectedProjId, title: title.text, description: desc.text, status: status, start: start, end: end, progress: progress));
            }
            Navigator.pop(context);
            _refresh();
          }, child: Text(isEdit ? "Save Changes" : "Create Task"))
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final projects = MockDatabase.getEvents();
    final allTasks = MockDatabase.getAllTasks();
    final displayTasks = _filter == "All" ? allTasks : allTasks.where((t) => t.projectId == _filter).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: () => _showTaskDialog(), child: const Icon(Icons.add)),
      body: Column(
        children: [
          Container(
            height: 50, color: Colors.white,
            child: ListView(
              scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              children: [
                _buildFilterChip("All Projects", "All"),
                ...projects.map((p) => _buildFilterChip(p.title, p.id)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 200, decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade300))),
                  child: Column(
                    children: [
                      Container(height: 50, alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 10), color: Colors.grey.shade100, child: const Text("Task Name", style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(
                        child: ListView.builder(
                          itemCount: displayTasks.length,
                          itemBuilder: (c, i) => Container(
                            height: _rowHeight, alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 10),
                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
                            child: Text(displayTasks[i].title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: _dayWidth * 120,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 50,
                            child: Stack(children: [
                              for(int i=0; i<120; i+=30)
                                Positioned(left: i*_dayWidth, top: 15, child: Text(DateFormat('MMM').format(_viewStartDate.add(Duration(days: i))), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                            ]),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: Stack(
                              children: [
                                for(int i=0; i<120; i+=7) Positioned(left: i*_dayWidth, top: 0, bottom: 0, child: Container(width: 1, color: Colors.grey.shade100)),
                                ...displayTasks.asMap().entries.map((entry) {
                                  final t = entry.value;
                                  final i = entry.key;
                                  final startOffset = t.start.difference(_viewStartDate).inDays * _dayWidth;
                                  final width = t.end.difference(t.start).inDays * _dayWidth;
                                  return Positioned(
                                    top: i * _rowHeight + 15, left: startOffset,
                                    child: InkWell(
                                      onTap: () => _showTaskDialog(task: t), // EDIT ON CLICK
                                      child: Container(
                                        width: width < _dayWidth ? _dayWidth : width, height: 30,
                                        decoration: BoxDecoration(color: _getTaskColor(t), borderRadius: BorderRadius.circular(4)),
                                        alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 5),
                                        child: Text("${(t.progress * 100).toInt()}%", style: const TextStyle(color: Colors.white, fontSize: 10)),
                                      ),
                                    ),
                                  );
                                }),
                                Positioned(left: DateTime.now().difference(_viewStartDate).inDays * _dayWidth, top: 0, bottom: 0, child: Container(width: 2, color: Colors.blueAccent))
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String id) {
    return Padding(padding: const EdgeInsets.only(right: 8.0), child: ChoiceChip(label: Text(label), selected: _filter == id, onSelected: (v) => setState(() => _filter = id), selectedColor: Colors.indigo.shade100));
  }
}

// ==========================================
// 9. TEAM PAGE (ADMIN MANAGEMENT)
// ==========================================

class TeamPage extends StatefulWidget {
  const TeamPage({super.key});
  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  void _refresh() => setState(() {});

  void _showAddUserDialog() {
    final name = TextEditingController();
    final email = TextEditingController();
    final pass = TextEditingController();
    UserRole role = UserRole.Member;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (context, setDst) => AlertDialog(
        title: const Text("Add New User"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: "Username")),
            TextField(controller: email, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: pass, decoration: const InputDecoration(labelText: "Password")),
            const SizedBox(height: 10),
            DropdownButton<UserRole>(
              value: role, isExpanded: true,
              items: UserRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.toString().split('.').last))).toList(),
              onChanged: (v) => setDst(()=> role = v!),
            )
          ],
        ),
        actions: [
          ElevatedButton(onPressed: (){
            MockDatabase.addUser(User(id: DateTime.now().toString(), username: name.text, email: email.text, password: pass.text, role: role));
            Navigator.pop(context); _refresh();
          }, child: const Text("Create User"))
        ],
      )
    ));
  }

  void _showEditUserDialog(User user) {
    final name = TextEditingController(text: user.username);
    final email = TextEditingController(text: user.email);
    UserRole role = user.role;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (context, setDst) => AlertDialog(
        title: const Text("Edit User"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: "Username")),
            TextField(controller: email, decoration: const InputDecoration(labelText: "Email")),
            const SizedBox(height: 10),
            DropdownButton<UserRole>(
              value: role, isExpanded: true,
              items: UserRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.toString().split('.').last))).toList(),
              onChanged: (v) => setDst(()=> role = v!),
            )
          ],
        ),
        actions: [
          ElevatedButton(onPressed: (){
            MockDatabase.updateUser(User(id: user.id, username: name.text, email: email.text, password: user.password, role: role));
            Navigator.pop(context); _refresh();
          }, child: const Text("Update User"))
        ],
      )
    ));
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthSession.currentUser!;
    final users = MockDatabase.getUsers();
    final canManage = currentUser.role == UserRole.Admin;

    return Scaffold(
      floatingActionButton: canManage ? FloatingActionButton(onPressed: _showAddUserDialog, child: const Icon(Icons.add)) : null,
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: users.length,
        separatorBuilder: (c, i) => const Divider(),
        itemBuilder: (c, i) {
          final u = users[i];
          return ListTile(
            leading: CircleAvatar(child: Text(u.username[0])),
            title: Text(u.username, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${u.email} • ${u.role.toString().split('.').last}"),
            trailing: canManage 
              ? IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showEditUserDialog(u))
              : null,
          );
        },
      ),
    );
  }
}