
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/theme/app_colors.dart';

abstract final class ReceiptPdfGenerator {
  static final NumberFormat _money =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  static final DateFormat _date = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTime = DateFormat('dd/MM/yyyy HH:mm');

  static PdfColor _pdfColor(Color c) => PdfColor.fromInt(c.value);

  static double _num(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }

  static String _fmtDate(dynamic v) {
    if (v == null) return '—';
    final dt = DateTime.tryParse(v.toString());
    if (dt == null) return v.toString();
    return _date.format(dt);
  }

  static String _fmtDateTime(dynamic v) {
    if (v == null) return '—';
    final dt = DateTime.tryParse(v.toString());
    if (dt == null) return v.toString();
    return _dateTime.format(dt);
  }

  static Future<Uint8List> generate(Map<String, dynamic> receiptData) async {
    final pdf = pw.Document();
    final header = _pdfColor(AppColors.primary);
    final bodyText = _pdfColor(AppColors.textPrimary);
    final tableHeaderBg = _pdfColor(AppColors.primaryAccent);
    final border = _pdfColor(AppColors.border);

    final receipt = (receiptData['receipt'] is Map)
        ? Map<String, dynamic>.from(receiptData['receipt'] as Map)
        : <String, dynamic>{};
    final vendor = (receiptData['vendor'] is Map)
        ? Map<String, dynamic>.from(receiptData['vendor'] as Map)
        : <String, dynamic>{};
    final customer = (receiptData['customer'] is Map)
        ? Map<String, dynamic>.from(receiptData['customer'] as Map)
        : <String, dynamic>{};
    final subscription = (receiptData['subscription'] is Map)
        ? Map<String, dynamic>.from(receiptData['subscription'] as Map)
        : <String, dynamic>{};
    final summary = (receiptData['summary'] is Map)
        ? Map<String, dynamic>.from(receiptData['summary'] as Map)
        : <String, dynamic>{};
    final deliveries = (receiptData['deliveries'] as List?) ?? const [];
    final paymentHistory = (receiptData['paymentHistory'] as List?) ?? const [];

    // ── Dynamic vendor fields ──────────────────────────────────────
    final vendorName = '${vendor['businessName'] ?? 'Business'}';
    final vendorPhone = '${vendor['phone'] ?? ''}';          // fully dynamic
    final vendorEmail = '${vendor['email'] ?? ''}';
    final vendorAddress = '${vendor['address'] ?? ''}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (_) {
          return pw.DefaultTextStyle(
            style: pw.TextStyle(color: bodyText, fontSize: 10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [

                // ── HEADER ─────────────────────────────────────────
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 48,
                      height: 48,
                      alignment: pw.Alignment.center,
                      decoration: pw.BoxDecoration(
                        color: _pdfColor(AppColors.primaryContainer),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Text(
                        'LOGO',
                        style: pw.TextStyle(
                          color: header,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            vendorName,
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: header,
                            ),
                          ),
                          // ✅ vendor['phone'] dynamic — no hardcoding
                          pw.Text('$vendorPhone | $vendorEmail'),
                          pw.Text(vendorAddress),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Divider(color: border),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Receipt No: ${receipt['receiptNumber'] ?? '—'}'),
                    pw.Text('Date: ${_fmtDate(receipt['date'])}'),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Text('Generated: ${_fmtDateTime(receipt['generatedAt'])}'),
                pw.SizedBox(height: 10),

                // ── BILL TO ────────────────────────────────────────
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: _pdfColor(AppColors.surfaceContainer),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BILL TO',
                        style: pw.TextStyle(
                          color: header,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '${customer['name'] ?? '—'}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        '${customer['phone'] ?? ''} | ${customer['address'] ?? ''}',
                      ),
                      pw.Text(
                        'Customer Code: ${customer['customerCode'] ?? '—'}',
                      ),
                      pw.Text(
                        'Subscription: ${subscription['planName'] ?? ''} (${subscription['planType'] ?? ''})',
                      ),
                      pw.Text(
                        'Delivery Slot: ${subscription['deliverySlot'] ?? ''}',
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),

                // ── DELIVERIES ─────────────────────────────────────
                if (deliveries.isEmpty)
                  pw.Text('No deliveries recorded for this date')
                else
                  ...deliveries.whereType<Map>().map((slotRaw) {
                    final slot = Map<String, dynamic>.from(slotRaw);
                    final items = (slot['items'] as List?) ?? const [];
                    return pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        pw.Container(
                          color: tableHeaderBg,
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                '${slot['slot'] ?? 'MEAL'}'.toUpperCase(),
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Text(
                                'Subtotal: ${_money.format(_num(slot['slotTotal']))}',
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.Table(
                          border: pw.TableBorder.all(
                            color: border,
                            width: 0.4,
                          ),
                          columnWidths: const {
                            0: pw.FlexColumnWidth(2.2),
                            1: pw.FlexColumnWidth(0.6),
                            2: pw.FlexColumnWidth(0.8),
                            3: pw.FlexColumnWidth(1),
                            4: pw.FlexColumnWidth(1),
                          },
                          children: [
                            pw.TableRow(
                              decoration:
                                  pw.BoxDecoration(color: tableHeaderBg),
                              children: [
                                'Item Name',
                                'Qty',
                                'Unit',
                                'Unit Price',
                                'Total',
                              ]
                                  .map(
                                    (t) => pw.Padding(
                                      padding: const pw.EdgeInsets.all(4),
                                      child: pw.Text(
                                        t,
                                        style: pw.TextStyle(
                                          color: PdfColors.white,
                                          fontWeight: pw.FontWeight.bold,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            ...items.asMap().entries.map((entry) {
                              final i = entry.key;
                              final it = Map<String, dynamic>.from(
                                entry.value as Map,
                              );
                              final bg = i.isEven
                                  ? _pdfColor(AppColors.surface)
                                  : _pdfColor(AppColors.primaryContainer);
                              return pw.TableRow(
                                decoration: pw.BoxDecoration(color: bg),
                                children: [
                                  '${it['name'] ?? '—'}',
                                  '${it['quantity'] ?? '—'}',
                                  '${it['unit'] ?? '—'}',
                                  _money.format(_num(it['unitPrice'])),
                                  _money.format(_num(it['total'])),
                                ]
                                    .map(
                                      (t) => pw.Padding(
                                        padding: const pw.EdgeInsets.all(4),
                                        child: pw.Text(t),
                                      ),
                                    )
                                    .toList(),
                              );
                            }),
                          ],
                        ),
                        pw.SizedBox(height: 8),
                      ],
                    );
                  }),

                // ── SUMMARY ────────────────────────────────────────
                pw.Divider(color: border),
                _sumRow('Subtotal', _num(summary['subtotal'])),
                _sumRow('Tax (0%)', _num(summary['taxAmount'])),
                pw.Divider(color: border),
                _sumRow(
                  'Grand Total',
                  _num(summary['grandTotal']),
                  bold: true,
                  fontSize: 12,
                ),
                pw.Divider(color: border),
                _sumRow('Paid Amount', _num(summary['paidAmount'])),
                _sumRow('Amount Due', _num(summary['dueAmount'])),
                _sumRow('Running Balance', _num(summary['runningBalance'])),
                pw.Divider(color: border),

                // ── PAYMENT HISTORY ────────────────────────────────
                if (paymentHistory.isNotEmpty) ...[
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'RECENT PAYMENTS',
                    style: pw.TextStyle(
                      color: header,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Table(
                    border: pw.TableBorder.all(color: border, width: 0.4),
                    columnWidths: const {
                      0: pw.FlexColumnWidth(1.2),
                      1: pw.FlexColumnWidth(1),
                      2: pw.FlexColumnWidth(1),
                      3: pw.FlexColumnWidth(1.3),
                      4: pw.FlexColumnWidth(1),
                    },
                    children: [
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: tableHeaderBg),
                        children: [
                          'Date',
                          'Amount',
                          'Method',
                          'Ref ID',
                          'Status',
                        ]
                            .map(
                              (t) => pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(
                                  t,
                                  style: pw.TextStyle(
                                    color: PdfColors.white,
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 8.5,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      ...paymentHistory.whereType<Map>().map((pRaw) {
                        final p = Map<String, dynamic>.from(pRaw);
                        return pw.TableRow(
                          children: [
                            _fmtDate(p['date']),
                            _money.format(_num(p['amount'])),
                            '${p['method'] ?? ''}',
                            '${p['referenceId'] ?? ''}',
                            '${p['status'] ?? ''}',
                          ]
                              .map(
                                (t) => pw.Padding(
                                  padding: const pw.EdgeInsets.all(4),
                                  child: pw.Text(
                                    t,
                                    style: const pw.TextStyle(fontSize: 8.5),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      }),
                    ],
                  ),
                ],

                // ── FOOTER ─────────────────────────────────────────
                pw.Spacer(),
                pw.Divider(color: border),
                pw.Center(child: pw.Text('Thank you for your business!')),
                pw.Center(
                  child: pw.Text(
                    // ✅ businessName + phone — both from vendor map
                    '$vendorName · $vendorPhone',
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    'This is a computer generated receipt',
                    style: pw.TextStyle(
                      color: _pdfColor(AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _sumRow(
    String label,
    double value, {
    bool bold = false,
    double fontSize = 10,
  }) {
    final style = pw.TextStyle(
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontSize: fontSize,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(_money.format(value), style: style),
        ],
      ),
    );
  }
}