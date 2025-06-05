import 'package:flutter/material.dart';
import 'package:classfinder_f/screens/home_screen.dart';
import 'package:classfinder_f/screens/classes.dart';
import 'package:classfinder_f/screens/create_class.dart';

class BottomBarView extends StatefulWidget {
  const BottomBarView({Key? key}) : super(key: key);

  @override
  State<BottomBarView> createState() => _BottomBarViewState();
}

class _BottomBarViewState extends State<BottomBarView> {
  int currentIndex = 0;

  final List<Widget> widgetOption = [
    const HomeScreen(),
    const Classes(),
    const CreateClass(),
    //Screens in index order
  ];

  void onItemTapped(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widgetOption[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
            //button for home
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.class_),
            label: "Classes",
            //button for classes
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: "Create Class",
            //button for create class
          ),
        ],
      ),
    );
  }
}
