import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
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
      appBar: AppBar(title: const Text('YDS & YÖKDİL Asistanı', style: TextStyle(fontWeight: FontWeight.bold))),
      body: yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. KELİME ÇALIŞMA BÖLÜMÜ
                  const Text("Kelime Çalışmaları", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  const Divider(thickness: 2),
                  const SizedBox(height: 10),
                  _KategoriButonu("Genel Kelimeler", "kelimeler", Icons.list_alt, Colors.indigo),
                  const SizedBox(height: 12),
                  _KategoriButonu("Zarflar (Adverbs)", "adverbler", Icons.speed, Colors.indigo),
                  const SizedBox(height: 12),
                  _KategoriButonu("Bağlaçlar (Conjunctions)", "baglaclar", Icons.link, Colors.indigo),
                  const SizedBox(height: 12),
                  _KategoriButonu("Edatlar (Prepositions)", "prepler", Icons.place, Colors.indigo),
                  
                  const SizedBox(height: 25),
                  
                  // 2. TEST & QUİZ BÖLÜMÜ (YENİ)
                  const Text("Kendini Test Et", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple)),
                  const Divider(thickness: 2),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: Colors.purpleAccent.shade700,
                      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    icon: const Icon(Icons.quiz, size: 32, color: Colors.white),
                    label: const Text("📝 Test / Quiz Çöz", style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => QuizSecimEkrani(tumKelimeler: tumKelimeler)),
                      );
                    },
                  ),

                  const SizedBox(height: 25),
                  
                  // 3. HAP BİLGİLER BÖLÜMÜ
                  const Text("Strateji ve Taktikler", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                  const Divider(thickness: 2),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: Colors.deepOrangeAccent,
                      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    icon: const Icon(Icons.lightbulb, size: 32, color: Colors.white),
                    label: const Text("💊 Hap Bilgiler & Taktikler", style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => HapBilgilerMenuEkrani(hapVerisi: hapBilgiler)));
                    },
                  ),
                  const SizedBox(height: 20),
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
// EKRAN: KELİME ÇALIŞMA (Eski yapı korundu)
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
    setState(() => currentIndex = prefs.getInt(widget.kategoriKey) ?? 0);
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
    if (widget.kelimeListesi.isEmpty) return Scaffold(appBar: AppBar(title: Text(widget.kategoriAdi)), body: const Center(child: Text("Veri bulunamadı.")));
    var aktifKelime = widget.kelimeListesi[currentIndex];

    return Scaffold(
      appBar: AppBar(title: Text(widget.kategoriAdi), actions: [Center(child: Padding(padding: const EdgeInsets.only(right: 16.0), child: Text("${currentIndex + 1} / ${widget.kelimeListesi.length}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))))]),
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
// YENİ EKRAN: QUİZ SEÇİM MENÜSÜ
// ---------------------------------------------------
class QuizSecimEkrani extends StatelessWidget {
  final Map<String, dynamic> tumKelimeler;

  const QuizSecimEkrani({Key? key, required this.tumKelimeler}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hangi Konudan Test Çözelim?'), backgroundColor: Colors.purple),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _QuizButonu(context, "Genel Kelime Testi", "kelimeler", Icons.list_alt, Colors.purple.shade400),
            const SizedBox(height: 16),
            _QuizButonu(context, "Zarflar Testi", "adverbler", Icons.speed, Colors.purple.shade500),
            const SizedBox(height: 16),
            _QuizButonu(context, "Bağlaçlar Testi", "baglaclar", Icons.link, Colors.purple.shade600),
            const SizedBox(height: 16),
            _QuizButonu(context, "Edatlar Testi", "prepler", Icons.place, Colors.purple.shade700),
          ],
        ),
      ),
    );
  }

  Widget _QuizButonu(BuildContext context, String baslik, String jsonAnahtari, IconData ikon, Color renk) {
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
            builder: (context) => QuizEkrani(
              kategoriAdi: baslik,
              tamListe: tumKelimeler[jsonAnahtari] ?? [],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------
// YENİ EKRAN: QUİZ (TEST) ÇÖZME EKRANI
// ---------------------------------------------------
class QuizEkrani extends StatefulWidget {
  final String kategoriAdi;
  final List<dynamic> tamListe;

  const QuizEkrani({Key? key, required this.kategoriAdi, required this.tamListe}) : super(key: key);

  @override
  State<QuizEkrani> createState() => _QuizEkraniState();
}

class _QuizEkraniState extends State<QuizEkrani> {
  List<Map<String, dynamic>> testSorulari = [];
  int aktifSoruIndex = 0;
  int dogruSayisi = 0;
  int yanlisSayisi = 0;
  bool cevaplandi = false;
  String secilenCevap = "";

  @override
  void initState() {
    super.initState();
    _sorulariHazirla();
  }

  void _sorulariHazirla() {
    if (widget.tamListe.length < 4) return; // En az 4 şık için 4 kelime lazım

    final random = Random();
    List<dynamic> karisikListe = List.from(widget.tamListe)..shuffle(random);
    
    // 10 soruluk bir test oluştur
    int soruSayisi = min(10, karisikListe.length);
    
    for (int i = 0; i < soruSayisi; i++) {
      var dogruKelime = karisikListe[i];
      List<String> siklar = [dogruKelime['tr']];

      // 3 tane yanlış şık bul
      while (siklar.length < 4) {
        var rastgeleYanlis = widget.tamListe[random.nextInt(widget.tamListe.length)]['tr'];
        if (!siklar.contains(rastgeleYanlis)) {
          siklar.add(rastgeleYanlis);
        }
      }
      siklar.shuffle(random); // Şıkların yerini karıştır

      testSorulari.add({
        'en': dogruKelime['en'],
        'dogru_cevap': dogruKelime['tr'],
        'siklar': siklar,
      });
    }
  }

  void _cevapKontrol(String secim) {
    if (cevaplandi) return; // Sadece 1 kere tıklanabilir

    setState(() {
      cevaplandi = true;
      secilenCevap = secim;
      if (secim == testSorulari[aktifSoruIndex]['dogru_cevap']) {
        dogruSayisi++;
      } else {
        yanlisSayisi++;
      }
    });
  }

  void _sonrakiSoru() {
    if (aktifSoruIndex < testSorulari.length - 1) {
      setState(() {
        aktifSoruIndex++;
        cevaplandi = false;
        secilenCevap = "";
      });
    } else {
      _sonuclariGoster();
    }
  }

  void _sonuclariGoster() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Test Bitti!", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("✅ Doğru: $dogruSayisi", style: const TextStyle(color: Colors.green, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("❌ Yanlış: $yanlisSayisi", style: const TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text("Başarı Oranı: %${((dogruSayisi / testSorulari.length) * 100).round()}", style: const TextStyle(fontSize: 18)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Dialogu kapat
              Navigator.pop(context); // Menüye dön
            },
            child: const Text("Menüye Dön"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                testSorulari.clear();
                aktifSoruIndex = 0;
                dogruSayisi = 0;
                yanlisSayisi = 0;
                cevaplandi = false;
                secilenCevap = "";
                _sorulariHazirla();
              });
            },
            child: const Text("Tekrar Çöz", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (testSorulari.isEmpty) return const Scaffold(body: Center(child: Text("Yeterli kelime yok.")));

    var aktifSoru = testSorulari[aktifSoruIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kategoriAdi),
        backgroundColor: Colors.purple,
        actions: [
          Center(child: Padding(padding: const EdgeInsets.only(right: 16.0), child: Text("${aktifSoruIndex + 1} / ${testSorulari.length}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(flex: 1),
            const Text("Bu kelimenin anlamı nedir?", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 10),
            Text(aktifSoru['en'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const Spacer(flex: 2),
            
            // ŞIKLAR
            ...List.generate(4, (index) {
              String sikMetni = aktifSoru['siklar'][index];
              Color butonRengi = Colors.white;
              Color yaziRengi = Colors.black87;

              if (cevaplandi) {
                if (sikMetni == aktifSoru['dogru_cevap']) {
                  butonRengi = Colors.green.shade500; // Doğru cevap her zaman yeşil yanar
                  yaziRengi = Colors.white;
                } else if (sikMetni == secilenCevap && secilenCevap != aktifSoru['dogru_cevap']) {
                  butonRengi = Colors.red.shade500; // Yanlış seçtiğin kırmızı yanar
                  yaziRengi = Colors.white;
                } else {
                  butonRengi = Colors.grey.shade300; // Diğerleri solar
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: butonRengi,
                    foregroundColor: yaziRengi,
                    side: BorderSide(color: Colors.grey.shade300),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () => _cevapKontrol(sikMetni),
                  child: Text(sikMetni, textAlign: TextAlign.center),
                ),
              );
            }),
            
            const Spacer(flex: 2),
            if (cevaplandi)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: Colors.indigo,
                ),
                onPressed: _sonrakiSoru,
                child: const Text("Sonraki Soru ➔", style: TextStyle(fontSize: 20, color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------
// EKRAN: HAP BİLGİLER MENÜSÜ & KARTLARI (Eski yapı korundu)
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
            const SizedBox(height: 12),
            _TaktikButonu(context, "Modal (Kip) Taktikleri", "modal_taktikleri", Icons.psychology, Colors.pink),
            const SizedBox(height: 12),
            _TaktikButonu(context, "Passive (Edilgen) Taktikleri", "passive_taktikleri", Icons.visibility_off, Colors.indigo),
            const SizedBox(height: 12),
            _TaktikButonu(context, "If Clauses (Koşul) Taktikleri", "if_clause_taktikleri", Icons.alt_route, Colors.deepPurple),
            const SizedBox(height: 12),
            _TaktikButonu(context, "Bağlaç Taktikleri", "baglac_taktikleri", Icons.link, Colors.teal),
            const SizedBox(height: 12),
            _TaktikButonu(context, "Edat (Prep) Taktikleri", "prep_taktikleri", Icons.pin_drop, Colors.orange),
            const SizedBox(height: 12),
            _TaktikButonu(context, "Paragraf Soru Taktikleri", "paragraf_taktikleri", Icons.article, Colors.brown),
          ],
        ),
      ),
    );
  }

  Widget _TaktikButonu(BuildContext context, String baslik, String jsonAnahtari, IconData ikon, Color renk) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), backgroundColor: renk, textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      icon: Icon(ikon, size: 28, color: Colors.white),
      label: Text(baslik, style: const TextStyle(color: Colors.white)),
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => HapBilgiKartEkrani(kategoriAdi: baslik, kategoriKey: jsonAnahtari, bilgiListesi: hapVerisi[jsonAnahtari] ?? []))),
    );
  }
}

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
    setState(() => currentIndex = prefs.getInt("hap_${widget.kategoriKey}") ?? 0);
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
    if (widget.bilgiListesi.isEmpty) return Scaffold(appBar: AppBar(title: Text(widget.kategoriAdi)), body: const Center(child: Text("Bu taktik henüz eklenmedi.")));
    var aktifBilgi = widget.bilgiListesi[currentIndex];

    return Scaffold(
      appBar: AppBar(title: Text(widget.kategoriAdi), backgroundColor: Colors.deepOrange, actions: [Center(child: Padding(padding: const EdgeInsets.only(right: 16.0), child: Text("${currentIndex + 1} / ${widget.bilgiListesi.length}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))))]),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.indigo.shade200)), child: Text(aktifBilgi['baslik'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo))),
                    const SizedBox(height: 16),
                    _BilgiKutusu("Sınav Kuralı", aktifBilgi['kural'], Icons.menu_book, Colors.blue.shade100, Colors.blue.shade900),
                    const SizedBox(height: 16),
                    _BilgiKutusu("Altın İpucu", aktifBilgi['ipucu'], Icons.lightbulb_outline, Colors.amber.shade100, Colors.amber.shade900),
                    const SizedBox(height: 16),
                    _BilgiKutusu("Örnek Cümle", aktifBilgi['ornek'], Icons.format_quote, Colors.green.shade100, Colors.green.shade900),
                  ],
                ),
              ),
            ),
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

  Widget _BilgiKutusu(String baslik, String icerik, IconData ikon, Color arkaPlan, Color metinRengi) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: arkaPlan, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(ikon, color: metinRengi), const SizedBox(width: 8), Text(baslik, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: metinRengi))]),
          const Divider(),
          Text(icerik, style: TextStyle(fontSize: 17, color: metinRengi.withOpacity(0.9), height: 1.4)),
        ],
      ),
    );
  }
}