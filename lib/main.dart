import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const supabaseUrl = 'https://bepkzpkjyvdtboszpfyo.supabase.co';
const supabaseKey = 'sb_publishable_WKjoXzN0MJw63ZDCBxcWoQ_iuC1lf6Y';
const webApp = 'https://nfc-lens-pro.lovable.app';
const sapphire = Color(0xFF1D4ED8);
const gold = Color(0xFFD4AF37);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(const VaultApp());
}

final db = Supabase.instance.client;

class VaultApp extends StatefulWidget {
  const VaultApp({super.key});
  @override
  State<VaultApp> createState() => _VaultAppState();
}

class _VaultAppState extends State<VaultApp> {
  bool dark = false;
  @override
  Widget build(BuildContext context) {
    ThemeData t(Brightness b) => ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: sapphire, brightness: b),
        );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NFC Vault',
      theme: t(Brightness.light),
      darkTheme: t(Brightness.dark),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      builder: (c, w) => Directionality(textDirection: TextDirection.rtl, child: w!),
      home: StreamBuilder<AuthState>(
        stream: db.auth.onAuthStateChange,
        builder: (c, _) => db.auth.currentSession == null
            ? const LoginPage()
            : BioGate(child: HomePage(onTheme: () => setState(() => dark = !dark))),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController(), pass = TextEditingController();
  bool busy = false, signup = false;
  String? msg;
  Future<void> go() async {
    setState(() { busy = true; msg = null; });
    try {
      if (signup) {
        await db.auth.signUp(email: email.text.trim(), password: pass.text);
        msg = 'تم إنشاء الحساب — مستني موافقة الأدمن';
      } else {
        await db.auth.signInWithPassword(email: email.text.trim(), password: pass.text);
      }
    } on AuthException catch (e) { msg = e.message; }
    if (mounted) setState(() => busy = false);
  }
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const Icon(Icons.nfc, size: 72, color: sapphire),
              const Text('NFC Vault', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: gold)),
              const SizedBox(height: 24),
              TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'الإيميل', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة السر', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              FilledButton(onPressed: busy ? null : go, child: Text(signup ? 'إنشاء حساب' : 'دخول')),
              TextButton(onPressed: () => setState(() => signup = !signup), child: Text(signup ? 'عندي حساب' : 'حساب جديد')),
              if (msg != null) Text(msg!, textAlign: TextAlign.center),
            ]),
          ),
        ),
      );
}

/// يطلب البصمة / Face ID قبل فتح التطبيق
class BioGate extends StatefulWidget {
  final Widget child;
  const BioGate({super.key, required this.child});
  @override
  State<BioGate> createState() => _BioGateState();
}

class _BioGateState extends State<BioGate> with WidgetsBindingObserver {
  final auth = LocalAuthentication();
  bool ok = false;
  String? err;
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); unlock(); }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.paused) setState(() => ok = false); // إعادة القفل عند الخروج
  }
  Future<void> unlock() async {
    try {
      final r = await auth.authenticate(localizedReason: 'أكد هويتك لفتح NFC Vault', options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true));
      setState(() { ok = r; err = r ? null : 'تم الإلغاء'; });
    } catch (e) { setState(() => err = 'الجهاز لا يدعم البصمة'); }
  }
  @override
  Widget build(BuildContext context) => ok
      ? widget.child
      : Scaffold(
          body: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.fingerprint, size: 96, color: sapphire),
              const SizedBox(height: 16),
              FilledButton.icon(onPressed: unlock, icon: const Icon(Icons.lock_open), label: const Text('افتح بالبصمة')),
              if (err != null) Padding(padding: const EdgeInsets.all(8), child: Text(err!)),
            ]),
          ),
        );
}

class HomePage extends StatefulWidget {
  final VoidCallback onTheme;
  const HomePage({super.key, required this.onTheme});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('NFC Vault', style: TextStyle(fontWeight: FontWeight.w900)),
          actions: [
            IconButton(onPressed: widget.onTheme, icon: const Icon(Icons.dark_mode)),
            IconButton(onPressed: () => db.auth.signOut(), icon: const Icon(Icons.logout)),
          ],
        ),
        body: tab == 0 ? const ScanPage() : const VaultPage(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (i) => setState(() => tab = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.nfc), label: 'قراءة'),
            NavigationDestination(icon: Icon(Icons.lock), label: 'الخزنة'),
          ],
        ),
      );
}

String hex(List<int> b) => b.map((e) => e.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});
  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  Map<String, String>? info;
  bool scanning = false;
  String? err;

  Future<void> scan() async {
    if (!await NfcManager.instance.isAvailable()) { setState(() => err = 'NFC مقفول أو غير مدعوم'); return; }
    setState(() { scanning = true; err = null; info = null; });
    NfcManager.instance.startSession(onDiscovered: (tag) async {
      final d = tag.data;
      final r = <String, String>{};
      List<int>? id;
      for (final k in ['nfca', 'nfcb', 'nfcf', 'nfcv', 'isodep', 'mifare', 'mifareclassic', 'mifareultralight']) {
        final m = d[k];
        if (m is Map) {
          r['تقنية'] = '${r['تقنية'] ?? ''} $k'.trim();
          final x = m['identifier'];
          if (x is List && id == null) id = x.cast<int>();
        }
      }
      if (id != null) r['UID'] = hex(id!);
      final ndef = Ndef.from(tag);
      if (ndef != null) {
        r['NDEF'] = 'نعم';
        r['قابل للكتابة'] = ndef.isWritable ? 'نعم' : 'لا';
        r['السعة'] = '${ndef.maxSize} بايت';
        for (final rec in ndef.cachedMessage?.records ?? []) {
          r['سجل ${r.length}'] = String.fromCharCodes(rec.payload.skip(1));
        }
      }
      await NfcManager.instance.stopSession();
      setState(() { info = r; scanning = false; });
    });
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
        Card(
          color: sapphire,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(children: [
              Icon(scanning ? Icons.wifi_tethering : Icons.nfc, size: 80, color: gold),
              const SizedBox(height: 12),
              Text(scanning ? 'قرّب البطاقة من الموبايل…' : 'جاهز للقراءة', style: const TextStyle(color: Colors.white, fontSize: 20)),
              const SizedBox(height: 12),
              FilledButton(onPressed: scanning ? null : scan, style: FilledButton.styleFrom(backgroundColor: gold), child: const Text('امسح البطاقة')),
            ]),
          ),
        ),
        if (err != null) Text(err!, textAlign: TextAlign.center),
        if (info != null) ...info!.entries.map((e) => ListTile(title: Text(e.key), subtitle: SelectableText(e.value))),
        if (info?['UID'] != null)
          FilledButton.icon(
            icon: const Icon(Icons.shield),
            label: const Text('اعرض/احفظ المحتوى الآمن'),
            onPressed: () => launchUrl(Uri.parse('$webApp/?tagid=${Uri.encodeComponent(info!['UID']!)}'), mode: LaunchMode.externalApplication),
          ),
      ]);
}

class VaultPage extends StatefulWidget {
  const VaultPage({super.key});
  @override
  State<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends State<VaultPage> {
  late Future<List<Map<String, dynamic>>> cards = load();
  Future<List<Map<String, dynamic>>> load() async => List<Map<String, dynamic>>.from(
      await db.from('nfc_tags').select('id,uid,label,has_text,has_pin,has_ipn,updated_at').order('updated_at', ascending: false));
  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: () async => setState(() => cards = load()),
        child: FutureBuilder(
          future: cards,
          builder: (c, s) {
            if (s.hasError) return ListView(children: [Padding(padding: const EdgeInsets.all(24), child: Text('تعذر التحميل: ${s.error}'))]);
            if (!s.hasData) return const Center(child: CircularProgressIndicator());
            if (s.data!.isEmpty) return ListView(children: const [Padding(padding: EdgeInsets.all(24), child: Text('مفيش بطاقات محفوظة'))]);
            return ListView(padding: const EdgeInsets.all(12), children: s.data!.map((t) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.verified, color: sapphire),
                    title: Text(t['label'] ?? t['uid']),
                    subtitle: Text([if (t['has_text'] == true) 'نص', if (t['has_pin'] == true) 'PIN', if (t['has_ipn'] == true) 'IPN'].join(' · ')),
                    trailing: const Icon(Icons.lock, color: gold),
                    onTap: () => launchUrl(Uri.parse('$webApp/?tagid=${Uri.encodeComponent(t['uid'])}'), mode: LaunchMode.externalApplication),
                  ),
                )).toList());
          },
        ),
      );
}