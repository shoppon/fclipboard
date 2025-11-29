import 'package:fclipboard/model.dart';
import 'package:fclipboard/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'generated/l10n.dart';

class SearchParamWidget extends StatefulWidget {
  const SearchParamWidget({
    super.key,
    required this.onChanged,
    required this.entry,
    required this.focusNode,
    required this.filters,
  }) : super();

  final ValueNotifier<Entry> entry;

  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final List<String> filters;

  @override
  State<SearchParamWidget> createState() => _SearchParamWidgetState();
}

class _SearchParamWidgetState extends State<SearchParamWidget> {
  Entry _entry = Entry.empty();
  final _formKey = GlobalKey<FormState>();
  bool _showParamsInput = true;

  final TextEditingController _controller = TextEditingController();
  String _prefix = '';
  String _filter = '';

  @override
  void initState() {
    super.initState();
    widget.entry.addListener(() {
      if (mounted) {
        setState(() {
          _entry = widget.entry.value;
        });
      }
    });

    _getMode();
  }

  void _getMode() async {
    final mode = await loadConfig('fclipboard.mode');
    setState(() {
      _showParamsInput = mode == 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _controller,
            focusNode: widget.focusNode,
            onChanged: widget.onChanged,
            onSubmitted: (value) {
              setState(() {
                if (_filter.isNotEmpty) {
                  _prefix = "$_prefix$value ";
                  _controller.text = '';
                  _filter = '';
                }
              });
            },
            decoration: InputDecoration(
                hintText: S.of(context).searchHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: PopupMenuButton(
                  icon: const Icon(Icons.search),
                  itemBuilder: (context) {
                    // return filters
                    return widget.filters
                        .map((e) => PopupMenuItem(
                              child: Text(e),
                              onTap: () {
                                setState(() {
                                  _prefix = "$_prefix  $e: ";
                                  _filter = e;
                                });
                              },
                            ))
                        .toList();
                  },
                ),
                prefix: Text(_prefix),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    setState(() {
                      _prefix = '';
                      _controller.text = '';
                    });
                  },
                )),
          ),
        ),
        // parameters input
        Visibility(
          visible: _showParamsInput,
          child: Container(
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
            ),
          ),
        )
      ],
    );
  }
}
