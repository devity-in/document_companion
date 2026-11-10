import 'dart:io';
import 'dart:typed_data';

import 'package:document_companion/modules/home/services/pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

Future<Uint8List> _pdf(List<String> pageTexts, {PdfPageFormat? format}) {
  final document = pw.Document();
  for (final text in pageTexts) {
    document.addPage(
      pw.Page(
        pageFormat: format ?? PdfPageFormat.a4,
        build: (_) => pw.Text(text, style: const pw.TextStyle(fontSize: 40)),
      ),
    );
  }
  return document.save();
}

List<String> _pageTexts(Uint8List bytes) {
  final document = sf.PdfDocument(inputBytes: bytes);
  final extractor = sf.PdfTextExtractor(document);
  final texts = [
    for (var i = 0; i < document.pages.count; i++)
      extractor.extractText(startPageIndex: i, endPageIndex: i).trim(),
  ];
  document.dispose();
  return texts;
}

void main() {
  late Directory root;

  setUp(() async => root = await Directory.systemTemp.createTemp('dc_pdf'));
  tearDown(() => root.delete(recursive: true));

  test('merge keeps every page, in order, with selectable text', () async {
    final first = File('${root.path}/a.pdf')
      ..writeAsBytesSync(await _pdf(['Alpha', 'Bravo']));
    final second = File('${root.path}/b.pdf')
      ..writeAsBytesSync(await _pdf(['Charlie'], format: PdfPageFormat.a5));

    final merged = await pdfService.mergePdfsFromFiles([first, second]);

    expect(_pageTexts(merged!), ['Alpha', 'Bravo', 'Charlie']);

    // Page sizes are preserved rather than forced to A4.
    final document = sf.PdfDocument(inputBytes: merged);
    expect(document.pages[0].size.width, closeTo(PdfPageFormat.a4.width, 1));
    expect(document.pages[2].size.width, closeTo(PdfPageFormat.a5.width, 1));
    document.dispose();
  });

  test('split returns one document per range with the right pages', () async {
    final source = await _pdf(['One', 'Two', 'Three', 'Four']);

    final parts = await pdfService.splitPdfByRanges(source, [
      PageRange(0, 0),
      PageRange(1, 3),
    ]);

    expect(parts, hasLength(2));
    expect(_pageTexts(parts[0]), ['One']);
    expect(_pageTexts(parts[1]), ['Two', 'Three', 'Four']);
  });

  test('page count', () async {
    expect(await pdfService.getPdfPageCount(await _pdf(['a', 'b', 'c'])), 3);
  });
}
