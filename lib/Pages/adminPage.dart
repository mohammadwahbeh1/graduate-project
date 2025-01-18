import 'package:flutter/material.dart';

import 'DriversAndLinesPage.dart';
import 'DriversRequestsPage.dart';
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
      // نستدعي الـDrawer المُحسّن:
      drawer: buildImprovedDrawer(context),
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

  /// دالة لبناء الـDrawer المُحسّن
  Widget buildImprovedDrawer(BuildContext context) {
    return Drawer(
      // استخدمنا Container لتطبيق خلفية متدرجة على كامل الـDrawer
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE1F5FE),
              Color(0xFFB3E5FC),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // رأس القائمة (Drawer Header)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: const [
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

            // باقي عناصر الـDrawer
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 10),
                  buildCustomDrawerItem(
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
                  buildDivider(),
                  buildCustomDrawerItem(
                    context,
                    icon: Icons.apartment,
                    title: 'Terminals',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TerminalPage(),
                        ),
                      );
                    },
                  ),
                  buildDivider(),
                  buildCustomDrawerItem(
                    context,
                    icon: Icons.assessment,
                    title: 'View Reports',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StatisticsPage(),
                        ),
                      );
                    },
                  ),
                  buildDivider(),
                  buildCustomDrawerItem(
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
                  buildDivider(),
                  buildCustomDrawerItem(
                    context,
                    icon: Icons.check,
                    title: 'Accept Driver',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DriversRequestsPage(),
                        ),
                      );
                    },
                  ),
                  buildDivider(),
                  buildCustomDrawerItem(
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
                  buildDivider(),
                  buildCustomDrawerItem(
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
                  const SizedBox(height: 10),
                  const Divider(
                    color: Colors.black54,
                    thickness: 1.2,
                    indent: 20,
                    endIndent: 20,
                  ),
                  const SizedBox(height: 10),
                  buildCustomDrawerItem(
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
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// عنصر خاص لكل خيار في الـDrawer مع بعض الزخارف
  Widget buildCustomDrawerItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: ListTile(
            leading: Icon(icon, color: Colors.blueGrey[800], size: 24),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.blueGrey[800],
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.black45,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDivider() {
    return const Divider(
      color: Colors.black26,
      thickness: 0.8,
      indent: 70,
      endIndent: 20,
    );
  }
}
