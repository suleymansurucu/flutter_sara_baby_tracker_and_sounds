# Sleep Tracker - Kullanıcı Senaryoları (Anne Perspektifi)

## 1. GÜNLÜK KULLANIM SENARYOLARI

### Senaryo 1.1: Bebek Uyudu, Timer Başlatıldı
- **Durum**: Bebek uyudu, anne timer'ı başlattı
- **Beklenen**: 
  - Start time otomatik olarak şu anki zaman olarak kaydedilmeli
  - Timer çalışmaya başlamalı
  - End time "Add" olarak görünmeli (disabled)
  - Total sleep time gerçek zamanlı olarak artmalı

### Senaryo 1.2: Bebek Uyandı, Timer Durduruldu
- **Durum**: Bebek uyandı, anne timer'ı durdurdu
- **Beklenen**:
  - Start time görünmeli (timer başlatıldığında kaydedilen zaman)
  - End time otomatik olarak şu anki zaman olarak ayarlanmalı
  - Total sleep time hesaplanmalı
  - Notes eklenebilmeli
  - Kaydet butonu aktif olmalı

### Senaryo 1.3: Timer Çalışırken Sayfa Kapatıldı
- **Durum**: Timer çalışırken anne başka sayfaya gitti veya uygulamayı kapattı
- **Beklenen**:
  - Timer arka planda çalışmaya devam etmeli
  - Sayfa tekrar açıldığında timer durumu korunmalı
  - Start time görünmeli
  - Total sleep time doğru hesaplanmalı

### Senaryo 1.4: Timer Çalışırken Manuel End Time Seçildi
- **Durum**: Timer çalışırken anne manuel olarak end time seçti
- **Beklenen**:
  - Timer otomatik olarak durmalı
  - Seçilen end time kaydedilmeli
  - Total sleep time yeniden hesaplanmalı
  - Manuel moda geçilmeli

---

## 2. MANUEL KAYIT SENARYOLARI

### Senaryo 2.1: Geçmiş Uyku Kaydı - Aynı Gün
- **Durum**: Anne sabah bebeğin gece uykusunu kaydetmek istiyor
- **Örnek**: 
  - Start: Dün gece 22:00
  - End: Bu sabah 06:00
- **Beklenen**:
  - Gece yarısını geçen durumlar doğru hesaplanmalı (8 saat)
  - Tarihler doğru kaydedilmeli
  - 24 saat limiti kontrol edilmeli

### Senaryo 2.2: Geçmiş Uyku Kaydı - Farklı Gün
- **Durum**: Anne dünkü uyku kaydını unutmuş, şimdi ekliyor
- **Örnek**:
  - Start: Dün 14:00
  - End: Dün 16:30
- **Beklenen**:
  - Eski tarihler seçilebilmeli
  - Gelecekteki tarihler seçilememeli
  - Duration doğru hesaplanmalı (2.5 saat)

### Senaryo 2.3: Gece Yarısını Geçen Uyku
- **Durum**: Bebek gece yarısından önce uyudu, sonra uyandı
- **Örnek**:
  - Start: 22 Kasım 21:52
  - End: 23 Kasım 07:52
- **Beklenen**:
  - Tarihler doğru kaydedilmeli
  - Duration doğru hesaplanmalı (10 saat)
  - Validation gece yarısını geçen durumları kabul etmeli

### Senaryo 2.4: Kısa Uyku (Öğle Uykusu)
- **Durum**: Bebek öğle uykusuna yattı
- **Örnek**:
  - Start: Bugün 13:00
  - End: Bugün 14:30
- **Beklenen**:
  - 1.5 saatlik uyku doğru kaydedilmeli
  - Aynı gün içinde kayıt yapılabilmeli

---

## 3. DÜZENLEME SENARYOLARI

### Senaryo 3.1: Yanlış Kayıt Düzeltme
- **Durum**: Anne yanlış saat girmiş, düzeltmek istiyor
- **Beklenen**:
  - Mevcut değerler formda görünmeli
  - Değişiklik yapılabilmeli
  - Validation kontrolleri çalışmalı
  - Güncelleme başarılı olmalı

### Senaryo 3.2: Notes Ekleme/Düzenleme
- **Durum**: Anne kayıt oluştururken notes yazdı, sonra düzenlemek istiyor
- **Beklenen**:
  - Notes kaydedilmeli
  - Düzenleme modunda notes görünmeli
  - Değişiklikler kaydedilmeli

---

## 4. HATA VE VALİDASYON SENARYOLARI

### Senaryo 4.1: End Time Start Time'dan Önce
- **Durum**: Anne yanlışlıkla end time'ı start time'dan önce seçti
- **Beklenen**:
  - Hata mesajı gösterilmeli
  - Kayıt yapılmamalı
  - Kullanıcı düzeltme yapabilmeli

### Senaryo 4.2: 24 Saati Aşan Uyku
- **Durum**: Anne yanlışlıkla 25 saatlik uyku kaydı girmeye çalışıyor
- **Beklenen**:
  - Hata mesajı gösterilmeli ("Sleep duration cannot exceed 24 hours")
  - Kayıt yapılmamalı
  - Kullanıcı düzeltme yapabilmeli

### Senaryo 4.3: Gelecekteki Tarih
- **Durum**: Anne yanlışlıkla gelecekteki bir tarih seçti
- **Beklenen**:
  - Hata mesajı gösterilmeli
  - Kayıt yapılmamalı
  - Sadece geçmiş ve bugünkü tarihler kabul edilmeli

### Senaryo 4.4: Eksik Alanlar
- **Durum**: Anne start time seçti ama end time seçmeden kaydetmeye çalışıyor
- **Beklenen**:
  - Hata mesajı gösterilmeli ("Please complete all fields")
  - Kayıt yapılmamalı
  - Eksik alanlar işaretlenmeli

### Senaryo 4.5: Start ve End Time Aynı
- **Durum**: Anne yanlışlıkla start ve end time'ı aynı yaptı
- **Beklenen**:
  - Hata mesajı gösterilmeli
  - Kayıt yapılmamalı
  - Duration 0 olamaz

### Senaryo 4.6: Duration ile Start-End Uyumsuzluğu
- **Durum**: Anne start-end aralığı 5 saat ama duration'ı 3 saat seçti
- **Beklenen**:
  - Hata mesajı gösterilmeli
  - Kayıt yapılmamalı
  - Duration start-end aralığı ile uyumlu olmalı

---

## 5. ÖZEL DURUMLAR

### Senaryo 5.1: Timer Çalışırken Start Time Değiştirildi
- **Durum**: Timer çalışırken anne start time'ı değiştirdi
- **Beklenen**:
  - Timer durmalı
  - Manuel moda geçilmeli
  - Yeni start time kaydedilmeli
  - End time null olmalı

### Senaryo 5.2: Duration Picker'dan Süre Seçildi
- **Durum**: Anne start ve end time yerine direkt duration seçti
- **Beklenen**:
  - 24 saat limiti kontrol edilmeli
  - Start ve end time otomatik hesaplanabilmeli (opsiyonel)
  - Veya kullanıcı start/end time'ı manuel seçmeli

### Senaryo 5.3: Reset Butonuna Basıldı
- **Durum**: Anne tüm alanları temizlemek istiyor
- **Beklenen**:
  - Tüm alanlar temizlenmeli
  - Timer resetlenmeli
  - Notes temizlenmeli
  - Geçici cache temizlenmeli

### Senaryo 5.4: Sayfa Kapatılıp Tekrar Açıldı (Notes Kaybolması)
- **Durum**: Anne notes yazdı, sayfayı kapattı, tekrar açtı
- **Beklenen**:
  - Notes geçici olarak kaydedilmeli (SharedPreferences)
  - Sayfa açıldığında notes geri yüklenmeli
  - Kayıt yapıldığında notes temizlenmeli

### Senaryo 5.5: Timer Çalışırken End Time Disabled
- **Durum**: Timer çalışırken anne end time seçmeye çalışıyor
- **Beklenen**:
  - End time picker disabled olmalı
  - Görsel olarak gri görünmeli
  - Tıklanamaz olmalı

---

## 6. ÇOKLU BEBEK SENARYOLARI

### Senaryo 6.1: Farklı Bebekler İçin Ayrı Notes
- **Durum**: Anne iki bebeği takip ediyor
- **Beklenen**:
  - Her bebek için ayrı notes cache'i olmalı
  - Bebek değiştirildiğinde notes doğru yüklenmeli

---

## 7. EDGE CASE'LER

### Senaryo 7.1: Çok Eski Tarih (1 Yıl Öncesi)
- **Durum**: Anne çok eski bir tarih seçmeye çalışıyor
- **Beklenen**:
  - Mantıklı bir limit olmalı (ör: 1 yıl)
  - Veya sınırsız olabilir (kullanıcı tercihi)

### Senaryo 7.2: Tam 24 Saatlik Uyku
- **Durum**: Anne tam 24 saatlik uyku kaydı girmeye çalışıyor
- **Beklenen**:
  - 24 saat = 86400 saniye kontrolü yapılmalı
  - Tam 24 saat kabul edilmeli veya edilmemeli (business rule)

### Senaryo 7.3: Gece Yarısı Tam Saatinde
- **Durum**: Start time 23:59, End time 00:01
- **Beklenen**:
  - Tarihler doğru hesaplanmalı
  - Duration 2 dakika olarak hesaplanmalı
  - Gece yarısını geçen durumlar doğru işlenmeli

### Senaryo 7.4: Çok Kısa Uyku (1 Dakika)
- **Durum**: Anne 1 dakikalık uyku kaydı girmeye çalışıyor
- **Beklenen**:
  - Minimum süre kontrolü olabilir (opsiyonel)
  - Veya herhangi bir süre kabul edilebilir

### Senaryo 7.5: Çok Uzun Uyku (23 Saat 59 Dakika)
- **Durum**: Anne 23 saat 59 dakikalık uyku kaydı girmeye çalışıyor
- **Beklenen**:
  - 24 saat limiti içinde olduğu için kabul edilmeli
  - Validation geçmeli

---

## 8. KULLANICI DENEYİMİ SENARYOLARI

### Senaryo 8.1: İlk Açılış (Boş Form)
- **Durum**: Anne ilk kez sleep tracker sayfasını açtı
- **Beklenen**:
  - Start time: "Add"
  - End time: "Add"
  - Total sleep time: "00:00"
  - Notes: Boş
  - Timer: Durmuş

### Senaryo 8.2: Timer Çalışırken Görünüm
- **Durum**: Timer çalışıyor
- **Beklenen**:
  - Start time: Görünmeli (timer başlatıldığında kaydedilen zaman)
  - End time: "Add" (disabled, gri)
  - Total sleep time: Gerçek zamanlı artmalı
  - Timer circle: Animasyonlu olmalı

### Senaryo 8.3: Kayıt Başarılı
- **Durum**: Anne kayıt yaptı
- **Beklenen**:
  - Başarı mesajı gösterilmeli
  - Sayfa kapanmalı
  - Ana sayfaya dönülmeli
  - Timer resetlenmeli
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
- **Durum**: Timer 12 saat çalıştı
- **Beklenen**:
  - Performance sorunu olmamalı
  - Battery drain minimal olmalı
  - Timer doğru çalışmaya devam etmeli

---

## ÖZET: KRİTİK VALİDASYON KURALLARI

1. ✅ Start time end time'dan sonra olamaz
2. ✅ End time start time'dan önce olamaz
3. ✅ Start ve end time aynı olamaz
4. ✅ Duration 24 saati geçemez (86400 saniye)
5. ✅ Start ve end time gelecekte olamaz
6. ✅ Duration ile start-end aralığı uyumlu olmalı
7. ✅ Tüm alanlar doldurulmalı
8. ✅ Gece yarısını geçen durumlar doğru hesaplanmalı
9. ✅ Timer çalışırken end time disabled olmalı
10. ✅ Notes geçici olarak kaydedilmeli

---

## TEST EDİLMESİ GEREKEN DURUMLAR

- [ ] Timer başlatma ve durdurma
- [ ] Gece yarısını geçen uyku kayıtları
- [ ] Eski tarihli kayıtlar
- [ ] Gelecekteki tarih engelleme
- [ ] 24 saat limiti kontrolü
- [ ] Validation hataları
- [ ] Notes geçici kayıt
- [ ] Timer state persistence
- [ ] Çoklu bebek desteği
- [ ] Edge case'ler (tam 24 saat, çok kısa süre, vb.)

