import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_baby_sara/widgets/custom_show_flush_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:open_baby_sara/app/routes/navigation_wrapper.dart';
import 'package:open_baby_sara/blocs/auth/auth_bloc.dart';
import 'package:open_baby_sara/blocs/caregiver/caregiver_bloc.dart';
import 'package:open_baby_sara/data/repositories/locator.dart';
import 'package:open_baby_sara/data/services/firebase/auth_service.dart';
import 'package:open_baby_sara/views/auth/sign_in_page.dart';
import 'package:open_baby_sara/widgets/build_custom_snack_bar.dart';
import 'package:open_baby_sara/widgets/custom_text_form_field.dart';

class CaregiverSignInPage extends StatefulWidget {
  const CaregiverSignInPage({super.key});

  @override
  State<CaregiverSignInPage> createState() => _CaregiverSignInPageState();
}

class _CaregiverSignInPageState extends State<CaregiverSignInPage> {
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _onPressedSignIn() {
    if (_formKey.currentState!.validate()) {
      context.read<CaregiverBloc>().add(
        CaregiverSignUp(
          firstName: _firstNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocListener<CaregiverBloc, CaregiverState>(
      listener: (context, state) {
        if (state is CaregiverSignedUp) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(buildCustomSnackBar(state.message));
          context.read<AuthBloc>().add(AppStarted());
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => NavigationWrapper()),
            (route) => false,
          );
        } else if (state is CaregiverError) {
          showCustomFlushbar(
            context,
            context.tr('error'),
            state.message,
            Icons.warning_outlined,
          );
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFFFFF9C4), Color(0xFFFFE0B2), Color(0xFFFFCDD2)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -30.sp,
                left: 0,
                right: 0,
                child: Image.asset(
                  'assets/images/cloud.png',
                  fit: BoxFit.fitWidth,
                  width: 1.sw,
                  height: 150.h,
                ),
              ),

              Align(
                alignment: Alignment.center,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),

                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: size.width * 0.85,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 24.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(15.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              Text(
                                context.tr('join_a_family'),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              SizedBox(height: 10.h),
                              Text(
                                context.tr('join_a_family_info'),
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  fontSize: 14.sp,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w300,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 24.h),

                              // Google Sign-In Button
                              SizedBox(
                                width: double.infinity,
                                height: 50.h,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Trigger Google Sign-In through the bloc
                                    // The bloc will handle the Google Sign-In flow and extract user info
                                    context.read<CaregiverBloc>().add(
                                          CaregiverSignUpWithGoogle(),
                                        );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                      side: const BorderSide(
                                        color: Colors.black12,
                                        width: 1,
                                      ),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/google.png',
                                        width: 24.sp,
                                        height: 24.sp,
                                      ),
                                      SizedBox(width: 12.w),
                                      Text(
                                        context.tr("continue_with_google") ??
                                            'Continue with Google',
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 20.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      thickness: 1,
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                    ),
                                    child: Text(
                                      context.tr("or"),
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleMedium?.copyWith(
                                            color: Colors.grey.shade600,
                                            fontSize: 14.sp,
                                          ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      thickness: 1,
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20.h),

                              // Form Fields
                              CustomTextFormField(
                                hintText: context.tr("first_name"),
                                isPassword: false,
                                controller: _firstNameController,
                                validator:
                                    (value) =>
                                        value == null || value.isEmpty
                                            ? context.tr("required")
                                            : null,
                              ),
                              SizedBox(height: 7.h),
                              CustomTextFormField(
                                hintText: 'Email',
                                isPassword: false,
                                controller: _emailController,
                                validator:
                                    (value) =>
                                        value != null && value.contains('@')
                                            ? null
                                            : context.tr("invalid_email"),
                              ),
                              SizedBox(height: 7.h),
                              CustomTextFormField(
                                hintText: context.tr("password"),
                                isPassword: true,
                                controller: _passwordController,
                                validator:
                                    (value) =>
                                        value != null && value.length > 5
                                            ? null
                                            : context.tr("min_6_characters"),
                              ),
                              SizedBox(height: 20.h),

                              // Join Family Button
                              SizedBox(
                                width: double.infinity,
                                height: 45.h,
                                child: ElevatedButton(
                                  onPressed: _onPressedSignIn,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                  ),
                                  child: Text(
                                    context.tr('join_a_family'),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium?.copyWith(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20.h),

                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const SignInPage(),
                                    ),
                                  );
                                },
                                child: Text(
                                  context.tr("already_have_an_account_sign_in"),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    fontSize: 15.sp,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Top icon (stroller)
                      Positioned(
                        top: -90,
                        right: -40,
                        child: Image.asset(
                          'assets/images/stroller.png',
                          width: 180,
                          height: 180,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom logo
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  width: 75.w,
                  height: 75.h,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
