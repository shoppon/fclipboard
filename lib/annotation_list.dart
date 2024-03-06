import 'package:fclipboard/dao.dart';
import 'package:fclipboard/matcher.dart';
import 'package:fclipboard/model.dart';
import 'package:flutter/material.dart';

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

  final DBHelper _dbHelper = DBHelper();
  final _matcher = Matcher<Annotation>(50);

  @override
  void initState() {
    super.initState();

    _dbHelper.annotations().then((value) {
      setState(() {
        annotations = value;
        allAnnotations = value;
      });
    });

    widget.filterNotifier.addListener(() {
      _filterAnnotations(widget.filterNotifier.value);
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
        return ListTile(
            title: Text(
                "${annotations[index].book.title}/${annotations[index].book.author}"),
            subtitle: AnnotationItem(
              annotation: annotations[index],
            ),
            leading: CircleAvatar(
              backgroundColor: _getColor(annotations[index].color),
              radius: 24.0,
            ));
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
        )
      ],
    );
  }
}
