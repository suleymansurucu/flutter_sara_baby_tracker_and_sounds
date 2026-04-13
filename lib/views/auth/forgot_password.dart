import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_baby_sara/app/routes/app_router.dart';
import 'package:open_baby_sara/blocs/auth/auth_bloc.dart';
import 'package:open_baby_sara/views/auth/sign_in_page.dart';
import 'package:open_baby_sara/widgets/custom_show_flush_bar.dart';
import 'package:open_baby_sara/widgets/custom_text_form_field.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is ForgotPasswordSuccess) {
            showCustomFlushbar(
              context,
              context.tr("reset_email_sent_title"),
              context.tr("reset_email_sent_message"),
              Icons.mark_email_read_outlined,
              color: const Color(0xFF66BB6A),
            );
            Future.delayed(const Duration(seconds: 3), () {
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.signin);
              }
            });
          }
        },
        builder: (context, state) {
          return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Color(0xFFFFF9C4),
                      Color(0xFFFFE0B2),
                      Color(0xFFFFCDD2),
                    ],
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
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      context.tr("forgot_password"),
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleLarge,
                                    ),
                                    SizedBox(height: 10.h),
                                    Text(
                                      context.tr("forgot_password_information"),
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleSmall,
                                    ),
                                    SizedBox(height: 20.h),
                                    CustomTextFormField(
                                      hintText: "Email",
                                      controller: _emailController,
                                      isPassword: false,
                                      validator:
                                          (value) =>
                                              value != null &&
                                                      value.contains('@')
                                                  ? null
                                                  : context.tr("invalid_email"),
                                    ),
                                    SizedBox(height: 20.h),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 45.h,
                                      child: ElevatedButton(
                                        onPressed:
                                            state is AuthLoading
                                                ? null
                                                : () =>
                                                    _onForgotPasswordPressed(
                                                      context,
                                                    ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Theme.of(context).primaryColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                          ),
                                        ),
                                        child:
                                            state is AuthLoading
                                                ? CircularProgressIndicator(
                                                  color: Colors.white,
                                                )
                                                : Text(
                                                  context.tr("send_reset_link"),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        color: Colors.white,
                                                        fontSize: 18.sp,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                      ),
                                    ),
                                    SizedBox(height: 10.h),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder:
                                                (context) => const SignInPage(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        context.tr(
                                          "already_have_an_account_sign_in",
                                        ),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium?.copyWith(
                                          fontSize: 16.sp,
                                          color: Theme.of(context).primaryColor,
                                          // fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Stroller
                            Positioned(
                              top: -100,
                              right: -50,
                              child: Image.asset(
                                'assets/images/stroller.png',
                                width: 200,
                                height: 200,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Footer logo
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
              );
        },
      ),
    );
  }

  _onForgotPasswordPressed(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      showCustomFlushbar(
        context,
        context.tr("error"),
        context.tr("failure_forgot_password"),
        Icons.warning_outlined,
      );
    } else {
      context.read<AuthBloc>().add(
        ForgotPasswordUser(email: _emailController.text),
      );
    }
  }
}
