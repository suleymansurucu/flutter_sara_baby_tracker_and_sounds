# Baby Firsts Tracker - Kullanıcı Senaryoları (Anne Perspektifi)

## ÖNEMLİ NOTLAR
- Sleep tracker'da yapılan değişiklikler baby firsts tracker'a da uygulanmalı
- CustomDateTimePicker kullanılmalı (tarih + saat birlikte)
- Full DateTime objeleri kullanılmalı (sadece saat/dakika değil)
- Validation kuralları sleep tracker ile aynı olmalı
- Notes geçici kayıt (SharedPreferences) eklenmeli
- Milestone seçimi dialog içinde yapılıyor, dialog içinde de tarih seçimi var

---

## 1. GÜNLÜK KULLANIM SENARYOLARI

### Senaryo 1.1: İlk Milestone Kaydı
- **Durum**: Bebek ilk kez bir şey yaptı (ör: ilk gülümseme), anne kayıt yapmak istiyor
- **Beklenen**:
  - Time: CustomDateTimePicker ile tarih + saat seçilebilmeli
  - Baby Firsts: "Add" butonuna tıklayınca dialog açılmalı
  - Dialog içinde milestone seçilebilmeli
  - Seçilen milestone'lar chip olarak görünmeli
  - Notes eklenebilmeli
  - Kayıt başarılı olmalı

### Senaryo 1.2: Geçmiş Milestone Kaydı
- **Durum**: Anne dünkü bir milestone'u unutmuş, şimdi ekliyor
- **Örnek**:
  - Time: Dün 14:00
  - Milestone: "First smile"
- **Beklenen**:
  - Eski tarihler seçilebilmeli
  - Gelecekteki tarihler seçilememeli
  - Kayıt başarılı olmalı

### Senaryo 1.3: Birden Fazla Milestone Seçimi
- **Durum**: Anne aynı gün birden fazla milestone kaydetmek istiyor
- **Beklenen**:
  - Dialog içinde birden fazla milestone seçilebilmeli
  - Seçilen milestone'lar chip olarak görünmeli
  - Her chip silinebilmeli
  - Kayıt başarılı olmalı

### Senaryo 1.4: Daha Önce Seçilmiş Milestone Engelleme
- **Durum**: Anne daha önce kaydedilmiş bir milestone'u tekrar seçmeye çalışıyor
- **Beklenen**:
  - Daha önce seçilmiş milestone'lar disabled olmalı
  - Checkbox tıklanamaz olmalı
  - Kullanıcıya görsel olarak gösterilmeli

### Senaryo 1.5: Dialog İçinde Tarih Seçimi
- **Durum**: Anne dialog açtı, milestone seçti, dialog içindeki tarih picker'ı kullanmak istiyor
- **Beklenen**:
  - Dialog içinde CustomDateTimePicker çalışmalı
  - Tarih seçildiğinde ana formdaki tarih güncellenmeli
  - Validation kuralları geçerli olmalı

---

## 2. DÜZENLEME SENARYOLARI

### Senaryo 2.1: Yanlış Kayıt Düzeltme
- **Durum**: Anne yanlış milestone seçmiş, düzeltmek istiyor
- **Beklenen**:
  - Mevcut değerler formda görünmeli
  - Milestone'lar chip olarak görünmeli
  - Chip'ler silinebilmeli
  - Yeni milestone eklenebilmeli
  - Tarih değiştirilebilmeli
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

### Senaryo 3.1: Milestone Seçmeden Kaydetme
- **Durum**: Anne milestone seçmeden kaydetmeye çalışıyor
- **Beklenen**:
  - Hata mesajı gösterilmeli ("Please enter baby first activity")
  - Kayıt yapılmamalı
  - Kullanıcı milestone seçebilmeli

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
  - Milestone chip'leri silinmeli
  - Notes temizlenmeli
  - Geçici cache temizlenmeli

### Senaryo 4.2: Sayfa Kapatılıp Tekrar Açıldı (Notes Kaybolması)
- **Durum**: Anne notes yazdı, sayfayı kapattı, tekrar açtı
- **Beklenen**:
  - Notes geçici olarak kaydedilmeli (SharedPreferences)
  - Sayfa açıldığında notes geri yüklenmeli
  - Kayıt yapıldığında notes temizlenmeli
  - Her bebek için ayrı notes cache'i olmalı

### Senaryo 4.3: Dialog İptal Edildi
- **Durum**: Anne dialog açtı, milestone seçti ama iptal etti
- **Beklenen**:
  - Dialog kapanmalı
  - Seçilen milestone'lar kaydedilmemeli
  - Ana formdaki değişiklikler korunmalı

### Senaryo 4.4: Dialog İçinde Milestone Seçimi ve Kayıt
- **Durum**: Anne dialog açtı, milestone seçti, "Add" butonuna bastı
- **Beklenen**:
  - Dialog kapanmalı
  - Seçilen milestone'lar chip olarak görünmeli
  - Ana formda milestone'lar görünmeli

---

## 5. ÇOKLU BEBEK SENARYOLARI

### Senaryo 5.1: Farklı Bebekler İçin Ayrı Notes
- **Durum**: Anne iki bebeği takip ediyor
- **Beklenen**:
  - Her bebek için ayrı notes cache'i olmalı
  - Bebek değiştirildiğinde notes doğru yüklenmeli
  - Her bebek için ayrı milestone kayıtları olmalı

---

## 6. EDGE CASE'LER

### Senaryo 6.1: Çok Eski Tarih (1 Yıl Öncesi)
- **Durum**: Anne çok eski bir tarih seçmeye çalışıyor
- **Beklenen**:
  - 1 yıl öncesi limiti olmalı
  - Hata mesajı gösterilmeli

### Senaryo 6.2: Gece Yarısı Tam Saatinde
- **Durum**: Milestone gece yarısında gerçekleşti
- **Beklenen**:
  - Tarih doğru kaydedilmeli (full DateTime)
  - Kayıt başarılı olmalı

---

## 7. KULLANICI DENEYİMİ SENARYOLARI

### Senaryo 7.1: İlk Açılış (Boş Form)
- **Durum**: Anne ilk kez baby firsts sayfasını açtı
- **Beklenen**:
  - Time: "Add"
  - Baby Firsts: "Add" butonu görünmeli
  - Milestone chip'leri görünmemeli
  - Notes: Boş

### Senaryo 7.2: Milestone Seçildikten Sonra Görünüm
- **Durum**: Anne milestone seçti
- **Beklenen**:
  - Seçilen milestone'lar chip olarak görünmeli
  - Her chip silinebilmeli
  - "Add" butonu hala görünmeli (yeni milestone eklemek için)

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
3. ✅ En az bir milestone seçilmeli
4. ✅ Daha önce seçilmiş milestone'lar tekrar seçilememeli
5. ✅ Notes geçici olarak kaydedilmeli

---

## YAPILMASI GEREKENLER

### 1. CustomDateTimePicker Entegrasyonu
- [ ] Ana formda CustomDateTimePicker kullanılmalı (şu an kullanılıyor ama validation yok)
- [ ] Dialog içinde CustomDateTimePicker kullanılmalı (şu an kullanılıyor ama validation yok)
- [ ] Full DateTime objeleri kullanılmalı (sadece saat/dakika değil)
- [ ] initialDateTime parametresi eklenmeli

### 2. Validation Kuralları
- [ ] Gelecekteki tarih kontrolü (maxDate: DateTime.now())
- [ ] 1 yıl öncesi limiti (minDate: DateTime.now().subtract(Duration(days: 365)))
- [ ] Milestone seçimi kontrolü (en az bir milestone gerekli)

### 3. Notes Geçici Kayıt
- [ ] SharedPrefsHelper'a baby firsts notes metodları eklenmeli
- [ ] Notes değişikliklerinde otomatik kayıt
- [ ] Sayfa açılışında notes geri yükleme
- [ ] Kayıt yapıldığında notes temizleme
- [ ] Her bebek için ayrı cache key'i

### 4. Data Format Değişikliği
- [ ] Eski format: Sadece hour/minute (backward compatibility için korunmalı)
- [ ] Yeni format: Full DateTime ISO string (activityDateTime zaten var)
- [ ] Edit modunda eski format desteği

### 5. Dialog İçinde Tarih Seçimi
- [ ] Dialog içindeki CustomDateTimePicker validation kurallarına uymalı
- [ ] Dialog içinde tarih seçildiğinde ana formdaki tarih güncellenmeli
- [ ] Dialog kapatıldığında tarih değişiklikleri korunmalı

### 6. UI Güncellemeleri
- [ ] CustomDateTimePicker ile "Today HH:mm" veya "Month Day HH:mm" formatı
- [ ] Validation hataları için error mesajları
- [ ] Milestone chip'leri silme animasyonu

### 7. Test Senaryoları
- [ ] Milestone seçimi ve kayıt
- [ ] Geçmiş tarihli kayıtlar
- [ ] Gelecekteki tarih engelleme
- [ ] Validation hataları
- [ ] Notes geçici kayıt
- [ ] Çoklu bebek desteği
- [ ] Dialog içinde tarih seçimi
- [ ] Daha önce seçilmiş milestone engelleme

---

## NOTLAR

1. **Backward Compatibility**: Eski veriler sadece hour/minute içeriyor. Yeni format full DateTime kullanıyor. Edit modunda eski format desteği olmalı.

2. **Dialog İçinde Tarih**: Dialog içinde CustomDateTimePicker var. Bu picker'ın da validation kurallarına uyması gerekiyor.

3. **Milestone Seçimi**: Milestone'lar dialog içinde seçiliyor. Daha önce seçilmiş milestone'lar disabled olmalı.

4. **Notes Cache**: Her bebek için ayrı cache key'i kullanılmalı: `baby_firsts_notes_{babyID}`

5. **Validation Mesajları**: Tüm validation hataları için kullanıcı dostu mesajlar gösterilmeli.


