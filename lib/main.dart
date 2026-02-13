import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const ProofItApp());
}

// ==========================================
// 1. MOCK DATABASE & MODELS
// ==========================================

class User {
  final String username;
  final String email;
  final String password;
  final String role; // 'Admin', 'PIC', 'Member'
  User({required this.username, required this.email, required this.password, required this.role});
}

class EventModel {
  String id;
  String title;
  String description;
  String status;
  DateTime date;
  String location;
  String pic;

  EventModel(this.id, this.title, this.description, this.status, this.date, this.location, this.pic);
}

class RoadmapTask {
  String id;
  String title;
  String description;
  String status;
  DateTime start;
  DateTime end;
  double progress;

  RoadmapTask({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.start,
    required this.end,
    this.progress = 0.0,
  });
}

class MockDatabase {
  // DATA USER
  static final List<User> _users = [
    User(username: "Super Admin", email: "admin@proofit.com", password: "admin123", role: "Admin"),
    User(username: "Siti Manager", email: "pic@test.com", password: "123", role: "PIC"),
    User(username: "Andi Staff", email: "member@test.com", password: "123", role: "Member"),
    User(username: "Budi Senior", email: "budi@test.com", password: "123", role: "Member"),
  ];

  // DATA PROJECT / EVENT
  static final List<EventModel> _events = [
    EventModel("1", "Grand Launching Product", "Peluncuran produk baru Proof It!", "Upcoming", DateTime.now().add(const Duration(days: 5)), "Grand Ballroom", "Siti Manager"),
    EventModel("2", "Internal Workshop", "Pelatihan manajemen.", "On Progress", DateTime.now(), "Meeting Room 1", "Budi Senior"),
  ];

  // DATA ROADMAP
  static final List<RoadmapTask> _roadmapTasks = [
    RoadmapTask(id: "1", title: "Build Mobile App", description: "Fase development flutter.", status: "In Progress", start: DateTime(2023, 10, 1), end: DateTime(2023, 11, 15), progress: 0.5),
    RoadmapTask(id: "2", title: "Booking feature", description: "Fitur booking venue.", status: "To Do", start: DateTime(2023, 10, 20), end: DateTime(2023, 11, 25), progress: 0.0),
  ];

  // AUTH
  static User? login(String email, String password) {
    try {
      return _users.firstWhere((u) => u.email == email && u.password == password);
    } catch (e) {
      return null;
    }
  }

  static void register(String username, String email, String password, String role) {
    _users.add(User(username: username, email: email, password: password, role: role));
  }

  // EVENT / PROJECT CRUD
  static List<EventModel> getEvents() => _events;
  
  static void addEvent(EventModel event) {
    _events.add(event);
  }

  static void deleteEvent(String id) {
    _events.removeWhere((e) => e.id == id);
  }

  static void updateEvent(String id, EventModel newEvent) {
    int index = _events.indexWhere((e) => e.id == id);
    if(index != -1) _events[index] = newEvent;
  }

  // ROADMAP CRUD
  static List<RoadmapTask> getRoadmap() => _roadmapTasks;
  static void addTask(RoadmapTask task) => _roadmapTasks.add(task);
  static void updateTaskStatus(String id, String status, double progress) {
    final index = _roadmapTasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _roadmapTasks[index].status = status;
      _roadmapTasks[index].progress = progress;
    }
  }
  static void deleteTask(String id) => _roadmapTasks.removeWhere((t) => t.id == id);

  // USER LIST
  static List<User> getUsers() => _users;
}

class AuthSession {
  static User? currentUser;
}

// ==========================================
// 2. MAIN APP & THEME
// ==========================================

class ProofItApp extends StatelessWidget {
  const ProofItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Proof It!',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFF4F5F7),
        useMaterial3: true,
        fontFamily: 'Segoe UI',
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
        )
      ),
      home: const LoginScreen(),
    );
  }
}

// ==========================================
// 3. LOGIN SCREEN
// ==========================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  String _errorMessage = "";

  void _handleLogin() {
    final user = MockDatabase.login(_emailController.text, _passController.text);
    if (user != null) {
      AuthSession.currentUser = user;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainLayout()));
    } else {
      setState(() => _errorMessage = "Email atau Password salah!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 10)]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_user, size: 60, color: Colors.deepPurple),
              const SizedBox(height: 20),
              const Text("Login Proof It!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder(), prefixIcon: Icon(Icons.email))),
              const SizedBox(height: 15),
              TextField(controller: _passController, obscureText: true, decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
              if (_errorMessage.isNotEmpty) ...[const SizedBox(height: 10), Text(_errorMessage, style: const TextStyle(color: Colors.red))],
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _handleLogin, style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white), child: const Text("MASUK"))),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 4. MAIN LAYOUT
// ==========================================

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});
  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0; 

  @override
  Widget build(BuildContext context) {
    final user = AuthSession.currentUser!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 0,
        toolbarHeight: 65,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              const Icon(Icons.verified_user, color: Colors.deepPurple, size: 28),
              const SizedBox(width: 8),
              const Text("Proof It!", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(width: 40),
              if (MediaQuery.of(context).size.width > 700) ...[
                _navButton("Dashboard", 0),
                _navButton("Roadmap", 1),
                if (user.role == 'PIC' || user.role == 'Admin') _navButton("Team", 2),
              ],
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              showMenu(
                context: context, 
                position: const RelativeRect.fromLTRB(100, 80, 0, 0),
                items: [
                  const PopupMenuItem(child: ListTile(leading: Icon(Icons.info, color: Colors.blue), title: Text("New Task Assigned"), subtitle: Text("Just now"))),
                ]
              );
            }, 
            icon: const Icon(Icons.notifications_outlined, color: Colors.grey)
          ),
          const SizedBox(width: 15),
          Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Hi, ${user.username}", style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(user.role, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                ],
              ),
              const SizedBox(width: 10),
              CircleAvatar(backgroundColor: Colors.deepPurple, radius: 16, child: Text(user.username[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 14))),
              const SizedBox(width: 10),
              PopupMenuButton(
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
                onSelected: (val) {
                  if (val == 'logout') {
                    AuthSession.currentUser = null;
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                  }
                },
                itemBuilder: (context) => [const PopupMenuItem(value: 'logout', child: Text("Logout", style: TextStyle(color: Colors.red)))],
              ),
              const SizedBox(width: 20),
            ],
          )
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: return DashboardPage(user: AuthSession.currentUser!);
      case 1: return const RoadmapPage();
      case 2: return const TeamPage();
      default: return const Center(child: Text("Halaman dalam pengembangan"));
    }
  }

  Widget _navButton(String title, int index) {
    bool isActive = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(border: isActive ? const Border(bottom: BorderSide(color: Colors.deepPurple, width: 3)) : null),
        child: Text(title, style: TextStyle(color: isActive ? Colors.deepPurple : const Color(0xFF42526E), fontWeight: isActive ? FontWeight.w600 : FontWeight.w500)),
      ),
    );
  }
}

// ==========================================
// 5. DASHBOARD PAGE
// ==========================================

class DashboardPage extends StatefulWidget {
  final User user;
  const DashboardPage({super.key, required this.user});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  
  void _refresh() => setState(() {});

  void _showCreateProjectDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final picCtrl = TextEditingController();
    
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    String status = "Upcoming";

    showDialog(
      context: context, 
      builder: (context) {
        return StatefulBuilder( 
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Create New Project"),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Project Title", icon: Icon(Icons.title))),
                      TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Description", icon: Icon(Icons.description))),
                      TextField(controller: locCtrl, decoration: const InputDecoration(labelText: "Location", icon: Icon(Icons.location_on))),
                      TextField(controller: picCtrl, decoration: const InputDecoration(labelText: "PIC Name", icon: Icon(Icons.person))),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.grey),
                          const SizedBox(width: 15),
                          Text("Deadline: ${DateFormat('dd MMM yyyy').format(selectedDate)}"),
                          const Spacer(),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
                              if (picked != null) setDialogState(() => selectedDate = picked);
                            }, 
                            child: const Text("Change Date")
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                           const Icon(Icons.flag, color: Colors.grey),
                           const SizedBox(width: 15),
                           const Text("Status: "),
                           const SizedBox(width: 10),
                           DropdownButton<String>(
                             value: status,
                             items: const [
                               DropdownMenuItem(value: "Upcoming", child: Text("Upcoming")),
                               DropdownMenuItem(value: "On Progress", child: Text("On Progress")),
                             ], 
                             onChanged: (val) => setDialogState(() => status = val!)
                           )
                        ],
                      )
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.isEmpty) return;
                    MockDatabase.addEvent(EventModel(
                      DateTime.now().millisecondsSinceEpoch.toString(), 
                      titleCtrl.text, 
                      descCtrl.text, 
                      status, 
                      selectedDate, 
                      locCtrl.text, 
                      picCtrl.text
                    ));
                    Navigator.pop(context);
                    _refresh(); 
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Project Created Successfully!")));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                  child: const Text("Create Project"),
                )
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = MockDatabase.getEvents();

    return ListView(
      padding: const EdgeInsets.all(30),
      children: [
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.deepPurple, Colors.purpleAccent]), borderRadius: BorderRadius.circular(15)),
          child: Row(
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Halo, ${widget.user.role} ${widget.user.username}!", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  const Text("Selamat datang di Proof It! Kelola proyek dan bukti pekerjaanmu di sini.", style: TextStyle(color: Colors.white70)),
                ]),
              ),
              const Icon(Icons.rocket_launch, color: Colors.white24, size: 80),
            ],
          ),
        ),
        const SizedBox(height: 30),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Active Projects", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            if (widget.user.role == 'PIC' || widget.user.role == 'Admin')
              ElevatedButton.icon(
                onPressed: _showCreateProjectDialog,
                icon: const Icon(Icons.add), 
                label: const Text("Create Project"), 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white)
              ),
          ],
        ),
        const SizedBox(height: 15),
        
        Wrap(
          spacing: 20, 
          runSpacing: 20, 
          children: events.isEmpty 
            ? [const Text("No projects available. Create one!", style: TextStyle(color: Colors.grey))] 
            : events.map((e) => _buildEventCard(context, e)).toList(),
        ),
      ],
    );
  }

  Widget _buildEventCard(BuildContext context, EventModel event) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: event.status == 'Upcoming' ? Colors.orange[100] : Colors.green[100], borderRadius: BorderRadius.circular(5)), child: Text(event.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[800]))),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onSelected: (val) {
              if (val == 'delete') {
                 MockDatabase.deleteEvent(event.id);
                 _refresh();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'delete', child: Text("Delete Project", style: TextStyle(color: Colors.red))),
            ]
          ),
        ]),
        const SizedBox(height: 10),
        Text(event.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(event.description, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 15),
        Row(children: [const Icon(Icons.calendar_today, size: 14, color: Colors.grey), const SizedBox(width: 5), Text(DateFormat('dd MMM yyyy').format(event.date), style: const TextStyle(fontSize: 12))]),
        const SizedBox(height: 15),
        
        SizedBox(
          width: double.infinity, 
          child: OutlinedButton(
            onPressed: (){
              // Navigasi ke Halaman Detail Proyek dan Refresh saat kembali
              Navigator.push(context, MaterialPageRoute(builder: (context) => ProjectDetailPage(event: event))).then((_) => _refresh());
            }, 
            style: OutlinedButton.styleFrom(foregroundColor: Colors.deepPurple), 
            child: const Text("View Details")
          )
        )
      ]),
    );
  }
}

// ==========================================
// 6. TEAM PAGE
// ==========================================

class TeamPage extends StatelessWidget {
  const TeamPage({super.key});

  @override
  Widget build(BuildContext context) {
    List<User> users = MockDatabase.getUsers();
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 const Text("Team Members", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                 ElevatedButton.icon(onPressed: (){}, icon: const Icon(Icons.person_add), label: const Text("Add Member"), style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white)),
               ],
             ),
             const SizedBox(height: 20),
             Expanded(
               child: ListView.separated(
                 itemCount: users.length,
                 separatorBuilder: (c, i) => const Divider(),
                 itemBuilder: (context, index) {
                   final u = users[index];
                   return ListTile(
                     leading: CircleAvatar(child: Text(u.username[0])),
                     title: Text(u.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                     subtitle: Text(u.email),
                     trailing: Chip(
                       label: Text(u.role),
                       backgroundColor: u.role == 'Admin' ? Colors.red[100] : (u.role == 'PIC' ? Colors.blue[100] : Colors.grey[200]),
                     ),
                   );
                 },
               ),
             )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 7. PROJECT DETAIL PAGE (UPDATED WITH EDIT)
// ==========================================

class ProjectDetailPage extends StatefulWidget {
  final EventModel event;
  const ProjectDetailPage({super.key, required this.event});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  // State Lokal untuk refresh halaman setelah edit
  late EventModel _currentEvent;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
  }

  void _showEditProjectDialog() {
    final titleCtrl = TextEditingController(text: _currentEvent.title);
    final descCtrl = TextEditingController(text: _currentEvent.description);
    final locCtrl = TextEditingController(text: _currentEvent.location);
    final picCtrl = TextEditingController(text: _currentEvent.pic);
    
    DateTime selectedDate = _currentEvent.date;
    String status = _currentEvent.status;

    showDialog(
      context: context, 
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Edit Project Details"),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Project Title", icon: Icon(Icons.title))),
                      TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Description", icon: Icon(Icons.description))),
                      TextField(controller: locCtrl, decoration: const InputDecoration(labelText: "Location", icon: Icon(Icons.location_on))),
                      TextField(controller: picCtrl, decoration: const InputDecoration(labelText: "PIC Name", icon: Icon(Icons.person))),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.grey),
                          const SizedBox(width: 15),
                          Text("Deadline: ${DateFormat('dd MMM yyyy').format(selectedDate)}"),
                          const Spacer(),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
                              if (picked != null) setDialogState(() => selectedDate = picked);
                            }, 
                            child: const Text("Change")
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                           const Icon(Icons.flag, color: Colors.grey),
                           const SizedBox(width: 15),
                           const Text("Status: "),
                           const SizedBox(width: 10),
                           DropdownButton<String>(
                             value: status,
                             items: const [
                               DropdownMenuItem(value: "Upcoming", child: Text("Upcoming")),
                               DropdownMenuItem(value: "On Progress", child: Text("On Progress")),
                               DropdownMenuItem(value: "Done", child: Text("Done")),
                             ], 
                             onChanged: (val) => setDialogState(() => status = val!)
                           )
                        ],
                      )
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    // Update ke Database
                    final updatedEvent = EventModel(
                      _currentEvent.id, 
                      titleCtrl.text, 
                      descCtrl.text, 
                      status, 
                      selectedDate, 
                      locCtrl.text, 
                      picCtrl.text
                    );
                    MockDatabase.updateEvent(_currentEvent.id, updatedEvent);
                    
                    // Update UI Lokal
                    setState(() {
                      _currentEvent = updatedEvent;
                    });
                    
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Project Updated!")));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                  child: const Text("Save Changes"),
                )
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Project Details"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 1),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.deepPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.folder_copy, color: Colors.deepPurple, size: 30)),
              const SizedBox(width: 20),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_currentEvent.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 5), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: _currentEvent.status == 'Upcoming' ? Colors.orange : Colors.green, borderRadius: BorderRadius.circular(20)), child: Text(_currentEvent.status, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)))])),
            ]),
            const SizedBox(height: 30),
            
            GridView.count(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3, crossAxisSpacing: 20, mainAxisSpacing: 20, childAspectRatio: 2.5,
              children: [
                _buildInfoCard(Icons.calendar_month, "Date", DateFormat('dd MMMM yyyy').format(_currentEvent.date)),
                _buildInfoCard(Icons.location_on, "Location", _currentEvent.location),
                _buildInfoCard(Icons.person, "PIC", _currentEvent.pic),
              ],
            ),
            const SizedBox(height: 30),
            
            const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[300]!)), child: Text(_currentEvent.description, style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87))),
            const SizedBox(height: 30),

            const Text("Quick Notes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                hintText: "Add a quick note...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: IconButton(icon: const Icon(Icons.send), onPressed: (){})
              ),
            ),

            const SizedBox(height: 30),
            Row(children: [
              // TOMBOL EDIT BERFUNGSI
              ElevatedButton.icon(
                onPressed: _showEditProjectDialog, 
                icon: const Icon(Icons.edit), 
                label: const Text("Edit Project"), 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15))
              ),
              const SizedBox(width: 15),
              OutlinedButton.icon(
                onPressed: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const RoadmapPage()));
                }, 
                icon: const Icon(Icons.list_alt), 
                label: const Text("Open Roadmap"), 
                style: OutlinedButton.styleFrom(foregroundColor: Colors.deepPurple, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15))
              ),
            ])
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[300]!)), child: Row(children: [Icon(icon, color: Colors.grey, size: 20), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis)]))]));
  }
}

// ==========================================
// 8. ROADMAP PAGE (UPDATED ADD TASK)
// ==========================================

class RoadmapPage extends StatefulWidget {
  const RoadmapPage({super.key});
  @override
  State<RoadmapPage> createState() => _RoadmapPageState();
}

class _RoadmapPageState extends State<RoadmapPage> {
  final ScrollController _horizontalController = ScrollController();
  final double _rowHeight = 50.0;
  final double _headerHeight = 40.0;
  final double _taskColumnWidth = 250.0;
  final double _dayWidth = 30.0;
  final DateTime _startDate = DateTime(2023, 10, 1);

  void _refresh() => setState(() {});

  void _showTaskDetail(RoadmapTask task) {
    showDialog(context: context, builder: (context) {
      return StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          title: Text(task.title),
          content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Description:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])), Text(task.description), const SizedBox(height: 15),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Status: ${task.status}", style: const TextStyle(fontWeight: FontWeight.bold)), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: task.status == 'Done' ? Colors.green : (task.status == 'In Progress' ? Colors.blue : Colors.grey), borderRadius: BorderRadius.circular(4)), child: Text(task.status, style: const TextStyle(color: Colors.white, fontSize: 12)))]),
            const SizedBox(height: 20),
            Text("Progress: ${(task.progress * 100).toInt()}%", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
            Slider(value: task.progress, min: 0.0, max: 1.0, activeColor: Colors.deepPurple, onChanged: (val) { setStateDialog(() { task.progress = val; if (val == 1.0) task.status = 'Done'; else if (val > 0) task.status = 'In Progress'; else task.status = 'To Do'; }); }),
          ])),
          actions: [
            TextButton(onPressed: () { MockDatabase.deleteTask(task.id); Navigator.pop(context); _refresh(); }, child: const Text("Delete", style: TextStyle(color: Colors.red))),
            ElevatedButton(onPressed: () { MockDatabase.updateTaskStatus(task.id, task.status, task.progress); Navigator.pop(context); _refresh(); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white), child: const Text("Save Changes")),
          ],
        );
      });
    });
  }

  // --- ADD TASK DENGAN DATE RANGE ---
  void _showAddTaskDialog() {
    final titleCtrl = TextEditingController(); 
    final descCtrl = TextEditingController();
    
    // State Lokal untuk Dialog
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context, 
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Add New Task"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Task Title")), 
                  TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Description")),
                  const SizedBox(height: 20),
                  // START DATE
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 10),
                      Text("Start: ${DateFormat('dd MMM').format(startDate)}"),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                           final picked = await showDatePicker(context: context, initialDate: startDate, firstDate: DateTime(2023), lastDate: DateTime(2030));
                           if (picked != null) setDialogState(() => startDate = picked);
                        }, 
                        child: const Text("Select")
                      )
                    ],
                  ),
                  // END DATE
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 10),
                      Text("End:   ${DateFormat('dd MMM').format(endDate)}"),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                           final picked = await showDatePicker(context: context, initialDate: endDate, firstDate: DateTime(2023), lastDate: DateTime(2030));
                           if (picked != null) setDialogState(() => endDate = picked);
                        }, 
                        child: const Text("Select")
                      )
                    ],
                  )
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () { 
                    MockDatabase.addTask(RoadmapTask(
                      id: DateTime.now().toString(), 
                      title: titleCtrl.text, 
                      description: descCtrl.text, 
                      status: "To Do", 
                      start: startDate, 
                      end: endDate
                    )); 
                    Navigator.pop(context); 
                    _refresh(); 
                  }, 
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white), 
                  child: const Text("Create")
                )
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    List<RoadmapTask> tasks = MockDatabase.getRoadmap();
    return Scaffold(
      appBar: AppBar(title: const Text("Roadmap"), elevation: 1, backgroundColor: Colors.white, foregroundColor: Colors.black),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFDFE1E6)))), child: Row(children: [const Text("Roadmap View", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF172B4D))), const Spacer(), ElevatedButton.icon(onPressed: _showAddTaskDialog, icon: const Icon(Icons.add), label: const Text("Add Task"), style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white))])),
          Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: _taskColumnWidth, child: Column(children: [
              Container(height: _headerHeight, padding: const EdgeInsets.only(left: 20, top: 10), decoration: const BoxDecoration(color: Color(0xFFF4F5F7), border: Border(bottom: BorderSide(color: Color(0xFFDFE1E6)), right: BorderSide(color: Color(0xFFDFE1E6)))), alignment: Alignment.centerLeft, child: const Text("Epic", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B778C)))),
              Expanded(child: ListView.builder(itemCount: tasks.length, itemBuilder: (context, index) { return InkWell(onTap: () => _showTaskDetail(tasks[index]), child: Container(height: _rowHeight, padding: const EdgeInsets.symmetric(horizontal: 20), alignment: Alignment.centerLeft, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEBECF0)), right: BorderSide(color: Color(0xFFDFE1E6)))), child: Row(children: [Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: tasks[index].status == 'Done' ? Colors.green : Colors.deepPurple, borderRadius: BorderRadius.circular(4)), child: Icon(tasks[index].status == 'Done' ? Icons.check : Icons.bolt, color: Colors.white, size: 12)), const SizedBox(width: 10), Expanded(child: Text(tasks[index].title, style: const TextStyle(color: Color(0xFF172B4D), fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis))]))); }))
            ])),
            Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, controller: _horizontalController, child: SizedBox(width: _dayWidth * 90, child: Column(children: [
              Container(height: _headerHeight, decoration: const BoxDecoration(color: Color(0xFFF4F5F7), border: Border(bottom: BorderSide(color: Color(0xFFDFE1E6)))), child: Stack(children: [Row(children: List.generate(90, (i) => Container(width: _dayWidth, decoration: const BoxDecoration(border: Border(right: BorderSide(color: Color(0xFFEBECF0))))))), const Positioned(left: 10, top: 10, child: Text("Oct 2023", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B778C)))), Positioned(left: 31 * _dayWidth + 10, top: 10, child: const Text("Nov 2023", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B778C))))])),
              Expanded(child: SingleChildScrollView(child: Stack(children: [
                Column(children: List.generate(tasks.length, (index) => Container(height: _rowHeight, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEBECF0)))), child: Row(children: List.generate(90, (i) => Container(width: _dayWidth, decoration: const BoxDecoration(border: Border(right: BorderSide(color: Color(0xFFF4F5F7)))))))))),
                ...tasks.asMap().entries.map((entry) { final task = entry.value; final index = entry.key; int startOffset = task.start.difference(_startDate).inDays; int duration = task.end.difference(task.start).inDays; if (startOffset < 0) startOffset = 0; return Positioned(top: index * _rowHeight + 12.0, left: startOffset * _dayWidth, child: Tooltip(message: "${task.title} (${(task.progress * 100).toInt()}%)", child: InkWell(onTap: () => _showTaskDetail(task), child: Container(width: (duration * _dayWidth).toDouble(), height: 26, padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.centerLeft, decoration: BoxDecoration(color: task.status == 'Done' ? Colors.green : const Color(0xFF8777D9), borderRadius: BorderRadius.circular(4)), child: FractionallySizedBox(widthFactor: task.progress, child: Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(4)))))))); }).toList(),
                Positioned(left: DateTime.now().difference(_startDate).inDays * _dayWidth, top: 0, bottom: 0, child: Container(width: 2, color: Colors.orange))
              ])))
            ]))))
          ]))
        ],
      ),
    );
  }
}