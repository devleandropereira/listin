import 'dart:async';

import 'package:flutter/material.dart';

Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String content,
}) async {
  final result = await showDialog<bool?>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Atenção"),
        content: Text(content),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              textStyle: Theme.of(context).textTheme.labelLarge
            ),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text("Cancelar"),
          ),
          TextButton(
            style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge
            ),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text("Confirmar"),
          )
        ],
      );
    },
  );

  return result ?? false;
}
