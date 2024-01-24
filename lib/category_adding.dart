import 'dart:developer';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:fclipboard/dao.dart';
import 'package:fclipboard/model.dart' as model;
import 'package:fclipboard/utils.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:openapi/api.dart';

import 'generated/l10n.dart';

class CategoryAddingPage extends StatefulWidget {
  const CategoryAddingPage({Key? key}) : super(key: key);

  @override
  State<CategoryAddingPage> createState() => _CategoryAddingPageState();
}

class _CategoryAddingPageState extends State<CategoryAddingPage> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  String _icon = '😆';

  final DBHelper _dbHelper = DBHelper();

  final FToast _fToast = FToast();

  @override
  void initState() {
    super.initState();

    _fToast.init(context);
  }

  Future<bool> createCategory() async {
    try {
      final email = loadUserEmail();
      final apiInstance = CategoryApi(ApiClient(
        basePath: await loadServerAddr(),
      ));
      final req = CategoryPostReq(
          category: CategoryPostReqCategory(
        icon: _icon,
        name: _name,
      ));
      await apiInstance.createCategory(email, categoryPostReq: req);
      return true;
    } catch (e) {
      log(e.toString());
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).addCategory),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: S.of(context).name,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return S.of(context).categoryCannotBeEmpty;
                          }
                          _name = value;
                          return null;
                        },
                      ),
                      Positioned(
                          right: 0,
                          child: InkWell(
                            child: Text(_icon,
                                style: const TextStyle(fontSize: 32.0)),
                            onTap: () {
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return EmojiPicker(
                                      onEmojiSelected: (category, emoji) {
                                        setState(() {
                                          _icon = emoji.emoji;
                                        });
                                        Navigator.pop(context);
                                      },
                                      onBackspacePressed: () => {
                                        Navigator.pop(context),
                                      },
                                      config: const Config(
                                        columns: 8,
                                        emojiSizeMax: 32,
                                        buttonMode: ButtonMode.MATERIAL,
                                      ),
                                    );
                                  });
                            },
                          )),
                    ],
                  ),
                  const SizedBox(height: 32.0),
                  ElevatedButton(
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }
                        final success = await createCategory();
                        if (success) {
                          final category =
                              model.Category(name: _name, icon: _icon);
                          _dbHelper.insertCategory(category);
                          // toasts success
                          if (context.mounted) {
                            showToast(
                                context, S.of(context).addSuccessfully, false);
                            Navigator.pop(context);
                          }
                        } else {
                          if (context.mounted) {
                            showToast(context, S.of(context).addFailed, true);
                            Navigator.pop(context);
                          }
                        }
                      },
                      child: Text(S.of(context).save)),
                ],
              ),
            ),
          ),
        ]));
  }
}
