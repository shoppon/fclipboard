import 'package:fclipboard/dao.dart';
import 'package:fclipboard/generated/l10n.dart';
import 'package:fclipboard/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';

class ExportButton extends StatelessWidget {
  const ExportButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ProgressDialog pd = ProgressDialog(context: context);
    return PopupMenuButton(
      icon: const Icon(Icons.import_export),
      itemBuilder: (context) => [
        PopupMenuItem(
          child: TextButton(
            onPressed: () async {
              final msg = S.of(context).loading;
              String? output = await FilePicker.platform.saveFile(
                dialogTitle: S.of(context).export,
                fileName: 'fclipboard.yaml',
              );
              if (output == null) {
                return;
              }
              pd.show(msg: msg);
              await DBHelper().exportToFile(output);
              if (context.mounted) {
                Navigator.pop(context);
                showToast(context, S.of(context).exportSuccessfully, false);
              }
              pd.close();
            },
            child: Text(S.of(context).export),
          ),
        ),
        PopupMenuItem(
          child: TextButton(
            onPressed: () async {
              final msg = S.of(context).loading;
              FilePickerResult? result = await FilePicker.platform
                  .pickFiles(allowedExtensions: ['yaml']);
              if (result == null) {
                return;
              }
              pd.show(msg: msg);
              try {
                await DBHelper().importFromFile(result.files.single.path!);
                if (context.mounted) {
                  showToast(context, S.of(context).importSuccessfully, false);
                }
              } catch (e) {
                if (context.mounted) {
                  showToast(context, S.of(context).importFailed, true);
                }
              } finally {
                if (context.mounted) {
                  Navigator.pop(context);
                }
                pd.close();
              }
            },
            child: Text(S.of(context).import),
          ),
        ),
      ],
    );
  }
}
