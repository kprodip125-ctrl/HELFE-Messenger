import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hwjxzrfvgtttghseydhk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh3anh6cmZ2Z3R0dGdoc2V5ZGhrIiwicm9sZSI6IjBhbm9uIiwiaWF0IjoxNzkzNTI2NzQ3LCJleHAiOjIxMDkxMDI3NDd9.aKw20_UsBLH807Qi0G8MfykCmyssxnZOuZOL7pOG16I',
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
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
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
                  MaterialPageRoute(
                    builder: (_) => const RegisterPage(),
                  ),
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
      showMessage(
        context,
        'Enter name, email and password (min 6 characters).',
      );
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

      showMessage(
        context,
        'Account created. Check your email for verification.',
      );

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
            decoration: const InputDecoration(
              labelText: 'Email Address',
            ),
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

                showMessage(
                  context,
                  'Group created. You are the Admin.',
                );
              } catch (e) {
                if (mounted) {
                  showMessage(context, 'Create failed: $e');
                }
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
                        Center(
                          child: Text(
                            'No groups yet. Create your first group!',
                          ),
                        ),
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
                            title: Text(
                              group['name'] ?? 'Unnamed Group',
                            ),
                            subtitle: Text(
                              group['created_by'] ==
                                      supabase.auth.currentUser?.id
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

  const GroupDetailsPage({
    super.key,
    required this.group,
  });

  @override
  State<GroupDetailsPage> createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  List<Map<String, dynamic>> members = [];
  List<Map<String, dynamic>> joinRequests = [];
  List<Map<String, dynamic>> invites = [];

  bool loading = true;
  bool isAdmin = false;

  String get groupId => widget.group['id'].toString();

  @override
  void initState() {
    super.initState();
    loadMembers();
  }

  // ================= LOAD MEMBERS =================

  Future<void> loadMembers() async {
    if (mounted) setState(() => loading = true);

    try {
      final data = await supabase
          .from('group_members')
          .select('user_id, role, joined_at')
          .eq('group_id', groupId)
          .order('joined_at');

      members = List<Map<String, dynamic>>.from(data);

      final currentId = supabase.auth.currentUser!.id;

      isAdmin = members.any(
        (m) =>
            m['user_id'] == currentId &&
            m['role'] == 'admin',
      );

      if (isAdmin) {
        await loadInviteData();
      }
    } catch (e) {
      if (mounted) {
        showMessage(context, 'Member loading failed: $e');
      }
    }

    if (mounted) setState(() => loading = false);
  }

  // ================= LOAD INVITES =================

  Future<void> loadInviteData() async {
    try {
      final requests = await supabase
          .from('group_join_requests')
          .select('id, user_id, status, created_at')
          .eq('group_id', groupId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final inviteData = await supabase
          .from('group_invites')
          .select(
            'id, expires_at, max_uses, uses_count, revoked_at',
          )
          .eq('group_id', groupId)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        joinRequests = List<Map<String, dynamic>>.from(requests);
        invites = List<Map<String, dynamic>>.from(inviteData);
      });
    } catch (e) {
      if (mounted) {
        showMessage(context, 'Invite loading failed: $e');
      }
    }
  }

  // ================= CREATE INVITE =================

  Future<void> createInvite() async {
    try {
      final token = await supabase.rpc(
        'create_group_invite',
        params: {
          '_group_id': groupId,
          '_expires_in_hours': 168,
          '_max_uses': 20,
        },
      );

      final inviteLink = 'helfe://join?token=$token';

      await Clipboard.setData(
        ClipboardData(text: inviteLink),
      );

      await loadInviteData();

      if (mounted) {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Invite Link Created'),
            content: SelectableText(inviteLink),
            actions: [
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: inviteLink),
                  );

                  if (mounted) {
                    Navigator.pop(dialogContext);
                    showMessage(context, 'Invite link copied.');
                  }
                },
                child: const Text('COPY'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('CLOSE'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showMessage(context, 'Invite creation failed: $e');
      }
    }
  }

  // ================= APPROVE REQUEST =================

  Future<void> approveRequest(String requestId) async {
    try {
      final result = await supabase.rpc(
        'approve_group_join_request',
        params: {'_request_id': requestId},
      );

      await loadMembers();
      await loadInviteData();

      if (mounted) showMessage(context, result.toString());
    } catch (e) {
      if (mounted) showMessage(context, 'Approval failed: $e');
    }
  }

  // ================= REJECT REQUEST =================

  Future<void> rejectRequest(String requestId) async {
    try {
      final result = await supabase.rpc(
        'reject_group_join_request',
        params: {'_request_id': requestId},
      );

      await loadInviteData();

      if (mounted) showMessage(context, result.toString());
    } catch (e) {
      if (mounted) showMessage(context, 'Rejection failed: $e');
    }
  }

  // ================= REVOKE INVITE =================

  Future<void> revokeInvite(String inviteId) async {
    try {
      final result = await supabase.rpc(
        'revoke_group_invite',
        params: {'_invite_id': inviteId},
      );

      await loadInviteData();

      if (mounted) showMessage(context, result.toString());
    } catch (e) {
      if (mounted) showMessage(context, 'Revoke failed: $e');
    }
  }

  // ================= ADD MEMBER =================

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

  // ================= REMOVE MEMBER =================

  Future<void> removeMember(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Member?'),
        content: const Text(
          'This member will be removed from the group.',
        ),
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

  // ================= GROUP UI =================

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
          : ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: const Text('Group Admin'),
                  subtitle: Text(
                    isAdmin ? 'You are the Admin' : 'You are a Member',
                  ),
                ),

                const Divider(),

                // INVITE MANAGEMENT
                if (isAdmin) ...[
                  ListTile(
                    leading: const Icon(Icons.link),
                    title: const Text('Create Group Invite Link'),
                    subtitle: const Text(
                      'Valid for 7 days • Maximum 20 uses',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_link),
                      onPressed: createInvite,
                    ),
                  ),

                  const Divider(),

                  ListTile(
                    leading: const Icon(Icons.pending_actions),
                    title: const Text('Pending Join Requests'),
                    trailing: Text('${joinRequests.length}'),
                    onTap: loadInviteData,
                  ),

                  if (joinRequests.isEmpty)
                    const ListTile(
                      title: Text('No pending requests'),
                    ),

                  ...joinRequests.map((request) {
                    final requestId = request['id'].toString();

                    return ListTile(
                      leading: const Icon(Icons.person_add_alt_1),
                      title: Text(
                        'User ID: ${request['user_id']}',
                      ),
                      subtitle: const Text('Waiting for approval'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            onPressed: () => approveRequest(requestId),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.cancel,
                              color: Colors.red,
                            ),
                            onPressed: () => rejectRequest(requestId),
                          ),
                        ],
                      ),
                    );
                  }),

                  const Divider(),

                  const ListTile(
                    leading: Icon(Icons.link),
                    title: Text('Active Invite Links'),
                  ),

                  ...invites.where(
                    (invite) => invite['revoked_at'] == null,
                  ).map((invite) {
                    return ListTile(
                      leading: const Icon(Icons.link),
                      title: const Text('Active Invite'),
                      subtitle: Text(
                        'Uses: ${invite['uses_count']}/${invite['max_uses']}'
                        '\nExpires: ${invite['expires_at']}',
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.link_off,
                          color: Colors.red,
                        ),
                        tooltip: 'Revoke invite',
                        onPressed: () => revokeInvite(
                          invite['id'].toString(),
                        ),
                      ),
                    );
                  }),

                  const Divider(),
                ],

                // MEMBERS
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

                if (members.isEmpty)
                  const Center(child: Text('No members found'))
                else
                  ...members.asMap().entries.map((entry) {
                    final index = entry.key;
                    final member = entry.value;

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
                      trailing: isAdmin && role == 'member'
                          ? IconButton(
                              icon: const Icon(
                                Icons.person_remove,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => removeMember(userId),
                            )
                          : null,
                    );
                  }),
              ],
            ),
    );
  }
}
