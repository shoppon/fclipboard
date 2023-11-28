import 'package:fclipboard/constants.dart';
import 'package:fclipboard/generated/l10n.dart';
import 'package:fclipboard/utils.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServerConfiguration extends StatefulWidget {
  const ServerConfiguration({Key? key}) : super(key: key);

  @override
  State<ServerConfiguration> createState() => ServerConfigurationState();
}

class ServerConfigurationState extends State<ServerConfiguration> {
  @override
  void initState() {
    super.initState();
  }

  Future<String> getServerAddr() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("fclipboard.serverAddr") ?? baseURL;
  }

  TextEditingController serverAddrController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.web),
      title: Text(S.of(context).serverAddr),
      subtitle: FutureBuilder(
        future: getServerAddr(),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
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
                  controller: serverAddrController,
                  onChanged: (value) {
                    try {
                      Uri.parse(value);
                    } catch (e) {
                      return;
                    }
                  },
                  decoration: InputDecoration(
                    errorText: S.of(context).invalidFormat,
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
                      final SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      prefs.setString(
                          "fclipboard.serverAddr", serverAddrController.text);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        showToast(context, S.of(context).settingSuccess, false);
                      }
                    },
                  )
                ],
              );
            });
      },
    );
    // current version
  }
}
