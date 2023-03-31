import 'package:fclipboard/dao.dart';
import 'package:fclipboard/model.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AddingPage extends StatefulWidget {
  const AddingPage({Key? key}) : super(key: key);

  @override
  State<AddingPage> createState() => _AddingPageState();
}

class _AddingPageState extends State<AddingPage> {
  final _formKey = GlobalKey<FormState>();

  String _title = '';
  String _content = '';
  String _category = '';

  final List<String> _categories = [];

  final DBHelper _dbHelper = DBHelper();

  final FToast _fToast = FToast();

  List<DropdownMenuItem> buildDropdownMenuItems() {
    List<DropdownMenuItem> items = [];
    for (var c in _categories) {
      items.add(DropdownMenuItem(
        value: c,
        child: Text(c),
      ));
    }
    return items;
  }

  @override
  void initState() {
    super.initState();

    _fToast.init(context);

    loadCategories();
  }

  void loadCategories() async {
    final categories = await _dbHelper.categories();

    setState(() {
      for (var c in categories) {
        _categories.add(c.name);
      }
    });
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null) {
                    return 'Please enter some text';
                  }
                  return null;
                },
                onChanged: (value) {
                  _title = value;
                },
              ),
              DropdownButtonFormField(
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                  items: buildDropdownMenuItems(),
                  onChanged: (value) {
                    setState(() {
                      _category = value.toString();
                    });
                  }),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Content'),
                onChanged: (value) {
                  _content = value;
                },
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                  onPressed: () {
                    final entry = Entry(
                        title: _title, subtitle: _content, category: _category);
                    _dbHelper.insertEntry(entry);
                    // toasts success
                    showToast("Added successfully");
                    Navigator.pop(context);
                  },
                  child: const Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}
