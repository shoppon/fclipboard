import 'package:fclipbaord/matcher.dart';
import 'package:fclipbaord/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  List<ClipboardItem> clipboards = [];
  int _selectedIndex = 0;

  final _focusNode = FocusNode();

  final _matcher = Matcher();

  @override
  void initState() {
    super.initState();
    _matcher.all.forEach((key, value) {
      clipboards.add(ClipboardItem(title: key, subtitle: value));
    });

    RawKeyboard.instance.addListener(_handleKeyEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    super.dispose();
    RawKeyboard.instance.removeListener(_handleKeyEvent);
    _focusNode.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.isControlPressed) {
        if (event.logicalKey == LogicalKeyboardKey.digit0) {
          _selectItem(0);
        }
      }
    }
  }

  void _filterClipboard(String searchText) {
    setState(() {
      clipboards.add(ClipboardItem(title: searchText, subtitle: searchText));
      _selectedIndex = 0;
    });
  }

  void _selectItem(int index) {
    setState(() {
      if (clipboards.length > index) {
        _selectedIndex = index;
        Clipboard.setData(ClipboardData(text: clipboards[index].subtitle));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              // controller: _searchController,
              focusNode: _focusNode,
              onChanged: (value) {
                _filterClipboard(value);
              },
              decoration: InputDecoration(
                hintText: "Search",
                // prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
              child: ListView.builder(
                  itemCount: clipboards.length,
                  itemBuilder: (context, index) {
                    return Container(
                      color: _selectedIndex == index
                          ? const Color.fromARGB(255, 199, 226, 248)
                          : null,
                      child: ListTile(
                        leading: const FlutterLogo(),
                        title: Text(clipboards[index].title),
                        subtitle: Text(clipboards[index].subtitle),
                        trailing: Text("Ctrl+$index"),
                        selected: _selectedIndex == index,
                        onTap: () {
                          _selectItem(index);
                        },
                      ),
                    );
                  }))
        ],
      )),
    );
  }
}
