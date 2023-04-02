import 'package:fclipboard/dao.dart';
import 'package:fclipboard/flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fclipboard/model.dart';
import 'package:fclipboard/utils.dart';
import 'package:flutter/material.dart';

class ListingPage extends StatefulWidget {
  const ListingPage({Key? key}) : super(key: key);

  @override
  State<ListingPage> createState() => _ListingPageState();
}

class _ListingPageState extends State<ListingPage> {
  List<Entry> entries = [];
  final List<String> _categories = ['all'];

  String _category = 'all';

  final DBHelper _dbHelper = DBHelper();

  void loadCategories() async {
    final categories = await _dbHelper.categories();

    setState(() {
      for (var c in categories) {
        _categories.add(c.name);
      }
      if (_categories.isNotEmpty) {
        _category = _categories[0];
      }
    });
  }

  void loadEntries() async {
    final filter = _category == 'all' ? null : _category;
    final entries = await _dbHelper.entries(filter);

    setState(() {
      this.entries = entries;
    });
  }

  @override
  void initState() {
    super.initState();

    loadCategories();
    loadEntries();
  }

  List<DropdownMenuItem<String>> buildDropdownMenuItems() {
    List<DropdownMenuItem<String>> items = [];
    for (var c in _categories) {
      items.add(DropdownMenuItem(
        value: c,
        child: Text(c),
      ));
    }
    return items;
  }

  void deleteListItem(int index) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          var title = index == -1
              ? 'Delete category $_category'
              : 'Delete ${entries[index].title}';
          return AlertDialog(
            title: Text(title),
            content: Text(AppLocalizations.of(context).confirmDelete),
            actions: <Widget>[
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(AppLocalizations.of(context).cancel)),
              TextButton(
                onPressed: () {
                  // delete category
                  if (index == -1) {
                    if (entries.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              AppLocalizations.of(context).categoryNotEmpty)));
                    } else {
                      _dbHelper.deleteCategory(_category).then((value) {
                        setState(() {
                          _categories.remove(_category);
                          _category = _categories[0];
                        });
                        showToast(context,
                            AppLocalizations.of(context).deleteSuccess, false);
                      });
                    }
                  } else {
                    // delete entry
                    _dbHelper.deleteEntry(entries[index].title).then((value) {
                      setState(() {
                        entries.removeAt(index);
                      });
                      showToast(context,
                          AppLocalizations.of(context).deleteSuccess, false);
                    });
                  }
                  Navigator.of(context).pop();
                },
                child: Text(AppLocalizations.of(context).ok),
              )
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).listing),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: <Widget>[
                  Text(AppLocalizations.of(context).category),
                  IconButton(
                    onPressed: () {
                      deleteListItem(-1);
                    },
                    icon: const Icon(Icons.delete),
                  ),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _category,
                      onChanged: (String? newValue) {
                        setState(() {
                          _category = newValue!;
                          loadEntries();
                        });
                      },
                      isExpanded: true,
                      items: buildDropdownMenuItems(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
                child: ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, i) {
                      return Container(
                        color: Colors.white,
                        child: ListTile(
                          title: Text(entries[i].title),
                          subtitle: Text(entries[i].subtitle),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              deleteListItem(i);
                            },
                          ),
                          onTap: () {},
                        ),
                      );
                    }))
          ],
        ));
  }
}
