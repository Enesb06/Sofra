// lib/services/sync_service.dart

import 'package:flutter/foundation.dart';

/// Uygulamanın ilk veri senkronizasyonunun durumunu global olarak tutar.
/// false: Henüz tamamlanmadı veya hata oluştu.
/// true: Başarıyla tamamlandı.
final ValueNotifier<bool> syncCompletedNotifier = ValueNotifier(false);