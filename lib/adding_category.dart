import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:fclipboard/dao.dart';
import 'package:fclipboard/model.dart' as model;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

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

  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();

    _fToast.init(context);
  }

  void showToast(String content) {
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: Colors.greenAccent,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check),
          const SizedBox(
            width: 12.0,
          ),
          Text(content),
        ],
      ),
    );

    _fToast.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Adding'),
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
                        decoration: const InputDecoration(
                          labelText: 'Name',
                        ),
                        validator: (value) {
                          if (value == null) {
                            return 'Please enter some text';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          _name = value;
                        },
                      ),
                      Positioned(
                          right: 0,
                          child: InkWell(
                            child: Text(_icon,
                                style: const TextStyle(fontSize: 32.0)),
                            onTap: () {
                              setState(() {
                                _showEmojiPicker = true;
                              });
                            },
                          )),
                    ],
                  ),
                  const SizedBox(height: 32.0),
                  ElevatedButton(
                      onPressed: () {
                        final category =
                            model.Category(name: _name, icon: _icon);
                        _dbHelper.insertCategory(category);
                        // toasts success
                        showToast("Added successfully");
                        Navigator.pop(context);
                      },
                      child: const Text('Save')),
                ],
              ),
            ),
          ),
          Offstage(
              offstage: !_showEmojiPicker,
              child: SizedBox(
                height: 300,
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    _icon = emoji.emoji;
                    setState(() {
                      _showEmojiPicker = false;
                    });
                  },
                  onBackspacePressed: () => {
                    setState(() {
                      _showEmojiPicker = false;
                    })
                  },
                  config: const Config(
                    columns: 7,
                    emojiSizeMax: 32,
                    buttonMode: ButtonMode.MATERIAL,
                  ),
                ),
              ))
        ]));
  }
}
