import 'dart:io';
import 'dart:math';

import 'package:fclipboard/adding_category.dart';
import 'package:fclipboard/adding_entry.dart';
import 'package:fclipboard/dao.dart';
import 'package:fclipboard/matcher.dart';
import 'package:fclipboard/model.dart';
import 'package:fclipboard/subscription.dart';
import 'package:fclipboard/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'flutter_gen/gen_l10n/app_localizations.dart';

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

  Offset _tapPosition = Offset.zero;

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
      // get most used 10 entries
      entries.sort((a, b) => b.counter.compareTo(a.counter));
      this.entries = entries.sublist(0, min(10, entries.length));
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
      if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
        _selectItem(_selectedIndex);
      }
      if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % entries.length;
        });
      }
      if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
        setState(() {
          _selectedIndex = (_selectedIndex - 1) % entries.length;
        });
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

  void _selectItem(int index) async {
    await _dbHelper.incEntryCounter(entries[index].title);
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

  String _getTrailingText(int index) {
    if (isDesktop()) {
      return 'Ctrl+${index + 1}';
    } else {
      return '';
    }
  }

  void _deleteListItem(BuildContext context, int index) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          var title = 'Delete ${entries[index].title}';
          return AlertDialog(
            title: Text(title),
            content: Text(AppLocalizations.of(context).confirmDelete),
            actions: <Widget>[
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(AppLocalizations.of(context).cancel)),
              TextButton(
                onPressed: () {
                  // delete entry
                  _dbHelper.deleteEntry(entries[index].title).then((value) {
                    setState(() {
                      entries.removeAt(index);
                    });
                    showToast(context,
                        AppLocalizations.of(context).deleteSuccess, false);
                  });
                  Navigator.of(context).pop();
                },
                child: Text(AppLocalizations.of(context).ok),
              )
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('zh', 'CN'),
      ],
      home: Builder(builder: (context) {
        return Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context).appTitle),
              actions: <Widget>[
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
                        child: Text(AppLocalizations.of(context).addCategory),
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
                        child: Text(AppLocalizations.of(context).addEntry),
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
                        child:
                            Text(AppLocalizations.of(context).addSubscription),
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
                    title: Text(AppLocalizations.of(context).clearAll),
                    onTap: () async {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title:
                                  Text(AppLocalizations.of(context).clearAll),
                              content: Text(
                                  AppLocalizations.of(context).confirmDelete),
                              actions: <Widget>[
                                TextButton(
                                  child:
                                      Text(AppLocalizations.of(context).cancel),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: Text(AppLocalizations.of(context).ok),
                                  onPressed: () async {
                                    await _dbHelper.deleteAll();
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                      showToast(
                                          context,
                                          AppLocalizations.of(context)
                                              .deleteAllSuccess,
                                          false);
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
                      hintText: AppLocalizations.of(context).searchHint,
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
                          return GestureDetector(
                            onTapDown: (details) {
                              _tapPosition = details.globalPosition;
                            },
                            child: Container(
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
                                trailing: Text(_getTrailingText(i)),
                                selected: _selectedIndex == i,
                                onTap: () {
                                  _selectItem(i);
                                },
                                onLongPress: () async {
                                  _selectItem(i);
                                  final RelativeRect position =
                                      RelativeRect.fromLTRB(
                                    _tapPosition.dx,
                                    _tapPosition.dy,
                                    _tapPosition.dx + 40,
                                    _tapPosition.dy + 40,
                                  );
                                  int? selectedValue = await showMenu(
                                    context: context,
                                    position: position,
                                    items: <PopupMenuEntry<int>[
                                      PopupMenuItem(
                                          value: 0,
                                          child: Text(
                                              AppLocalizations.of(context)
                                                  .update)),
                                      PopupMenuItem(
                                          value: 1,
                                          child: Text(
                                              AppLocalizations.of(context)
                                                  .delete)),
                                    ],
                                  );
                                  if (selectedValue == 1) {
                                    if (context.mounted) {
                                      _deleteListItem(context, i);
                                    }
                                  }
                                },
                              ),
                            ),
                          );
                        }))
              ],
            ));
      }),
    );
  }
}
