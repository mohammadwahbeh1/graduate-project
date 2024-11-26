import 'package:flutter/material.dart';

import 'DriversAndLinesPage.dart';
import 'LinesAndManagersPage.dart';
import 'loginPage.dart';

class ManagerPage extends StatelessWidget {
  const ManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Manager Dashboard",
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      drawer: buildDrawer(context, 'Manager'),
      body: const Center(
        child: Text(
          "Welcome to the Manager's Page",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }

  Widget buildDrawer(BuildContext context, String role) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            height: MediaQuery.of(context).size.height * 0.25,
            decoration: const BoxDecoration(
              color: Colors.green,
            ),
            child: const DrawerHeader(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 80,
                    color: Colors.white,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Manager Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.supervised_user_circle),
            title: const Text('Manage Users'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('View Reports'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.directions_car),
            title: const Text('View Drivers and Lines'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DriversAndLinesPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.manage_accounts),
            title: const Text('View Lines and Managers'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LinesAndManagersPage()),
              );
            },
          ),

          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
