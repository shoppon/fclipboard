import 'package:flutter/material.dart';

import 'generated/l10n.dart';
import 'utils.dart';

class DebugModeSwitch extends StatefulWidget {
  const DebugModeSwitch({Key? key}) : super(key: key);

  @override
  State<DebugModeSwitch> createState() => _DebugModeSwitchState();
}

class _DebugModeSwitchState extends State<DebugModeSwitch> {
  bool _debugMode = false;

  @override
  void initState() {
    super.initState();
    () async {
      final debug = await loadConfig('fclipboard.debug');
      setState(() {
        _debugMode = debug == 1;
      });
    }();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.terminal),
      title: Text(S.of(context).debugMode),
      subtitle: Container(
        alignment: Alignment.centerLeft,
        child: Switch(
          value: _debugMode,
          onChanged: (value) {
            setState(() {
              _debugMode = value;
            });
            saveConfig('fclipboard.debug', value ? 1 : 0);
          },
        ),
      ),
      titleAlignment: ListTileTitleAlignment.center,
    );
  }
}
