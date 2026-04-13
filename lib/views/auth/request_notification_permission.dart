import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:open_baby_sara/app/routes/navigation_wrapper.dart';
import 'package:open_baby_sara/data/services/notification_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RequestNotificationPermission extends StatefulWidget {
  const RequestNotificationPermission({super.key});

  @override
  State<RequestNotificationPermission> createState() =>
      _RequestNotificationPermissionState();
}

class _RequestNotificationPermissionState
    extends State<RequestNotificationPermission> {
  bool _isLoading = false;

  Future<void> _handleAllow() async {
    setState(() => _isLoading = true);
    await NotificationService.instance.requestPermission();
    if (!mounted) return;
    setState(() => _isLoading = false);
    _navigateHome();
  }

  void _navigateHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => NavigationWrapper()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFFFFF9C4), Color(0xFFFFE0B2), Color(0xFFFFCDD2)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                Image.asset(
                  'assets/images/reminder_logo.png',
                  fit: BoxFit.fitWidth,
                  width: 200.w,
                  height: 200.h,
                ),
                SizedBox(height: 16.h),
                Text(
                  context.tr('do_not_miss_a_moment'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                SizedBox(height: 16.h),
                Text(
                  context.tr('get_gentle_reminders'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 32.h),

                // Feature chips
                _FeatureChip(
                  emoji: '🌙',
                  label: context.tr('notif_sleep_reminders'),
                ),
                SizedBox(height: 8.h),
                _FeatureChip(
                  emoji: '🍼',
                  label: context.tr('notif_feed_reminders'),
                ),
                SizedBox(height: 8.h),
                _FeatureChip(
                  emoji: '🌟',
                  label: context.tr('notif_milestone_notifications'),
                ),

                const Spacer(),

                // Allow button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleAllow,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 52.h),
                    backgroundColor: Colors.pinkAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 22.h,
                          width: 22.w,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          context.tr('allow_notifications'),
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),

                SizedBox(height: 12.h),

                // Skip button
                TextButton(
                  onPressed: _isLoading ? null : _navigateHome,
                  child: Text(
                    context.tr('skip'),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ),

                SizedBox(height: 8.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.emoji, required this.label});

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 20.sp)),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
