import 'dart:io';

import 'package:fclipboard/adding_category.dart';
import 'package:fclipboard/adding_entry.dart';
import 'package:fclipboard/dao.dart';
import 'package:fclipboard/listing.dart';
import 'package:fclipboard/matcher.dart';
import 'package:fclipboard/model.dart';
import 'package:fclipboard/subscription.dart';
import 'package:fclipboard/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (isDesktop()) {
    await windowManager.ensureInitialized();
    await hotKeyManager.unregisterAll();
    await registerHotkey();
  }
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
  }
  databaseFactory = databaseFactoryFfi;
  runApp(const MainApp());
}

Future<void> registerHotkey() async {
  HotKey hotkey = HotKey(
    KeyCode.keyP,
    modifiers: [KeyModifier.alt],
    scope: HotKeyScope.system,
  );
  await hotKeyManager.register(
    hotkey,
    keyDownHandler: (hotKey) async {
      await windowManager.show();
      await windowManager.focus();
    },
  );

  // await hotKeyManager.unregister(hotkey);
  // await hotKeyManager.unregisterAll();
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  List<Entry> entries = [];
  int _selectedIndex = 0;
  List<String> _params = [];

  final _focusNode = FocusNode();

  final _matcher = Matcher(10);
  final _dbHelper = DBHelper();

  @override
  void initState() {
    super.initState();

    loadEntries();

    RawKeyboard.instance.addListener(_handleKeyEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void loadEntries() async {
    final entries = await _dbHelper.entries(null);
    _matcher.reset(entries);
    setState(() {
      this.entries = entries;
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
        final logicalKey = event.character;
        int number = logicalKey!.codeUnitAt(0) - 49;
        if (number >= 0 && number <= 9) {
          _selectItem(number);
        }
      }
    }
  }

  void _filterClipboard(String searchText) {
    setState(() {
      final searchTexts = searchText.split(' ');
      if (searchTexts.length > 1) {
        _params = searchTexts.sublist(1);
      } else {
        _params = [];
      }
      final matches = _matcher.match(searchTexts[0]);
      entries.clear();
      for (final match in matches) {
        entries.add(match);
      }
      _selectedIndex = 0;
    });
  }

  void _selectItem(int index) {
    setState(() {
      if (entries.length > index) {
        _selectedIndex = index;
        var subtitle = entries[index].subtitle;
        final params = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'];
        for (var i = 0; i < params.length; i++) {
          if (subtitle.contains('\$${params[i]}')) {
            if (i < _params.length) {
              subtitle = '${params[i]}="${_params[i]}";$subtitle';
            }
          }
        }
        Clipboard.setData(ClipboardData(text: subtitle));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Builder(builder: (context) {
        return Scaffold(
            appBar: AppBar(
              title: const Text('fclipboard'),
              actions: <Widget>[
                IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ListingPage()),
                      ).then((value) => loadEntries());
                    },
                    icon: const Icon(Icons.list)),
                PopupMenuButton(
                  icon: const Icon(Icons.add),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const CategoryAddingPage()),
                          );
                        },
                        child: const Text('Add Categories'),
                      ),
                    ),
                    PopupMenuItem(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const EntryAddingPage()),
                          ).then((value) => loadEntries());
                        },
                        child: const Text('Add Entries'),
                      ),
                    ),
                    PopupMenuItem(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SubscriptionPage()),
                          ).then((value) => loadEntries());
                        },
                        child: const Text('Subscribe'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            drawer: Drawer(
              child: ListView(
                children: <Widget>[
                  const UserAccountsDrawerHeader(
                      accountName: Text('Shoppon'),
                      accountEmail: Text('shopppon@gmail.com'),
                      currentAccountPicture: CircleAvatar(
                        child: Icon(Icons.person),
                      )),
                  ListTile(
                    leading: const Icon(Icons.clear),
                    title: const Text('Clear all data'),
                    onTap: () async {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Clear all data'),
                              content: const Text('Are you sure?'),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('Cancel'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: const Text('OK'),
                                  onPressed: () async {
                                    await _dbHelper.deleteAll();
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                      showToast(
                                          context, 'Clear successfully', false);
                                    }
                                  },
                                )
                              ],
                            );
                          }).then((value) => loadEntries());
                    },
                  ),
                ],
              ),
            ),
            body: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    focusNode: _focusNode,
                    onChanged: (value) {
                      _filterClipboard(value);
                    },
                    decoration: InputDecoration(
                      hintText: "Search",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                Expanded(
                    child: ListView.builder(
                        itemCount: entries.length,
                        itemBuilder: (context, i) {
                          return Container(
                            color: _selectedIndex == i
                                ? const Color.fromARGB(255, 199, 226, 248)
                                : null,
                            child: ListTile(
                              leading: InkWell(
                                child: Text(
                                  entries[i].icon,
                                  style: const TextStyle(fontSize: 32.0),
                                ),
                              ),
                              title: Text(entries[i].title),
                              subtitle: Text(entries[i].subtitle),
                              trailing: Text("Ctrl+${i + 1}"),
                              selected: _selectedIndex == i,
                              onTap: () {
                                _selectItem(i);
                              },
                            ),
                          );
                        }))
              ],
            ));
      }),
    );
  }
}
