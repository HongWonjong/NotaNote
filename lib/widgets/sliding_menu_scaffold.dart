import 'package:flutter/material.dart';

/// 화면이 밀리는 슬라이딩 메뉴가 있는 스캐폴드 위젯
///
/// [menuWidget] 메뉴 영역에 표시될 위젯
/// [contentWidget] 메인 컨텐츠 영역에 표시될 위젯
/// [menuWidth] 메뉴의 너비 (기본값: 화면 너비의 70%)
/// [menuBackgroundColor] 메뉴 배경색 (기본값: 회색)
/// [contentBackgroundColor] 컨텐츠 배경색 (기본값: 흰색)
/// [animationDuration] 애니메이션 지속 시간 (기본값: 300ms)
class SlidingMenuScaffold extends StatefulWidget {
  final Widget menuWidget;
  final Widget contentWidget;
  final double? menuWidth;
  final Color? menuBackgroundColor;
  final Color? contentBackgroundColor;
  final Duration? animationDuration;
  final SlidingMenuController? controller;

  const SlidingMenuScaffold({
    Key? key,
    required this.menuWidget,
    required this.contentWidget,
    this.menuWidth,
    this.menuBackgroundColor,
    this.contentBackgroundColor,
    this.animationDuration,
    this.controller,
  }) : super(key: key);

  @override
  State<SlidingMenuScaffold> createState() => _SlidingMenuScaffoldState();
}

class _SlidingMenuScaffoldState extends State<SlidingMenuScaffold> {
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      widget.controller!._scaffoldState = this;
    }
  }

  @override
  void dispose() {
    if (widget.controller != null) {
      widget.controller!._scaffoldState = null;
    }
    super.dispose();
  }

  void toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final menuWidth =
        widget.menuWidth ?? MediaQuery.of(context).size.width * 0.7;
    final menuBgColor = widget.menuBackgroundColor ?? const Color(0xFFEEEEEE);
    final contentBgColor = widget.contentBackgroundColor ?? Colors.white;
    final animDuration =
        widget.animationDuration ?? const Duration(milliseconds: 300);

    return Scaffold(
      body: Stack(
        children: [
          // 메뉴 부분
          Container(
            width: menuWidth,
            color: menuBgColor,
            child: widget.menuWidget,
          ),

          // 메인 컨텐츠 부분
          AnimatedContainer(
            duration: animDuration,
            curve: Curves.easeInOut,
            transform: Matrix4.translationValues(
              _isMenuOpen ? menuWidth : 0,
              0,
              0,
            ),
            child: Stack(
              children: [
                // 실제 콘텐츠
                Container(
                  color: contentBgColor,
                  child: widget.contentWidget,
                ),

                // 메뉴가 열렸을 때만 표시되는 탭 감지 오버레이
                if (_isMenuOpen)
                  Positioned.fill(
                    child: Material(
                      color: Colors.black.withOpacity(0.05),
                      child: InkWell(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: toggleMenu,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 외부에서 SlidingMenuScaffold에 접근하기 위한 컨트롤러
class SlidingMenuController {
  _SlidingMenuScaffoldState? _scaffoldState;

  /// 메뉴 상태를 토글합니다
  void toggleMenu() {
    _scaffoldState?.toggleMenu();
  }

  /// 메뉴를 엽니다
  void openMenu() {
    _scaffoldState?._isMenuOpen = true;
    _scaffoldState?.setState(() {});
  }

  /// 메뉴를 닫습니다
  void closeMenu() {
    _scaffoldState?._isMenuOpen = false;
    _scaffoldState?.setState(() {});
  }

  /// 메뉴가 열려있는지 확인합니다
  bool get isMenuOpen => _scaffoldState?._isMenuOpen ?? false;
}
