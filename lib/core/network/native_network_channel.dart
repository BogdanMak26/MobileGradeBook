// lib/core/network/native_network_channel.dart
import 'package:flutter/services.dart';

const _eventChannel = EventChannel('com.viti.gradebook/network');

/// Emits whenever Android's ConnectivityManager.NetworkCallback.onAvailable fires.
/// This works even when the Flutter Dart isolate was suspended (app backgrounded
/// but not killed). Complements the connectivity_plus stream in SyncService.
Stream<void> get nativeNetworkAvailableStream => _eventChannel
    .receiveBroadcastStream()
    .where((e) => e == true)
    .cast<void>();
