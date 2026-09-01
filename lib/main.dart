import 'package:flutter/material.dart';
import 'package:raid_compass/features/items/ammo_caliber_page.dart';
import 'package:raid_compass/features/items/items_page.dart';

void main() {
  runApp(const RaidCompassApp());
}

class RaidCompassApp extends StatelessWidget {
  const RaidCompassApp({super.key});

  static const backgroundColor = Color(0xFF111410);
  static const surfaceColor = Color(0xFF1B201A);
  static const accentColor = Color(0xFFB7A56A);

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: accentColor,
          brightness: Brightness.dark,
        ).copyWith(
          primary: accentColor,
          surface: surfaceColor,
          error: const Color(0xFFB85C57),
        );

    return MaterialApp(
      title: 'Raid Compass',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          foregroundColor: Color(0xFFE8E4D8),
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: surfaceColor,
          indicatorColor: accentColor.withValues(alpha: 0.22),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);

            return TextStyle(
              color: selected ? accentColor : const Color(0xFFA8A598),
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            );
          }),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceColor,
          hintStyle: const TextStyle(color: Color(0xFF858279)),
          prefixIconColor: const Color(0xFFA8A598),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const RaidCompassShell(),
    );
  }
}

class RaidCompassShell extends StatefulWidget {
  const RaidCompassShell({super.key});

  @override
  State<RaidCompassShell> createState() => _RaidCompassShellState();
}

class _RaidCompassShellState extends State<RaidCompassShell> {
  int _currentIndex = 0;

  static const _titles = ['Raid Compass', 'アイテム', 'タスク', '弾薬', '設定'];

  void _selectPage(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onNavigate: _selectPage),
      const ItemsPage(),
      const FeaturePage(
        icon: Icons.assignment_outlined,
        title: 'タスク管理',
        description: 'タスクの進行状況と必要アイテムを管理します。',
      ),
      const AmmoCaliberPage(),

      const SettingsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_currentIndex == 0)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(child: _StatusBadge()),
            ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _selectPage,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'ホーム',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'アイテム',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'タスク',
          ),
          NavigationDestination(
            icon: Icon(Icons.adjust_outlined),
            selectedIcon: Icon(Icons.adjust),
            label: '弾薬',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({required this.onNavigate, super.key});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const _WelcomeCard(),
        const SizedBox(height: 24),
        const _SectionTitle(title: '進捗'),
        const SizedBox(height: 12),
        const _ProgressCard(),
        const SizedBox(height: 24),
        const _SectionTitle(title: 'クイックアクセス'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            _QuickActionCard(
              icon: Icons.search,
              title: 'アイテム検索',
              subtitle: '価格・用途を確認',
              onTap: () => onNavigate(1),
            ),
            _QuickActionCard(
              icon: Icons.assignment_turned_in_outlined,
              title: 'タスク',
              subtitle: '進捗を記録',
              onTap: () => onNavigate(2),
            ),
            _QuickActionCard(
              icon: Icons.adjust,
              title: '弾薬',
              subtitle: '性能を比較',
              onTap: () => onNavigate(3),
            ),
            _QuickActionCard(
              icon: Icons.tune,
              title: '設定',
              subtitle: 'データを管理',
              onTap: () => onNavigate(4),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _SectionTitle(title: 'データ状態'),
        const SizedBox(height: 12),
        const _DataStatusCard(),
      ],
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF292A20), Color(0xFF1B201A)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFB7A56A).withValues(alpha: 0.35),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.explore_outlined, color: Color(0xFFB7A56A), size: 34),
          SizedBox(height: 16),
          Text(
            'READY FOR RAID',
            style: TextStyle(
              color: Color(0xFFB7A56A),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'レイド準備を、ひとつの場所で。',
            style: TextStyle(
              color: Color(0xFFE8E4D8),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'アイテム、タスク、弾薬、ハイドアウトの情報を管理する個人用コンパニオンです。',
            style: TextStyle(color: Color(0xFFA8A598), height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'タスク進捗',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text('0 / 0', style: TextStyle(color: Color(0xFFB7A56A))),
            ],
          ),
          SizedBox(height: 14),
          LinearProgressIndicator(
            value: 0,
            minHeight: 7,
            borderRadius: BorderRadius.all(Radius.circular(10)),
            backgroundColor: Color(0xFF30352D),
            color: Color(0xFFB7A56A),
          ),
          SizedBox(height: 12),
          Text(
            'タスクデータはまだ取得されていません。',
            style: TextStyle(color: Color(0xFFA8A598), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFFB7A56A), size: 28),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFE8E4D8),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFFA8A598), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DataStatusCard extends StatelessWidget {
  const _DataStatusCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(0xFF30352D),
            child: Icon(Icons.cloud_off_outlined, color: Color(0xFFA8A598)),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ローカルモード', style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(height: 3),
                Text(
                  '次の段階でTarkov.dev APIを接続します',
                  style: TextStyle(color: Color(0xFFA8A598), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FeaturePage extends StatelessWidget {
  const FeaturePage({
    required this.icon,
    required this.title,
    required this.description,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: const Color(0xFFB7A56A)),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFA8A598), height: 1.5),
            ),
            const SizedBox(height: 18),
            const Chip(label: Text('近日実装')),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const _SettingsTile(
          icon: Icons.sync,
          title: 'データ更新',
          subtitle: 'API接続後に利用できます',
        ),
        const SizedBox(height: 10),
        const _SettingsTile(
          icon: Icons.save_outlined,
          title: 'バックアップ',
          subtitle: '進捗データの書き出し・復元',
        ),
        const SizedBox(height: 10),
        const _SettingsTile(
          icon: Icons.language,
          title: 'データ提供元',
          subtitle: 'Tarkov.dev API',
        ),
        const SizedBox(height: 10),
        const _SettingsTile(
          icon: Icons.info_outline,
          title: 'Raid Compass',
          subtitle: 'Version 0.1.0',
        ),
        const SizedBox(height: 24),
        const Text(
          '本アプリは非公式の個人利用ツールです。'
          'Battlestate Gamesおよび各攻略サイトとは関係ありません。',
          style: TextStyle(color: Color(0xFF858279), fontSize: 12, height: 1.5),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFB7A56A)),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Color(0xFFA8A598)),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFFE8E4D8),
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF30352D),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: Color(0xFF7A9E65), size: 8),
          SizedBox(width: 6),
          Text(
            'LOCAL',
            style: TextStyle(
              color: Color(0xFFA8A598),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: const Color(0xFF1B201A),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFF30352D)),
  );
}
