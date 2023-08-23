import 'package:flutter/material.dart';

import 'player_page.dart';
import 'thumbnail_page.dart';
import 'transcoding_page.dart';

const List<Widget> _kPages = <Widget>[
  TranscodingPage(),
  ThumbnailPage(),
  PlayerPage(),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _kPages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.change_circle),
            label: 'Transcoding',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.image),
            label: 'Thumbnail',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle),
            label: 'Player',
          ),
        ],
        onTap: _handleTapItem,
        currentIndex: _currentIndex,
      ),
    );
  }

  void _handleTapItem(int index) {
    if (_currentIndex == index) {
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }
}
