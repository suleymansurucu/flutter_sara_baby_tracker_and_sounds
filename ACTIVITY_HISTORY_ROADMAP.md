# Sara Baby — Activity History & Dashboard Yol Haritası

> **Son güncelleme:** 23 Mart 2026  
> **Kapsam:** `lib/views/activities/` · `lib/widgets/custom_card.dart` · `lib/views/history/`  
> **Prensip:** Mevcut altyapıyı (ActivityBloc, LoadActivitiesByDateRange, HistoryPage) kullan — sıfırdan yazma.

---

## Mevcut Sistem — Ne Var, Ne Eksik

### Var olanlar ✅
- `ActivityBloc` → `LoadActivitiesByDateRange` (tarih aralığı + tür filtreli veri çekme)
- `HistoryPage` → global log, date picker, filter chips, edit/delete
- `helper_activities.dart` → tüm aktiviteler için son-aktivite özet fonksiyonları
- `ActivitiesWithDateLoaded` → bugünkü tüm aktiviteleri türe göre ayrılmış
- `ActivityModel.data` → esnek `Map<String, dynamic>` — grafik verisi zaten içinde

### Eksikler ❌
- Kartlar tıklanabilir değil → history'e geçiş yok
- Kart üzerindeki 2. satır özeti çok küçük (10sp) ve yetersiz
- Per-aktivite history sayfası yok (charts, trends, stats)
- `HistoryPage` → sadece log, hiç görselleştirme yok
- Baby Firsts için ayrı UX paradigması yok
- Fever/Medication için uyarı/alert mekanizması yok

---

## Kaçınılacaklar — Tasarım Kuralları

> Bu kurallar her fazda geçerlidir. Bir adım atmadan önce kontrol et.

| ❌ Yapma | ✅ Yap |
|---|---|
| Her aktiviteye aynı bar chart koyma | Her aktivite için doğru grafik tipini seç |
| Baby Firsts için chart kullanma | Baby Firsts için scrapbook/timeline paradigması |
| History'yi bottom sheet içinde gösterme | Full page navigation (charts sığmaz) |
| Yeni Bloc yaratma (data için) | `ActivityBloc.LoadActivitiesByDateRange` kullan |
| `CustomCard`'ı büyütme | Grid oranını koru (`childAspectRatio: 1.6`) |
| Kart tap ile (+) tap'ı çakıştırma | Split tap pattern uygula |
| Nested BlocBuilder ekleme | `BlocSelector` veya ayrı widget ile izole et |
| `switch-case` büyütme | Yeni aktivite = yeni `SummaryProvider` class |
| `helper_activities.dart`'a daha fazla fonksiyon ekleme | Mevcut fonksiyonları modele dönüştür |
| `HistoryPage`'i bozmadan değiştirme | Yeni `ActivityDetailPage` oluştur, HistoryPage'e dokunma |

---

## Mimari Karar: Hangi Yaklaşım?

`HistoryPage` zaten çalışıyor. Strateji:

```
Kart tap  →  ActivityDetailPage (YENİ)
              ├── Header: Stats row (bugün/hafta özet)
              ├── Chart: Aktiviteye özel görselleştirme
              └── List: Mevcut HistoryPage'deki log listesi (kodu kopyalama, refactor et)

(+) tap   →  Bottom sheet (MEVCUT — dokunma)
```

`ActivityDetailPage`, `ActivityBloc.LoadActivitiesByDateRange`'i kullanır.  
`HistoryPage` değişmez — global bakış için olduğu gibi kalır.

---

## Faz 0 — Temel Hazırlık
**Süre:** 1 gün · **Risk:** Düşük · **Önkoşul:** Yok

Bu faz kod yazmadan önce alınacak kararlar ve küçük hazırlıklardır.

### 0.1 — ActivitySummary Model Oluştur

`lib/core/models/activity_summary.dart` dosyası oluştur.  
`helper_activities.dart`'taki `String` dönen fonksiyonlar bu modeli dönsün.

```dart
// lib/core/models/activity_summary.dart
class ActivitySummary {
  final String primaryLine;    // "Son: Sol — 18dk, 2 saat önce"
  final String secondaryLine;  // "Bugün: 8 seans · 2s 10dk"
  final Color? alertColor;     // Fever: kırmızı, Medication: turuncu, normal: null
  final String? alertMessage;  // "Doz zamanı yaklaşıyor" — null ise alert yok
}
```

> **Not:** `helper_activities.dart` içindeki mevcut fonksiyonlar şimdilik String döndürmeye devam edebilir.  
> Faz 2'de `ActivitySummary` döndürecek şekilde refactor edilir. Faz 0'da sadece model tanımı yeterli.

### 0.2 — ActivityDetailRoute Sabiti Ekle

`lib/app/routes/app_router.dart`'a `activityDetail` route'u ekle (içini Faz 3'te doldur).

```dart
// Şimdilik placeholder
static const String activityDetail = '/activity-detail';
```

### 0.3 — fl_chart Bağımlılığını Ekle

```bash
flutter pub add fl_chart
```

> `pubspec.yaml`'a eklenir. Faz 4'e kadar import edilmez — sadece hazır olsun.

**Checklist:**
- [ ] `ActivitySummary` model dosyası oluşturuldu
- [ ] Route sabiti eklendi
- [ ] `fl_chart` `pubspec.yaml`'a eklendi (`flutter pub get` çalıştırıldı)

---

## Faz 1 — Kartları Tıklanabilir Yap
**Süre:** 1 gün · **Risk:** Çok düşük · **Önkoşul:** Faz 0

Bu fazda backend'e dokunulmaz. Sadece navigation eklenir.

### 1.1 — CustomCard'a onTap Ekle

`lib/widgets/custom_card.dart` — `Card` widget'ı `GestureDetector` ile sar.

```dart
// custom_card.dart içinde
// ÖNCE: Card(...)
// SONRA:

GestureDetector(
  onTap: widget.onCardTap,  // YENİ parametre
  child: Card(
    // mevcut kod değişmez
  ),
)
```

`CustomCard`'a yeni opsiyonel parametre ekle:

```dart
final VoidCallback? onCardTap;  // null ise tıklama sessizce yoksayılır
```

> **Kritik:** `voidCallback` (add butonu) ve `onCardTap` (kart gövdesi) FARKLI.  
> `GestureDetector.onTap` ve `GestureDetector` içindeki `Icons.add_circle`'ın kendi `GestureDetector`'ı çakışmaz.

### 1.2 — ActivityDetailPage (Shell — sadece liste)

`lib/views/activity_detail/activity_detail_page.dart` oluştur.

```
lib/views/activity_detail/
├── activity_detail_page.dart     ← Bu fazda oluşturulur
└── widgets/
    └── (Faz 3 ve 4'te doldurulur)
```

Bu fazda `ActivityDetailPage`, `HistoryPage`'deki mevcut liste kodunu yeniden kullanır:
- Aynı `LoadActivitiesByDateRange` event'i
- Aynı `NewActivityCard` widget'ı
- Ekstra: üstte aktivite adı ve ikon

```dart
class ActivityDetailPage extends StatefulWidget {
  final String activityType;   // 'sleep', 'breastFeed', vb.
  final String babyID;
  final String activityTitle;  // lokalize edilmiş başlık
  final Color activityColor;
  final String activityIconPath;
}
```

Başlangıç state: son 7 gün, ilgili aktivite tipi filtreli.

### 1.3 — activity_page.dart'ta Navigation Ekle

Her `CustomCard`'a `onCardTap` bağla:

```dart
CustomCard(
  // mevcut parametreler...
  onCardTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ActivityDetailPage(
        activityType: ActivityType.sleep.name,
        babyID: selectedBabyID,
        activityTitle: context.tr('sleep'),
        activityColor: AppColors.sleepColor,
        activityIconPath: 'assets/images/sleep_icon.png',
      ),
    ),
  ),
),
```

**Checklist:**
- [ ] `CustomCard`'a `onCardTap` parametresi eklendi
- [ ] Kart gövdesi `GestureDetector` ile sarıldı
- [ ] `activity_detail/activity_detail_page.dart` oluşturuldu
- [ ] Tüm kartlara (Feed, Pump, Diaper, Sleep, Baby Firsts, Teething, Medication, Doctor Visit, Vaccination, Fever) navigation eklendi
- [ ] Growth kartı için `CustomizeGrowthCard`'a da navigation eklendi
- [ ] Uygulama çalıştırıldı, tüm kartlar doğru sayfaya açılıyor

---

## Faz 2 — Kart Quick Stats Geliştirme
**Süre:** 2 gün · **Risk:** Düşük · **Önkoşul:** Faz 1

Kartların alt kısmındaki 10sp metin yerini anlamlı 2-satır özete bırakır.

### 2.1 — ActivitySummary'yi helper_activities.dart'a Entegre Et

Her `getLastXxxSummary` fonksiyonu için `ActivitySummary` döndüren versiyonunu ekle.

**Öncelik sırası** (en çok kullanılandan):
1. Feed → `primaryLine`: "Sol · 18dk · 2s önce" / `secondaryLine`: "Bugün: 8 seans · 2s 10dk"
2. Sleep → `primaryLine`: "2s 15dk · 3 saat önce bitti" / `secondaryLine`: "Bugün: 9s 40dk"
3. Diaper → `primaryLine`: "Islak · 1s 15dk önce" / `secondaryLine`: "Bugün: 6 değişim (4I · 2K)"
4. Pump → `primaryLine`: "Sol 45ml · Sağ 50ml · 4s önce" / `secondaryLine`: "Bugün: 280ml"
5. Medication → `primaryLine`: "Parol 125mg · 3s 20dk önce" / `secondaryLine`: "Sonraki: 20:30" + `alertColor` turuncu
6. Fever → `primaryLine`: "38.2°C · 2 saat önce" / `secondaryLine`: "Maks: 38.7°C" + `alertColor` (eşiğe göre)
7. Diğerleri: mevcut string özet yeterli (Faz 2 kapsamı dışında bırakılabilir)

### 2.2 — CustomCard'ı İki Satır Destekleyecek Şekilde Güncelle

```dart
// _buildLastActivityText yerine _buildSummaryWidget
Widget _buildSummaryWidget(ActivitySummary summary) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        summary.primaryLine,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: summary.alertColor,  // Fever/Medication için renk
        ),
      ),
      Text(
        summary.secondaryLine,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 9.sp,
          color: Colors.black54,
        ),
      ),
    ],
  );
}
```

### 2.3 — Medication & Fever Alert Mantığı

`ActivitySummary.alertColor` için eşikler:
- Fever: `< 37.5` → null, `37.5–38.4` → `Colors.orange`, `>= 38.5` → `Colors.red`
- Medication: son doz `< 4 saat önce` → turuncu uyarı

**Checklist:**
- [ ] `ActivitySummary` model tamamlandı (Faz 0'dan)
- [ ] Feed summary → `ActivitySummary` döndürüyor
- [ ] Sleep summary → `ActivitySummary` döndürüyor
- [ ] Diaper summary → `ActivitySummary` döndürüyor
- [ ] Pump summary → `ActivitySummary` döndürüyor
- [ ] Medication alert mantığı çalışıyor (renk kodu)
- [ ] Fever alert mantığı çalışıyor (eşik renkleri)
- [ ] `CustomCard` iki satır gösteriyor
- [ ] Grid layout bozulmadı (childAspectRatio korundu)

---

## Faz 3 — ActivityDetailPage Tam İçerik (Stats + List)
**Süre:** 2–3 gün · **Risk:** Orta · **Önkoşul:** Faz 1

Grafik yok — sadece stats satırı ve geliştirilmiş liste.

### 3.1 — ActivityDetailPage Header Stats Row

```
┌─────────────────────────────────────────────┐
│  ← Geri    UYKU              [+ Ekle]       │
│                                             │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐    │
│  │ Bugün    │ │ Haftalık │ │ Ort. Süre│    │
│  │ 9s 40dk  │ │ 62s 30dk │ │ 2s 10dk  │    │
│  └──────────┘ └──────────┘ └──────────┘    │
└─────────────────────────────────────────────┘
```

`ActivityStatRow` widget'ı oluştur (`lib/views/activity_detail/widgets/activity_stat_row.dart`):

```dart
class ActivityStatItem {
  final String label;   // "Bugün"
  final String value;   // "9s 40dk"
  final Color? color;   // opsiyonel vurgu
}

class ActivityStatRow extends StatelessWidget {
  final List<ActivityStatItem> stats;  // max 3 item
}
```

### 3.2 — Stat Hesaplamaları (aktiviteye özel)

`lib/views/activity_detail/` altında her aktivite için stat hesaplayan helper:

```
lib/views/activity_detail/
├── activity_detail_page.dart
├── stats/
│   ├── sleep_stats.dart          → bugün toplam, haftalık ort., ort. süre
│   ├── feed_stats.dart           → bugün seans, haftalık ort., L/R denge %
│   ├── diaper_stats.dart         → bugün toplam, ıslak/kaka ayrımı, haftalık ort.
│   ├── pump_stats.dart           → bugün ml, haftalık ort., sol/sağ farkı
│   ├── fever_stats.dart          → son epizod maks, son tarih, epiod sayısı
│   └── medication_stats.dart     → son doz zamanı, toplam doz bugün, sonraki doz
└── widgets/
    ├── activity_stat_row.dart
    └── activity_log_list.dart    ← HistoryPage'deki liste kodu buraya taşınır
```

### 3.3 — Date Range Seçici

`ActivityDetailPage` header'ına basit seçici ekle:

```
[Son 7 gün]  [Son 30 gün]  [Tümü]
```

`LoadActivitiesByDateRange` event'i yeniden tetiklenir. `ActivityBloc` zaten destekliyor.

### 3.4 — ActivityLogList Reusable Widget

`HistoryPage`'deki liste render mantığını buraya taşı (kopyalama değil, extract et):

```dart
class ActivityLogList extends StatelessWidget {
  final List<ActivityModel> activities;
  final VoidCallback? onReload;
  // edit/delete callbacks
}
```

> **Kritik:** `HistoryPage` bu widget'ı import eder. Kod duplikasyonu olmaz.

**Checklist:**
- [ ] `ActivityStatRow` widget'ı çalışıyor
- [ ] Sleep stats hesaplamaları doğru
- [ ] Feed stats hesaplamaları doğru
- [ ] Fever alert banner `ActivityDetailPage`'de görünüyor
- [ ] Medication "sonraki doz" hesabı doğru
- [ ] Date range seçici çalışıyor
- [ ] `ActivityLogList` extracted, `HistoryPage` bunu kullanıyor
- [ ] Edit/Delete `ActivityDetailPage`'den de çalışıyor

---

## Faz 4 — Aktiviteye Özel Grafikler
**Süre:** 3–5 gün · **Risk:** Orta-Yüksek · **Önkoşul:** Faz 3, fl_chart eklendi

Her aktivite için grafik tipi analizi (tekrar etme, her biri farklı):

### Öncelik Sırası ve Grafik Tipleri

| Öncelik | Aktivite | Grafik Tipi | Neden |
|---|---|---|---|
| 1 | **Fever** | Line chart (epizod bazlı) | Medikal, kritik, zaman serisi |
| 2 | **Sleep** | Bar chart + 24s Gantt timeline | En sık görüntülenen |
| 3 | **Feed** | Bar chart + Donut (L/R) | En sık kaydedilen |
| 4 | **Pump** | Line chart (ml trendi, 14 gün) | Supply tracking |
| 5 | **Growth** | WHO percentile curve | Uygulamayı farklılaştırır |
| 6 | **Diaper** | Stacked bar chart | Medikal pattern takibi |
| 7 | **Baby Firsts** | Kronolojik kart listesi | Chart değil, scrapbook |

### 4.1 — Fever Line Chart

```
lib/views/activity_detail/charts/
└── fever_line_chart.dart
```

- X ekseni: saat (son 24–72 saat)
- Y ekseni: sıcaklık (35°C–40°C)
- Renk bantları: yeşil/sarı/kırmızı (eşik çizgileri)
- Her nokta tap'lanabilir → tarih/saat tooltip
- `fl_chart` `LineChart` kullan

```dart
class FeverLineChart extends StatelessWidget {
  final List<ActivityModel> feverActivities;
  // Sadece veri alır, hesaplama dışarda yapılır
}
```

### 4.2 — Sleep Bar Chart

```
lib/views/activity_detail/charts/
└── sleep_bar_chart.dart
```

- X ekseni: son 7 gün (gün adı kısaltması: Pts, Sal, vb.)
- Y ekseni: toplam uyku saati
- Hedef çizgisi: 16s (0–3 ay normu) — sabit, kalın noktalı çizgi
- Bar rengi: `AppColors.sleepIconColor`

### 4.3 — Feed Charts

```
lib/views/activity_detail/charts/
├── feed_bar_chart.dart     ← günlük seans sayısı
└── feed_donut_chart.dart   ← L/R emzirme dengesi
```

Donut chart için: sadece `breastFeed` tipinde göster, `bottleFeed` ve `solids` için gizle.

### 4.4 — Pump Line Chart

```
lib/views/activity_detail/charts/
└── pump_line_chart.dart
```

- X ekseni: son 14 gün
- Y ekseni: günlük toplam ml
- `AppColors.pumpIconColor` rengi
- Düşüş varsa → "Supply azalıyor olabilir" soft uyarısı

### 4.5 — Growth WHO Curve (En Kritik)

```
lib/views/activity_detail/charts/
└── growth_who_chart.dart
```

Bu grafik için ayrı bir helper:

```
lib/core/utils/who_growth_data.dart
```

WHO 2006 referans verileri (P3, P15, P50, P85, P97 bantları) hardcode edilir.  
Ağırlık/Boy/Baş çevresi için ayrı sekmeli görünüm (`DefaultTabController`).

> **Uyarı:** WHO eğrisi implementasyonu bu listedeki en karmaşık iş.  
> Yanlış hesaplanırsa medikal yanlış bilgi verir. WHO referans tablosunu doğrula.

### 4.6 — Diaper Stacked Bar

```
lib/views/activity_detail/charts/
└── diaper_stacked_bar_chart.dart
```

- Her bar = bir gün
- Stack: ıslak (mavi), kaka (kahve), kuru (gri)
- `fl_chart` `BarChart` ile `BarChartGroupData` iç içe kullan

### 4.7 — Baby Firsts Timeline (Chart değil)

```
lib/views/activity_detail/
└── baby_firsts_timeline_view.dart
```

Kronolojik kart listesi. Her kart:
- Milestone adı (büyük, kalın)
- Tarih
- Varsa fotoğraf (gelecek faz)
- Kategori chip'i (Motor, Sosyal, Dil, Beslenme)

**Kesinlikle chart kullanma.**

**Checklist:**
- [ ] `fl_chart` import edildi ve lint hatası yok
- [ ] `fever_line_chart.dart` çalışıyor, eşik renkleri doğru
- [ ] `sleep_bar_chart.dart` çalışıyor, hedef çizgisi var
- [ ] `feed_bar_chart.dart` çalışıyor
- [ ] `feed_donut_chart.dart` sadece breastFeed'de gösteriliyor
- [ ] `pump_line_chart.dart` çalışıyor
- [ ] `growth_who_chart.dart` WHO verileri doğrulandı
- [ ] `diaper_stacked_bar_chart.dart` çalışıyor
- [ ] `baby_firsts_timeline_view.dart` chart içermiyor

---

## Faz 5 — Özel UX Paradigmaları
**Süre:** 2–3 gün · **Risk:** Orta · **Önkoşul:** Faz 4

### 5.1 — Teething Dental Map

```
lib/views/activity_detail/
└── teething_dental_map_view.dart
```

ISO dişeti koordinat sistemi ile interaktif diş şeması.  
`activity_constants.dart` ve `iso_tooth_descriptions_constants.dart` zaten var — kullan.

Her diş:
- Kayıt varsa: `AppColors.teethingIconColor` dolu
- Kayıt yoksa: outline, açık renk
- Tap edilince: diş adı + çıkış tarihi tooltip

### 5.2 — Doctor Visit & Vaccination Archive

```
lib/views/activity_detail/
├── doctor_visit_archive_view.dart
└── vaccination_timeline_view.dart
```

`doctor_visit`: kronolojik liste, notlar genişletilebilir, arama kutusu.  
`vaccination`: timeline + "yapılmamış aşı" boş slot gösterimi.

### 5.3 — Medication Safety Layer

`ActivityDetailPage` için `medication` özelinde ek güvenlik:

- Son 24 saat içinde verilen toplam doz sayısı
- "Maksimum günlük doz aşıldı" kırmızı banner (ilaç bazlı max doz `data` alanından okunur)
- Sonraki doz countdown timer (gerçek zamanlı)

**Checklist:**
- [ ] Dental map render ediliyor, tıklanan dişin tarihi gösteriliyor
- [ ] Doctor Visit'te arama çalışıyor
- [ ] Vaccination'da eksik aşı slot'ları görünüyor
- [ ] Medication maks doz banner'ı tetikleniyor

---

## Faz 6 — Polish & Production Hazırlığı
**Süre:** 2 gün · **Risk:** Düşük · **Önkoşul:** Faz 5

### 6.1 — Loading & Empty States

Her `ActivityDetailPage` için:
- `ActivityLoading` → skeleton shimmer (chart alanı için placeholder)
- Boş durum: aktiviteye özel mesaj ("Henüz uyku kaydı yok — ilk kaydı ekle")
- Error state: retry butonu

### 6.2 — Haptic Feedback

Kart tap, grafik nokta tap → `HapticFeedback.lightImpact()`

### 6.3 — Deep Link & Route Parametresi

`app_router.dart`'ta tam route:

```dart
GoRoute(
  path: '/activity-detail/:type',
  builder: (context, state) => ActivityDetailPage(
    activityType: state.pathParameters['type']!,
    // ...
  ),
)
```

> Push notification'dan direkt açılabilmesi için (Faz sonrası yol haritası).

### 6.4 — Performance Audit

- `ActivityDetailPage`'de `BlocSelector` kullanımını kontrol et
- `ListView.builder` — `itemExtent` sabitle (aynı yükseklik varsa)
- `RepaintBoundary` grafik widget'larının etrafına ekle

**Checklist:**
- [ ] Skeleton shimmer çalışıyor
- [ ] Tüm boş durumlar aktiviteye özel mesaj gösteriyor
- [ ] Haptic feedback eklendi
- [ ] Route parametresi çalışıyor
- [ ] `flutter analyze` sıfır hata
- [ ] `flutter build apk --release` başarılı

---

## Dosya Organizasyonu — Final Yapı

```
lib/
├── core/
│   ├── models/
│   │   └── activity_summary.dart          ← FAZ 0 (YENİ)
│   └── utils/
│       ├── helper_activities.dart         ← MEVCUT (refactor edilecek)
│       └── who_growth_data.dart           ← FAZ 4 (YENİ)
│
├── views/
│   ├── activities/
│   │   └── activity_page.dart             ← FAZ 1 (navigation eklendi)
│   ├── history/
│   │   └── history_page.dart              ← DOKUNMA (global log kalır)
│   └── activity_detail/                   ← FAZ 1–6 (TAMAMEN YENİ)
│       ├── activity_detail_page.dart
│       ├── stats/
│       │   ├── sleep_stats.dart
│       │   ├── feed_stats.dart
│       │   ├── diaper_stats.dart
│       │   ├── pump_stats.dart
│       │   ├── fever_stats.dart
│       │   └── medication_stats.dart
│       ├── charts/
│       │   ├── fever_line_chart.dart
│       │   ├── sleep_bar_chart.dart
│       │   ├── feed_bar_chart.dart
│       │   ├── feed_donut_chart.dart
│       │   ├── pump_line_chart.dart
│       │   ├── growth_who_chart.dart
│       │   └── diaper_stacked_bar_chart.dart
│       └── widgets/
│           ├── activity_stat_row.dart
│           ├── activity_log_list.dart     ← HistoryPage'den extract edildi
│           ├── baby_firsts_timeline_view.dart
│           ├── teething_dental_map_view.dart
│           ├── doctor_visit_archive_view.dart
│           └── vaccination_timeline_view.dart
│
└── widgets/
    └── custom_card.dart                   ← FAZ 1 (onCardTap eklendi)
```

---

## Bağımlılıklar

| Paket | Versiyon | Kullanım | Faz |
|---|---|---|---|
| `fl_chart` | `^0.70.x` | Tüm grafikler | Faz 0 |
| Mevcut tüm paketler | — | Değişmez | — |

> `who_growth_data.dart` için harici paket yok. WHO 2006 verileri hardcode.  
> Medikal doğruluk gerektirdiğinden WHO web sitesinden referans al:  
> https://www.who.int/tools/child-growth-standards/standards

---

## Faz Özeti — Hızlı Bakış

| Faz | İş | Süre | Kullanıcı Değeri |
|---|---|---|---|
| **0** | Hazırlık — model, route, bağımlılık | 1 gün | — |
| **1** | Kartlar tıklanabilir + detail page shell | 1 gün | ⭐⭐⭐⭐⭐ |
| **2** | Kart quick stats (2 satır, alert) | 2 gün | ⭐⭐⭐⭐ |
| **3** | Detail page stats + gelişmiş liste | 2–3 gün | ⭐⭐⭐⭐ |
| **4** | Aktiviteye özel grafikler | 3–5 gün | ⭐⭐⭐⭐⭐ |
| **5** | Özel UX (dental map, milestone, vaccination) | 2–3 gün | ⭐⭐⭐ |
| **6** | Polish & production | 2 gün | ⭐⭐ |
| **Toplam** | | **~13–17 gün** | |

> **Tavsiye:** Faz 0 + Faz 1 en önce. Kart navigation olmadan diğer fazlar test edilemez.  
> Faz 4'te Growth WHO curve'ü en son bırak — en karmaşık ve medikal doğrulama gerektiriyor.

---

## Sık Yapılan Hatalar — Referans

```
❌ "Hepsine bar chart koyuyorum, hızlı olur"
   → Baby Firsts için chart ekleme. Scrapbook paradigması kullan.

❌ "ActivityDetailPage için yeni bir Bloc yazıyorum"
   → ActivityBloc.LoadActivitiesByDateRange zaten var. Kullan.

❌ "HistoryPage'i kaldırıyorum, ActivityDetailPage yeterli"
   → HistoryPage global bakış için gerekli. Dokunma. İkisi birbirini tamamlar.

❌ "CustomCard'ı büyüteyim, daha fazla bilgi sığar"
   → Grid oranı bozulur. childAspectRatio: 1.6 koru. Bilgi detay sayfasına gider.

❌ "WHO eğrisini approximation ile yapıyorum"
   → Medikal veri. WHO tablosunu doğrudan kullan. Yanlış persentil göstermek zararlıdır.

❌ "Pump ve Feed için aynı chart tipini kullanıyorum"
   → Feed: bar (günlük seans sayısı) + donut (L/R). Pump: line chart (ml trendi).
   → Farklı soru, farklı grafik.
```

---

*Bu belge yaşayan bir dokümandır. Her faz tamamlandığında checklist'leri işaretle ve sonraki faza geç.*
