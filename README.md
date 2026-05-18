# 🐦 Godot 4.6 Flappy Bird: Souls-like & MCP Edition

Bu proje, **Godot Engine 4.6** kullanılarak geliştirilmiş, **Dark Souls** temalı gotik görsellere ve **Model Context Protocol (MCP)** entegrasyonuna sahip benzersiz ve premium bir Flappy Bird uyarlamasıdır. Oyun, sadece manuel oynanışla sınırlı kalmayıp, dış dünyadaki yapay zeka modelleri ve otomasyon araçları tarafından kontrol edilmeye hazır bir yapı sunar.

---

## 🌟 Öne Çıkan Özellikler

### 🎭 1. Gotik Souls-like Tasarım ve Arayüz
- **Premium Ana Menü:** Dark Souls estetiğine sahip karanlık, gotik ve çarpıcı bir ana menü tasarımı.
- **Cinematic Bonfire (Şenlik Ateşi):** Kuşun dinlenebileceği sinematik bir "Bonfire" dinlenme alanı.
- **Kalıcı Kontrol Noktaları (Persistent Checkpoints):** İlerlemenizi kaydeden ve öldüğünüzde sizi en son dinlendiğiniz bonfire noktasında yeniden canlandıran kalıcı yerel checkpoint sistemi.

### ⚔️ 2. Epic 100-Level Boss Gauntlet
- **10 Farklı Boss Aşaması (Boss Tiers):** Her 10 skorda bir tetiklenen, zorluğu ve görsel teması artan boss savaşları.
- **10 Özel Saldırı Davranışı:** Boss'ların kuşu engellemek için kullandığı dinamik ve parametrik 10 farklı mermi ve saldırı şablonu.
- **Dinamik Hareket Eden Sütunlar:** Sadece dikey engeller değil, aynı zamanda hareket eden tehlikeli sütunlar.
- **Doğrusal HUD İlerleme Haritası:** 100 seviyelik gauntlet boyunca nerede olduğunuzu gösteren şık bir doğrusal ilerleme haritası.

### 🔌 3. Model Context Protocol (MCP) Entegrasyonu
- **Python FastMCP Sunucusu:** `mcp_server.py` üzerinden çalışan ve LLM (Large Language Model) ajanlarının oyunu analiz etmesini/yönetmesini sağlayan modern FastMCP sunucusu.
- **Godot WebSocket İletişimi:** Godot tarafındaki WebSocket istemcisi sayesinde oyun içi tüm olaylar (konum, hız, yaklaşan engeller) 20Hz frekansla Python sunucusuna aktarılır.
- **Akıllı Otopilot AI:** Python sunucusunda çalışan ve gelen verileri analiz ederek kuşu boruların arasından mükemmel şekilde geçiren otopilot algoritması.

---

## 🛠️ Teknoloji Yığını

- **Oyun Motoru:** Godot Engine 4.6 (Forward Plus & GL Compatibility)
- **Script Dili:** GDScript (Tip güvenli, optimize edilmiş yapı)
- **Sunucu & Protokol:** Python 3.10+, FastMCP, `websockets`, `asyncio`

---

## ⚙️ Kurulum ve Çalıştırma

### 1. Gereksinimlerin Yüklenmesi
Öncelikle gerekli Python paketlerini yükleyin:
```bash
pip install -r requirements.txt
```

### 2. MCP Sunucusunu Başlatma
Python MCP ve WebSocket sunucusunu ayağa kaldırın:
```bash
python mcp_server.py
```

### 3. Oyunu Başlatma
Godot Engine 4.6 ile projeyi açın ve çalıştırın. Oyun başladığında otomatik olarak `ws://localhost:8765` adresindeki Python sunucusuna bağlanacaktır.

---

## 🤖 Kullanılabilir MCP Araçları (MCP Tools)

FastMCP sunucusu dış dünyaya şu fonksiyonları sunar:

| Araç Adı | Açıklama |
| :--- | :--- |
| `get_game_state()` | Kuşun konumu, hızı, skor, yüksek skor ve yaklaşan boruların alt/üst koordinatlarını JSON olarak döner. |
| `flap_bird()` | Kuşun zıplamasını tetikler. |
| `pause_game()` | Oyunu anlık olarak duraklatır. |
| `resume_game()` | Duraklatılmış oyunu devam ettirir. |
| `restart_game()` | Game Over durumunda oyunu yeniden başlatır. |
| `set_autopilot(enabled: bool)` | Python sunucusundaki yerleşik otopilot yapay zekasını açar veya kapatır. |

---

## 🛡️ Lisans
Bu proje eğitim ve deneysel amaçlarla geliştirilmiştir. Geliştirme sürecinde katkıda bulunan tüm MCP ajanlarına teşekkür ederiz!
