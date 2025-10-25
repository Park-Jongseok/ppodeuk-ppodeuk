import 'package:flutter/material.dart';
import 'package:template/features/ppodeuk_ppodeuk/screens/all_tasks_screen.dart';
import 'package:template/features/ppodeuk_ppodeuk/screens/dashboard_screen.dart';
import 'package:template/features/ppodeuk_ppodeuk/screens/today_tasks_screen.dart';

/// 메인 화면
class MainScreen extends StatefulWidget {
  /// [MainScreen] 생성자
  const MainScreen({super.key, this.initialIndex = 0});

  /// 초기 선택된 탭 인덱스
  final int initialIndex;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  // 페이지 전환 시마다 새로운 인스턴스를 생성하여 데이터를 새로 가져옵니다
  Widget _getCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const TodayTasksScreen();
      case 2:
        return const AllTasksScreen();
      default:
        return const DashboardScreen();
    }
  }

  final _widgetTitles = [
    '대시보드',
    '오늘의 청소',
    '전체 청소',
  ];

  void _onItemTapped(int index) {
    if (index == _selectedIndex) {
      return; // 같은 탭을 누르면 무시
    }

    // pushReplacement를 사용하여 페이지를 완전히 교체
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            MainScreen(initialIndex: index),
        transitionDuration: Duration.zero, // 애니메이션 없이 즉시 전환
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_widgetTitles[_selectedIndex]),
      ),
      body: _getCurrentScreen(),
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
