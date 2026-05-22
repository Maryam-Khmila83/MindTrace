import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../home/home_screen.dart';
import '../history/history_screen.dart';
import '../insights/insights_screen.dart';
import '../letter/letter_screen.dart';
import '../mode_selection/mode_selection_screen.dart';
import '../team_selection/team_selection_screen.dart'; 
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    HistoryScreen(),
    InsightsScreen(),
    LetterScreen(),
  ];

  Future<void> _logout() async {
    
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9575CD), 
              foregroundColor: Colors.white,
            ),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_mode');
      
      await prefs.remove('user_team');
      
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ModeSelectionScreen()),
        );
      }
    }
  }

  
  Future<void> _switchTeam() async {
    final shouldSwitch = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Switch Team"),
        content: const Text("This will restart the app and return to team selection. Continue?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9575CD),
            ),
            child: const Text("Switch"),
          ),
        ],
      ),
    );

    if (shouldSwitch == true) {
      // Clear saved team but keep mode as worker
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_team');
      
      // Navigate back to team selection
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => TeamSelectionScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF4A148C);
    final backgroundColor = isDarkMode 
        ? const Color(0xFF1A1A2E)
        : const Color(0xFFF3E5F5);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "MindTrace",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.switch_account),
            onPressed: _switchTeam,
            tooltip: 'Switch Team',
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF5F3FF),
            selectedItemColor: const Color(0xFF9575CD),
            unselectedItemColor: isDarkMode ? Colors.white54 : Colors.grey.shade600,
            selectedLabelStyle: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 12.sp,
            ),
            iconSize: 28.sp,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history),
                label: "History",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.insights_outlined),
                activeIcon: Icon(Icons.insights),
                label: "Insights",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.email_outlined),
                activeIcon: Icon(Icons.email),
                label: "Share Voice", 
              ),
            ],
          ),
          
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF5F3FF),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5.r,
                  offset: Offset(0, -2.h),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: Icon(Icons.logout, size: 18.sp),
                  label: Text(
                    "Logout",
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9575CD), // Purple theme
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 40.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}