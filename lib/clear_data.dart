import 'package:fclipboard/dao.dart';
import 'package:fclipboard/generated/l10n.dart';
import 'package:fclipboard/utils.dart';
import 'package:flutter/material.dart';

class ClearDataButton extends StatelessWidget {
  const ClearDataButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dbHelper = DBHelper();

    return ListTile(
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
                      await dbHelper.deleteAll();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        showToast(
                            context, S.of(context).deleteAllSuccess, false);
                      }
                    },
                  )
                ],
              );
            }).then((value) => {});
      },
    );
  }
}
