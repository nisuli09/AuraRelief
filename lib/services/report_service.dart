import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ReportService {
  static Future<void> generateMigraineReport(int days) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 📅 Calculate date FIRST
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));

    // 🔥 Fetch filtered data directly from Firestore
    final snapshot = await FirebaseFirestore.instance
        .collection('logs')
        .where('userId', isEqualTo: user.uid)
        .where('date', isGreaterThan: Timestamp.fromDate(startDate))
        .get();

    final data = snapshot.docs.map((doc) => doc.data()).toList();

    //  DEBUG
    debugPrint("Total docs: ${data.length}");

    final filteredData = data;

    //  DEBUG
    debugPrint("Filtered docs: ${filteredData.length}");

    if (filteredData.isEmpty) {
      throw Exception("No data available");
    }

    // 📊 Process Data
    int total = filteredData.length;

    double avgIntensity =
        filteredData
            .map((e) => (e['painLevel'] is int) ? e['painLevel'] : 0)
            .reduce((a, b) => a + b) /
        total;

    // 🔥 Trigger count
    Map<String, int> triggerCount = {};
    for (var item in filteredData) {
      List triggers = (item['triggers'] is List) ? item['triggers'] : [];

      for (var t in triggers) {
        triggerCount[t] = (triggerCount[t] ?? 0) + 1;
      }
    }

    // Sort triggers
    var sortedTriggers = triggerCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 📅 Date formatting
    final dateFormat = DateFormat('yyyy-MM-dd');

    // 📄 Create PDF
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          // 🧾 Title
          pw.Text(
            "Migraine Report",
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 10),

          pw.Text("User ID: ${user.uid}"),
          pw.Text("Generated on: ${dateFormat.format(DateTime.now())}"),

          pw.Divider(),

          // 📊 Summary
          pw.Text("Summary", style: pw.TextStyle(fontSize: 18)),

          pw.Text("Total Migraine Days: $total"),
          pw.Text("Average Pain Level: ${avgIntensity.toStringAsFixed(1)}"),

          pw.SizedBox(height: 10),

          pw.Text("Top Triggers:"),

          ...sortedTriggers
              .take(3)
              .map((e) => pw.Text("${e.key} (${e.value} times)")),

          pw.Divider(),

          // 📋 Detailed Records
          pw.Text("Detailed Records", style: pw.TextStyle(fontSize: 18)),

          pw.SizedBox(height: 10),

          pw.TableHelper.fromTextArray(
            headers: ["Date", "Pain Level", "Triggers"],
            data: filteredData.map((e) {
              final date = (e['date'] is Timestamp)
                  ? (e['date'] as Timestamp).toDate()
                  : DateTime.now();

              final pain = (e['painLevel'] is int) ? e['painLevel'] : 0;

              final triggers = (e['triggers'] is List) ? e['triggers'] : [];

              return [
                dateFormat.format(date),
                pain.toString(),
                triggers.join(", "),
              ];
            }).toList(),
          ),
        ],
      ),
    );

    // 📤 Show / Share PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'migraine_report.pdf',
    );
  }
}
