import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

Future<void> exportToCSV({
  required BuildContext context,
  required List<Map<String, dynamic>> rows,
  required List<String> headers,
  required String defaultFileName,
}) async {
  final result = await FilePicker.platform.saveFile(
    dialogTitle: 'Guardar CSV',
    fileName: defaultFileName,
    type: FileType.custom,
    allowedExtensions: ['csv'],
  );

  if (result == null) return;

  final data = [
    headers,
    ...rows.map((r) => headers.map((h) => r[h]?.toString() ?? '').toList()),
  ];

  final csv = const ListToCsvConverter().convert(data);
  await File(result).writeAsString(csv);

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exportado: $result')),
    );
  }
}
