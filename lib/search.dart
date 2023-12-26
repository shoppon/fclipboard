import 'package:fclipboard/dao.dart';
import 'package:fclipboard/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'generated/l10n.dart';

class SearchParamWidget extends StatefulWidget {
  const SearchParamWidget({
    super.key,
    required this.onChanged,
    required this.entry,
    required this.focusNode,
  }) : super();

  final ValueNotifier<Entry> entry;

  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  @override
  State<SearchParamWidget> createState() => _SearchParamWidgetState();
}

class _SearchParamWidgetState extends State<SearchParamWidget> {
  Entry _entry = Entry.empty();
  final _formKey = GlobalKey<FormState>();
  final DBHelper _dbHelper = DBHelper();

  @override
  void initState() {
    super.initState();
    widget.entry.addListener(() {
      setState(() {
        _entry = widget.entry.value;
      });
    });
  }

  Future<List<Category>> _loadCategories() async {
    final categories = _dbHelper.categories();
    return categories;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              focusNode: widget.focusNode,
              onChanged: widget.onChanged,
              decoration: InputDecoration(
                hintText: S.of(context).searchHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: FutureBuilder<List<Category>>(
                  future: _loadCategories(),
                  builder: (
                    BuildContext context,
                    AsyncSnapshot<List<Category>> snapshot,
                  ) {
                    if (!snapshot.hasData || snapshot.data == null) {
                      return const Icon(Icons.error);
                    }
                    return PopupMenuButton(
                      icon: const Icon(Icons.category_sharp),
                      itemBuilder: (BuildContext context) {
                        List<PopupMenuItem> items = [];
                        for (var c in snapshot.data!) {
                          items.add(PopupMenuItem(
                            value: c.name,
                            child: Text(c.name),
                          ));
                        }
                        return items;
                      },
                      onSelected: (value) {
                        widget.onChanged!("#category:$value");
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          Container(
              height: 96,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
              child: Form(
                key: _formKey,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Visibility(
                      visible: _entry.parameters.isEmpty,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(S.of(context).noParameters),
                        ),
                      ),
                    ),
                    ..._entry.parameters.map((param) => Expanded(
                            child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextFormField(
                                    decoration: InputDecoration(
                                        labelText: param.description.isEmpty
                                            ? (param.required
                                                ? '* ${param.name}'
                                                : param.name)
                                            : (param.required
                                                ? '* ${param.description}'
                                                : param.description)),
                                    initialValue: param.initial,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return S.of(context).required;
                                      }
                                      param.current = value;
                                      return null;
                                    },
                                    onEditingComplete: () {
                                      if (!_formKey.currentState!.validate()) {
                                        return;
                                      }
                                      var subtitle = _entry.subtitle;
                                      final params = _entry.parameters;
                                      for (var p in params) {
                                        if (p.current.isNotEmpty) {
                                          subtitle = subtitle.replaceAll(
                                              p.name, p.current);
                                        }
                                      }
                                      Clipboard.setData(
                                          ClipboardData(text: subtitle));
                                    }),
                              ),
                            )
                          ],
                        )))
                  ],
                ),
              )),
        ]);
  }
}
