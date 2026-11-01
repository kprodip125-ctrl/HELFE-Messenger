import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hwjxzrfvgtttghseydhk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh3anh6cmZ2Z3R0dGdoc2V5ZGhrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM1MjY3NDcsImV4cCI6MjEwOTEwMjc0N30.aKw20_UsBLH807Qi0G8MfykCmyssxnZOuZOL7pOG16I',
  );

  runApp(const HelfeMessenger());
}

final supabase = Supabase.instance.client;

class HelfeMessenger extends StatelessWidget {
  const HelfeMessenger({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HELFE Messenger',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: supabase.auth.currentSession == null
          ? const LoginPage()
          : const HomePage(),
    );
  }
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

// ================= LOGIN =================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;

  Future<void> login() async {
    setState(() => loading = true);
    try {
      await supabase.auth.signInWithPassword(
        email: email.text.trim(),
        password: password.text,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      if (mounted) showMessage(context, 'Login failed: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.forum, size: 76),
              const SizedBox(height: 18),
              const Text(
                'HELFE Messenger',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 35),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: loading ? null : login,
                  child: Text(loading ? 'Loading...' : 'LOGIN'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterPage()),
                ),
                child: const Text('Create New Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= REGISTER =================

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;

  Future<void> register() async {
    if (name.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        password.text.length < 6) {
      showMessage(context, 'Enter name, email and password (min 6 characters).');
      return;
    }

    setState(() => loading = true);
    try {
      await supabase.auth.signUp(
        email: email.text.trim(),
        password: password.text,
        data: {'full_name': name.text.trim()},
      );

      if (!mounted) return;
      showMessage(context, 'Account created. Check your email for verification.');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showMessage(context, 'Registration failed: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Full Name'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email Address'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: loading ? null : register,
            child: Text(loading ? 'Creating...' : 'CREATE ACCOUNT'),
          ),
        ],
      ),
    );
  }
}

// ================= HOME / GROUPS =================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> groups = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadGroups();
  }

  Future<void> loadGroups() async {
    if (mounted) setState(() => loading = true);

    try {
      final data = await supabase
          .from('groups')
          .select('id, name, created_by, created_at')
          .order('created_at', ascending: false);

      groups = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      if (mounted) showMessage(context, 'Could not load groups: $e');
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> createGroup() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create New Group'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Group Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final groupName = controller.text.trim();
              if (groupName.isEmpty) return;

              try {
                await supabase.from('groups').insert({
                  'name': groupName,
                  'created_by': supabase.auth.currentUser!.id,
                });

                if (!mounted) return;
                Navigator.pop(dialogContext);
                await loadGroups();
                showMessage(context, 'Group created. You are the Admin.');
              } catch (e) {
                if (mounted) showMessage(context, 'Create failed: $e');
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    controller.dispose();
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HELFE Messenger'),
        actions: [
          IconButton(
            onPressed: loadGroups,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadGroups,
              child: groups.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 220),
                        Center(child: Text('No groups yet. Create your first group!')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        final group = groups[index];

                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.groups),
                            ),
                            title: Text(group['name'] ?? 'Unnamed Group'),
                            subtitle: Text(
                              group['created_by'] == supabase.auth.currentUser?.id
                                  ? 'Created by you'
                                  : 'Business Group',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GroupDetailsPage(
                                    group: group,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: createGroup,
        icon: const Icon(Icons.group_add),
        label: const Text('New Group'),
      ),
    );
  }
}

// ================= GROUP DETAILS =================

class GroupDetailsPage extends StatefulWidget {
  final Map<String, dynamic> group;

  const GroupDetailsPage({super.key, required this.group});

  @override
  State<GroupDetailsPage> createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  List<Map<String, dynamic>> members = [];
  bool loading = true;
  bool isAdmin = false;

  String get groupId => widget.group['id'].toString();

  @override
  void initState() {
    super.initState();
    loadMembers();
  }

  Future<void> loadMembers() async {
    setState(() => loading = true);

    try {
      final data = await supabase
          .from('group_members')
          .select('user_id, role, joined_at')
          .eq('group_id', groupId)
          .order('joined_at');

      members = List<Map<String, dynamic>>.from(data);

      final currentId = supabase.auth.currentUser!.id;
      isAdmin = members.any(
        (m) => m['user_id'] == currentId && m['role'] == 'admin',
      );
    } catch (e) {
      if (mounted) showMessage(context, 'Member loading failed: $e');
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> addMember() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Group Member'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Registered Email Address',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final address = controller.text.trim();
              if (address.isEmpty) return;

              try {
                final result = await supabase.rpc(
                  'add_group_member_by_email',
                  params: {
                    '_group_id': groupId,
                    '_email': address,
                  },
                );

                if (!mounted) return;
                Navigator.pop(dialogContext);
                await loadMembers();
                showMessage(context, result.toString());
              } catch (e) {
                if (mounted) {
                  showMessage(context, 'Could not add member: $e');
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    controller.dispose();
  }

  Future<void> removeMember(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Member?'),
        content: const Text('This member will be removed from the group.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await supabase
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);

      await loadMembers();
      if (mounted) showMessage(context, 'Member removed.');
    } catch (e) {
      if (mounted) showMessage(context, 'Remove failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group['name'] ?? 'Group'),
        actions: [
          IconButton(
            onPressed: loadMembers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: const Text('Group Admin'),
                  subtitle: Text(
                    isAdmin ? 'You are the Admin' : 'You are a Member',
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Members',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isAdmin)
                        FilledButton.icon(
                          onPressed: addMember,
                          icon: const Icon(Icons.person_add),
                          label: const Text('Add Member'),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: members.isEmpty
                      ? const Center(child: Text('No members found'))
                      : ListView.builder(
                          itemCount: members.length,
                          itemBuilder: (context, index) {
                            final member = members[index];
                            final userId = member['user_id'].toString();
                            final role = member['role'].toString();
                            final isMe =
                                userId == supabase.auth.currentUser!.id;

                            return ListTile(
                              leading: CircleAvatar(
                                child: Icon(
                                  role == 'admin'
                                      ? Icons.admin_panel_settings
                                      : Icons.person,
                                ),
                              ),
                              title: Text(
                                isMe ? 'You' : 'Member ${index + 1}',
                              ),
                              subtitle: Text(role.toUpperCase()),
                              trailing: isAdmin &&
                                      role == 'member'
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.person_remove,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () => removeMember(userId),
                                    )
                                  : null,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
