import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../repositories/user_repository.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

/// Profile Screen — User info, edit name/preferences, logout
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _userRepo = UserRepository();
  bool _notificationsOn = true;
  bool _darkModeOn = false;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() {
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated) {
      _nameCtrl.text = state.user.name;
      _notificationsOn = state.user.preferences['notifications'] ?? true;
      _darkModeOn = state.user.preferences['darkMode'] ?? false;
    }
  }

  Future<void> _saveProfile() async {
    final state = context.read<AuthBloc>().state;
    if (state is! AuthAuthenticated) return;

    setState(() => _isSaving = true);
    try {
      await _userRepo.updateUser(state.user.uid, {
        'name': _nameCtrl.text.trim(),
        'preferences': {
          'notifications': _notificationsOn,
          'darkMode': _darkModeOn,
        },
      });
      // Refresh auth state
      context.read<AuthBloc>().add(AuthCheckRequested());
      setState(() { _isEditing = false; _isSaving = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Profile updated ✅'),
          backgroundColor: const Color(0xFF3B6D11),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: const Color(0xFFA32D2D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
        content: const Text('Are you sure you want to logout?', style: TextStyle(color: Color(0xFF6B7280))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280)))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(LogoutEvent());
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA32D2D), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF185FA5))));
        }
        final user = state.user;

        return Scaffold(
          backgroundColor: const Color(0xFFF2F3F7),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  // Header
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Profile', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                    IconButton(
                      onPressed: () => setState(() { _isEditing = !_isEditing; if (_isEditing) _nameCtrl.text = user.name; }),
                      icon: Icon(_isEditing ? Icons.close_rounded : Icons.edit_rounded, color: const Color(0xFF185FA5)),
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFFE6F1FB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ]),
                  const SizedBox(height: 32),

                  // Avatar
                  Container(
                    width: 100, height: 100,
                    decoration: const BoxDecoration(color: Color(0xFF185FA5), shape: BoxShape.circle),
                    child: Center(child: Text(user.initials, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(height: 16),
                  Text(user.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 4),
                  Text(user.email, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                  const SizedBox(height: 32),

                  // Info / Edit card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Personal Information', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF9CA3AF))),
                      const SizedBox(height: 16),
                      if (_isEditing)
                        CustomTextField(controller: _nameCtrl, label: 'Full Name', hint: 'Your name', prefixIcon: Icons.person_outline_rounded)
                      else ...[
                        _infoRow(Icons.person_outline_rounded, 'Name', user.name),
                        const SizedBox(height: 12),
                        _infoRow(Icons.email_outlined, 'Email', user.email),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Preferences card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Preferences', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF9CA3AF))),
                      const SizedBox(height: 16),
                      _toggleRow(Icons.notifications_outlined, 'Notifications', _notificationsOn, (v) { if (_isEditing) setState(() => _notificationsOn = v); }),
                      const SizedBox(height: 8),
                      _toggleRow(Icons.dark_mode_outlined, 'Dark Mode', _darkModeOn, (v) { if (_isEditing) setState(() => _darkModeOn = v); }),
                    ]),
                  ),

                  if (_isEditing) ...[
                    const SizedBox(height: 24),
                    PrimaryButton(text: 'Save Changes', onPressed: _saveProfile, isLoading: _isSaving),
                  ],

                  const SizedBox(height: 32),

                  // Logout button
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _showLogoutDialog,
                      icon: const Icon(Icons.logout_rounded, color: Color(0xFFA32D2D)),
                      label: const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFA32D2D))),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFA32D2D)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, color: const Color(0xFF185FA5), size: 22),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
      ]),
    ]);
  }

  Widget _toggleRow(IconData icon, String label, bool value, ValueChanged<bool> onChanged) {
    return Row(children: [
      Icon(icon, color: const Color(0xFF185FA5), size: 22),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)))),
      Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFF185FA5)),
    ]);
  }
}
