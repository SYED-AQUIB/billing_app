import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';

import '../services/bluetooth_printer_service.dart';

/// Encapsulates the user's printer and paper size selection.
class PrinterSelectionResult {
  const PrinterSelectionResult({
    required this.printer,
    required this.paperSize,
  });

  final BluetoothInfo printer;
  final PaperSize paperSize;
}

/// Material 3 dialog that lists paired Bluetooth printers and allows selecting paper width.
class PrinterSelectionDialog extends StatefulWidget {
  const PrinterSelectionDialog({
    super.key,
    required this.printerService,
  });

  final BluetoothPrinterService printerService;

  @override
  State<PrinterSelectionDialog> createState() => _PrinterSelectionDialogState();
}

class _PrinterSelectionDialogState extends State<PrinterSelectionDialog> {
  bool _isLoading = true;
  String? _errorMessage;
  List<BluetoothInfo> _printers = [];
  BluetoothInfo? _selectedPrinter;
  PaperSize _selectedPaperSize = PaperSize.mm58;

  @override
  void initState() {
    super.initState();
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 1. Permission check
    final hasPermission = await widget.printerService.ensureBluetoothPermission();
    if (!hasPermission) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = widget.printerService.lastError ??
            'Bluetooth permission is required to connect to the printer.';
      });
      return;
    }

    // 2. Bluetooth power status
    final isEnabled = await widget.printerService.isBluetoothEnabled;
    if (!isEnabled) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = widget.printerService.lastError ??
            'Bluetooth is turned off. Please turn on Bluetooth in device settings.';
      });
      return;
    }

    // 3. Query paired printers
    final printers = await widget.printerService.getPairedPrinters();
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _printers = printers;
      if (printers.isEmpty) {
        _errorMessage = widget.printerService.lastError ??
            'No paired Bluetooth printers found. Please pair your thermal printer in Android Bluetooth settings first.';
      } else {
        _selectedPrinter = printers.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Printer'),
      content: SizedBox(
        width: double.maxFinite,
        child: _buildContent(context),
      ),
      actions: _buildActions(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 16),
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Checking paired printers...'),
          SizedBox(height: 16),
        ],
      );
    }

    if (_errorMessage != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paper Width',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Center(
            child: SegmentedButton<PaperSize>(
              segments: const [
                ButtonSegment<PaperSize>(
                  value: PaperSize.mm58,
                  label: Text('58 mm'),
                  icon: Icon(Icons.receipt_outlined),
                ),
                ButtonSegment<PaperSize>(
                  value: PaperSize.mm80,
                  label: Text('80 mm'),
                  icon: Icon(Icons.receipt_long_outlined),
                ),
              ],
              selected: {_selectedPaperSize},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _selectedPaperSize = newSelection.first;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Paired Printers',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          ..._printers.map((printer) {
            final isSelected = _selectedPrinter?.macAdress == printer.macAdress;
            final displayName = printer.name.trim().isNotEmpty
                ? printer.name.trim()
                : 'Bluetooth Printer';

            return ListTile(
              leading: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? Theme.of(context).colorScheme.primary : null,
              ),
              title: Text(
                displayName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                printer.macAdress,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              selected: isSelected,
              onTap: () {
                setState(() {
                  _selectedPrinter = printer;
                });
              },
            );
          }),
        ],
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    if (_errorMessage != null) {
      return [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: _loadPrinters,
          child: const Text('Retry'),
        ),
      ];
    }

    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(null),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _selectedPrinter == null
            ? null
            : () {
                Navigator.of(context).pop(
                  PrinterSelectionResult(
                    printer: _selectedPrinter!,
                    paperSize: _selectedPaperSize,
                  ),
                );
              },
        child: const Text('Print'),
      ),
    ];
  }
}

/// Helper function to display the [PrinterSelectionDialog].
Future<PrinterSelectionResult?> showPrinterSelectionDialog({
  required BuildContext context,
  required BluetoothPrinterService printerService,
}) {
  return showDialog<PrinterSelectionResult>(
    context: context,
    builder: (dialogContext) => PrinterSelectionDialog(printerService: printerService),
  );
}

