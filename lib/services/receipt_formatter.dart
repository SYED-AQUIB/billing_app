import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';

import '../models/bill_item_model.dart';
import '../models/bill_model.dart';
import '../models/shop_settings.dart';

/// Pure Dart utility that formats a saved bill into ESC/POS thermal printer bytes.
///
/// This formatter does not access database, Provider, BuildContext, or network/Bluetooth.
/// It uses the persisted [BillModel.createdAt] timestamp and never invokes [DateTime.now].
class ReceiptFormatter {
  const ReceiptFormatter._();

  /// Generates ESC/POS receipt bytes for the given [bill], [items], and optional [shopSettings].
  ///
  /// Supports [PaperSize.mm58] and [PaperSize.mm80].
  /// If [profile] is omitted, [CapabilityProfile.load] is used to load the default profile.
  static Future<List<int>> generateReceipt({
    required BillModel bill,
    required List<BillItemModel> items,
    ShopSettings? shopSettings,
    PaperSize paperSize = PaperSize.mm58,
    CapabilityProfile? profile,
  }) async {
    final effectiveProfile = profile ?? await CapabilityProfile.load();
    return formatBytes(
      bill: bill,
      items: items,
      shopSettings: shopSettings,
      paperSize: paperSize,
      profile: effectiveProfile,
    );
  }

  /// Synchronously converts bill data into ESC/POS bytes using the provided [profile].
  static List<int> formatBytes({
    required BillModel bill,
    required List<BillItemModel> items,
    ShopSettings? shopSettings,
    required PaperSize paperSize,
    required CapabilityProfile profile,
  }) {
    final generator = Generator(paperSize, profile);
    final maxWidth = getMaxChars(paperSize);
    List<int> bytes = [];

    // Initialize and reset printer
    bytes += generator.reset();

    // -----------------------------------------------------------------
    // 1. SHOP HEADER
    // -----------------------------------------------------------------
    if (shopSettings != null && shopSettings.shopName.trim().isNotEmpty) {
      final shopName = shopSettings.shopName.trim();
      final isShort = shopName.length <= (paperSize == PaperSize.mm58 ? 16 : 24);

      bytes += generator.text(
        shopName,
        styles: PosStyles(
          align: PosAlign.center,
          bold: true,
          height: isShort ? PosTextSize.size2 : PosTextSize.size1,
          width: isShort ? PosTextSize.size2 : PosTextSize.size1,
        ),
      );

      final owner = shopSettings.ownerName?.trim();
      if (owner != null && owner.isNotEmpty) {
        bytes += generator.text(
          'Prop: $owner',
          styles: const PosStyles(align: PosAlign.center),
        );
      }

      final address = shopSettings.shopAddress?.trim();
      if (address != null && address.isNotEmpty) {
        for (final line in wrapText(address, maxWidth)) {
          bytes += generator.text(
            line,
            styles: const PosStyles(align: PosAlign.center),
          );
        }
      }

      final phone = shopSettings.phoneNumber?.trim();
      if (phone != null && phone.isNotEmpty) {
        bytes += generator.text(
          'Ph: $phone',
          styles: const PosStyles(align: PosAlign.center),
        );
      }
    } else {
      bytes += generator.text(
        'RECEIPT',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
    }

    bytes += generator.hr();

    // -----------------------------------------------------------------
    // 2. BILL METADATA & PERSISTED TIMESTAMP
    // -----------------------------------------------------------------
    bytes += generator.text(
      'Bill No: ${bill.billNumber}',
      styles: const PosStyles(bold: true),
    );

    final dateStr = DateFormat('dd/MM/yyyy').format(bill.createdAt);
    final timeStr = DateFormat('hh:mm a').format(bill.createdAt);
    final dateTimeLine = twoColumnLine('Date: $dateStr', 'Time: $timeStr', maxWidth);

    if (dateTimeLine != null) {
      bytes += generator.text(dateTimeLine);
    } else {
      bytes += generator.text('Date: $dateStr');
      bytes += generator.text('Time: $timeStr');
    }

    // -----------------------------------------------------------------
    // 3. CUSTOMER DETAILS (Strictly omitted if missing)
    // -----------------------------------------------------------------
    final customerName = bill.customerName?.trim();
    final customerPhone = bill.customerPhone?.trim();
    final hasName = customerName != null && customerName.isNotEmpty;
    final hasPhone = customerPhone != null && customerPhone.isNotEmpty;

    if (hasName || hasPhone) {
      if (hasName) {
        for (final line in wrapText('Customer: $customerName', maxWidth)) {
          bytes += generator.text(line);
        }
      }
      if (hasPhone) {
        bytes += generator.text('Phone: $customerPhone');
      }
    }

    bytes += generator.hr();

    // -----------------------------------------------------------------
    // 4. BILL ITEMS
    // -----------------------------------------------------------------
    for (final item in items) {
      final brand = item.brand.trim();
      final productName = item.productName.trim();
      final title = brand.isNotEmpty ? '$productName ($brand)' : productName;

      // Print product title, cleanly wrapped if long
      for (final line in wrapText(title, maxWidth)) {
        bytes += generator.text(line, styles: const PosStyles(bold: true));
      }

      // Quantity x Unit Price and Line Total
      final qtyStr = item.quantity.toStringAsFixed(2);
      final unitStr = item.unitType.trim();
      final qtyUnit = unitStr.isNotEmpty ? '$qtyStr $unitStr' : qtyStr;
      final priceStr = 'Rs. ${item.pricePerUnit.toStringAsFixed(2)}';
      final totalStr = 'Rs. ${item.lineTotal.toStringAsFixed(2)}';

      final leftDetails = '  $qtyUnit x $priceStr';
      final itemRow = twoColumnLine(leftDetails, totalStr, maxWidth);

      if (itemRow != null) {
        bytes += generator.text(itemRow);
      } else {
        bytes += generator.text(leftDetails);
        bytes += generator.text(
          totalStr.padLeft(maxWidth),
          styles: const PosStyles(align: PosAlign.right),
        );
      }
    }

    bytes += generator.hr();

    // -----------------------------------------------------------------
    // 5. TOTALS
    // -----------------------------------------------------------------
    final subtotalStr = 'Rs. ${bill.subtotal.toStringAsFixed(2)}';
    final totalStr = 'Rs. ${bill.total.toStringAsFixed(2)}';

    final subtotalLine = twoColumnLine('Subtotal', subtotalStr, maxWidth);
    if (subtotalLine != null) {
      bytes += generator.text(subtotalLine);
    } else {
      bytes += generator.text('Subtotal: $subtotalStr');
    }

    final totalLine = twoColumnLine('TOTAL', totalStr, maxWidth);
    if (totalLine != null) {
      bytes += generator.text(totalLine, styles: const PosStyles(bold: true));
    } else {
      bytes += generator.text('TOTAL: $totalStr', styles: const PosStyles(bold: true));
    }

    bytes += generator.hr();

    // -----------------------------------------------------------------
    // 6. FOOTER & CUT
    // -----------------------------------------------------------------
    bytes += generator.text(
      'Thank You! Visit Again',
      styles: const PosStyles(align: PosAlign.center),
    );

    // cut() internally emits feed lines before cutting
    bytes += generator.cut();

    return bytes;
  }

  /// Returns the max monospace characters per line for the given paper size.
  static int getMaxChars(PaperSize paperSize) {
    return paperSize == PaperSize.mm58 ? 32 : 48;
  }

  /// Formats two strings flush-left and flush-right across [maxWidth].
  /// Returns null if the combined string exceeds [maxWidth].
  static String? twoColumnLine(String left, String right, int maxWidth) {
    final combinedLength = left.length + right.length;
    if (combinedLength > maxWidth) {
      return null;
    }
    final spaces = maxWidth - combinedLength;
    return '$left${' ' * spaces}$right';
  }

  /// Wraps a given string at word boundaries so that no line exceeds [maxWidth].
  /// Unbroken words longer than [maxWidth] are split safely.
  static List<String> wrapText(String text, int maxWidth) {
    if (text.isEmpty) {
      return const [''];
    }
    if (text.length <= maxWidth) {
      return [text];
    }

    final words = text.split(' ');
    final lines = <String>[];
    var currentLine = '';

    for (final word in words) {
      if (word.isEmpty) {
        continue;
      }

      if (currentLine.isEmpty) {
        if (word.length <= maxWidth) {
          currentLine = word;
        } else {
          var remaining = word;
          while (remaining.length > maxWidth) {
            lines.add(remaining.substring(0, maxWidth));
            remaining = remaining.substring(maxWidth);
          }
          currentLine = remaining;
        }
      } else if (currentLine.length + 1 + word.length <= maxWidth) {
        currentLine = '$currentLine $word';
      } else {
        lines.add(currentLine);
        if (word.length <= maxWidth) {
          currentLine = word;
        } else {
          var remaining = word;
          while (remaining.length > maxWidth) {
            lines.add(remaining.substring(0, maxWidth));
            remaining = remaining.substring(maxWidth);
          }
          currentLine = remaining;
        }
      }
    }

    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }

    return lines.isEmpty ? [text] : lines;
  }
}

