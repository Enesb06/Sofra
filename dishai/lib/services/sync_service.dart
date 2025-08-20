import 'package:flutter/foundation.dart';

class SyncService {
  // Uygulama genelinde dinlenebilecek bir "değişken" oluşturuyoruz.
  // true = senkronizasyon tamamlandı, false = senkronizasyon devam ediyor.
  static final ValueNotifier<bool> isSyncCompleted = ValueNotifier(false);
}