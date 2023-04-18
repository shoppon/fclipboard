import 'package:fclipboard/flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fclipboard/model.dart';
import 'package:flutter/material.dart';

class SearchParamWidget extends StatefulWidget {
  const SearchParamWidget({
    super.key,
    required this.onChanged,
    required this.parameters,
    required this.focusNode,
  }) : super();

  final List<Param> parameters;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  @override
  State<SearchParamWidget> createState() => _SearchParamWidgetState();
}

class _SearchParamWidgetState extends State<SearchParamWidget> {
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
                hintText: AppLocalizations.of(context).searchHint,
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
                  visible: widget.parameters.isEmpty,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(AppLocalizations.of(context).noParameters),
                    ),
                  ),
                ),
                ...widget.parameters.map((entry) => Expanded(
                        child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              decoration:
                                  InputDecoration(labelText: entry.name),
                              controller:
                                  TextEditingController(text: entry.initial),
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
