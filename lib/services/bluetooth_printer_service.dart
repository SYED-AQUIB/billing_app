import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

export 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart' show BluetoothInfo;

/// Exception thrown when a Bluetooth printer operation encounters an error.
class PrinterException implements Exception {
  const PrinterException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Service dedicated exclusively to Bluetooth printer discovery, connection,
/// and byte transmission.
///
/// This service does not contain receipt formatting, billing, or database logic.
/// It interacts with already paired Android Bluetooth printers using RFCOMM/SPP.
class BluetoothPrinterService {
  String? _lastError;

  /// The most recent user-friendly error message if an operation failed.
  String? get lastError => _lastError;

  /// Clears the current recorded error message.
  void clearError() {
    _lastError = null;
  }

  /// Ensures that Bluetooth permission is granted.
  ///
  /// On Android 12+ (API 31+), requests [Permission.bluetoothConnect] at runtime.
  /// On Android <= 11, verifies install-time Bluetooth permission via the plugin.
  Future<bool> ensureBluetoothPermission() async {
    try {
      if (await PrintBluetoothThermal.isPermissionBluetoothGranted) {
        return true;
      }

      final status = await Permission.bluetoothConnect.request();
      if (status.isGranted) {
        return true;
      }

      final isGranted = await PrintBluetoothThermal.isPermissionBluetoothGranted;
      if (!isGranted) {
        _lastError = 'Bluetooth permission is required to connect to the printer. Please allow nearby devices / Bluetooth permission in settings.';
        return false;
      }

      return true;
    } catch (e) {
      _lastError = 'Failed to verify Bluetooth permission: $e';
      return false;
    }
  }

  /// Checks whether device Bluetooth is currently turned on.
  Future<bool> get isBluetoothEnabled async {
    try {
      final enabled = await PrintBluetoothThermal.bluetoothEnabled;
      if (!enabled) {
        _lastError = 'Bluetooth is turned off. Please turn on Bluetooth in device settings.';
        return false;
      }
      return true;
    } catch (e) {
      _lastError = 'Failed to check Bluetooth status: $e';
      return false;
    }
  }

  /// Returns the list of printers already paired in Android Bluetooth settings.
  ///
  /// Does not scan for unpaired devices.
  Future<List<BluetoothInfo>> getPairedPrinters() async {
    try {
      final devices = await PrintBluetoothThermal.pairedBluetooths;
      if (devices.isEmpty) {
        _lastError = 'No paired Bluetooth printers found. Please pair your thermal printer in Android Bluetooth settings first.';
      }
      return devices;
    } catch (e) {
      _lastError = 'Failed to fetch paired printers: $e';
      return [];
    }
  }

  /// Connects to a selected paired printer using its MAC address.
  Future<bool> connect(BluetoothInfo printer) async {
    try {
      final mac = printer.macAdress.trim();
      if (mac.isEmpty) {
        _lastError = 'Invalid printer address.';
        return false;
      }

      final connected = await PrintBluetoothThermal.connect(
        macPrinterAddress: mac,
      );

      if (!connected) {
        final displayName = printer.name.trim().isNotEmpty ? printer.name : 'printer';
        _lastError = 'Could not connect to $displayName. Please ensure the printer is turned on and in range.';
        return false;
      }

      return true;
    } catch (e) {
      _lastError = 'Connection error: $e';
      return false;
    }
  }

  /// Checks if currently connected to a printer.
  Future<bool> get isConnected async {
    try {
      return await PrintBluetoothThermal.connectionStatus;
    } catch (e) {
      _lastError = 'Failed to check connection status: $e';
      return false;
    }
  }

  /// Streams raw ESC/POS bytes to the connected printer.
  Future<bool> printBytes(List<int> bytes) async {
    try {
      if (bytes.isEmpty) {
        _lastError = 'No print data provided.';
        return false;
      }

      final success = await PrintBluetoothThermal.writeBytes(bytes);
      if (!success) {
        _lastError = 'Could not send the receipt to the printer. Please check printer power and paper.';
        return false;
      }

      return true;
    } catch (e) {
      _lastError = 'Print write error: $e';
      return false;
    }
  }

  /// Disconnects safely from the printer without throwing.
  Future<void> disconnect() async {
    try {
      await PrintBluetoothThermal.disconnect;
    } catch (_) {
      // Disconnection errors should never crash the app
    }
  }
}

