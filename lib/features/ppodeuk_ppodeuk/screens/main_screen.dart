import 'package:flutter/material.dart';
import 'package:template/features/ppodeuk_ppodeuk/screens/all_tasks_screen.dart';
import 'package:template/features/ppodeuk_ppodeuk/screens/dashboard_screen.dart';
import 'package:template/features/ppodeuk_ppodeuk/screens/today_tasks_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    TodayTasksScreen(),
    AllTasksScreen(),
  ];

  static const List<String> _widgetTitles = <String>[
    '대시보드',
    '오늘의 청소',
    '전체 청소',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_widgetTitles[_selectedIndex]),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: '대시보드',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.today),
            label: '오늘의 청소',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_list),
            label: '전체 청소',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
