import 'package:fclipboard/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionLine extends StatelessWidget {
  const VersionLine({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Future<String> getVersion() async {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    }

    return ListTile(
      leading: const Icon(Icons.info),
      title: Text(S.of(context).version),
      subtitle: FutureBuilder(
        future: getVersion(),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            return Text(snapshot.data!);
          } else {
            return const Text('');
          }
        },
      ),
    );
  }
}
