import 'package:fclipboard/model.dart';
import 'package:flutter/material.dart';

import 'generated/l10n.dart';

class SearchParamWidget extends StatefulWidget {
  const SearchParamWidget({
    super.key,
    required this.onChanged,
    required this.entry,
    required this.focusNode,
    required this.onEditingComplete,
  }) : super();

  final ValueNotifier<Entry> entry;

  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final VoidCallback? onEditingComplete;

  @override
  State<SearchParamWidget> createState() => _SearchParamWidgetState();
}

class _SearchParamWidgetState extends State<SearchParamWidget> {
  Entry _entry = Entry.empty();

  @override
  void initState() {
    super.initState();
    widget.entry.addListener(() {
      setState(() {
        _entry = widget.entry.value;
      });
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
              focusNode: widget.focusNode,
              onChanged: widget.onChanged,
              decoration: InputDecoration(
                hintText: S.of(context).searchHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
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
                            child: TextField(
                              decoration:
                                  InputDecoration(labelText: param.name),
                              controller:
                                  TextEditingController(text: param.initial),
                              onChanged: (value) {
                                param.current = value;
                              },
                              onEditingComplete: widget.onEditingComplete,
                            ),
                          ),
                        )
                      ],
                    )))
              ],
            ),
          ),
        ]);
  }
}
