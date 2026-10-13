# NFC Vault — Flutter
1. ثبّت Flutter 3.22+.
2. فك الضغط وشغّل: `./setup.sh` (على ويندوز استخدم Git Bash).
3. `flutter run` أو `flutter build apk --release` (الملف في build/app/outputs/flutter-apk/).

المميزات: دخول بالحساب نفسه، بصمة/Face ID للدخول وإعادة قفل عند الخروج، قراءة NFC مباشرة (UID، النوع، NDEF، قابلية الكتابة، السعة)، الخزنة بقائمة بطاقاتك، وفتح المحتوى المشفر (نص/PIN/IPN) عبر الصفحة الآمنة.
آيفون: محتاج حساب Apple Developer وتفعيل NFC Tag Reading في Xcode.
