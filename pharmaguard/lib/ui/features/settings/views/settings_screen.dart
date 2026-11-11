import 'package:flutter/material.dart';
import '../../../../data/local_storage.dart';
import '../../auth/views/auth_screen.dart';
import '../../quarantine/quarantine_screen.dart';
import '../../history/history_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(title: const Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          Container(
            padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: Row(children: [
              GestureDetector(
                onTap: () { 
                  showModalBottomSheet(context: context, builder: (context) { 
                    return Container(padding: const EdgeInsets.symmetric(vertical: 24), child: Column(mainAxisSize: MainAxisSize.min, children: [
                      ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Ganti Foto'), onTap: () async { setState(() { userProfileImageUrl = 'https://i.pravatar.cc/150?img=47'; }); await saveData(); Navigator.pop(context); }), 
                      ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('Hapus Foto', style: TextStyle(color: Colors.red)), onTap: () async { setState(() { userProfileImageUrl = null; }); await saveData(); Navigator.pop(context); })
                    ]));
                  });
                }, 
                child: Stack(children: [CircleAvatar(radius: 36, backgroundColor: const Color(0xFFCCFBF1), backgroundImage: userProfileImageUrl != null ? NetworkImage(userProfileImageUrl!) : null, child: userProfileImageUrl == null ? const Text('P', style: TextStyle(fontSize: 32, color: Color(0xFF0D9488))) : null), const Positioned(bottom: 0, right: 0, child: Icon(Icons.camera_alt, color: Color(0xFF0D9488)))])
              ), 
              const SizedBox(width: 20), 
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('Apoteker Pija', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), SizedBox(height: 6), Text('Apotek Sehat Medika', style: TextStyle(color: Color(0xFF64748B)))]))
            ]),
          ),
          const SizedBox(height: 32),
          _buildListTile(Icons.move_to_inbox, 'Kotak Karantina', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuarantineScreen()))),
          _buildListTile(Icons.history, 'Riwayat Aktivitas', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()))),
          const SizedBox(height: 48),
          TextButton.icon(
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthScreen())), 
            icon: const Icon(Icons.logout, color: Color(0xFFDC2626)), 
            label: const Text('Keluar Akun', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold))
          ),
        ],
      )
    );
  }

  Widget _buildListTile(IconData icon, String title, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), 
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), 
      child: ListTile(leading: Icon(icon, color: const Color(0xFF64748B)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), trailing: const Icon(Icons.chevron_right), onTap: onTap)
    );
  }
}