import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/theme.dart';

class UserProfile {
  final String name;
  final String phone;
  final String? photoPath;
  final bool pinEnabled;
  const UserProfile({
    this.name = '',
    this.phone = '',
    this.photoPath,
    this.pinEnabled = false,
  });
  UserProfile copyWith({String? name, String? phone, String? photoPath, bool? pinEnabled}) {
    return UserProfile(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      photoPath: photoPath ?? this.photoPath,
      pinEnabled: pinEnabled ?? this.pinEnabled,
    );
  }
}

class ProfileNotifier extends StateNotifier<UserProfile> {
  ProfileNotifier() : super(const UserProfile()) { _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = UserProfile(
      name: p.getString('user_name') ?? '',
      phone: p.getString('user_phone') ?? '',
      photoPath: p.getString('user_photo'),
      pinEnabled: p.getBool('pin_enabled') ?? false,
    );
  }

  Future<void> save({required String name, required String phone}) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('user_name', name);
    await p.setString('user_phone', phone);
    state = state.copyWith(name: name, phone: phone);
  }

  Future<void> savePhoto(String path) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('user_photo', path);
    state = state.copyWith(photoPath: path);
  }

  Future<void> savePin(String pin) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('app_pin', pin);
    await p.setBool('pin_enabled', true);
    state = state.copyWith(pinEnabled: true);
  }

  Future<void> disablePin() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('app_pin');
    await p.setBool('pin_enabled', false);
    state = state.copyWith(pinEnabled: false);
  }

  Future<bool> verifyPin(String pin) async {
    final p = await SharedPreferences.getInstance();
    return p.getString('app_pin') == pin;
  }

  Future<bool> isPinEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('pin_enabled') ?? false;
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, UserProfile>(
    (ref) => ProfileNotifier());

// AppLock
class AppLockScreen extends ConsumerStatefulWidget {
  final Widget child;
  const AppLockScreen({super.key, required this.child});
  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  bool _locked = true;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkLock();
  }

  Future<void> _checkLock() async {
    final enabled = await ref.read(profileProvider.notifier).isPinEnabled();
    setState(() { _locked = enabled; _checking = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }
    if (_locked) {
      return PinEntryScreen(onUnlocked: () => setState(() => _locked = false));
    }
    return widget.child;
  }
}

// PIN Entry
class PinEntryScreen extends ConsumerStatefulWidget {
  final VoidCallback onUnlocked;
  const PinEntryScreen({super.key, required this.onUnlocked});
  @override
  ConsumerState<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends ConsumerState<PinEntryScreen> {
  String _pin = '';
  bool _error = false;

  void _add(String d) {
    if (_pin.length >= 4) return;
    setState(() { _pin += d; _error = false; });
    if (_pin.length == 4) _verify();
  }

  void _back() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _verify() async {
    final ok = await ref.read(profileProvider.notifier).verifyPin(_pin);
    if (ok) {
      widget.onUnlocked();
    } else {
      HapticFeedback.heavyImpact();
      setState(() { _error = true; _pin = ''; });
    }
  }

  Widget _numBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(
          color: AppColors.textPrimary, fontSize: 24,
          fontWeight: FontWeight.w700, fontFamily: 'Syne',
        )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            profile.photoPath != null
                ? CircleAvatar(radius: 44, backgroundImage: FileImage(File(profile.photoPath!)))
                : Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradGold, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.3), blurRadius: 20)],
                    ),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 44),
                  ),
            const SizedBox(height: 16),
            Text(
              profile.name.isNotEmpty ? 'স্বাগতম, ${profile.name}!' : 'FinanceFlow',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 20,
                  fontWeight: FontWeight.w800, fontFamily: 'Syne'),
            ),
            const SizedBox(height: 8),
            Text(
              _error ? '❌ ভুল PIN! আবার চেষ্টা করো' : '🔐 PIN দিয়ে unlock করো',
              style: TextStyle(color: _error ? AppColors.rose : AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 16, height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _pin.length ? AppColors.gold : Colors.white.withOpacity(0.15),
                ),
              )),
            ),
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['1','2','3'].map((d) => _numBtn(d, () => _add(d))).toList()),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['4','5','6'].map((d) => _numBtn(d, () => _add(d))).toList()),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['7','8','9'].map((d) => _numBtn(d, () => _add(d))).toList()),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  const SizedBox(width: 72),
                  _numBtn('0', () => _add('0')),
                  SizedBox(width: 72, height: 72,
                    child: GestureDetector(
                      onTap: _back,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.backspace_outlined, color: AppColors.textMuted, size: 22),
                      ),
                    ),
                  ),
                ]),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// Profile Screen
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider);
    _nameCtrl = TextEditingController(text: p.name);
    _phoneCtrl = TextEditingController(text: p.phone);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, maxWidth: 400, maxHeight: 400, imageQuality: 80);
    if (img != null) {
      await ref.read(profileProvider.notifier).savePhoto(img.path);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    await ref.read(profileProvider.notifier).save(name: _nameCtrl.text.trim(), phone: _phoneCtrl.text.trim());
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: AppColors.teal, behavior: SnackBarBehavior.floating,
        content: Row(children: [
          Text('✅ ', style: TextStyle(fontSize: 16)),
          Text('Profile save হয়েছে!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ]),
      ));
    }
  }

  void _showPinSetup() {
    final p = ref.read(profileProvider);
    if (p.pinEnabled) {
      _showDisablePinDialog();
    } else {
      _showStep1();
    }
  }

  void _showStep1() {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => _PinDialog(
        title: '🔐 নতুন PIN দাও', subtitle: '৪ সংখ্যার PIN লেখো',
        onComplete: (pin1) {
          Navigator.pop(context);
          Future.delayed(const Duration(milliseconds: 200), () => _showStep2(pin1));
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _showStep2(String pin1) {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => _PinDialog(
        title: '🔐 PIN নিশ্চিত করো', subtitle: 'আবার একই PIN দাও',
        onComplete: (pin2) {
          Navigator.pop(context);
          if (pin1 == pin2) {
            ref.read(profileProvider.notifier).savePin(pin1);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              backgroundColor: AppColors.teal, behavior: SnackBarBehavior.floating,
              content: Text('✅ PIN চালু হয়েছে!', style: TextStyle(color: Colors.white)),
            ));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              backgroundColor: AppColors.rose, behavior: SnackBarBehavior.floating,
              content: Text('❌ PIN মিলেনি! আবার চেষ্টা করো', style: TextStyle(color: Colors.white)),
            ));
            Future.delayed(const Duration(milliseconds: 300), () => _showStep1());
          }
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _showDisablePinDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF141C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('PIN বন্ধ করবে?',
            style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Syne', fontWeight: FontWeight.w700)),
        content: const Text('PIN বন্ধ করলে যে কেউ অ্যাপ খুলতে পারবে।',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('বাতিল', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () {
              ref.read(profileProvider.notifier).disablePin();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                backgroundColor: AppColors.rose, behavior: SnackBarBehavior.floating,
                content: Text('PIN বন্ধ হয়েছে', style: TextStyle(color: Colors.white)),
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('বন্ধ করো'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('Profile & Security',
            style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Syne', fontWeight: FontWeight.w700, fontSize: 18)),
        leading: IconButton(onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Column(children: [
            GestureDetector(
              onTap: _pickPhoto,
              child: Stack(children: [
                profile.photoPath != null
                    ? CircleAvatar(radius: 56, backgroundImage: FileImage(File(profile.photoPath!)))
                    : Container(
                        width: 112, height: 112,
                        decoration: BoxDecoration(
                          gradient: AppColors.gradGold, shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.3), blurRadius: 20)],
                        ),
                        child: const Icon(Icons.person_rounded, color: Colors.white, size: 56),
                      ),
                Positioned(bottom: 0, right: 0,
                  child: Container(width: 32, height: 32,
                    decoration: BoxDecoration(gradient: AppColors.gradTeal, shape: BoxShape.circle,
                      border: Border.all(color: AppColors.bg, width: 2)),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16))),
              ]),
            ),
            const SizedBox(height: 8),
            const Text('ছবি বদলাতে ট্যাপ করো', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ])),
          const SizedBox(height: 28),
          const Text('তোমার নাম', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'নাম লেখো', hintStyle: const TextStyle(color: AppColors.textDim),
              prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.gold, size: 20),
              filled: true, fillColor: Colors.white.withOpacity(0.04),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.gold, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          const Text('মোবাইল নম্বর', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneCtrl, keyboardType: TextInputType.phone,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: '০১XXXXXXXXX', hintStyle: const TextStyle(color: AppColors.textDim),
              prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.teal, size: 20),
              filled: true, fillColor: Colors.white.withOpacity(0.04),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.teal, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _saving ? null : _saveProfile,
            child: Container(
              width: double.infinity, height: 52,
              decoration: BoxDecoration(
                gradient: AppColors.gradGold, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              alignment: Alignment.center,
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : const Text('Profile সেভ করো',
                      style: TextStyle(color: Color(0xFF0A0E1A), fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'Syne')),
            ),
          ),
          const SizedBox(height: 32),
          const Divider(color: Colors.white12),
          const SizedBox(height: 24),
          const Text('নিরাপত্তা', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Syne')),
          const SizedBox(height: 4),
          const Text('PIN দিয়ে অ্যাপ লক করো', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _showPinSetup,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF141C2E), borderRadius: BorderRadius.circular(18),
                border: Border.all(color: profile.pinEnabled ? AppColors.teal.withOpacity(0.3) : Colors.white.withOpacity(0.06)),
              ),
              child: Row(children: [
                Container(width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: profile.pinEnabled ? AppColors.teal.withOpacity(0.15) : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14)),
                  child: Center(child: Text(profile.pinEnabled ? '🔐' : '🔓', style: const TextStyle(fontSize: 22)))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('PIN Lock', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                  Text(profile.pinEnabled ? 'চালু আছে — ট্যাপ করে বন্ধ করো' : 'বন্ধ — ট্যাপ করে PIN সেট করো',
                    style: TextStyle(color: profile.pinEnabled ? AppColors.teal : AppColors.textMuted, fontSize: 12)),
                ])),
                Switch(value: profile.pinEnabled, onChanged: (_) => _showPinSetup(), activeColor: AppColors.teal),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.06), borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gold.withOpacity(0.15))),
            child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('💡', style: TextStyle(fontSize: 16)),
              SizedBox(width: 10),
              Expanded(child: Text(
                'PIN সেট করতে: প্রথমে ৪ সংখ্যার PIN দাও → নিশ্চিত করার জন্য আবার একই PIN দাও। দুটো মিললে PIN চালু হবে।',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.5))),
            ]),
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}

class _PinDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final Function(String) onComplete;
  final VoidCallback onCancel;
  const _PinDialog({required this.title, required this.subtitle, required this.onComplete, required this.onCancel});
  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  String _pin = '';

  void _add(String d) {
    if (_pin.length >= 4) return;
    setState(() => _pin += d);
    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 300), () => widget.onComplete(_pin));
    }
  }

  void _back() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Widget _btn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(width: 56, height: 56,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF141C2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(widget.title, style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Syne', fontWeight: FontWeight.w700, fontSize: 16)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(widget.subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 8), width: 14, height: 14,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: i < _pin.length ? AppColors.gold : Colors.white.withOpacity(0.2))))),
        const SizedBox(height: 24),
        Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center,
            children: ['1','2','3'].map((d) => Padding(padding: const EdgeInsets.all(4), child: _btn(d, () => _add(d)))).toList()),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center,
            children: ['4','5','6'].map((d) => Padding(padding: const EdgeInsets.all(4), child: _btn(d, () => _add(d)))).toList()),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center,
            children: ['7','8','9'].map((d) => Padding(padding: const EdgeInsets.all(4), child: _btn(d, () => _add(d)))).toList()),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(width: 64),
            Padding(padding: const EdgeInsets.all(4), child: _btn('0', () => _add('0'))),
            Padding(padding: const EdgeInsets.all(4),
              child: GestureDetector(onTap: _back,
                child: Container(width: 56, height: 56,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.backspace_outlined, color: AppColors.textMuted, size: 20)))),
          ]),
        ]),
      ]),
      actions: [
        TextButton(onPressed: widget.onCancel, child: const Text('বাতিল', style: TextStyle(color: AppColors.textMuted))),
      ],
    );
  }
}
