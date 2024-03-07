import 'package:fclipboard/category_adding.dart';
import 'package:fclipboard/entry_adding.dart';
import 'package:fclipboard/generated/l10n.dart';
import 'package:fclipboard/model.dart';
import 'package:fclipboard/paste.dart';
import 'package:flutter/material.dart';

class CreatingMenu extends StatelessWidget {
  const CreatingMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: const Icon(Icons.add),
      itemBuilder: (context) => [
        PopupMenuItem(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const CategoryAddingPage()),
            );
          },
          child: Text(S.of(context).addCategory),
        ),
        PopupMenuItem(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => EntryAddingPage(entry: Entry.empty())),
            ).then((value) => {});
          },
          child: Text(S.of(context).addEntry),
        ),
        PopupMenuItem(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PastePage()),
            ).then((value) => {});
          },
          child: Text(S.of(context).paste),
        )
      ],
    );
  }
}
