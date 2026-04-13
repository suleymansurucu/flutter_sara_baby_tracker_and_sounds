# 📲 Google Play ve App Store’a Uygulama Yükleme Rehberi

Bu rehber **Sara Baby Tracker** Flutter uygulamasını Google Play ve Apple App Store’a yüklemeniz için adım adım talimatları içerir.

---

## 📋 Genel Ön Hazırlık

### 1. Versiyon ve build numarası

Her yayından önce `pubspec.yaml` içindeki sürümü güncelleyin:

```yaml
# Örnek: 1.2.0 → 1.2.1 veya 1.3.0
version: 1.2.0   # format: major.minor.patch
```

- **Google Play:** Her yeni APK/AAB için `versionCode` (build number) artmalı (genelde otomatik).
- **App Store:** Her yeni yükleme için **Build number** (CFBundleVersion) bir öncekinden büyük olmalı.

### 2. Release build testi

Yüklemeden önce release build’i yerel test edin:

```bash
flutter clean
flutter pub get

# Android
flutter build appbundle

# iOS (Mac gerekir)
flutter build ios
```

---

# 🤖 GOOGLE PLAY’E YÜKLEME

## Adım 1: Google Play Console hesabı

1. [Google Play Console](https://play.google.com/console) → Google hesabıyla giriş.
2. **Tek seferlik kayıt ücreti:** 25 USD (developer hesabı açmak için).
3. Geliştirici sözleşmesini kabul edin.

## Adım 2: Uygulama oluşturma (ilk kez ise)

1. **Tüm uygulamalar** → **Uygulama oluştur**.
2. Uygulama adı: **Sara Baby Tracker** (veya tercih ettiğiniz ad).
3. Varsayılan dil, uygulama/oyun seçimi, ücretli/ücretsiz seçin.
4. Gerekli politika onaylarını işaretleyip **Uygulama oluştur**’a tıklayın.

## Adım 3: Android App Bundle (AAB) oluşturma

Proje kökünde:

```bash
cd /Users/suleymansurucu/projects/open_baby_sara

flutter clean
flutter pub get
flutter build appbundle --release
```

Çıktı dosyası:

```
build/app/outputs/bundle/release/app-release.aab
```

Bu `.aab` dosyasını Play Console’a yükleyeceksiniz.

## Adım 4: İmzalı build (keystore kullanıyorsanız)

İlk kez yayınlıyorsanız keystore oluşturmanız gerekir. Projenizde CI/CD için keystore kullanılıyor; yerel yükleme için:

1. Keystore oluşturma (bir kez):

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. `android/key.properties` (repo’ya eklemeyin, .gitignore’da olsun):

```properties
storePassword=<keystore-şifresi>
keyPassword=<key-şifresi>
keyAlias=upload
storeFile=<keystore-dosyasının-yolu>
```

3. `android/app/build.gradle.kts` içinde `signingConfigs` tanımlı olmalı (zaten varsa bu adımı atlayın).

Sonra tekrar:

```bash
flutter build appbundle --release
```

### ⚠️ "Your Android App Bundle is signed with the wrong key" hatası

Google Play şu hatayı veriyorsa:

- **Beklenen sertifika:** Play’in kaydettiği imza anahtarı (ilk yüklemede kullanılan).
- **Yüklediğiniz:** AAB’yi imzaladığınız anahtar farklı.

**Neden olur:** İlk yükleme farklı bir keystore ile yapıldı (ör. CI/CD’deki `KEYSTORE_BASE64`), siz yerelde farklı veya yeni keystore / debug keystore kullanıyorsunuz.

**Çözüm 1 – Doğru keystore’u kullanın (tercih edilen):**

1. İlk yüklemede hangi keystore kullanıldıysa onu kullanmalısınız.
2. İlk yükleme **CI/CD (GitHub Actions)** ile yapıldıysa: GitHub Secrets’taki `KEYSTORE_BASE64` ile aynı keystore’u yerelde kullanın.
   - Secret’ı base64 decode edip bir dosyaya yazın:  
     `echo "$KEYSTORE_BASE64_ICERIGI" | base64 --decode > android/keystore.jks`
   - `android/key.properties` içinde bu dosyayı gösterin (örn. `storeFile=keystore.jks`).
3. Keystore parolası ve alias’ı (`KEYSTORE_PASSWORD`, `KEY_ALIAS`) aynı olmalı.
4. Yerel imza parmak izini kontrol etmek için:  
   `keytool -list -v -keystore android/keystore.jks -alias <keyAlias>`  
   Çıktıdaki **SHA1** değeri, Play Console’un beklediği parmak izi ile aynı olmalı (örn. `35:58:EF:95:30:FD:0E:...`).

**Çözüm 2 – Eski keystore yoksa: Upload key sıfırlama (Play App Signing açıksa):**

1. [Play Console](https://play.google.com/console) → Uygulamanız → **Kurulum** → **Uygulama bütünlüğü** (App integrity).
2. **App signing** bölümünde **Upload key’i sıfırla** / **Request upload key reset** benzeri seçeneği bulun.
3. Google, yeni upload key’i (şu an imzaladığınız keystore) yüklemenizi isteyebilir. Talimatları izleyin ve mevcut keystore’unuzu (SHA1: 04:8E:CF:...) yeni upload key olarak kaydedin.
4. Onay sonrası aynı keystore ile imzalayıp AAB’yi tekrar yükleyin.

**Özet:** Her zaman **aynı** keystore ile imzalayın. Keystore dosyasını ve parolasını güvenli yedekleyin; yerel ve CI build’lerde aynı keystore kullanın.

## Adım 5: Play Console’da sürüm yükleme

1. Play Console’da uygulamanızı seçin.
2. Sol menü: **Yayın** → **Üretim** (veya **Test** / **İç test**).
3. **Yeni sürüm oluştur**.
4. **App Bundle’ları yükle** → `app-release.aab` dosyasını sürükleyin veya seçin.
5. Sürüm notları ekleyin (örn. “Hata düzeltmeleri ve iyileştirmeler”).
6. **İncelemeye gönder** (veya **Kaydet** sonra incelemeye gönder).

## Adım 6: Mağaza bilgileri (ilk yayın veya eksikse)

- **Mağaza ayarları:** Uygulama adı, kısa uzun açıklama, ikon, ekran görüntüleri (telefon/tablet), kategori, iletişim e‑posta.
- **İçerik derecelendirmesi:** Anketi doldurup derecelendirme alın.
- **Gizlilik politikası:** URL zorunlu (Firebase kullanıyorsanız veri toplama için gerekli).
- **Hedef kitle:** Yaş grubu vb.

Tüm zorunlu alanlar yeşil tik olana kadar doldurup **Gönder** / **İncelemeye gönder** deyin.

---

# 🍎 APPLE APP STORE’A YÜKLEME

## Adım 1: Apple Developer Program

1. [Apple Developer](https://developer.apple.com/programs/) → **Enroll**.
2. Yıllık ücret: **99 USD**.
3. Onay sonrası App Store Connect’e erişirsiniz.

## Adım 2: App Store Connect’te uygulama (ilk kez ise)

1. [App Store Connect](https://appstoreconnect.apple.com) → **My Apps**.
2. **+** → **New App**.
3. Platform: iOS, isim (örn. Sara Baby Tracker), dil, Bundle ID (Xcode’daki ile aynı olmalı: projenizde `ios/Runner.xcodeproj` veya `ios/Runner/Info.plist` içinde).
4. SKU: benzersiz bir kod (örn. `sara-baby-tracker-2025`).

## Adım 3: Xcode ayarları (Mac gerekir)

1. Projeyi Xcode’da açın:

```bash
open ios/Runner.xcworkspace
```

2. **Signing & Capabilities:**
   - **Team:** Apple Developer hesabınızı seçin.
   - **Bundle Identifier:** Play’deki paket adına benzer şekilde tutarlı olsun (örn. `com.suleymansurucu.sarababy`).
   - **Automatically manage signing** işaretli olsun (önerilir).

3. **General** sekmesinde Version ve Build number’ın `pubspec.yaml` ile uyumlu olduğundan emin olun (Flutter build sırasında bunları kullanır).

## Adım 4: iOS archive ve yükleme

1. Release build:

```bash
flutter build ios --release
```

2. Xcode’da:
   - Üstte cihaz olarak **Any iOS Device (arm64)** seçin.
   - Menü: **Product** → **Archive**.
   - Archive tamamlanınca **Organizer** açılır.
   - En son archive’ı seçip **Distribute App**.
   - **App Store Connect** → **Upload**.
   - Seçenekleri varsayılan bırakıp ilerleyin, bitene kadar **Next** / **Upload**.

Alternatif (komut satırı):

```bash
cd ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release -archivePath build/Runner.xcarchive archive
xcodebuild -exportArchive -archivePath build/Runner.xcarchive -exportOptionsPlist ExportOptions.plist -exportPath build/ipa
```

`ExportOptions.plist` için App Store dağıtımına uygun export seçeneği kullanılmalı.

## Adım 5: TestFlight (isteğe bağlı)

1. App Store Connect → uygulamanız → **TestFlight**.
2. Yüklenen build işlendikten sonra **Internal Testing** veya **External Testing** ile test edebilirsiniz.
3. İnceleme için build’i doğrudan **App Store** sürümüne atayabilirsiniz.

## Adım 6: App Store sayfası ve incelemeye gönderme

1. **App Store** sekmesi → **iOS App** → **+ Version or Platform** (veya mevcut sürüm).
2. **What’s New in This Version:** Sürüm notları.
3. **Screenshots:** Gerekli cihaz boyutları (iPhone 6.7", 6.5", 5.5" vb.).
4. **Description, Keywords, Category, Privacy Policy URL.**
5. **Pricing:** Ücretsiz/Ücretli.
6. **Build:** Yüklediğiniz build’i seçin.
7. **App Review Information:** İletişim, demo hesap gerekirse kullanıcı adı/şifre.
8. **Submit for Review**.

---

# 🔄 Güncelleme Yayınlarken

| Platform     | Artırılacak / Kontrol        |
|-------------|------------------------------|
| **pubspec** | `version: 1.2.1` (veya patch) |
| **Android** | Her yeni AAB için versionCode artar (Flutter build-number ile) |
| **iOS**     | Her yeni build için Build number artmalı (aynı sürüm numarasıyla birden fazla build gönderebilirsiniz) |

Örnek:

```bash
# pubspec.yaml: version: 1.2.1
flutter build appbundle --release --build-name=1.2.1 --build-number=3
flutter build ios --release --build-name=1.2.1 --build-number=3
```

Sonra Play Console ve App Store Connect’te bu build’leri yükleyip sürüm notlarıyla incelemeye gönderin.

---

# ✅ Kontrol Listesi

**Google Play**
- [ ] Developer hesabı ve 25 USD ödendi
- [ ] `flutter build appbundle --release` hatasız
- [ ] Mağaza bilgileri, ekran görüntüleri, gizlilik politikası
- [ ] İçerik derecelendirmesi tamamlandı
- [ ] AAB yüklendi ve “İncelemeye gönder” yapıldı

**App Store**
- [ ] Apple Developer Program (99 USD/yıl) aktif
- [ ] Xcode’da imzalama ve Bundle ID doğru
- [ ] `flutter build ios` ve Archive/Upload tamamlandı
- [ ] App Store sayfası (açıklama, ekran görüntüleri, gizlilik)
- [ ] Build seçilip “Submit for Review” yapıldı

---

# 🚀 CI/CD ile Otomatik Yükleme

Projenizde GitHub Actions ile CI/CD tanımlı. Otomatik yükleme için:

1. **REQUIRED_SECRETS.md** ve **CI_CD_QUICKSTART.md** dosyalarındaki secret’ları GitHub’a ekleyin.
2. **Android:** `KEYSTORE_*` ve `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`.
3. **iOS:** `APP_STORE_CONNECT_API_KEY`, `API_KEY_ID`, `ISSUER_ID` ve gerekirse sertifika/provisioning secret’ları.
4. `main`’e merge veya release tag’i (`v1.2.0`) push ettiğinizde pipeline release build alıp (yapılandırmaya göre) mağazalara yükleyebilir.

Detay için: **CI_CD_QUICKSTART.md**, **CI_CD_SETUP.md**.

---

İlk yayında her iki mağaza da 1–7 gün arası inceleme sürebilir. Güncellemeler genelde daha hızlı onaylanır.
