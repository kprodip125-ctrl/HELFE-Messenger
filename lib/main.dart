import 'package:flutter/material.dart';

void main() {
  runApp(const HelfeMessenger());
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
        scaffoldBackgroundColor: const Color(0xFF101820),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  final List<Map<String, String>> groups = [
    {'name': 'Business Team', 'message': 'Welcome to HELFE Messenger'},
    {'name': 'Management', 'message': 'Management group'},
    {'name': 'Delivery Team', 'message': 'Delivery updates'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'HELFE Messenger',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.account_circle),
          ),
        ],
      ),
      body: selectedIndex == 0
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Business Groups',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                ...groups.map(
                  (group) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.teal,
                        child: Icon(Icons.groups, color: Colors.white),
                      ),
                      title: Text(group['name']!),
                      subtitle: Text(group['message']!),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(
                              groupName: group['name']!,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: Text('Profile'),
            ),
      floatingActionButton: selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Group creation coming soon'),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('New Group'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat),
            label: 'Groups',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class ChatPage extends StatelessWidget {
  final String groupName;

  const ChatPage({super.key, required this.groupName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(groupName)),
      body: const Center(
        child: Text(
          'Welcome to HELFE Group Chat',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
