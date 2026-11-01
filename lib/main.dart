import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

void msg(BuildContext context, String value) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(value)),
  );
}

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

// LOGIN

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
      if (mounted) msg(context, 'Login failed: $e');
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

// REGISTER

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
      msg(context, 'Enter name, email and password (min 6 characters).');
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
      msg(context, 'Account created. Check your email for verification.');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) msg(context, 'Registration failed: $e');
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

// HOME / GROUPS

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
      if (mounted) msg(context, 'Could not load groups: $e');
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
                msg(context, 'Group created. You are the Admin.');
              } catch (e) {
                if (mounted) msg(context, 'Create failed: $e');
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    controller.dispose();
  }

  Future<void> joinWithToken() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Join Group'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Paste Invite Token',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final token = controller.text.trim();
              if (token.isEmpty) return;

              try {
                final result = await supabase.rpc(
                  'request_group_join',
                  params: {'_token': token},
                );

                if (!mounted) return;
                Navigator.pop(dialogContext);
                msg(context, result.toString());
                await loadGroups();
              } catch (e) {
                if (mounted) {
                  msg(context, 'Join request failed: $e');
                }
              }
            },
            child: const Text('Send Request'),
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
                        SizedBox(height: 180),
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
                                  builder: (_) => GroupDetailsPage(group: group),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'join',
            onPressed: joinWithToken,
            icon: const Icon(Icons.link),
            label: const Text('Join with Invite'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'create',
            onPressed: createGroup,
            icon: const Icon(Icons.group_add),
            label: const Text('New Group'),
          ),
        ],
      ),
    );
  }
}

// GROUP DETAILS

class GroupDetailsPage extends StatefulWidget {
  final Map<String, dynamic> group;

  const GroupDetailsPage({super.key, required this.group});

  @override
  State<GroupDetailsPage> createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  List<Map<String, dynamic>> members = [];
  List<Map<String, dynamic>> invites = [];
  List<Map<String, dynamic>> requests = [];

  bool loading = true;
  bool isAdmin = false;
  bool inviteLoading = false;

  String get groupId => widget.group['id'].toString();

  @override
  void initState() {
    super.initState();
    loadMembers();
  }

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
        (m) => m['user_id'] == currentId && m['role'] == 'admin',
      );

      if (isAdmin) {
        await loadInviteData();
      }
    } catch (e) {
      if (mounted) msg(context, 'Member loading failed: $e');
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> loadInviteData() async {
    try {
      final inviteData = await supabase
          .from('group_invites')
          .select()
          .eq('group_id', groupId)
          .order('created_at', ascending: false);

      final requestData = await supabase
          .from('group_join_requests')
          .select()
          .eq('group_id', groupId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      invites = List<Map<String, dynamic>>.from(inviteData);
      requests = List<Map<String, dynamic>>.from(requestData);
    } catch (e) {
      if (mounted) msg(context, 'Invite data loading failed: $e');
    }
  }

  Future<void> createInvite() async {
    try {
      setState(() => inviteLoading = true);

      final result = await supabase.rpc(
        'create_group_invite',
        params: {
          '_group_id': groupId,
          '_expires_in_hours': 168,
          '_max_uses': null,
        },
      );

      final token = result.toString();

      if (!mounted) return;

      final inviteText = 'HELFE Group Invite Token:\n$token';

      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Invite Created'),
          content: SelectableText(inviteText),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: token));
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                msg(context, 'Invite token copied.');
              },
              child: const Text('COPY TOKEN'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CLOSE'),
            ),
          ],
        ),
      );

      await loadInviteData();
    } catch (e) {
      if (mounted) msg(context, 'Invite creation failed: $e');
    } finally {
      if (mounted) setState(() => inviteLoading = false);
    }
  }

  Future<void> approveRequest(String requestId) async {
    try {
      await supabase.rpc(
        'approve_group_join_request',
        params: {'_request_id': requestId},
      );

      await loadMembers();
      if (mounted) msg(context, 'Join request approved.');
    } catch (e) {
      if (mounted) msg(context, 'Approval failed: $e');
    }
  }

  Future<void> rejectRequest(String requestId) async {
    try {
      await supabase.rpc(
        'reject_group_join_request',
        params: {'_request_id': requestId},
      );

      await loadMembers();
      if (mounted) msg(context, 'Join request rejected.');
    } catch (e) {
      if (mounted) msg(context, 'Rejection failed: $e');
    }
  }

  Future<void> revokeInvite(String inviteId) async {
    try {
      await supabase.rpc(
        'revoke_group_invite',
        params: {'_invite_id': inviteId},
      );

      await loadMembers();
      if (mounted) msg(context, 'Invite revoked.');
    } catch (e) {
      if (mounted) msg(context, 'Revoke failed: $e');
    }
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
                msg(context, result.toString());
              } catch (e) {
                if (mounted) {
                  msg(context, 'Could not add member: $e');
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
      if (mounted) msg(context, 'Member removed.');
    } catch (e) {
      if (mounted) msg(context, 'Remove failed: $e');
    }
  }

  Widget inviteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'INVITE MANAGEMENT',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: inviteLoading ? null : createInvite,
              icon: const Icon(Icons.link),
              label: Text(
                inviteLoading ? 'Creating...' : 'Create Invite Token',
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Active / Previous Invites',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        if (invites.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('No invites created yet.'),
          ),
        ...invites.map((invite) {
          final revoked = invite['revoked_at'] != null;
          final inviteId = invite['id'].toString();

          return ListTile(
            leading: Icon(
              revoked ? Icons.link_off : Icons.link,
              color: revoked ? Colors.red : Colors.teal,
            ),
            title: Text(revoked ? 'Revoked Invite' : 'Invite Token'),
            subtitle: Text(
              'Uses: ${invite['uses_count'] ?? 0} / ${invite['max_uses'] ?? 'Unlimited'}\n'
              'Expires: ${invite['expires_at'] ?? 'Unknown'}',
            ),
            trailing: revoked
                ? const Text('REVOKED')
                : IconButton(
                    icon: const Icon(Icons.block, color: Colors.redAccent),
                    onPressed: () => revokeInvite(inviteId),
                  ),
          );
        }),
        const Divider(),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'PENDING JOIN REQUESTS',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
        if (requests.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No pending requests.'),
          ),
        ...requests.map((request) {
          final requestId = request['id'].toString();
          final userId = request['user_id'].toString();

          return Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text('User: ${userId.substring(0, 8)}...'),
              subtitle: const Text('Waiting for admin approval'),
              trailing: Wrap(
                spacing: 0,
                children: [
                  IconButton(
                    tooltip: 'Approve',
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () => approveRequest(requestId),
                  ),
                  IconButton(
                    tooltip: 'Reject',
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => rejectRequest(requestId),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
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
          : RefreshIndicator(
              onRefresh: loadMembers,
              child: ListView(
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
                  if (members.isEmpty)
                    const Center(child: Text('No members found')),
                  ...members.asMap().entries.map((entry) {
                    final index = entry.key;
                    final member = entry.value;
                    final userId = member['user_id'].toString();
                    final role = member['role'].toString();
                    final isMe = userId == supabase.auth.currentUser!.id;

                    return ListTile(
                      leading: CircleAvatar(
                        child: Icon(
                          role == 'admin'
                              ? Icons.admin_panel_settings
                              : Icons.person,
                        ),
                      ),
                      title: Text(isMe ? 'You' : 'Member ${index + 1}'),
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
                  if (isAdmin) inviteSection(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}
