import 'package:fclipboard/dao.dart';
import 'package:fclipboard/model.dart';
import 'package:fclipboard/utils.dart';
import 'package:flutter/material.dart';

class EntryAddingPage extends StatefulWidget {
  const EntryAddingPage({Key? key}) : super(key: key);

  @override
  State<EntryAddingPage> createState() => _EntryAddingPageState();
}

class _EntryAddingPageState extends State<EntryAddingPage> {
  final _formKey = GlobalKey<FormState>();

  String _title = '';
  String _content = '';
  Category _category = Category(name: 'all', icon: '😆');

  final List<Category> _categories = [];

  final DBHelper _dbHelper = DBHelper();

  List<DropdownMenuItem> buildDropdownMenuItems() {
    List<DropdownMenuItem> items = [];
    for (var c in _categories) {
      items.add(DropdownMenuItem(
        value: c,
        child: Text(c.name),
      ));
    }
    return items;
  }

  @override
  void initState() {
    super.initState();

    loadCategories();
  }

  void loadCategories() async {
    final categories = await _dbHelper.categories();

    setState(() {
      for (var c in categories) {
        _categories.add(c);
      }
    });
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
                      _category = value;
                    });
                  }),
              TextFormField(
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  labelText: 'Content',
                ),
                onChanged: (value) {
                  _content = value;
                },
                minLines: 5,
                maxLines: 5,
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                  onPressed: () {
                    final entry = Entry(
                        title: _title,
                        subtitle: _content,
                        counter: 0,
                        categoryId: _category.id);
                    _dbHelper.insertEntry(entry);
                    // toasts success
                    showToast(context, "Added successfully", false);
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
