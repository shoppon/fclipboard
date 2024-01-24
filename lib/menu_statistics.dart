import 'package:fclipboard/category_list.dart';
import 'package:flutter/material.dart';

class StatisticsMenu extends StatelessWidget {
  const StatisticsMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.bar_chart),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CategoryPage()),
        );
      },
    );
  }
}
