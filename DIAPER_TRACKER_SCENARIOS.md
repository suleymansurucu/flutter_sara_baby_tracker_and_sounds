# Diaper Tracker - Kullanıcı Senaryoları (Anne Perspektifi)

## ÖNEMLİ NOTLAR
- Sleep tracker'da yapılan değişiklikler diaper tracker'a da uygulanmalı
- CustomDateTimePicker kullanılmalı (tarih + saat birlikte)
- Full DateTime objeleri kullanılmalı (sadece saat/dakika değil)
- Validation kuralları sleep tracker ile aynı olmalı
- Notes geçici kayıt (SharedPreferences) eklenmeli
- Wet/Dirty/Dry seçimi, Dirty için texture ve color seçimi var

---

## 1. GÜNLÜK KULLANIM SENARYOLARI

### Senaryo 1.1: Normal Bez Değişimi (Wet)
- **Durum**: Bebek bezini ıslattı, anne kayıt yapmak istiyor
- **Beklenen**:
  - Time: CustomDateTimePicker ile tarih + saat seçilebilmeli
  - Diaper Condition: "Wet" seçilebilmeli
  - Dirty detail options görünmemeli (sadece Dirty seçildiğinde görünmeli)
  - Additional observations seçilebilmeli
  - Notes eklenebilmeli
  - Kayıt başarılı olmalı

### Senaryo 1.2: Normal Bez Değişimi (Dirty)
- **Durum**: Bebek bezini kirletti, anne kayıt yapmak istiyor
- **Beklenen**:
  - Time: CustomDateTimePicker ile tarih + saat seçilebilmeli
  - Diaper Condition: "Dirty" seçilebilmeli
  - Dirty detail options görünmeli (texture ve color seçimi)
  - Texture ve color seçilebilmeli
  - Additional observations seçilebilmeli
  - Notes eklenebilmeli
  - Kayıt başarılı olmalı

### Senaryo 1.3: Normal Bez Değişimi (Dry)
- **Durum**: Bebek bezini değiştirdi ama kuru, anne kayıt yapmak istiyor
- **Beklenen**:
  - Time: CustomDateTimePicker ile tarih + saat seçilebilmeli
  - Diaper Condition: "Dry" seçilebilmeli
  - Dirty detail options görünmemeli
  - Additional observations seçilebilmeli
  - Notes eklenebilmeli
  - Kayıt başarılı olmalı

### Senaryo 1.4: Geçmiş Bez Değişimi Kaydı
- **Durum**: Anne dünkü bez değişimini unutmuş, şimdi ekliyor
- **Örnek**:
  - Time: Dün 14:00
  - Condition: Dirty
  - Texture: Soft
  - Color: Yellow
- **Beklenen**:
  - Eski tarihler seçilebilmeli
  - Gelecekteki tarihler seçilememeli
  - Tüm detaylar kaydedilmeli
  - Kayıt başarılı olmalı

### Senaryo 1.5: Wet ve Dirty Birlikte
- **Durum**: Bebek hem ıslattı hem kirletti
- **Beklenen**:
  - Hem "Wet" hem "Dirty" seçilebilmeli
  - Dirty seçildiğinde detail options görünmeli
  - Kayıt başarılı olmalı

### Senaryo 1.6: Additional Observations
- **Durum**: Anne bez değişiminde özel durumlar fark etti
- **Beklenen**:
  - Blowout checkbox'ı işaretlenebilmeli
  - Diaper rush checkbox'ı işaretlenebilmeli
  - Blood in stool checkbox'ı işaretlenebilmeli
  - Birden fazla observation seçilebilmeli
  - Kayıt başarılı olmalı

---

## 2. DÜZENLEME SENARYOLARI

### Senaryo 2.1: Yanlış Kayıt Düzeltme
- **Durum**: Anne yanlış saat girmiş, düzeltmek istiyor
- **Beklenen**:
  - Mevcut değerler formda görünmeli
  - Time değiştirilebilmeli
  - Condition değiştirilebilmeli
  - Texture/color değiştirilebilmeli
  - Validation kontrolleri çalışmalı
  - Güncelleme başarılı olmalı

### Senaryo 2.2: Notes Ekleme/Düzenleme
- **Durum**: Anne kayıt oluştururken notes yazdı, sonra düzenlemek istiyor
- **Beklenen**:
  - Notes kaydedilmeli
  - Düzenleme modunda notes görünmeli
  - Değişiklikler kaydedilmeli

---

## 3. HATA VE VALİDASYON SENARYOLARI

### Senaryo 3.1: Condition Seçmeden Kaydetme
- **Durum**: Anne condition seçmeden kaydetmeye çalışıyor
- **Beklenen**:
  - Hata mesajı gösterilmeli ("Please choose diaper condition")
  - Kayıt yapılmamalı
  - Kullanıcı condition seçebilmeli

### Senaryo 3.2: Gelecekteki Tarih
- **Durum**: Anne yanlışlıkla gelecekteki bir tarih seçti
- **Beklenen**:
  - Hata mesajı gösterilmeli ("Date cannot be in the future")
  - Kayıt yapılmamalı
  - Sadece geçmiş ve bugünkü tarihler kabul edilmeli

### Senaryo 3.3: Çok Eski Tarih (1 Yıl Öncesi)
- **Durum**: Anne çok eski bir tarih seçmeye çalışıyor
- **Beklenen**:
  - Hata mesajı gösterilmeli ("Date cannot be more than 1 year ago")
  - Kayıt yapılmamalı
  - 1 yıl öncesi limiti olmalı

---

## 4. ÖZEL DURUMLAR

### Senaryo 4.1: Reset Butonuna Basıldı
- **Durum**: Anne tüm alanları temizlemek istiyor
- **Beklenen**:
  - Tüm alanlar temizlenmeli
  - Condition seçimi temizlenmeli
  - Texture/color seçimi temizlenmeli
  - Additional observations temizlenmeli
  - Notes temizlenmeli
  - Geçici cache temizlenmeli

### Senaryo 4.2: Sayfa Kapatılıp Tekrar Açıldı (Notes Kaybolması)
- **Durum**: Anne notes yazdı, sayfayı kapattı, tekrar açtı
- **Beklenen**:
  - Notes geçici olarak kaydedilmeli (SharedPreferences)
  - Sayfa açıldığında notes geri yüklenmeli
  - Kayıt yapıldığında notes temizlenmeli
  - Her bebek için ayrı notes cache'i olmalı

### Senaryo 4.3: Dirty Seçildiğinde Detail Options Görünümü
- **Durum**: Anne "Dirty" seçti
- **Beklenen**:
  - Dirty detail options görünmeli
  - Texture seçimi görünmeli
  - Color seçimi görünmeli
  - "Wet" veya "Dry" seçildiğinde detail options gizlenmeli

### Senaryo 4.4: Dirty Seçimi Kaldırıldığında Detail Options
- **Durum**: Anne "Dirty" seçti, sonra kaldırdı
- **Beklenen**:
  - Dirty detail options gizlenmeli
  - Texture/color seçimi temizlenmeli

---

## 5. ÇOKLU BEBEK SENARYOLARI

### Senaryo 5.1: Farklı Bebekler İçin Ayrı Notes
- **Durum**: Anne iki bebeği takip ediyor
- **Beklenen**:
  - Her bebek için ayrı notes cache'i olmalı
  - Bebek değiştirildiğinde notes doğru yüklenmeli

---

## 6. EDGE CASE'LER

### Senaryo 6.1: Çok Eski Tarih (1 Yıl Öncesi)
- **Durum**: Anne çok eski bir tarih seçmeye çalışıyor
- **Beklenen**:
  - 1 yıl öncesi limiti olmalı
  - Hata mesajı gösterilmeli

### Senaryo 6.2: Gece Yarısı Tam Saatinde
- **Durum**: Bez değişimi gece yarısında yapıldı
- **Beklenen**:
  - Tarih doğru kaydedilmeli (full DateTime)
  - Kayıt başarılı olmalı

### Senaryo 6.3: Tüm Additional Observations Seçildi
- **Durum**: Anne tüm observation'ları seçti
- **Beklenen**:
  - Tüm checkbox'lar işaretlenebilmeli
  - Kayıt başarılı olmalı

---

## 7. KULLANICI DENEYİMİ SENARYOLARI

### Senaryo 7.1: İlk Açılış (Boş Form)
- **Durum**: Anne ilk kez diaper tracker sayfasını açtı
- **Beklenen**:
  - Time: "Add"
  - Diaper Condition: Seçilmemiş
  - Dirty detail options: Gizli
  - Additional observations: Tümü işaretsiz
  - Notes: Boş

### Senaryo 7.2: Dirty Seçildikten Sonra Görünüm
- **Durum**: Anne "Dirty" seçti
- **Beklenen**:
  - Dirty detail options görünmeli
  - Texture seçimi görünmeli
  - Color seçimi görünmeli

### Senaryo 7.3: Kayıt Başarılı
- **Durum**: Anne kayıt yaptı
- **Beklenen**:
  - Başarı mesajı gösterilmeli
  - Sayfa kapanmalı
  - Ana sayfaya dönülmeli
  - Geçici cache temizlenmeli

---

## 8. HATA KURTARMA SENARYOLARI

### Senaryo 8.1: Network Hatası
- **Durum**: Kayıt yapılırken internet kesildi
- **Beklenen**:
  - Local database'e kaydedilmeli
  - Sync durumu işaretlenmeli
  - İnternet geldiğinde otomatik sync yapılmalı

### Senaryo 8.2: Uygulama Çökmesi
- **Durum**: Kayıt yapılırken uygulama çöktü
- **Beklenen**:
  - Notes geçici olarak kaydedilmeli
  - Uygulama açıldığında notes geri yüklenmeli

---

## ÖZET: KRİTİK VALİDASYON KURALLARI

1. ✅ Time gelecekte olamaz
2. ✅ Time 1 yıl öncesinden eski olamaz
3. ✅ En az bir diaper condition seçilmeli
4. ✅ Dirty seçildiğinde texture/color seçimi görünmeli (opsiyonel)
5. ✅ Notes geçici olarak kaydedilmeli

---

## YAPILMASI GEREKENLER

### 1. CustomDateTimePicker Entegrasyonu
- [ ] CustomDateTimePicker kullanılmalı (şu an kullanılıyor ama validation yok)
- [ ] Full DateTime objeleri kullanılmalı (sadece saat/dakika değil)
- [ ] initialDateTime parametresi eklenmeli
- [ ] maxDate ve minDate parametreleri eklenmeli

### 2. Validation Kuralları
- [ ] Gelecekteki tarih kontrolü (maxDate: DateTime.now())
- [ ] 1 yıl öncesi limiti (minDate: DateTime.now().subtract(Duration(days: 365)))
- [ ] Diaper condition seçimi kontrolü (en az bir condition gerekli)

### 3. Notes Geçici Kayıt
- [ ] SharedPrefsHelper'a diaper tracker notes metodları eklenmeli
- [ ] Notes değişikliklerinde otomatik kayıt
- [ ] Sayfa açılışında notes geri yükleme
- [ ] Kayıt yapıldığında notes temizleme
- [ ] Her bebek için ayrı cache key'i

### 4. Data Format Değişikliği
- [ ] Eski format: Sadece hour/minute (backward compatibility için korunmalı)
- [ ] Yeni format: Full DateTime ISO string (activityDateTime zaten var)
- [ ] Edit modunda eski format desteği

### 5. UI Güncellemeleri
- [ ] CustomDateTimePicker ile "Today HH:mm" veya "Month Day HH:mm" formatı
- [ ] Validation hataları için error mesajları
- [ ] Dirty detail options görünüm/gizleme animasyonu

### 6. Test Senaryoları
- [ ] Diaper condition seçimi ve kayıt
- [ ] Geçmiş tarihli kayıtlar
- [ ] Gelecekteki tarih engelleme
- [ ] Validation hataları
- [ ] Notes geçici kayıt
- [ ] Çoklu bebek desteği
- [ ] Dirty detail options görünüm/gizleme
- [ ] Additional observations seçimi

---

## NOTLAR

1. **Backward Compatibility**: Eski veriler sadece hour/minute içeriyor. Yeni format full DateTime kullanıyor. Edit modunda eski format desteği olmalı.

2. **Dirty Detail Options**: Sadece "Dirty" seçildiğinde görünmeli. "Wet" veya "Dry" seçildiğinde gizlenmeli.

3. **Multiple Conditions**: "Wet" ve "Dirty" birlikte seçilebilmeli.

4. **Notes Cache**: Her bebek için ayrı cache key'i kullanılmalı: `diaper_tracker_notes_{babyID}`

5. **Validation Mesajları**: Tüm validation hataları için kullanıcı dostu mesajlar gösterilmeli.


