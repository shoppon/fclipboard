import 'package:fclipboard/adding_category.dart';
import 'package:fclipboard/adding_entry.dart';
import 'package:fclipboard/constants.dart';
import 'package:fclipboard/dao.dart';
import 'package:fclipboard/entry_list.dart';
import 'package:fclipboard/model.dart';
import 'package:fclipboard/search.dart';
import 'package:fclipboard/subscription_adding.dart';
import 'package:fclipboard/subscription_creating.dart';
import 'package:fclipboard/subscription_list.dart';
import 'package:fclipboard/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:window_manager/window_manager.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

import 'generated/l10n.dart';
import 'paste.dart';

var logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (isDesktop()) {
    await windowManager.ensureInitialized();
    await hotKeyManager.unregisterAll();
  }
  if (isWindowsOrLinux()) {
    sqfliteFfiInit();
  }

  if (kIsWeb) {
    // Change default factory on the web
    databaseFactory = databaseFactoryFfiWeb;
  } else {
    databaseFactory = databaseFactoryFfi;
  }

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
  ValueNotifier<String> filterNotifier = ValueNotifier('');
  ValueNotifier<Entry> entryNotifier = ValueNotifier(Entry.empty());

  // focus node for the search field
  final _searchFocusNode = FocusNode();

  final _dbHelper = DBHelper();

  String _givenName = "anonymous";
  String _email = defaultEmail;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });

    if (isDesktop()) {
      registerHotkey(_searchFocusNode);
    }

    loadUserInfo();
  }

  Future<void> loadUserInfo() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      final email = prefs.getString("fclipboard.email") ?? "";
      if (email.isNotEmpty) {
        _email = email;
      }
      final givenName = prefs.getString("fclipboard.givenName") ?? "";
      if (givenName.isNotEmpty) {
        _givenName = givenName;
      }
    });
  }

  Future<String> getVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  @override
  void dispose() {
    super.dispose();
    _searchFocusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('zh', 'CN'),
      ],
      home: Builder(builder: (context) {
        ProgressDialog pd = ProgressDialog(context: context);
        return Scaffold(
            appBar: AppBar(
              title: Text(S.of(context).appTitle),
              actions: <Widget>[
                isDesktop()
                    ? PopupMenuButton(
                        icon: const Icon(Icons.import_export),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: TextButton(
                              onPressed: () async {
                                final msg = S.of(context).loading;
                                String? output =
                                    await FilePicker.platform.saveFile(
                                  dialogTitle: S.of(context).export,
                                  fileName: 'fclipboard.yaml',
                                );
                                if (output == null) {
                                  return;
                                }
                                pd.show(msg: msg);
                                await DBHelper().exportToFile(output);
                                if (mounted) {
                                  Navigator.pop(context);
                                  showToast(context,
                                      S.of(context).exportSuccessfully, false);
                                }
                                pd.close();
                              },
                              child: Text(S.of(context).export),
                            ),
                          ),
                          PopupMenuItem(
                            child: TextButton(
                              onPressed: () async {
                                final msg = S.of(context).loading;
                                FilePickerResult? result = await FilePicker
                                    .platform
                                    .pickFiles(allowedExtensions: ['yaml']);
                                if (result == null) {
                                  return;
                                }
                                pd.show(msg: msg);
                                try {
                                  await DBHelper().importFromFile(
                                      result.files.single.path!);
                                  if (mounted) {
                                    showToast(
                                        context,
                                        S.of(context).importSuccessfully,
                                        false);
                                  }
                                } catch (e) {
                                  logger.e('Failed to import.', error: e);
                                  if (mounted) {
                                    showToast(context,
                                        S.of(context).importFailed, true);
                                  }
                                } finally {
                                  if (mounted) {
                                    Navigator.pop(context);
                                  }
                                  pd.close();
                                }
                              },
                              child: Text(S.of(context).import),
                            ),
                          ),
                        ],
                      )
                    : Container(),
                PopupMenuButton(
                  icon: const Icon(Icons.cloud),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const SubscriptionListView()),
                          ).then((value) => {});
                        },
                        child: Text(S.of(context).subscriptionList),
                      ),
                    ),
                    PopupMenuItem(
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const SubscriptionAddingPage()),
                          ).then((value) => {});
                        },
                        child: Text(S.of(context).addSubscription),
                      ),
                    ),
                    PopupMenuItem(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const SubscriptionCreatingPage()),
                          ).then((value) => {});
                        },
                        child: Text(S.of(context).creatingSubscription),
                      ),
                    ),
                  ],
                ),
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
                        child: Text(S.of(context).addCategory),
                      ),
                    ),
                    PopupMenuItem(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    EntryAddingPage(entry: Entry.empty())),
                          ).then((value) => {});
                        },
                        child: Text(S.of(context).addEntry),
                      ),
                    ),
                    PopupMenuItem(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const PastePage()),
                          ).then((value) => {});
                        },
                        child: Text(S.of(context).paste),
                      ),
                    )
                  ],
                ),
              ],
            ),
            drawer: Drawer(
              child: ListView(
                children: <Widget>[
                  UserAccountsDrawerHeader(
                      accountName: Text(_givenName),
                      accountEmail: Text(_email),
                      currentAccountPicture: const CircleAvatar(
                        child: Icon(Icons.person),
                      )),
                  ListTile(
                    leading: const Icon(Icons.clear),
                    title: Text(S.of(context).clearAll),
                    subtitle: Text(S.of(context).clearWarning),
                    onTap: () async {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(S.of(context).clearAll),
                              content: Text(S.of(context).confirmDelete),
                              actions: <Widget>[
                                TextButton(
                                  child: Text(S.of(context).cancel),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: Text(S.of(context).ok),
                                  onPressed: () async {
                                    await _dbHelper.deleteAll();
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                      showToast(
                                          context,
                                          S.of(context).deleteAllSuccess,
                                          false);
                                    }
                                  },
                                )
                              ],
                            );
                          }).then((value) => {});
                    },
                  ),
                  // current version
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: Text(S.of(context).version),
                    subtitle: FutureBuilder(
                      future: getVersion(),
                      builder: (BuildContext context,
                          AsyncSnapshot<String> snapshot) {
                        if (snapshot.hasData) {
                          return Text(snapshot.data!);
                        } else {
                          return const Text('');
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SignInWithAppleButton(
                      onPressed: () async {
                        final credential =
                            await SignInWithApple.getAppleIDCredential(
                          scopes: [
                            AppleIDAuthorizationScopes.email,
                            AppleIDAuthorizationScopes.fullName,
                          ],
                        );

                        if (credential.email!.isNotEmpty) {
                          final SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          await prefs.setString(
                              "fclipboard.email", credential.email!);
                          await prefs.setString(
                              "fclipboard.givenName", credential.givenName!);
                        }

                        await loadUserInfo();
                      },
                    ),
                  ),
                ],
              ),
            ),
            body: Column(
              children: <Widget>[
                SearchParamWidget(
                  entry: entryNotifier,
                  onChanged: (value) {
                    filterNotifier.value = value;
                  },
                  focusNode: _searchFocusNode,
                ),
                Expanded(
                    child: EntryListView(
                  filterNotifier: filterNotifier,
                  entryNotifier: entryNotifier,
                ))
              ],
            ));
      }),
    );
  }
}
