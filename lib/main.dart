import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const YdsAsistanim());
}

class YdsAsistanim extends StatelessWidget {
  const YdsAsistanim({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'YDS & YÖKDİL Asistanı',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const AnaEkran(),
    );
  }
}

class AnaEkran extends StatefulWidget {
  const AnaEkran({Key? key}) : super(key: key);

  @override
  State<AnaEkran> createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> {
  Map<String, dynamic> tumKelimeler = {};
  Map<String, dynamic> hapBilgiler = {};
  bool yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    // Hem kelimeleri hem de hap bilgileri aynı anda yüklüyoruz
    final String wordsResponse = await rootBundle.loadString('assets/words.json');
    final String hapResponse = await rootBundle.loadString('assets/hap_bilgiler.json');
    
    setState(() {
      tumKelimeler = json.decode(wordsResponse);
      hapBilgiler = json.decode(hapResponse);
      yukleniyor = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('YDS & YÖKDİL Asistanı')),
      body: yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Kelime Çalışmaları",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                  const Divider(thickness: 2),
                  const SizedBox(height: 10),
                  _KategoriButonu("Genel Kelimeler", "kelimeler", Icons.list_alt, Colors.indigo),
                  const SizedBox(height: 12),
                  _KategoriButonu("Zarflar (Adverbs)", "adverbler", Icons.speed, Colors.indigo),
                  const SizedBox(height: 12),
                  _KategoriButonu("Bağlaçlar (Conjunctions)", "baglaclar", Icons.link, Colors.indigo),
                  const SizedBox(height: 12),
                  _KategoriButonu("Edatlar (Prepositions)", "prepler", Icons.place, Colors.indigo),
                  
                  const SizedBox(height: 30),
                  
                  const Text(
                    "Strateji ve Taktikler",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                  ),
                  const Divider(thickness: 2),
                  const SizedBox(height: 10),
                  
                  // HAP BİLGİLER ANA BUTONU
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: Colors.deepOrangeAccent,
                      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    icon: const Icon(Icons.lightbulb, size: 32, color: Colors.white),
                    label: const Text("💊 Hap Bilgiler & Taktikler", style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HapBilgilerMenuEkrani(hapVerisi: hapBilgiler),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _KategoriButonu(String baslik, String jsonAnahtari, IconData ikon, Color renk) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        backgroundColor: renk,
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      icon: Icon(ikon, size: 28, color: Colors.white),
      label: Text(baslik, style: const TextStyle(color: Colors.white)),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CalismaEkrani(
              kategoriAdi: baslik,
              kategoriKey: jsonAnahtari,
              kelimeListesi: tumKelimeler[jsonAnahtari] ?? [],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------
// 1. KELİME ÇALIŞMA EKRANI (Eski yapı aynen korundu)
// ---------------------------------------------------
class CalismaEkrani extends StatefulWidget {
  final String kategoriAdi;
  final String kategoriKey;
  final List<dynamic> kelimeListesi;

  const CalismaEkrani({Key? key, required this.kategoriAdi, required this.kategoriKey, required this.kelimeListesi}) : super(key: key);

  @override
  State<CalismaEkrani> createState() => _CalismaEkraniState();
}

class _CalismaEkraniState extends State<CalismaEkrani> {
  int currentIndex = 0;
  bool anlamiGoster = false;

  @override
  void initState() {
    super.initState();
    _kaldigimYeriYukle();
  }

  Future<void> _kaldigimYeriYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentIndex = prefs.getInt(widget.kategoriKey) ?? 0;
    });
  }

  Future<void> _sonrakiKelime() async {
    if (currentIndex < widget.kelimeListesi.length - 1) {
      setState(() {
        currentIndex++;
        anlamiGoster = false;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(widget.kategoriKey, currentIndex);
    }
  }

  Future<void> _oncekiKelime() async {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        anlamiGoster = false;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(widget.kategoriKey, currentIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.kelimeListesi.isEmpty) {
      return Scaffold(appBar: AppBar(title: Text(widget.kategoriAdi)), body: const Center(child: Text("Veri bulunamadı.")));
    }

    var aktifKelime = widget.kelimeListesi[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kategoriAdi),
        actions: [
          Center(child: Padding(padding: const EdgeInsets.only(right: 16.0), child: Text("${currentIndex + 1} / ${widget.kelimeListesi.length}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("İngilizce:", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 10),
            Text(aktifKelime['en'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 40),
            if (anlamiGoster) ...[
              const Text("Türkçe Anlamı:", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey)),
              const SizedBox(height: 10),
              Text(aktifKelime['tr'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: Colors.green)),
            ] else ...[
              ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), backgroundColor: Colors.orangeAccent),
                onPressed: () => setState(() => anlamiGoster = true),
                child: const Text("Anlamını Göster", style: TextStyle(fontSize: 20)),
              ),
            ],
            const Spacer(),
            Row(
              children: [
                Expanded(flex: 1, child: ElevatedButton(style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20), backgroundColor: Colors.blueGrey), onPressed: currentIndex > 0 ? _oncekiKelime : null, child: const Text("Önceki", style: TextStyle(fontSize: 18, color: Colors.white)))),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: ElevatedButton(style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20), backgroundColor: Colors.indigo), onPressed: anlamiGoster ? _sonrakiKelime : null, child: const Text("Sonraki Kelime", style: TextStyle(fontSize: 18, color: Colors.white)))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------
// 2. HAP BİLGİLER ALT MENÜ EKRANI (YENİ)
// ---------------------------------------------------
class HapBilgilerMenuEkrani extends StatelessWidget {
  final Map<String, dynamic> hapVerisi;

  const HapBilgilerMenuEkrani({Key? key, required this.hapVerisi}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hap Bilgiler & Taktikler'), backgroundColor: Colors.deepOrange),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TaktikButonu(context, "Tense (Zaman) Taktikleri", "tenses", Icons.access_time, Colors.blueAccent),
            const SizedBox(height: 16),
            _TaktikButonu(context, "Bağlaç Taktikleri", "baglac_taktikleri", Icons.link, Colors.teal),
            const SizedBox(height: 16),
            _TaktikButonu(context, "Edat (Prep) Taktikleri", "prep_taktikleri", Icons.pin_drop, Colors.purple),
            const SizedBox(height: 16),
            _TaktikButonu(context, "Paragraf Soru Taktikleri", "paragraf_taktikleri", Icons.article, Colors.brown),
          ],
        ),
      ),
    );
  }

  Widget _TaktikButonu(BuildContext context, String baslik, String jsonAnahtari, IconData ikon, Color renk) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
        backgroundColor: renk,
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      icon: Icon(ikon, size: 28, color: Colors.white),
      label: Text(baslik, style: const TextStyle(color: Colors.white)),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HapBilgiKartEkrani(
              kategoriAdi: baslik,
              kategoriKey: jsonAnahtari,
              bilgiListesi: hapVerisi[jsonAnahtari] ?? [],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------
// 3. HAP BİLGİ KARTLARI EKRANI (YENİ TASARIM)
// ---------------------------------------------------
class HapBilgiKartEkrani extends StatefulWidget {
  final String kategoriAdi;
  final String kategoriKey;
  final List<dynamic> bilgiListesi;

  const HapBilgiKartEkrani({Key? key, required this.kategoriAdi, required this.kategoriKey, required this.bilgiListesi}) : super(key: key);

  @override
  State<HapBilgiKartEkrani> createState() => _HapBilgiKartEkraniState();
}

class _HapBilgiKartEkraniState extends State<HapBilgiKartEkrani> {
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _kaldigimYeriYukle();
  }

  Future<void> _kaldigimYeriYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentIndex = prefs.getInt("hap_${widget.kategoriKey}") ?? 0;
    });
  }

  Future<void> _sonrakiBilgi() async {
    if (currentIndex < widget.bilgiListesi.length - 1) {
      setState(() => currentIndex++);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt("hap_${widget.kategoriKey}", currentIndex);
    }
  }

  Future<void> _oncekiBilgi() async {
    if (currentIndex > 0) {
      setState(() => currentIndex--);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt("hap_${widget.kategoriKey}", currentIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bilgiListesi.isEmpty) {
      return Scaffold(appBar: AppBar(title: Text(widget.kategoriAdi)), body: const Center(child: Text("Bu taktik henüz eklenmedi.")));
    }

    var aktifBilgi = widget.bilgiListesi[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kategoriAdi),
        backgroundColor: Colors.deepOrange,
        actions: [
          Center(child: Padding(padding: const EdgeInsets.only(right: 16.0), child: Text("${currentIndex + 1} / ${widget.bilgiListesi.length}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // BAŞLIK
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.indigo.shade200)),
                      child: Text(aktifBilgi['baslik'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    ),
                    const SizedBox(height: 16),
                    
                    // KURAL
                    _BilgiKutusu("Sınav Kuralı", aktifBilgi['kural'], Icons.menu_book, Colors.blue.shade100, Colors.blue.shade900),
                    const SizedBox(height: 16),
                    
                    // İPUCU
                    _BilgiKutusu("Altın İpucu", aktifBilgi['ipucu'], Icons.lightbulb_outline, Colors.amber.shade100, Colors.amber.shade900),
                    const SizedBox(height: 16),
                    
                    // ÖRNEK
                    _BilgiKutusu("Örnek Cümle", aktifBilgi['ornek'], Icons.format_quote, Colors.green.shade100, Colors.green.shade900),
                  ],
                ),
              ),
            ),
            
            // BUTONLAR
            Row(
              children: [
                Expanded(flex: 1, child: ElevatedButton(style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20), backgroundColor: Colors.blueGrey), onPressed: currentIndex > 0 ? _oncekiBilgi : null, child: const Text("Önceki", style: TextStyle(fontSize: 18, color: Colors.white)))),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: ElevatedButton(style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20), backgroundColor: Colors.deepOrange), onPressed: currentIndex < widget.bilgiListesi.length - 1 ? _sonrakiBilgi : null, child: const Text("Sonraki Taktik", style: TextStyle(fontSize: 18, color: Colors.white)))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Özel Tasarımlı Bilgi Kutusu Widget'ı
  Widget _BilgiKutusu(String baslik, String icerik, IconData ikon, Color arkaPlan, Color metinRengi) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: arkaPlan, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ikon, color: metinRengi),
              const SizedBox(width: 8),
              Text(baslik, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: metinRengi)),
            ],
          ),
          const Divider(),
          Text(icerik, style: TextStyle(fontSize: 17, color: metinRengi.withOpacity(0.9), height: 1.4)),
        ],
      ),
    );
  }
}