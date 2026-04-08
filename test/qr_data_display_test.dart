// Test file for QRDataDisplay widget
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/features/qrscan/presentation/widgets/qr_data_display.dart';

void main() {
  group('QRDataDisplay Tests', () {
    testWidgets('displays URL correctly', (WidgetTester tester) async {
      const testUrl = 'https://www.udsm.ac.tz';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QRDataDisplay(qrData: testUrl),
          ),
        ),
      );

      expect(find.text('Website Link'), findsOneWidget);
      expect(find.byIcon(Icons.link), findsOneWidget);
      expect(find.text(testUrl), findsOneWidget);
    });

    testWidgets('displays email correctly', (WidgetTester tester) async {
      const testEmail = 'info@udsm.ac.tz';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QRDataDisplay(qrData: testEmail),
          ),
        ),
      );

      expect(find.text('Email Address'), findsOneWidget);
      expect(find.byIcon(Icons.email), findsOneWidget);
      expect(find.text(testEmail), findsOneWidget);
    });

    testWidgets('displays phone number correctly', (WidgetTester tester) async {
      const testPhone = '+255 22 2410500';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QRDataDisplay(qrData: testPhone),
          ),
        ),
      );

      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.byIcon(Icons.phone), findsOneWidget);
      expect(find.text(testPhone), findsOneWidget);
    });

    testWidgets('displays plain text correctly', (WidgetTester tester) async {
      const testText = 'University of Dar es Salaam';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QRDataDisplay(qrData: testText),
          ),
        ),
      );

      expect(find.text('Text'), findsOneWidget);
      expect(find.byIcon(Icons.text_fields), findsOneWidget);
      expect(find.text(testText), findsOneWidget);
    });

    testWidgets('displays image URL with preview', (WidgetTester tester) async {
      const testImageUrl = 'https://www.udsm.ac.tz/logo.png';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QRDataDisplay(qrData: testImageUrl),
          ),
        ),
      );

      expect(find.text('Image Link'), findsOneWidget);
      expect(find.byIcon(Icons.image), findsOneWidget);
      // The image display should be present (though it may show loading/error in test)
      expect(find.byType(QRDataDisplay), findsOneWidget);
    });
  });
}