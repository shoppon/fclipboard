import 'package:fclipboard/dao.dart';
import 'package:fclipboard/flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fclipboard/model.dart';
import 'package:fclipboard/utils.dart';
import 'package:flutter/material.dart';

class EntryAddingPage extends StatefulWidget {
  const EntryAddingPage({Key? key, required this.entry}) : super(key: key);

  final Entry entry;

  @override
  State<EntryAddingPage> createState() => _EntryAddingPageState();
}

class _EntryAddingPageState extends State<EntryAddingPage> {
  final _formKey = GlobalKey<FormState>();

  _EntryAddingPageState();

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
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context).titleCannotBeEmpty;
                  }
                  _title = value;
                  return null;
                },
                initialValue: widget.entry.title,
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
                          (element) => element.id == widget.entry.categoryId,
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
                initialValue: widget.entry.subtitle,
              ),
              const SizedBox(height: 16.0),
              ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.entry.parameters.length,
                  itemBuilder: (BuildContext context, index) {
                    return ParameterInput(
                        parameter: widget.entry.parameters[index],
                        onDelete: () {
                          setState(() {
                            widget.entry.parameters.removeAt(index);
                          });
                        });
                  }),
              const SizedBox(height: 16.0),
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      widget.entry.parameters.add(Param());
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
                      id: widget.entry.id,
                      title: _title,
                      subtitle: _content,
                      counter: 0,
                      categoryId: _category.id,
                      parameters: widget.entry.parameters,
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
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
                key: GlobalKey<FormState>(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'name'),
                      onChanged: (value) {
                        widget.parameter.name = value;
                      },
                      initialValue: widget.parameter.name,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'initial'),
                      onChanged: (value) {
                        widget.parameter.initial = value;
                      },
                      initialValue: widget.parameter.initial,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                            onPressed: widget.onDelete,
                            child: const Text('delete'))
                      ],
                    )
                  ],
                ))));
  }
}
