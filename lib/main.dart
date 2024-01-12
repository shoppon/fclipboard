import 'package:fclipboard/cloud_menu.dart';
import 'package:fclipboard/config.dart';
import 'firebase_options.dart';
import 'package:fclipboard/clear_data.dart';
import 'package:fclipboard/subscription_menu.dart';
import 'package:fclipboard/constants.dart';
import 'package:fclipboard/creating.dart';
import 'package:fclipboard/email_verify.dart';
import 'package:fclipboard/entry_list.dart';
import 'package:fclipboard/export.dart';
import 'package:fclipboard/login.dart';
import 'package:fclipboard/model.dart';
import 'package:fclipboard/profile.dart';
import 'package:fclipboard/search.dart';
import 'package:fclipboard/server_configuration.dart';
import 'package:fclipboard/utils.dart';
import 'package:fclipboard/version.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:logger/logger.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:window_manager/window_manager.dart';

import 'generated/l10n.dart';

var logger = Logger();
bool shouldUseFirebaseEmulator = false;

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
  FirebaseUIAuth.configureProviders(getAuthProviders());

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

  String _givenName = "anonymous";
  String _email = defaultEmail;
  Widget _photo = const Icon(Icons.person_4);

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
        final url = user.photoURL ?? "";
        if (url.isNotEmpty) {
          setState(() {
            _photo = Image.network(url);
          });
        }
      }
    });
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
        },
      },
      home: Builder(builder: (context) {
        return Scaffold(
            appBar: AppBar(
              title: Text(S.of(context).appTitle),
              actions: <Widget>[
                CloudMenu(),
                isDesktop() ? const ExportButton() : Container(),
                const SubscriptionMenu(),
                const CreatingMenu(),
              ],
            ),
            drawer: Drawer(
              child: ListView(
                children: <Widget>[
                  UserAccountsDrawerHeader(
                    accountName: Text(_givenName),
                    accountEmail: Text(_email),
                    currentAccountPicture: CircleAvatar(child: _photo),
                    onDetailsPressed: () {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) {
                        Navigator.pushNamed(context, '/sign-in');
                      } else {
                        Navigator.pushNamed(context, '/profile');
                      }
                    },
                  ),
                  const ClearDataButton(),
                  const ServerConfiguration(),
                  const VersionLine(),
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
