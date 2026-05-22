import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_provider.dart';
import 'breathing_exercise.dart';
import 'package:emotion_burnout_app/features/shared/priority_logic.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {

  final TextEditingController _controller = TextEditingController();

  String message = "";
  List<String> suggestions = [];
  String riskLevel = "";
  bool showBreathingExercise = false;  

  bool isLoading = false;

  int _breathingCount = 0;
  static const int _maxBreathingCycles = 4;
  bool _isBreathingActive = true; // Track if animation is still running

  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _breathingController.addStatusListener(_onBreathingStatusChanged);

    _breathingAnimation =
        Tween<double>(begin: 80, end: 140).animate(_breathingController);
  }

  void _onBreathingStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _breathingCount++;
      
      if (_breathingCount >= _maxBreathingCycles) {
        // Stop animation but keep widget visible
        _breathingController.stop();
        _breathingController.reset();
        _isBreathingActive = false;
        setState(() {}); // Update UI to show "completed" text
      } else {
        _breathingController.reverse();
      }
    }
    else if (status == AnimationStatus.dismissed) {
      if (_breathingCount < _maxBreathingCycles) {
        _breathingController.forward();
      }
    }
  }

  void _startBreathingExercise() {
    _breathingCount = 0;
    _isBreathingActive = true;
    _breathingController.forward();
  }

  @override
  void dispose() {
    _breathingController.removeStatusListener(_onBreathingStatusChanged);
    _breathingController.dispose();
    super.dispose();
  }

  Future<String> _getUserTeam() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_team') ?? 'Other';

  }

  void processResult(Map<String, dynamic> result, String originalText) {
    final risk = result["emotions"]["risk"];
    final tone = result["emotions"]["tone"];
    final topEmotions = result["emotions"]["top_emotions"];
    final finalStatus = result["final_status"];
    final distressLevel = result["distress"]["distress_level"];


    riskLevel = risk;
    bool shouldShowBreathing = (risk == "high" || distressLevel == "high_distress");
    showBreathingExercise = shouldShowBreathing;
    // Start the breathing animation if needed
    if (shouldShowBreathing) {
      _startBreathingExercise();
    }

    
    bool hasButWord = RegExp(r'\bbut\b', caseSensitive: false).hasMatch(originalText);
  
    // Check if the top emotion is sadness/negative
    final details = getPriorityDetails(
      risk: risk,
      distressLevel: distressLevel,
      finalStatus: finalStatus,
      tone: tone,
      topEmotions: topEmotions,
      originalText: originalText,
    );

    setState(() {
      message = details['message'];
      suggestions = details['suggestions'];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primary = Color(0xFFB39DDB);
    final darkPurple = Color(0xFF6A1B9A);
    
    
    final cardColor = isDarkMode ? const Color(0xFF2D2D44) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF4A148C);
    final hintColor = isDarkMode ? Colors.white54 : Colors.grey.shade600;
    final suggestionCardColor = isDarkMode ? const Color(0xFF2D2D44) : Colors.white;

    
    final backgroundColor = isDarkMode 
        ? const Color(0xFF1A1A2E)  
        : const Color(0xFFF3E5F5);  

    return Scaffold(
      body: Container(
        color: backgroundColor,  
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// THEME TOGGLE BUTTON
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Consumer<ThemeProvider>(
                            builder: (context, themeProvider, child) {
                              return IconButton(
                                icon: Icon(
                                  themeProvider.isDark 
                                      ? Icons.light_mode 
                                      : Icons.dark_mode,
                                  color: isDarkMode ? Colors.white : darkPurple,
                                ),
                                onPressed: () {
                                  themeProvider.toggleTheme();
                                },
                                tooltip: 'Toggle theme',
                              );
                            },
                          ),
                        ],
                      ),

                      /// 🧠 LOGO
                      Transform.translate(
                        offset: Offset(0, -12.h),
                        child: Center(
                          child: Column(
                            children: [
                              Image.asset("assets/mindtrace.png", height: 60.h),
                              SizedBox(height: 6.h),
                              Text(
                                "MindTrace",
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : darkPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 20.h),
                      /// QUESTION
                      Text(
                        "How are you feeling today?",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : darkPurple,
                        ),
                      ),

                      SizedBox(height: 14.h),

                      /// INPUT CARD
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode 
                                  ? Colors.black26 
                                  : Colors.black12,
                              blurRadius: 6.r,
                            )
                          ],
                        ),
                        child: TextField(
                          controller: _controller,
                          maxLines: 3,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14.sp,
                          ),
                          decoration: InputDecoration(
                            hintText: "Share your thoughts...",
                            hintStyle: TextStyle(
                              color: hintColor,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(14.w),
                          ),
                        ),
                      ),

                      SizedBox(height: 16.h),

                      /// BUTTON
                      GestureDetector(
                        onTap: isLoading ? null : () async {
                          setState(() => isLoading = true);

                          // INPUT VALIDATION - Check if empty
                          if (_controller.text.trim().isEmpty) {
                            setState((){
                              message = "Please share how you're feeling first 💭";
                              isLoading = false;
                              showBreathingExercise = false;  // Reset breathing if shown
                            });
                            return;
                          }
                          

                          try {
                            final team = await _getUserTeam();
                            final result =
                                await ApiService.analyzeText(_controller.text, team);

                            setState(() {
                              processResult(result, _controller.text);
                              isLoading = false;
                            });

                          } catch (e) {
                            setState(() {
                              message = "⚠ Unable to reach the server. Please try again.";
                              suggestions = [];
                              isLoading = false;
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDarkMode 
                                  ? [const Color(0xFF6A1B9A), const Color(0xFF9575CD)]
                                  : [const Color(0xFFD1C4E9), const Color(0xFF9575CD)],
                            ),
                            borderRadius: BorderRadius.circular(25.r),
                          ),
                          child: Center(
                            child: isLoading
                                ? SizedBox(
                                    height: 20.h,
                                    width: 20.w,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.w,
                                    ),
                                  )  
                                : Text(
                                    "Analyze",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.sp,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      SizedBox(height: 24.h),
                      /// RESULT
                      if (message.isNotEmpty) ...[
                        /// FEEDBACK CARD
                        Container(
                          padding: EdgeInsets.all(14.w),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDarkMode 
                                  ? [const Color(0xFF6A1B9A), const Color(0xFF9575CD)]
                                  : [const Color(0xFFD1C4E9), const Color(0xFF9575CD)],
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Text(
                            message,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),

                        SizedBox(height: 16.h),

                        /// 🧘 BREATHING ANIMATION (ONLY HIGH STRESS)
                        if (showBreathingExercise) ...[
                          BreathingExercise(
                            animation: _breathingAnimation,
                            isDarkMode: isDarkMode,
                            isActive: _isBreathingActive,
                          ),
                          SizedBox(height: 16.h),
                        ],

                        /// SUGGESTIONS
                        ...suggestions.map((s) {
                          return Container(
                            margin: EdgeInsets.only(bottom: 8.h),
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: suggestionCardColor,
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode 
                                      ? Colors.black26 
                                      : Colors.black12,
                                  blurRadius: 4.r,
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.self_improvement, 
                                  color: isDarkMode ? Colors.purpleAccent : darkPurple,
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    s,
                                    style: TextStyle(
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        SizedBox(height: 8.h),

                        Center(
                          child: Text(
                            "🌱 Even the smallest step forward is still forward.",
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ),
                      ]
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