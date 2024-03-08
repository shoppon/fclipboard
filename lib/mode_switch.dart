import 'package:fclipboard/utils.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'generated/l10n.dart';

class ModeSwitch extends StatefulWidget {
  const ModeSwitch({Key? key}) : super(key: key);

  @override
  State<ModeSwitch> createState() => _ModeSwitchState();
}

class _ModeSwitchState extends State<ModeSwitch> {
  int _mode = 1;

  @override
  void initState() {
    super.initState();
    _getMode();
  }

  void _getMode() async {
    final mode = await getMode();
    setState(() {
      _mode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.select_all),
      title: Text(S.of(context).modeSwitch),
      subtitle: Column(
        children: [
          Row(
            children: [
              Radio(
                  value: 1,
                  groupValue: _mode,
                  onChanged: (value) async {
                    setState(() {
                      _mode = value as int;
                    });
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setInt('fclipboard.mode', value as int);
                  }),
              Text(S.of(context).modeAnnotation),
              Radio(
                  value: 2,
                  groupValue: _mode,
                  onChanged: (value) async {
                    setState(() {
                      _mode = value as int;
                    });
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setInt('fclipboard.mode', value as int);
                  }),
              Text(S.of(context).modeNotes),
            ],
          )
        ],
      ),
    );
  }
}
