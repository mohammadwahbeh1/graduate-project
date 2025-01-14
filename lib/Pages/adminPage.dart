import 'package:flutter/material.dart';

import 'DriversAndLinesPage.dart';
import 'Reports.dart';
import 'TerminalsPage.dart';
import 'UsersManagementPage.dart';
import 'VehiclePage.dart';
import 'loginPage.dart';
import 'linePage.dart';

class ManagerPage extends StatelessWidget {
  const ManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Manager Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      drawer: buildDrawer(context, 'Manager'),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Text(
            "Welcome to the Manager's Page",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
              shadows: [
                Shadow(
                  offset: const Offset(2, 2),
                  blurRadius: 3,
                  color: Colors.grey.withOpacity(0.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDrawer(BuildContext context, String role) {
    return Drawer(
      child: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.25,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00B4DB), Color(0xFF0083B0)], //
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const DrawerHeader(
              margin: EdgeInsets.zero,
              padding: EdgeInsets.all(20),
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
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.supervised_user_circle,
                  title: 'Manage Users',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UsersManagementPage(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.apartment,
                  title: 'Terminals',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TerminalPage(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.assessment,
                  title: 'View Reports',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StatisticsPage(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.directions_car,
                  title: 'View Drivers and Lines',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DriversAndLinesPage(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.directions_car_filled,
                  title: 'Vehicle',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VehiclePage(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.route,
                  title: 'Line',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LinePage(),
                      ),
                    );
                  },
                ),
                const Divider(
                  color: Colors.black,
                  thickness: 1,
                  indent: 20,
                  endIndent: 20,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.logout,
                  title: 'Log out',
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
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
      }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.black,
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      tileColor: Colors.transparent,
      onTap: onTap,
    );
  }
}
