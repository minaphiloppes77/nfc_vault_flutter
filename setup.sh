#!/bin/bash
# يولّد ملفات أندرويد/آيفون ويضيف صلاحيات NFC والبصمة
set -e
flutter create --org com.nfcvault --platforms android,ios .
flutter pub get
M=android/app/src/main/AndroidManifest.xml
sed -i.bak 's#<application#<uses-permission android:name="android.permission.NFC"/>\n    <uses-permission android:name="android.permission.USE_BIOMETRIC"/>\n    <uses-permission android:name="android.permission.INTERNET"/>\n    <application#' $M
sed -i.bak 's/FlutterActivity/FlutterFragmentActivity/' android/app/src/main/kotlin/com/nfcvault/nfc_vault/MainActivity.kt
sed -i.bak 's/minSdk = flutter.minSdkVersion/minSdk = 23/' android/app/build.gradle* 2>/dev/null || true
P=ios/Runner/Info.plist
sed -i.bak 's#<dict>#<dict>\n\t<key>NFCReaderUsageDescription</key><string>لقراءة بطاقات NFC</string>\n\t<key>NSFaceIDUsageDescription</key><string>لفتح الخزنة بـ Face ID</string>#' $P
echo "تمام! شغّل: flutter run   أو   flutter build apk --release"
