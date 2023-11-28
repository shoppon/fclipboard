import 'package:fclipboard/cloud_sync.dart';
import 'package:fclipboard/creating.dart';
import 'package:fclipboard/export.dart';
import 'package:fclipboard/login.dart';
import 'package:fclipboard/profile.dart';
import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';

import 'email_verify.dart';
import 'firebase_options.dart';
import 'package:fclipboard/constants.dart';
import 'package:fclipboard/dao.dart';
import 'package:fclipboard/entry_list.dart';
import 'package:fclipboard/model.dart';
import 'package:fclipboard/search.dart';
import 'package:fclipboard/utils.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:window_manager/window_manager.dart';

import 'generated/l10n.dart';

var logger = Logger();
bool shouldUseFirebaseEmulator = true;

late final FirebaseApp app;
late final FirebaseAuth auth;

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

  app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  auth = FirebaseAuth.instanceFor(app: app);
  if (shouldUseFirebaseEmulator) {
    await auth.useAuthEmulator('localhost', 9099);
  }
  FirebaseUIAuth.configureProviders([
    EmailAuthProvider(),
  ]);

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
  String _serverAddr = "N/A";
  final _serverAddrCtrl = TextEditingController();
  bool _isServerAddrValid = true;

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
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      if (user == null) {
        _email = defaultEmail;
        _givenName = "anonymous";
      } else {
        _email = user.email ?? defaultEmail;
        _givenName = user.displayName ?? "anonymous";
      }
    });
  }

  Future<String> getVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Future<String> getServerAddr() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _serverAddr = prefs.getString("fclipboard.serverAddr") ?? baseURL;
    return _serverAddr;
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
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FirebaseUILocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('zh', 'CN'),
      ],
      debugShowCheckedModeBanner: false,
      routes: {
        '/sign-in': (context) {
          return const LoginPage();
        },
        '/verify-email': (context) {
          return const EmailVerifyPage();
        },
        '/profile': (context) {
          return const ProfilePage();
        }
      },
      home: Builder(builder: (context) {
        return Scaffold(
            appBar: AppBar(
              title: Text(S.of(context).appTitle),
              actions: <Widget>[
                isDesktop() ? const ExportButton() : Container(),
                const CloudSyncMenu(),
                const CreatingMenu(),
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
                    ),
                    onDetailsPressed: () {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) {
                        Navigator.pushNamed(context, '/sign-in');
                      } else {
                        Navigator.pushNamed(context, '/profile');
                      }
                    },
                  ),
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
                  // server address
                  ListTile(
                    leading: const Icon(Icons.web),
                    title: Text(S.of(context).serverAddr),
                    subtitle: FutureBuilder(
                      future: getServerAddr(),
                      builder: (BuildContext context,
                          AsyncSnapshot<String> snapshot) {
                        if (snapshot.hasData) {
                          return Text(snapshot.data!);
                        } else {
                          return const Text('');
                        }
                      },
                    ),
                    onTap: () {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(S.of(context).addCategory),
                              content: TextFormField(
                                controller: _serverAddrCtrl,
                                onChanged: (value) {
                                  try {
                                    Uri.parse(value);
                                  } catch (e) {
                                    setState(() {
                                      _isServerAddrValid = false;
                                    });
                                    return;
                                  }
                                  setState(() {
                                    _isServerAddrValid = true;
                                  });
                                },
                                decoration: InputDecoration(
                                  errorText: _isServerAddrValid
                                      ? null
                                      : S.of(context).invalidFormat,
                                ),
                              ),
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
                                    if (!_isServerAddrValid) {
                                      return;
                                    }
                                    final SharedPreferences prefs =
                                        await SharedPreferences.getInstance();
                                    prefs.setString("fclipboard.serverAddr",
                                        _serverAddrCtrl.text);
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                      showToast(context,
                                          S.of(context).settingSuccess, false);
                                      setState(() {});
                                    }
                                  },
                                )
                              ],
                            );
                          });
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
                ],
              ),
            ),
            onDrawerChanged: (isOpened) {
              if (isOpened) {
                loadUserInfo();
              }
            },
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
