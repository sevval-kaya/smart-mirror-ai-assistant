<div align="center">

# 🪞 Smart Mirror AI Assistant

### TÜBİTAK 2209-A Üniversite Öğrencileri Araştırma Projeleri Desteği

[![Flutter](https://img.shields.io/badge/Flutter-3.19%2B-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.3%2B-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-API%2021%2B-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com)
[![iOS](https://img.shields.io/badge/iOS-14%2B-000000?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com)
[![TÜBİTAK](https://img.shields.io/badge/TÜBİTAK-2209--A-E30A17?style=for-the-badge)](https://tubitak.gov.tr)

<br/>

**Yapay zeka destekli akıllı ayna donanımının mobil yardımcı uygulaması.**  
Sesli komut işleme, görev yönetimi ve çoklu kullanıcı desteğini tek bir arayüzde birleştirir.

</div>

---

## 👥 Proje Ekibi

| Rol | İsim | Kurum |
|-----|------|-------|
| 🎓 **Danışman** | Doç. Dr. Sinem Akyol | Fırat Üniversitesi |
| 👑 **Koordinatör** | Şevval Kaya | Fırat Üniversitesi |
| 👨‍💻 **Üye** | Berkay Parçal | Fırat Üniversitesi |
| 👩‍💻 **Üye** | Esra Kazan | Fırat Üniversitesi |

---

## 📋 İçindekiler

- [Proje Hakkında](#-proje-hakkında)
- [Özellikler](#-özellikler)
- [Mimari](#-mimari)
- [Teknoloji Yığını](#-teknoloji-yığını)
- [Kurulum](#-kurulum)
- [Kullanım](#-kullanım)
- [Proje Yapısı](#-proje-yapısı)
- [API Entegrasyonu](#-api-entegrasyonu)
- [Güvenlik](#-güvenlik)
- [Yol Haritası](#-yol-haritası)

---

## 🔍 Proje Hakkında

**Smart Mirror AI Assistant**, TÜBİTAK 2209-A kapsamında Fırat Üniversitesi'nde geliştirilen yapay zeka destekli akıllı ayna sisteminin mobil yardımcı uygulamasıdır. Uygulama; akıllı aynanın beyni ve kullanıcı arayüzü olarak görev yapar.

Ayna donanımı üzerinde çalışan **TensorFlow tabanlı AI modeli** ile **NGINX API Gateway** üzerinden güvenli (TLS) iletişim kurarak sesli komutları işler, kullanıcı planlarını yönetir ve kişiselleştirilmiş öneriler sunar.

---

## ✨ Özellikler

### 🎤 Sesli Komut & AI Asistan
| Özellik | Açıklama |
|---------|----------|
| Gerçek zamanlı STT | `speech_to_text` ile mikrofon girişini metne çevirir |
| AI İşleme | Transcript NGINX Gateway üzerinden TensorFlow modeline iletilir |
| TTS Yanıt | AI yanıtı `flutter_tts` ile Türkçe seslendirilir (`tr-TR`) |
| Çevrimdışı Mod | Bağlantı yoksa kural tabanlı yerel yanıt motoru devreye girer |
| Görev Sesli Okuma | Her görev kartındaki 🔊 butonu ile görev TTS ile okunur |

### 📝 Görev & Plan Yönetimi
| Özellik | Açıklama |
|---------|----------|
| CRUD Görevler | Görev ekleme, düzenleme, silme, tamamlama |
| Öncelik Seviyeleri | Acil / Yüksek / Orta / Düşük |
| Kategori Sistemi | İş, Kişisel, Sağlık, Alışveriş, Aile, Eğitim, Genel |
| Son Tarih | Takvim seçici ile bitiş tarihi atama |
| Akıllı Filtreleme | Aktif / Tamamlanan sekme görünümü |
| Otomatik Gizleme | Tamamlanan görevler 24 saat sonra listeden kalkar |
| Tam Metin Arama | Başlık ve açıklamada anlık arama |

### 👤 Çoklu Kullanıcı Desteği
| Özellik | Açıklama |
|---------|----------|
| Profil Yönetimi | Aile üyeleri için bağımsız profil oluşturma |
| PIN Doğrulama | SHA-256 ile şifrelenmiş 4-6 haneli PIN |
| Rol Sistemi | Admin / Member rolleri |
| Oturum Kalıcılığı | Aktif kullanıcı uygulama yeniden açılışında otomatik giriş |
| Gizlilik | Görevler kullanıcıya özel; kullanıcı değişiminde anında sıfırlanır |
| Hızlı Geçiş | İlk kullanıcı oluşturulduğunda otomatik oturum açılır |

### 🎨 Arayüz & Deneyim
| Özellik | Açıklama |
|---------|----------|
| Koyu Tema | Ayna estetiğiyle uyumlu minimalist tasarım |
| Noto Sans Font | Tam Türkçe karakter desteği (ğ, ü, ş, ı, İ, Ö, Ç) |
| Animasyonlar | `animate_do` ile yumuşak geçişler |
| Görev İlerleme | Dairesel yüzde göstergesi |
| Günlük Selamlama | Sabah / öğleden sonra / akşam bağlamsal mesajlar |
| Swipe to Delete | Kaydırarak görev silme + onay diyaloğu |

---

## 🏗 Mimari

Uygulama **Clean Architecture** prensiplerine göre katmanlı bir yapıda inşa edilmiştir:

```
┌─────────────────────────────────────────────┐
│          Presentation Layer                 │
│  Pages · Widgets · BLoC/Cubit States        │
├─────────────────────────────────────────────┤
│           Domain Layer                      │
│  Entities · Use Cases · Repository Interfaces│
├─────────────────────────────────────────────┤
│            Data Layer                       │
│  Models · Repository Impls · DataSources    │
├─────────────────────────────────────────────┤
│             Core                            │
│  DI (GetIt) · Theme · Network · Security    │
└─────────────────────────────────────────────┘
```

**State Management:** BLoC/Cubit (Flutter Bloc 8.x)
- `TaskBloc` — Görev CRUD ve filtreleme olayları
- `UserCubit` — Kullanıcı oturumu ve profil yönetimi
- `VoiceCubit` — STT → AI → TTS akış yönetimi

---

## 🛠 Teknoloji Yığını

### Temel Bağımlılıklar

| Kategori | Paket | Sürüm | Kullanım |
|----------|-------|-------|----------|
| **State Management** | flutter_bloc | 8.1.5 | BLoC/Cubit pattern |
| **State Management** | equatable | 2.0.5 | Değişmez durum nesneleri |
| **Dependency Injection** | get_it | 7.6.7 | Service locator |
| **Networking** | dio | 5.4.3 | HTTP istemcisi, TLS, interceptor |
| **Local DB** | sqflite | 2.3.3 | SQLite 3.x — görev ve kullanıcı verileri |
| **Güvenli Depolama** | flutter_secure_storage | 10.0.0 | Token, cihaz ID şifreleme |
| **Tercihler** | shared_preferences | 2.2.3 | Aktif kullanıcı, ayarlar |
| **Ses Tanıma** | speech_to_text | 7.0.0 | Mikrofon → metin (tr_TR) |
| **Metin → Ses** | flutter_tts | 4.0.2 | Türkçe TTS (tr-TR) |
| **Bildirimler** | flutter_local_notifications | 17.0.0 | Görev hatırlatıcıları |
| **Hata Yönetimi** | dartz | 0.10.1 | Either\<Failure, T\> pattern |
| **Kriptografi** | crypto | 3.0.3 | SHA-256 PIN hashleme |
| **Animasyon** | animate_do | 3.3.4 | Yumuşak UI geçişleri |
| **Grafik** | percent_indicator | 4.2.3 | Görev ilerleme göstergesi |
| **Tarih** | intl | 0.19.0 | Türkçe tarih/saat biçimleme |

### Geliştirme Araçları

| Araç | Sürüm | Amaç |
|------|-------|------|
| Flutter SDK | ≥ 3.19.0 | Cross-platform framework |
| Dart SDK | ≥ 3.3.0 | Programlama dili |
| bloc_test | 9.1.7 | BLoC birim testleri |
| mockito | 5.4.4 | Mock nesneler |
| build_runner | 2.4.9 | Kod üretimi |

---

## 🚀 Kurulum

### Ön Gereksinimler

- [Flutter SDK](https://flutter.dev/docs/get-started/install) ≥ 3.19.0
- [Android Studio](https://developer.android.com/studio) + Android Emülatör (API 21+)
- [Git](https://git-scm.com/)
- Java 17 (Android build için)

### 1. Depoyu Klonlayın

```bash
git clone https://github.com/firat-universitesi/smart-mirror-app.git
cd smart-mirror-app
```

### 2. Bağımlılıkları Yükleyin

```bash
flutter pub get
```

### 3. Türkçe Yerel Ayarını Aktif Edin

`pubspec.yaml` içinde yerel ayarlar zaten yapılandırılmıştır. Ek bir işlem gerekmez.

### 4. Android İçin (Windows)

Gradle önbelleğini OneDrive dışına yönlendirmek için `android/gradle.properties` dosyasında şu satırın bulunduğunu doğrulayın:

```properties
org.gradle.user.home=C:/gradle_home
```

### 5. Uygulamayı Çalıştırın

```bash
# Emülatör veya fiziksel cihazla
flutter run

# Windows'ta Gradle önbellek konumuyla
$env:GRADLE_USER_HOME = "C:/gradle_home"; flutter run
```

> ⚠️ **Önemli:** Projeyi OneDrive senkronizasyonu altındaki bir dizinden **çalıştırmayın**. Gradle build dosyaları kilitlenir ve build başarısız olur.

### 6. Release APK Oluşturma

```bash
flutter build apk --release
# Çıktı: build/app/outputs/flutter-apk/app-release.apk
```

---

## 📱 Kullanım

### İlk Açılış

```
Uygulama Başlat
    │
    ▼
Onay Ekranı (Mikrofon, Depolama, Bildirim izinleri)
    │
    ▼
Ana Panel (Dashboard)
    │
    ├── Profil oluşturmak için sağ üstteki avatara tıkla
    ├── Profil oluştur (İsim + PIN)  ──► Otomatik giriş
    │
    ▼
Görev Ekle → Görevler sekmesi → "+" butonu
    │
    ▼
Sesli Komut → Mikrofon butonuna bas → Konuş
```

### Temel İşlemler

| İşlem | Nasıl Yapılır |
|-------|---------------|
| Görev ekle | Görevler sekmesi → sağ üst `+` butonu |
| Görev tamamla | Görev kartındaki ○ butonuna tıkla |
| Görev sil | Kartı sola kaydır |
| Görevi sesli dinle | Kart üzerindeki 🔊 butonuna bas |
| Sesli komut | Ana sayfadaki mikrofon butonuna bas |
| Profil değiştir | Profil sekmesi → kullanıcı seç → PIN gir |
| Çıkış yap | Profil sekmesi → "Çıkış Yap" |

---

## 📁 Proje Yapısı

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart       # Uygulama sabitleri (DB, SharedPrefs)
│   │   └── api_constants.dart       # NGINX endpoint & timeout sabitleri
│   ├── di/
│   │   └── injection_container.dart # GetIt servis kaydı
│   ├── errors/
│   │   ├── failures.dart            # Domain hata sınıfları
│   │   └── exceptions.dart          # Data katmanı istisnaları
│   ├── network/
│   │   └── api_service.dart         # Dio istemcisi + TLS + interceptor
│   ├── security/
│   │   └── security_layer.dart      # Onay yönetimi, cihaz ID, token
│   └── theme/
│       └── app_theme.dart           # Koyu tema, renkler, tipografi
│
├── data/
│   ├── datasources/
│   │   ├── local/
│   │   │   └── database_helper.dart # SQLite CRUD yardımcısı (v2)
│   │   └── remote/
│   │       └── ai_remote_datasource.dart # NGINX AI endpoint istemcisi
│   ├── models/
│   │   ├── task_model.dart          # Task ↔ SQLite ↔ JSON dönüşümleri
│   │   └── user_model.dart          # User ↔ SQLite ↔ JSON dönüşümleri
│   └── repositories/
│       ├── task_repository_impl.dart
│       └── user_repository_impl.dart
│
├── domain/
│   ├── entities/
│   │   ├── task.dart                # Task, TaskPriority, TaskCategory
│   │   └── user.dart                # User, UserRole, UserPreferences
│   ├── repositories/
│   │   ├── task_repository.dart     # ITaskRepository arayüzü
│   │   └── user_repository.dart     # IUserRepository arayüzü
│   └── usecases/
│       └── task_usecases.dart       # GetTasks, CreateTask, ToggleTask…
│
└── presentation/
    ├── blocs/
    │   ├── task/
    │   │   └── task_bloc.dart       # TaskEvent, TaskState, TaskBloc
    │   ├── user/
    │   │   └── user_cubit.dart      # UserState, UserCubit
    │   └── voice/
    │       └── voice_cubit.dart     # VoiceState, VoiceCubit (STT→AI→TTS)
    ├── pages/
    │   ├── consent_page.dart        # İzin onay ekranı
    │   ├── dashboard_page.dart      # Ana panel + navigasyon
    │   ├── tasks_page.dart          # Görev listesi + ekleme
    │   └── profile_page.dart        # Çoklu kullanıcı profil yönetimi
    └── widgets/
        ├── task_card_widget.dart    # Swipe-to-delete görev kartı
        └── voice_assistant_widget.dart # Mikrofon + TTS durum widget'ı
```

---

## 🌐 API Entegrasyonu

Uygulama, AI modeliyle **NGINX API Gateway** üzerinden HTTPS ile iletişim kurar.

### Endpoint'ler

| Endpoint | Metot | Açıklama |
|----------|-------|----------|
| `/api/v1/ai/infer` | POST | Genel AI çıkarım isteği |
| `/api/v1/ai/status` | GET | AI modelinin hazır olup olmadığını kontrol eder |
| `/api/v1/voice/process` | POST | Sesli komut transkriptini işler |
| `/api/v1/users/sync` | POST | Kullanıcı tercihlerini sunucuya senkronize eder |

### Yapılandırma

`lib/core/constants/api_constants.dart` dosyasında ortam URL'lerini güncelleyin:

```dart
static const String _devBaseUrl  = 'https://192.168.1.100:8443';  // Geliştirme
static const String _prodBaseUrl = 'https://api.smartmirror.local'; // Üretim
```

### İstek Başlıkları

Tüm isteklere otomatik olarak eklenir:

| Başlık | Değer |
|--------|-------|
| `Authorization` | `Bearer <token>` |
| `X-Device-ID` | Cihaza özgü benzersiz UUID |
| `X-API-Version` | `v1` |
| `Content-Type` | `application/json` |

---

## 🔒 Güvenlik

| Katman | Uygulama |
|--------|----------|
| **TLS** | Dio `badCertificateCallback` ile geliştirmede self-signed; üretimde sertifika parmak izi doğrulaması |
| **PIN Şifreleme** | SHA-256 (crypto paketi) ile hashleme — ham PIN hiçbir zaman saklanmaz |
| **Token Depolama** | `flutter_secure_storage` ile Android Keystore / iOS Keychain şifrelemesi |
| **Kullanıcı Onayı** | Sistem ilk açılışta mikrofon, depolama ve bildirim izinleri için onay alır |
| **Oturum Yönetimi** | Oturum süresi `AppConstants.sessionTimeout` ile sınırlıdır |
| **Veri İzolasyonu** | Her kullanıcının görevleri `user_id` ile filtrelenir; profil değişiminde anında temizlenir |

---

## 🗺 Yol Haritası

### ✅ Tamamlanan (v1.0)

- [x] Clean Architecture + BLoC/Cubit altyapısı
- [x] SQLite yerel veritabanı (v2 — migration destekli)
- [x] CRUD görev yönetimi (öncelik, kategori, son tarih)
- [x] Tamamlanan görevlerin 24 saat sonra otomatik gizlenmesi
- [x] Çoklu kullanıcı desteği + SHA-256 PIN doğrulama
- [x] Sesli komut işleme (speech_to_text — tr_TR)
- [x] Türkçe TTS yanıt (flutter_tts — tr-TR)
- [x] Görevleri sesli okuma özelliği
- [x] NGINX API Gateway entegrasyon katmanı
- [x] TLS şifreli iletişim altyapısı
- [x] Kullanıcı onay mekanizması
- [x] Tam Türkçe karakter desteği (Noto Sans)

### 🔜 Bir Sonraki Aşama (v1.1)

- [ ] **TensorFlow AI Entegrasyonu** — Ayna donanımındaki modelin canlı bağlantısı
- [ ] **Gerçek Zamanlı AI Yanıt** — NGINX Gateway üzerinden uçtan uca sesli asistan akışı
- [ ] **Yüz Tanıma ile Kullanıcı Tespiti** — Kameradan otomatik profil seçimi
- [ ] **Akıllı Görev Önerileri** — AI modelinden kişiselleştirilmiş görev önerileri
- [ ] **Push Bildirimler** — Görev hatırlatıcı ve AI durum bildirimleri
- [ ] **Hava Durumu & Haber Entegrasyonu** — Dashboard'a harici veri kaynakları
- [ ] **Çevrimiçi Kullanıcı Senkronizasyonu** — Aile üyeleri arası bulut senkronizasyonu
- [ ] **Ses Profili Özelleştirmesi** — Kullanıcı bazlı TTS hız/perde ayarları
- [ ] **Erişilebilirlik** — Yüksek kontrast modu, büyük metin

### 🔮 Uzun Vadeli (v2.0)

- [ ] **iOS Desteği** — App Store yayını
- [ ] **Çoklu Dil** — İngilizce arayüz ve TTS desteği
- [ ] **Ayna Donanımı SDK** — Raspberry Pi / Jetson entegrasyon kütüphanesi
- [ ] **Federe Öğrenme** — Kullanıcı verisini paylaşmadan model iyileştirmesi

---

## 📄 Lisans

Bu proje **TÜBİTAK 2209-A** programı kapsamında Fırat Üniversitesi bünyesinde akademik amaçlı geliştirilmektedir.

---

<div align="center">

**Fırat Üniversitesi · TÜBİTAK 2209-A · 2025**

*Danışman: Doç. Dr. Sinem Akyol*

</div>
