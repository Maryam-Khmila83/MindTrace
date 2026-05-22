import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:emotion_burnout_app/features/shared/priority_logic.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  List<dynamic> historyData = [];
  bool isLoading = true;
  
  // Insights data
  Map<String, dynamic> weeklyInsights = {};

  @override
  void initState() {
    super.initState();
    fetchHistoryAndAnalyze();
  }

  Future<String> _getCurrentTeam() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_team') ?? '';
  }

  Future<void> fetchHistoryAndAnalyze() async {
    try {
      final team = await _getCurrentTeam();
      final result = await ApiService.getHistory(team: team);
      setState(() {
        historyData = result;
        isLoading = false;
        analyzeWeeklyData();
      });
    } catch (e) {
      print("Error fetching history: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void analyzeWeeklyData() {
    if (historyData.isEmpty) return;
    
    // Get last 7 days of entries (or all if less than 7)
    List<dynamic> last7Days = historyData.take(7).toList();
    int totalDays = last7Days.length;
    
    
    int stressedDays = 0;        // High distress
    int moderateStressDays = 0;   // Medium distress  
    int mildStressDays = 0;       // Mild/negative but not high
    int positiveDays = 0;         // Actually positive
    
    // Track stress trend (comparing first half vs second half)
    int firstHalfStress = 0;
    int secondHalfStress = 0;
    int halfSize = (totalDays / 2).floor();
    
    // Collect emotions for analysis
    List<String> allEmotions = [];
    
    for (int i = 0; i < last7Days.length; i++) {
      final item = last7Days[i];
      final risk = item["risk"] ?? "";
      final distressLevel = item["distress_level"] ?? "";
      final tone = item["tone"] ?? "";
      final topEmotions = item["top_emotions"] ?? [];
      
      // Count stress levels
      if (risk == "high" || distressLevel == "high_distress") {
        stressedDays++;
        if (i < halfSize) firstHalfStress++;
        else secondHalfStress++;
      } 
      else if (risk == "medium" || distressLevel == "moderate_distress") {
        moderateStressDays++;
        if (i < halfSize) firstHalfStress++;
        else secondHalfStress++;
      }
      else if (tone == "negative" || risk == "low") {
        
        mildStressDays++;
        if (i < halfSize) firstHalfStress++;
        else secondHalfStress++;
      }
      else {
        // Genuinely positive days
        positiveDays++;
      }
      
      // Extract top emotion
      if (topEmotions.isNotEmpty) {
        allEmotions.add(topEmotions[0][0]);
      }
    }
    
    
    int totalNonPositive = stressedDays + moderateStressDays + mildStressDays;
    int totalFirstHalfStress = firstHalfStress;
    int totalSecondHalfStress = secondHalfStress;
    
    String stressTrend = "stable";
    if (totalFirstHalfStress < totalSecondHalfStress) {
      stressTrend = "increasing";
    } else if (totalFirstHalfStress > totalSecondHalfStress) {
      stressTrend = "decreasing";
    }
    
    
    Map<String, int> emotionCount = {};
    for (String emotion in allEmotions) {
      emotionCount[emotion] = (emotionCount[emotion] ?? 0) + 1;
    }
    String mostCommonEmotion = "";
    int maxCount = 0;
    emotionCount.forEach((emotion, count) {
      if (count > maxCount) {
        maxCount = count;
        mostCommonEmotion = emotion;
      }
    });
    
    
    weeklyInsights = {
      'totalDays': totalDays,
      'stressedDays': stressedDays,
      'moderateStressDays': moderateStressDays,
      'mildStressDays': mildStressDays,
      'positiveDays': positiveDays,
      'nonPositiveDays': totalNonPositive,
      'stressTrend': stressTrend,
      'mostCommonEmotion': mostCommonEmotion,
      'hasData': true,
    };
  }

  String getStressMessage() {
    int nonPositiveDays = weeklyInsights['nonPositiveDays'] ?? 0;
    int totalDays = weeklyInsights['totalDays'] ?? 0;
    int stressedDays = weeklyInsights['stressedDays'] ?? 0;
    int mildStressDays = weeklyInsights['mildStressDays'] ?? 0;
    
    if (stressedDays >= 3) {
      return "⚠️ You've had ${stressedDays} very difficult days this week";
    } else if (stressedDays >= 1) {
      return "💪 You've faced ${stressedDays} challenging day(s) this week";
    } else if (nonPositiveDays >= 4) {
      return "📊 ${nonPositiveDays} out of ${totalDays} days have been tough for you";
    } else if (nonPositiveDays >= 2) {
      return "📈 You've had ${nonPositiveDays} difficult moments this week";
    } else if (weeklyInsights['positiveDays'] >= 4) {
      return "🌟 You're doing great! Most of your days have been positive ✨";
    } else {
      return "💪 You're managing with ${weeklyInsights['positiveDays']} good days this week";
    }
  }

  String getTrendMessage() {
    int nonPositiveDays = weeklyInsights['nonPositiveDays'] ?? 0;
    
    if (weeklyInsights['stressTrend'] == "increasing" && nonPositiveDays > 2) {
      return "📈 Your stress has been increasing lately — let's check in";
    } else if (weeklyInsights['stressTrend'] == "increasing") {
      return "📈 Your stress is showing a slight upward trend";
    } else if (weeklyInsights['stressTrend'] == "decreasing") {
      return "📉 Your stress is decreasing — keep going! 🌟";
    } else if (nonPositiveDays >= 4) {
      return "🔄 Your stress levels have been consistently high";
    } else {
      return "📊 Your stress levels are relatively stable";
    }
  }

  String getCompassionMessage() {
    int stressedDays = weeklyInsights['stressedDays'] ?? 0;
    int nonPositiveDays = weeklyInsights['nonPositiveDays'] ?? 0;
    String mostCommonEmotion = weeklyInsights['mostCommonEmotion'] ?? "";
    
    if (stressedDays >= 3) {
      return "💙 You've been carrying a lot lately.\nBe gentle with yourself — you're doing the best you can 🌿";
    } else if (nonPositiveDays >= 4) {
      return "💙 It's okay to have difficult days.\nYou're showing up for yourself, and that takes courage 💪";
    } else if (mostCommonEmotion == "sadness") {
      return "💙 Sadness is heavy, but it's also honest.\nLet yourself feel without judgment 🌸";
    } else if (mostCommonEmotion == "anger") {
      return "💙 Your anger is telling you something matters.\nTake a breath — you're safe right now 🌬️";
    } else if (mostCommonEmotion == "fear" || mostCommonEmotion == "anxiety") {
      return "💙 Anxiety lies to you about the future.\nYou've survived 100% of your hard days so far ✨";
    } else if (weeklyInsights['positiveDays'] >= 4) {
      return "✨ You're building great momentum!\nKeep celebrating the small wins 🎉";
    } else {
      return "🌱 Every small step forward is progress.\nYou're doing better than you think 💪";
    }
  }

  String getMeaningMessage() {
    int stressedDays = weeklyInsights['stressedDays'] ?? 0;
    int nonPositiveDays = weeklyInsights['nonPositiveDays'] ?? 0;
    String mostCommonEmotion = weeklyInsights['mostCommonEmotion'] ?? "";
    
    if (stressedDays >= 3) {
      return "👉 That means rest isn't a reward — it's a necessity right now";
    } else if (nonPositiveDays >= 5) {
      return "👉 That means checking in with someone you trust could help lighten the load";
    } else if (mostCommonEmotion == "anger") {
      return "👉 That means asking: 'What do I need right now?' could help";
    } else if (mostCommonEmotion == "sadness") {
      return "👉 That means small acts of self-care today will mean a lot tomorrow";
    } else if (weeklyInsights['stressTrend'] == "increasing") {
      return "👉 That means adding tiny breaks into your routine could make a difference";
    } else if (nonPositiveDays >= 2) {
      return "👉 That means you're building emotional awareness — that's real progress";
    } else {
      return "👉 That means you're learning the language of your own heart";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final backgroundColor = isDarkMode 
        ? const Color(0xFF1A1A2E)
        : const Color(0xFFF3E5F5);
    
    final textColor = isDarkMode 
        ? Colors.white 
        : const Color(0xFF4A148C);
    
    final cardColor = isDarkMode 
        ? const Color(0xFF2D2D44) 
        : Colors.white;
    
    final subtitleColor = isDarkMode 
        ? Colors.white70 
        : Colors.grey.shade700;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Insights",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : historyData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.insights,
                        size: 60.h,
                        color: const Color(0xFF9575CD).withOpacity(0.5),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        "Not enough data yet",
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "Add more entries to see your\nweekly emotional insights",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Icon(
                        Icons.arrow_downward,
                        color: const Color(0xFF9575CD),
                        size: 20.sp,
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        "Your Week Summary",
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      
                      
                      Container(
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4.r,
                              offset: Offset(0, 1.h),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFF9575CD).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Icon(
                                weeklyInsights['stressedDays'] >= 3 
                                    ? Icons.warning_rounded 
                                    : Icons.bar_chart,
                                color: const Color(0xFF9575CD),
                                size: 22,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                getStressMessage(),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 12.h),
                      
                      
                      Container(
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4.r,
                              offset: Offset(0, 1.h),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFF9575CD).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Icon(
                                weeklyInsights['stressTrend'] == "increasing"
                                    ? Icons.trending_up
                                    : weeklyInsights['stressTrend'] == "decreasing"
                                        ? Icons.trending_down
                                        : Icons.trending_flat,
                                color: const Color(0xFF9575CD),
                                size: 22.sp,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                getTrendMessage(),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 12.h),
                      
                      
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDarkMode 
                                ? [const Color(0xFF6A1B9A), const Color(0xFF9575CD)]
                                : [const Color(0xFFD1C4E9), const Color(0xFF9575CD)],
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              getCompassionMessage(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Container(
                              padding: EdgeInsets.all(10.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    " ",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      getMeaningMessage(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 24.h),
                      
                      
                      Center(
                        child: Text(
                          "🌱 You're not just tracking moods — you're learning the language of your own heart.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 11.sp,
                            color: subtitleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}