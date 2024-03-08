import 'package:fclipboard/dao.dart';
import 'package:fclipboard/matcher.dart';
import 'package:fclipboard/model.dart';
import 'package:fclipboard/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AnnotationListView extends StatefulWidget {
  const AnnotationListView({
    Key? key,
    required this.filterNotifier,
  }) : super(key: key);

  final ValueNotifier<String> filterNotifier;

  @override
  State<AnnotationListView> createState() => _AnnotationListViewState();
}

class _AnnotationListViewState extends State<AnnotationListView> {
  List<Annotation> annotations = [];
  List<Annotation> allAnnotations = [];
  int selected = -1;

  final DBHelper _dbHelper = DBHelper();
  final _matcher = Matcher<Annotation>(50);

  @override
  void initState() {
    super.initState();

    _dbHelper.annotations().then((value) {
      setState(() {
        annotations = value;
        allAnnotations = value;
        selected = -1;
      });
    });

    widget.filterNotifier.addListener(() {
      if (mounted) {
        _filterAnnotations(widget.filterNotifier.value);
      }
    });
  }

  void _filterAnnotations(String searchText) async {
    _matcher.reset(allAnnotations);
    var matches = _matcher.match(
      searchText,
      (Annotation e) => [e.selected, e.highlight, e.book.title, e.book.author],
    );
    setState(() {
      annotations = matches;
      selected = -1;
    });
  }

  Color _getColor(int color) {
    switch (color) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.yellow;
      case 4:
        return Colors.red;
      case 5:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: annotations.length,
      itemBuilder: (context, index) {
        return Container(
          color: getColor(selected, index),
          child: ListTile(
            subtitle: AnnotationItem(
              annotation: annotations[index],
            ),
            leading: CircleAvatar(
              backgroundColor: _getColor(annotations[index].color),
              radius: 24.0,
            ),
            onTap: () {
              Clipboard.setData(
                ClipboardData(text: annotations[index].selected),
              );
              setState(() {
                selected = index;
              });
            },
          ),
        );
      },
      separatorBuilder: (context, index) {
        return const Divider(
          color: Colors.grey,
        );
      },
    );
  }
}

class AnnotationItem extends StatelessWidget {
  const AnnotationItem({
    Key? key,
    required this.annotation,
  }) : super(key: key);

  final Annotation annotation;

  String calcTime(double createdAt) {
    final baseTime = DateTime.parse("2001-01-01 00:00:00");
    final resultTime = baseTime
        .add(Duration(seconds: createdAt.toInt()))
        .add(const Duration(hours: 8));
    DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    return dateFormat.format(resultTime);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.format_quote),
            const SizedBox(
              width: 8,
            ),
            Expanded(
              child: Text(
                annotation.selected,
                maxLines: 10,
                overflow: TextOverflow.ellipsis,
              ),
            )
          ],
        ),
        Divider(
          color: Colors.grey.shade400,
          thickness: 0.5,
        ),
        Row(
          children: [
            const Icon(Icons.brush),
            const SizedBox(
              width: 8,
            ),
            Expanded(
              child: Text(
                annotation.highlight,
                textAlign: TextAlign.start,
              ),
            ),
          ],
        ),
        Divider(
          color: Colors.grey.shade400,
          thickness: 0.5,
        ),
        Row(
          children: [
            const Icon(Icons.date_range),
            const SizedBox(
              width: 8,
            ),
            Expanded(
              child: Text(
                "${calcTime(annotation.createdAt)} <${annotation.book.title}> ${annotation.book.author}",
              ),
            ),
          ],
        )
      ],
    );
  }
}
