// Distribution Export IO Helper - Mobile/Desktop platformları için PDF indirme yardımcısı

import 'dart:typed_data';

/// IO platformlarında bu fonksiyon kullanılmaz
/// (Printing paketi doğrudan kullanılır)
void downloadPdf(Uint8List bytes, String fileName) {
  // Bu fonksiyon IO platformlarında çağrılmaz
  // Sadece conditional import için gerekli
  throw UnsupportedError('downloadPdf is only supported on web');
}
