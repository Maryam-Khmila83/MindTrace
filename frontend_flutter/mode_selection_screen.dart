import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/theme_provider.dart';
import '../navigation/main_screen.dart';
import '../hr/hr_screen.dart';
import '../team_selection/team_selection_screen.dart'; 
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordDialogVisible = false;
  String _errorMessage = '';
  bool _isLoading = false;

  static const String _adminPassword = "admin123";

  @override
  void initState() {
    super.initState();
    _checkSavedMode();
  }

  Future<void> _checkSavedMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString('user_mode');
    final savedTeam = prefs.getString('user_team');
    
    if (savedMode == 'worker' && savedTeam != null && savedTeam.isNotEmpty) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } else if (savedMode == 'hr') {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HRScreen()),
        );
      }
    }
  }

  void _saveMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_mode', mode);
  }

  void _showPasswordDialog() {
    _passwordController.clear();
    _errorMessage = '';
    setState(() {
      _isPasswordDialogVisible = true;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.admin_panel_settings, color: Color(0xFF9575CD)),
                  SizedBox(width: 8.w),
                  Text(
                    "Admin Access",
                    style: TextStyle(fontSize: 18.sp),
                  ),
                ],
              ),
              content: SizedBox(
                width: 280.w, 
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Enter admin password to continue:"),
                    SizedBox(height: 16.h),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      autofocus: true, 
                      decoration: InputDecoration(
                        hintText: "Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
                        prefixIcon: const Icon(Icons.lock),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                      ),
                      onSubmitted: (_) => _verifyPassword(context),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _isPasswordDialogVisible = false;
                    });
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () => _verifyPassword(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9575CD),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Verify"),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      setState(() {
        _isPasswordDialogVisible = false;
      });
    });
  }

  void _verifyPassword(BuildContext dialogContext) async {
    if (_passwordController.text == _adminPassword) {
      _saveMode('hr');
      Navigator.of(dialogContext).pop();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HRScreen()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Wrong password. Access denied.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _selectWorkerMode() {
    _saveMode('worker');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => TeamSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode 
        ? const Color(0xFF1A1A2E)
        : const Color(0xFFF3E5F5);
    
    final cardColor = isDarkMode 
        ? const Color(0xFF2D2D44) 
        : Colors.white;
    
    final textColor = isDarkMode 
        ? Colors.white 
        : const Color(0xFF4A148C);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                "assets/mindtrace.png",
                height: 80.h,
                width: 80.w,
              ),
              SizedBox(height: 16.h),
              
              // Welcome Text
              Text(
                "Welcome to",
                style: TextStyle(
                  fontSize: 16.sp,
                  color: textColor.withOpacity(0.7),
                ),
              ),
              SizedBox(height: 5.h),
              Text(
                "MindTrace",
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              SizedBox(height: 7.h),
              Text(
                "Supporting your emotional well-being at work",
                style: TextStyle(
                  fontSize: 12.sp,
                  color: textColor.withOpacity(0.6),
                ),
              ),
              SizedBox(height: 38.h),
              
              // employee Card
              GestureDetector(
                onTap: _selectWorkerMode,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(18.w),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8.r,
                        offset: Offset(0, 3.h),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9575CD).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.person_outline,
                          size: 32.sp,
                          color: const Color(0xFF9575CD),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Employee",
                              style: TextStyle(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              "Track your emotions, get insights, and share your voice privately",
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: textColor.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16.sp,
                        color: textColor.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16.h),
              
              // HR Card
              GestureDetector(
                onTap: _showPasswordDialog,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(18.w),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8.r,
                        offset: Offset(0, 3.h),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9575CD).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.admin_panel_settings,
                          size: 32.sp,
                          color: const Color(0xFF9575CD),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "HR / Admin",
                              style: TextStyle(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              "Explore anonymous feedback and team well-being insights",
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: textColor.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.lock_outline,
                        size: 16.sp,
                        color: textColor.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}