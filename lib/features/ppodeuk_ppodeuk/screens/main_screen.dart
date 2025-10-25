import 'package:flutter/material.dart';
import 'package:template/features/ppodeuk_ppodeuk/screens/dashboard_screen.dart';
import 'package:template/features/ppodeuk_ppodeuk/screens/task_list_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    TaskListScreen(),
  ];

  static const List<String> _widgetTitles = <String>[
    '대시보드',
    '청소 목록',
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
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: '대시보드',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: '청소 목록',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
