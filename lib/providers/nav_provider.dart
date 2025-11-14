// Simple navigation provider to control bottom navigation index across company screens.
// Use IndexedStack in CompanyMainScreen to preserve state between tabs.

import 'package:flutter/material.dart';

class NavProvider extends ChangeNotifier {
  int _index = 0;
  int get index => _index;

  void changeIndex(int i) {
    if (i == _index) return;
    _index = i;
    notifyListeners();
  }
}
