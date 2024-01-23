import 'package:fclipboard/dao.dart';
import 'package:fclipboard/generated/l10n.dart';
import 'package:fclipboard/model.dart';
import 'package:fclipboard/utils.dart';
import 'package:flutter/material.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';

import 'package:openapi/api.dart' as s;

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

  Future<s.Entry?> _getServerEntry(String eid) async {
    final api = s.EntryApi(s.ApiClient(basePath: await loadServerAddr()));
    final email = loadUserEmail();
    try {
      final resp = await api.getEntry(email, eid);
      return resp!.entry!;
    } on s.ApiException catch (e) {
      if (e.code == 404) {
        return null;
      } else {
        rethrow;
      }
    }
  }

  Future<bool> _updateServerEntry(Entry entry) async {
    final api = s.EntryApi(s.ApiClient(basePath: await loadServerAddr()));
    final email = loadUserEmail();
    try {
      final req = s.EntryPatchReq(
          entry: s.EntryBody(
              name: entry.title,
              content: entry.subtitle,
              counter: entry.counter,
              version: entry.version,
              parameters: entry.parameters
                  .map((e) => s.Parameter.fromJson(e.toJson())!)
                  .toList()));
      await api.updateEntry(email, entry.uuid, entryPatchReq: req);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).addEntry),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextFormField(
                    decoration: InputDecoration(labelText: S.of(context).title),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return S.of(context).titleCannotBeEmpty;
                      }
                      _title = value;
                      return null;
                    },
                    initialValue: widget.entry.title,
                  ),
                  DropdownButtonFormField(
                      decoration: InputDecoration(
                        labelText: S.of(context).category,
                      ),
                      items: buildDropdownMenuItems(),
                      validator: (value) {
                        if (value == null) {
                          return S.of(context).categoryCannotBeEmpty;
                        }
                        _category = value;
                        return null;
                      },
                      value: _categories.isNotEmpty
                          ? _categories.firstWhere(
                              (element) =>
                                  element.id == widget.entry.categoryId,
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
                      labelText: S.of(context).content,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return S.of(context).contentCannotBeEmpty;
                      }
                      _content = value;
                      return null;
                    },
                    minLines: 5,
                    maxLines: 20,
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
                      child: Text(S.of(context).addParameter)),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }
                        ProgressDialog pd = ProgressDialog(context: context);
                        pd.show(msg: S.of(context).loading);

                        // build entry
                        final entry = Entry(
                          id: widget.entry.id,
                          uuid: widget.entry.uuid,
                          title: _title,
                          subtitle: _content,
                          counter: widget.entry.counter,
                          categoryId: _category.id,
                          parameters: widget.entry.parameters,
                        );

                        try {
                          final se = await _getServerEntry(widget.entry.uuid);
                          if (se == null) {
                            await _updateServerEntry(entry);
                            await _dbHelper.insertEntry(entry);
                          } else {
                            if (se.version != widget.entry.version) {
                              if (context.mounted) {
                                showToast(
                                  context,
                                  S.of(context).addFailed,
                                  true,
                                );
                              }
                              throw Exception('conflict');
                            } else {
                              // must update server entry first to avoid conflict
                              final success = await _updateServerEntry(entry);
                              if (!success) {
                                if (context.mounted) {
                                  showToast(
                                    context,
                                    S.of(context).addFailed,
                                    true,
                                  );
                                }
                                throw Exception('update failed');
                              }
                              await _dbHelper.insertEntry(entry);
                            }
                          }

                          // toasts success
                          if (context.mounted) {
                            showToast(
                              context,
                              S.of(context).addSuccessfully,
                              false,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            showToast(
                              context,
                              S.of(context).addFailed,
                              true,
                            );
                          }
                        } finally {
                          pd.close();
                        }
                      },
                      child: Text(S.of(context).save)),
                ],
              ),
            ),
          )),
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
                      decoration:
                          InputDecoration(labelText: S.of(context).name),
                      onChanged: (value) {
                        widget.parameter.name = value;
                      },
                      initialValue: widget.parameter.name,
                    ),
                    TextFormField(
                      decoration:
                          InputDecoration(labelText: S.of(context).description),
                      onChanged: (value) {
                        widget.parameter.description = value;
                      },
                      initialValue: widget.parameter.description,
                    ),
                    TextFormField(
                      decoration:
                          InputDecoration(labelText: S.of(context).initial),
                      onChanged: (value) {
                        widget.parameter.initial = value;
                      },
                      initialValue: widget.parameter.initial,
                    ),
                    Row(
                      children: [
                        Checkbox(
                            value: widget.parameter.required,
                            onChanged: (value) {
                              setState(() {
                                widget.parameter.required = value!;
                              });
                            }),
                        Text(S.of(context).required)
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                            onPressed: widget.onDelete,
                            child: Text(S.of(context).delete))
                      ],
                    )
                  ],
                ))));
  }
}
