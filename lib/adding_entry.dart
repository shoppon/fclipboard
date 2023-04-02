import 'package:fclipboard/dao.dart';
import 'package:fclipboard/flutter_gen/gen_l10n/app_localizations.dart';
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
        title: Text(AppLocalizations.of(context).addEntry),
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
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).title),
                validator: (value) {
                  if (value == null) {
                    return AppLocalizations.of(context).titleCannotBeEmpty;
                  }
                  return null;
                },
                onChanged: (value) {
                  _title = value;
                },
              ),
              DropdownButtonFormField(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).category,
                  ),
                  items: buildDropdownMenuItems(),
                  onChanged: (value) {
                    setState(() {
                      _category = value;
                    });
                  }),
              TextFormField(
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).content,
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
                    showToast(context,
                        AppLocalizations.of(context).addSuccessfully, false);
                    Navigator.pop(context);
                  },
                  child: Text(AppLocalizations.of(context).save)),
            ],
          ),
        ),
      ),
    );
  }
}
