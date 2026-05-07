import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/loading_overlay.dart';

/// Forgot Password Screen — Send password reset email
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _sendReset() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(ForgotPasswordEvent(email: _emailCtrl.text.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is ForgotPasswordSent) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Reset link sent to your email ✅'),
            backgroundColor: const Color(0xFF3B6D11),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
          Navigator.pop(context);
        }
        if (state is ForgotPasswordError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: const Color(0xFFA32D2D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF2F3F7),
          body: LoadingOverlay(
            isLoading: state is AuthLoading,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1A1A2E), size: 22),
                      style: IconButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.all(10)),
                    ),
                    const SizedBox(height: 32),
                    Container(width: 64, height: 64, decoration: BoxDecoration(color: const Color(0xFFE6F1FB), borderRadius: BorderRadius.circular(20)),
                      child: const Icon(Icons.lock_reset_rounded, size: 32, color: Color(0xFF185FA5))),
                    const SizedBox(height: 24),
                    const Text('Forgot\nPassword? 🔑', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E), height: 1.2)),
                    const SizedBox(height: 8),
                    const Text("Enter your email and we'll send you a link to reset your password.", style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                    const SizedBox(height: 32),
                    Form(
                      key: _formKey,
                      child: Column(children: [
                        CustomTextField(controller: _emailCtrl, label: 'Email Address', hint: 'Enter your email', prefixIcon: Icons.email_outlined, keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Please enter your email';
                            if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(v)) return 'Please enter a valid email';
                            return null;
                          }),
                        const SizedBox(height: 24),
                        PrimaryButton(text: 'Send Reset Link', onPressed: _sendReset, isLoading: state is AuthLoading),
                      ]),
                    ),
                    const SizedBox(height: 28),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text('Remember your password? ', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                      GestureDetector(onTap: () => Navigator.pop(context), child: const Text('Sign In', style: TextStyle(color: Color(0xFF185FA5), fontWeight: FontWeight.w700, fontSize: 14))),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
