# Feed Tracker - Kullanıcı Senaryoları (Anne Perspektifi)

## ÖNEMLİ NOTLAR
- Sleep tracker'da yapılan değişiklikler feed tracker'a da uygulanmalı
- CustomDateTimePicker kullanılmalı (tarih + saat birlikte)
- Full DateTime objeleri kullanılmalı (sadece saat/dakika değil)
- Validation kuralları sleep tracker ile aynı olmalı
- Notes geçici kayıt (SharedPreferences) eklenmeli

---

## 1. BOTTLE FEED (Biberon Beslenme) SENARYOLARI

### Senaryo 1.1: Normal Biberon Beslenme Kaydı
- **Durum**: Anne bebeği biberonla besledi, kayıt yapmak istiyor
- **Beklenen**:
  - Feeding time: CustomDateTimePicker ile tarih + saat seçilebilmeli
  - Gelecekteki tarih seçilememeli
  - 1 yıl öncesi limiti olmalı
  - Feeding type seçilebilmeli
  - Amount ve unit girilebilmeli
  - Notes eklenebilmeli
  - Kayıt başarılı olmalı

### Senaryo 1.2: Geçmiş Biberon Beslenme Kaydı
- **Durum**: Anne dünkü beslenmeyi unutmuş, şimdi ekliyor
- **Örnek**:
  - Feeding time: Dün 14:00
- **Beklenen**:
  - Eski tarihler seçilebilmeli
  - Gelecekteki tarihler seçilememeli
  - Kayıt başarılı olmalı

### Senaryo 1.3: Gece Yarısını Geçen Beslenme
- **Durum**: Bebek gece yarısından önce beslenmeye başladı, sonra bitti
- **Örnek**:
  - Feeding time: 22 Kasım 23:30
- **Beklenen**:
  - Tarih doğru kaydedilmeli
  - CustomDateTimePicker ile tam tarih + saat seçilebilmeli

### Senaryo 1.4: İlk Açılış (Boş Form)
- **Durum**: Anne ilk kez bottle feed sayfasını açtı
- **Beklenen**:
  - Feeding time: "Add" (boş)
  - Feeding type: Seçilmemiş
  - Amount: Boş
  - Notes: Boş

### Senaryo 1.5: Notes Geçici Kayıt
- **Durum**: Anne notes yazdı, sayfayı kapattı, tekrar açtı
- **Beklenen**:
  - Notes geçici olarak kaydedilmeli (SharedPreferences)
  - Sayfa açıldığında notes geri yüklenmeli
  - Kayıt yapıldığında notes temizlenmeli
  - Her bebek için ayrı notes cache'i olmalı

---

## 2. BREASTFEED (Emzirme) SENARYOLARI

### Senaryo 2.1: Timer Başlatıldı (Sol Taraf)
- **Durum**: Anne sol taraftan emzirmeye başladı, timer'ı başlattı
- **Beklenen**:
  - Start time otomatik olarak şu anki zaman olarak kaydedilmeli (full DateTime)
  - Timer çalışmaya başlamalı
  - End time "Add" olarak görünmeli (disabled)
  - Total time gerçek zamanlı olarak artmalı
  - Start time CustomDateTimePicker ile görünmeli (tarih + saat)

### Senaryo 2.2: Timer Durduruldu (Sol Taraf)
- **Durum**: Sol taraftan emzirme bitti, timer durduruldu
- **Beklenen**:
  - Start time görünmeli (timer başlatıldığında kaydedilen zaman - full DateTime)
  - End time otomatik olarak şu anki zaman olarak ayarlanmalı (full DateTime)
  - Total time hesaplanmalı
  - Amount ve unit girilebilmeli
  - Notes eklenebilmeli
  - Kaydet butonu aktif olmalı

### Senaryo 2.3: Timer Çalışırken Sayfa Kapatıldı
- **Durum**: Timer çalışırken anne başka sayfaya gitti veya uygulamayı kapattı
- **Beklenen**:
  - Timer arka planda çalışmaya devam etmeli
  - Sayfa tekrar açıldığında timer durumu korunmalı
  - Start time görünmeli (full DateTime)
  - Total time doğru hesaplanmalı

### Senaryo 2.4: Timer Çalışırken Manuel End Time Seçildi
- **Durum**: Timer çalışırken anne manuel olarak end time seçti
- **Beklenen**:
  - Timer otomatik olarak durmalı
  - Seçilen end time kaydedilmeli (full DateTime)
  - Total time yeniden hesaplanmalı
  - Manuel moda geçilmeli

### Senaryo 2.5: Geçmiş Emzirme Kaydı - Aynı Gün
- **Durum**: Anne sabah bebeğin gece emzirmesini kaydetmek istiyor
- **Örnek**:
  - Sol taraf Start: Dün gece 22:00
  - Sol taraf End: Bu sabah 00:30
- **Beklenen**:
  - Gece yarısını geçen durumlar doğru hesaplanmalı
  - Tarihler doğru kaydedilmeli (full DateTime)
  - CustomDateTimePicker ile tarih + saat seçilebilmeli

### Senaryo 2.6: Geçmiş Emzirme Kaydı - Farklı Gün
- **Durum**: Anne dünkü emzirme kaydını unutmuş, şimdi ekliyor
- **Örnek**:
  - Sol taraf Start: Dün 14:00
  - Sol taraf End: Dün 14:30
- **Beklenen**:
  - Eski tarihler seçilebilmeli
  - Gelecekteki tarihler seçilememeli
  - Duration doğru hesaplanmalı (30 dakika)
  - Full DateTime kullanılmalı

### Senaryo 2.7: Gece Yarısını Geçen Emzirme
- **Durum**: Bebek gece yarısından önce emzirmeye başladı, sonra bitti
- **Örnek**:
  - Sol taraf Start: 22 Kasım 23:00
  - Sol taraf End: 23 Kasım 00:30
- **Beklenen**:
  - Tarihler doğru kaydedilmeli (full DateTime)
  - Duration doğru hesaplanmalı (1.5 saat)
  - Validation gece yarısını geçen durumları kabul etmeli

### Senaryo 2.8: Kısa Emzirme
- **Durum**: Bebek kısa süre emzirdi
- **Örnek**:
  - Sol taraf Start: Bugün 13:00
  - Sol taraf End: Bugün 13:15
- **Beklenen**:
  - 15 dakikalık emzirme doğru kaydedilmeli
  - Aynı gün içinde kayıt yapılabilmeli

### Senaryo 2.9: İki Taraflı Emzirme
- **Durum**: Anne hem sol hem sağ taraftan emzirdi
- **Beklenen**:
  - Her iki taraf için ayrı start/end time kaydedilmeli
  - Total time her iki tarafın toplamı olmalı
  - Her iki taraf için ayrı amount girilebilmeli

### Senaryo 2.10: Timer Çalışırken Start Time Değiştirildi
- **Durum**: Timer çalışırken anne start time'ı değiştirdi
- **Beklenen**:
  - Timer durmalı
  - Manuel moda geçilmeli
  - Yeni start time kaydedilmeli (full DateTime)
  - End time null olmalı

### Senaryo 2.11: Timer Çalışırken End Time Disabled
- **Durum**: Timer çalışırken anne end time seçmeye çalışıyor
- **Beklenen**:
  - End time picker disabled olmalı
  - Görsel olarak gri görünmeli
  - Tıklanamaz olmalı

---

## 3. DÜZENLEME SENARYOLARI

### Senaryo 3.1: Yanlış Kayıt Düzeltme (Bottle Feed)
- **Durum**: Anne yanlış saat girmiş, düzeltmek istiyor
- **Beklenen**:
  - Mevcut değerler formda görünmeli
  - Feeding time değiştirilebilmeli
  - Validation kontrolleri çalışmalı
  - Güncelleme başarılı olmalı

### Senaryo 3.2: Yanlış Kayıt Düzeltme (Breastfeed)
- **Durum**: Anne yanlış start/end time girmiş, düzeltmek istiyor
- **Beklenen**:
  - Mevcut değerler formda görünmeli
  - Start/end time değiştirilebilmeli
  - Validation kontrolleri çalışmalı
  - Duration yeniden hesaplanmalı
  - Güncelleme başarılı olmalı

### Senaryo 3.3: Notes Ekleme/Düzenleme
- **Durum**: Anne kayıt oluştururken notes yazdı, sonra düzenlemek istiyor
- **Beklenen**:
  - Notes kaydedilmeli
  - Düzenleme modunda notes görünmeli
  - Değişiklikler kaydedilmeli

---

## 4. HATA VE VALİDASYON SENARYOLARI

### Senaryo 4.1: End Time Start Time'dan Önce (Breastfeed)
- **Durum**: Anne yanlışlıkla end time'ı start time'dan önce seçti
- **Beklenen**:
  - Hata mesajı gösterilmeli
  - Kayıt yapılmamalı
  - Kullanıcı düzeltme yapabilmeli

### Senaryo 4.2: Gelecekteki Tarih
- **Durum**: Anne yanlışlıkla gelecekteki bir tarih seçti
- **Beklenen**:
  - Hata mesajı gösterilmeli ("Date cannot be in the future")
  - Kayıt yapılmamalı
  - Sadece geçmiş ve bugünkü tarihler kabul edilmeli

### Senaryo 4.3: Eksik Alanlar (Bottle Feed)
- **Durum**: Anne feeding time seçti ama amount girmeden kaydetmeye çalışıyor
- **Beklenen**:
  - Hata mesajı gösterilmeli ("Please complete all fields")
  - Kayıt yapılmamalı
  - Eksik alanlar işaretlenmeli

### Senaryo 4.4: Eksik Alanlar (Breastfeed)
- **Durum**: Anne start time seçti ama end time seçmeden kaydetmeye çalışıyor
- **Beklenen**:
  - Hata mesajı gösterilmeli ("Please complete all fields")
  - Kayıt yapılmamalı
  - Eksik alanlar işaretlenmeli

### Senaryo 4.5: Start ve End Time Aynı (Breastfeed)
- **Durum**: Anne yanlışlıkla start ve end time'ı aynı yaptı
- **Beklenen**:
  - Hata mesajı gösterilmeli
  - Kayıt yapılmamalı
  - Duration 0 olamaz

### Senaryo 4.6: Çok Eski Tarih (1 Yıl Öncesi)
- **Durum**: Anne çok eski bir tarih seçmeye çalışıyor
- **Beklenen**:
  - Hata mesajı gösterilmeli ("Date cannot be more than 1 year ago")
  - Kayıt yapılmamalı
  - 1 yıl öncesi limiti olmalı

---

## 5. ÖZEL DURUMLAR

### Senaryo 5.1: Reset Butonuna Basıldı (Bottle Feed)
- **Durum**: Anne tüm alanları temizlemek istiyor
- **Beklenen**:
  - Tüm alanlar temizlenmeli
  - Notes temizlenmeli
  - Geçici cache temizlenmeli

### Senaryo 5.2: Reset Butonuna Basıldı (Breastfeed)
- **Durum**: Anne tüm alanları temizlemek istiyor
- **Beklenen**:
  - Tüm alanlar temizlenmeli
  - Timer resetlenmeli
  - Notes temizlenmeli
  - Geçici cache temizlenmeli

### Senaryo 5.3: Sayfa Kapatılıp Tekrar Açıldı (Notes Kaybolması)
- **Durum**: Anne notes yazdı, sayfayı kapattı, tekrar açtı
- **Beklenen**:
  - Notes geçici olarak kaydedilmeli (SharedPreferences)
  - Sayfa açıldığında notes geri yüklenmeli
  - Kayıt yapıldığında notes temizlenmeli
  - Her bebek için ayrı notes cache'i olmalı

### Senaryo 5.4: Duration Picker'dan Süre Seçildi (Breastfeed)
- **Durum**: Anne start ve end time yerine direkt duration seçti
- **Beklenen**:
  - Start ve end time otomatik hesaplanabilmeli (opsiyonel)
  - Veya kullanıcı start/end time'ı manuel seçmeli
  - Validation kontrolleri çalışmalı

---

## 6. ÇOKLU BEBEK SENARYOLARI

### Senaryo 6.1: Farklı Bebekler İçin Ayrı Notes
- **Durum**: Anne iki bebeği takip ediyor
- **Beklenen**:
  - Her bebek için ayrı notes cache'i olmalı
  - Bebek değiştirildiğinde notes doğru yüklenmeli
  - Timer durumları ayrı olmalı

---

## 7. EDGE CASE'LER

### Senaryo 7.1: Çok Eski Tarih (1 Yıl Öncesi)
- **Durum**: Anne çok eski bir tarih seçmeye çalışıyor
- **Beklenen**:
  - 1 yıl öncesi limiti olmalı
  - Hata mesajı gösterilmeli

### Senaryo 7.2: Gece Yarısı Tam Saatinde
- **Durum**: Start time 23:59, End time 00:01
- **Beklenen**:
  - Tarihler doğru hesaplanmalı (full DateTime)
  - Duration 2 dakika olarak hesaplanmalı
  - Gece yarısını geçen durumlar doğru işlenmeli

### Senaryo 7.3: Çok Kısa Emzirme (1 Dakika)
- **Durum**: Anne 1 dakikalık emzirme kaydı girmeye çalışıyor
- **Beklenen**:
  - Minimum süre kontrolü olabilir (opsiyonel)
  - Veya herhangi bir süre kabul edilebilir

---

## 8. KULLANICI DENEYİMİ SENARYOLARI

### Senaryo 8.1: İlk Açılış (Boş Form - Bottle Feed)
- **Durum**: Anne ilk kez bottle feed sayfasını açtı
- **Beklenen**:
  - Feeding time: "Add"
  - Feeding type: Seçilmemiş
  - Amount: Boş
  - Notes: Boş

### Senaryo 8.2: İlk Açılış (Boş Form - Breastfeed)
- **Durum**: Anne ilk kez breastfeed sayfasını açtı
- **Beklenen**:
  - Sol/Sağ Start time: "Add"
  - Sol/Sağ End time: "Add"
  - Sol/Sağ Total time: "00:00"
  - Notes: Boş
  - Timer: Durmuş

### Senaryo 8.3: Timer Çalışırken Görünüm (Breastfeed)
- **Durum**: Timer çalışıyor
- **Beklenen**:
  - Start time: Görünmeli (timer başlatıldığında kaydedilen zaman - full DateTime)
  - End time: "Add" (disabled, gri)
  - Total time: Gerçek zamanlı artmalı
  - Timer circle: Animasyonlu olmalı

### Senaryo 8.4: Kayıt Başarılı
- **Durum**: Anne kayıt yaptı
- **Beklenen**:
  - Başarı mesajı gösterilmeli
  - Sayfa kapanmalı
  - Ana sayfaya dönülmeli
  - Timer resetlenmeli (breastfeed için)
  - Geçici cache temizlenmeli

---

## 9. HATA KURTARMA SENARYOLARI

### Senaryo 9.1: Network Hatası
- **Durum**: Kayıt yapılırken internet kesildi
- **Beklenen**:
  - Local database'e kaydedilmeli
  - Sync durumu işaretlenmeli
  - İnternet geldiğinde otomatik sync yapılmalı

### Senaryo 9.2: Uygulama Çökmesi
- **Durum**: Timer çalışırken uygulama çöktü
- **Beklenen**:
  - Timer durumu local database'de saklanmalı
  - Uygulama açıldığında timer durumu yüklenmeli
  - Timer kaldığı yerden devam etmeli

---

## 10. PERFORMANS SENARYOLARI

### Senaryo 10.1: Uzun Süre Timer Çalışması
- **Durum**: Timer 2 saat çalıştı
- **Beklenen**:
  - Performance sorunu olmamalı
  - Battery drain minimal olmalı
  - Timer doğru çalışmaya devam etmeli

---

## ÖZET: KRİTİK VALİDASYON KURALLARI

### Bottle Feed İçin:
1. ✅ Feeding time gelecekte olamaz
2. ✅ Feeding time 1 yıl öncesinden eski olamaz
3. ✅ Tüm zorunlu alanlar doldurulmalı (feeding time, type, amount)
4. ✅ Notes geçici olarak kaydedilmeli

### Breastfeed İçin:
1. ✅ Start time end time'dan sonra olamaz
2. ✅ End time start time'dan önce olamaz
3. ✅ Start ve end time aynı olamaz
4. ✅ Start ve end time gelecekte olamaz
5. ✅ Start ve end time 1 yıl öncesinden eski olamaz
6. ✅ Timer çalışırken end time disabled olmalı
7. ✅ Gece yarısını geçen durumlar doğru hesaplanmalı (full DateTime)
8. ✅ Notes geçici olarak kaydedilmeli

---

## YAPILMASI GEREKENLER

### 1. CustomDateTimePicker Entegrasyonu
- [ ] Bottle feed için CustomDateTimePicker kullanılmalı (şu an kullanılıyor ama validation yok)
- [ ] Breastfeed için start/end time'lar CustomDateTimePicker ile değiştirilmeli (şu an sadece TimePicker var)
- [ ] Full DateTime objeleri kullanılmalı (sadece saat/dakika değil)

### 2. Validation Kuralları
- [ ] Gelecekteki tarih kontrolü (maxDate: DateTime.now())
- [ ] 1 yıl öncesi limiti (minDate: DateTime.now().subtract(Duration(days: 365)))
- [ ] Start/end time ilişkisi kontrolü (breastfeed için)
- [ ] Eksik alan kontrolü
- [ ] Start ve end time aynı olamaz kontrolü

### 3. Notes Geçici Kayıt
- [ ] SharedPrefsHelper'a feed tracker notes metodları eklenmeli
- [ ] Notes değişikliklerinde otomatik kayıt
- [ ] Sayfa açılışında notes geri yükleme
- [ ] Kayıt yapıldığında notes temizleme
- [ ] Her bebek için ayrı cache key'i

### 4. Timer State Persistence
- [ ] Timer durumu local database'de saklanmalı
- [ ] Uygulama açılışında timer durumu yüklenmeli
- [ ] Timer çalışırken sayfa kapatıldığında durum korunmalı

### 5. Data Format Değişikliği
- [ ] Eski format: Sadece hour/minute (backward compatibility için korunmalı)
- [ ] Yeni format: Full DateTime ISO string (startTimeDate, endTimeDate)
- [ ] Edit modunda eski format desteği

### 6. Breastfeed Timer Bloc Güncellemeleri
- [ ] SetStartTimeTimer event'i full DateTime kabul etmeli
- [ ] SetEndTimeTimer event'i full DateTime kabul etmeli
- [ ] Gece yarısını geçen durumlar için doğru hesaplama
- [ ] Timer çalışırken end time disabled kontrolü

### 7. UI Güncellemeleri
- [ ] CustomDateTimePicker ile "Today HH:mm" veya "Month Day HH:mm" formatı
- [ ] End time disabled durumunda gri görünüm
- [ ] Validation hataları için error mesajları
- [ ] Loading states

### 8. Test Senaryoları
- [ ] Timer başlatma ve durdurma
- [ ] Gece yarısını geçen kayıtlar
- [ ] Eski tarihli kayıtlar
- [ ] Gelecekteki tarih engelleme
- [ ] Validation hataları
- [ ] Notes geçici kayıt
- [ ] Timer state persistence
- [ ] Çoklu bebek desteği
- [ ] Edge case'ler

---

## NOTLAR

1. **Backward Compatibility**: Eski veriler sadece hour/minute içeriyor. Yeni format full DateTime kullanıyor. Edit modunda eski format desteği olmalı.

2. **Timer Bloc Değişiklikleri**: Breastfeed timer bloc'ları şu an sadece hour/minute kullanıyor. Full DateTime kullanımına geçilmeli.

3. **CustomDateTimePicker**: Sleep tracker'da kullanılan aynı picker kullanılmalı. minDate ve maxDate parametreleri ile validation yapılmalı.

4. **Notes Cache**: Her bebek için ayrı cache key'i kullanılmalı: `feed_tracker_notes_{babyID}`

5. **Timer State**: Timer durumları local database'de saklanmalı. Uygulama açılışında yüklenmeli.

6. **Validation Mesajları**: Tüm validation hataları için kullanıcı dostu mesajlar gösterilmeli.


