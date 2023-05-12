import 'dart:io';

import 'package:fclipboard/adding_category.dart';
import 'package:fclipboard/adding_entry.dart';
import 'package:fclipboard/dao.dart';
import 'package:fclipboard/entry_list.dart';
import 'package:fclipboard/matcher.dart';
import 'package:fclipboard/model.dart';
import 'package:fclipboard/search.dart';
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
  }
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
  }
  databaseFactory = databaseFactoryFfi;
  runApp(const MainApp());
}

Future<void> registerHotkey(FocusNode focusNode) async {
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
      focusNode.requestFocus();
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

  // focus node for the search field
  final _searchFocusNode = FocusNode();

  final _matcher = Matcher(10);
  final _dbHelper = DBHelper();

  final List<Param> _parameters = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });

    if (isDesktop()) {
      registerHotkey(_searchFocusNode);
    }
  }

  @override
  void dispose() {
    super.dispose();
    _searchFocusNode.dispose();
  }

  void _filterClipboard(String searchText) {
    setState(() {
      final searchTexts = searchText.split(' ');
      final matches = _matcher.match(searchTexts[0]);
      entries.clear();
      for (final match in matches) {
        entries.add(match);
      }
      _selectedIndex = 0;
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
                          ).then((value) => {});
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
                          ).then((value) => {});
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
                          }).then((value) => {});
                    },
                  ),
                ],
              ),
            ),
            body: Column(
              children: <Widget>[
                SearchParamWidget(
                  parameters: _parameters,
                  onChanged: (value) {
                    _filterClipboard(value);
                  },
                  onEditingComplete: () {
                    final entry = entries[_selectedIndex];
                    var subtitle = entry.subtitle;
                    final params = entry.parameters;
                    for (var p in params) {
                      if (p.current.isNotEmpty) {
                        subtitle = subtitle.replaceAll(p.name, p.current);
                      }
                    }
                    Clipboard.setData(ClipboardData(text: subtitle));
                  },
                  focusNode: _searchFocusNode,
                ),
                Expanded(child: EntryListView())
              ],
            ));
      }),
    );
  }
}
