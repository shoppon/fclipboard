import 'package:fclipboard/dao.dart';
import 'package:fclipboard/flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fclipboard/model.dart';
import 'package:fclipboard/utils.dart';
import 'package:flutter/material.dart';

class EntryAddingPage extends StatefulWidget {
  const EntryAddingPage({Key? key, this.old}) : super(key: key);

  final Entry? old;

  @override
  State<EntryAddingPage> createState() => _EntryAddingPageState();
}

class _EntryAddingPageState extends State<EntryAddingPage> {
  final _formKey = GlobalKey<FormState>();

  _EntryAddingPageState();

  String _title = '';
  String _content = '';
  Category _category = Category(name: 'all', icon: '😆');
  List<Param> parameters = [];

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
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context).titleCannotBeEmpty;
                  }
                  _title = value;
                  return null;
                },
                initialValue: widget.old == null ? '' : '${widget.old?.title}',
              ),
              DropdownButtonFormField(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).category,
                  ),
                  items: buildDropdownMenuItems(),
                  validator: (value) {
                    if (value == null) {
                      return AppLocalizations.of(context).categoryCannotBeEmpty;
                    }
                    _category = value;
                    return null;
                  },
                  value: _categories.isNotEmpty
                      ? _categories.firstWhere(
                          (element) => element.id == widget.old?.categoryId,
                          orElse: () {
                            return _categories[0];
                          },
                        )
                      : null,
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context).contentCannotBeEmpty;
                  }
                  _content = value;
                  return null;
                },
                minLines: 5,
                maxLines: 5,
                initialValue:
                    widget.old == null ? '' : '${widget.old?.subtitle}',
              ),
              const SizedBox(height: 16.0),
              ListView.builder(
                  shrinkWrap: true,
                  itemCount: parameters.length,
                  itemBuilder: (BuildContext context, index) {
                    return ParameterInput(
                        parameter: parameters[index],
                        onDelete: () {
                          setState(() {
                            parameters.removeAt(index);
                          });
                        });
                  }),
              const SizedBox(height: 16.0),
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      parameters.add(Param());
                    });
                  },
                  child: const Text('add')),
              const SizedBox(height: 16.0),
              ElevatedButton(
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }
                    final entry = Entry(
                      title: _title,
                      subtitle: _content,
                      counter: 0,
                      categoryId: _category.id,
                      parameters: parameters,
                    );
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

class ParameterInput extends StatefulWidget {
  final Param parameter;
  final VoidCallback onDelete;

  const ParameterInput(
      {super.key, required this.parameter, required this.onDelete});

  @override
  State<ParameterInput> createState() => _ParameterInputState();
}

class _ParameterInputState extends State<ParameterInput> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _initialController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'name'),
                  onChanged: (value) {
                    widget.parameter.name = value;
                  },
                ),
                TextField(
                  controller: _initialController,
                  decoration: const InputDecoration(labelText: 'initial'),
                  onChanged: (value) {
                    widget.parameter.initial = value;
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: widget.onDelete, child: const Text('delete'))
                  ],
                )
              ],
            )));
  }
}
