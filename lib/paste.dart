import 'dart:convert';

import 'package:fclipboard/dao.dart';
import 'package:fclipboard/model.dart';
import 'package:fclipboard/utils.dart';
import 'package:flutter/material.dart';

import 'generated/l10n.dart';

class PastePage extends StatefulWidget {
  const PastePage({Key? key}) : super(key: key);

  @override
  State<PastePage> createState() => _PastePageState();
}

class _PastePageState extends State<PastePage> {
  String content = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).paste),
        ),
        body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: S.of(context).content,
                  ),
                  onChanged: (value) {
                    content = value;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return S.of(context).contentCannotBeEmpty;
                    }
                    return null;
                  },
                  maxLines: 10,
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final entity = Entry.fromJson(
                          jsonDecode(utf8.decode(base64Decode(content))));
                      // set entry id
                      final entries =
                          await DBHelper().entries(title: entity.title);
                      if (entries.isNotEmpty) {
                        entity.id = entries.first.id;
                      } else {
                        entity.id = 0;
                      }
                      // add category if not exists
                      final category = await DBHelper()
                          .getCategoryByName(entity.categoryName);
                      if (category == null) {
                        final id = await DBHelper().insertCategory(
                            Category(name: entity.categoryName, icon: '😆'));
                        entity.categoryId = id;
                      } else {
                        entity.categoryId = category.id;
                      }
                      // insert entry
                      await DBHelper().insertEntry(entity);
                      if (context.mounted) {
                        showToast(
                            context, S.of(context).pasteSuccessfully, false);
                        Navigator.of(context).pop();
                      }
                    } catch (e) {
                      showToast(context, S.of(context).errorFormat, true);
                    }
                  },
                  child: Text(S.of(context).ok),
                ),
              ],
            )));
  }
}
