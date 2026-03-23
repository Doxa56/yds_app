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
  bool yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    final String response = await rootBundle.loadString('assets/words.json');
    final data = await json.decode(response);
    setState(() {
      tumKelimeler = data;
      yukleniyor = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Çalışma Kategorileri')),
      body: yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _KategoriButonu("Genel Kelimeler", "kelimeler", Icons.list_alt),
                  const SizedBox(height: 16),
                  _KategoriButonu("Zarflar (Adverbs)", "adverbler", Icons.speed),
                  const SizedBox(height: 16),
                  _KategoriButonu("Bağlaçlar (Conjunctions)", "baglaclar", Icons.link),
                  const SizedBox(height: 16),
                  _KategoriButonu("Edatlar (Prepositions)", "prepler", Icons.place),
                ],
              ),
            ),
    );
  }

  Widget _KategoriButonu(String baslik, String jsonAnahtari, IconData ikon) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      icon: Icon(ikon, size: 28),
      label: Text(baslik),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CalismaEkrani(
              kategoriAdi: baslik,
              kategoriKey: jsonAnahtari,
              kelimeListesi: tumKelimeler[jsonAnahtari],
            ),
          ),
        );
      },
    );
  }
}

class CalismaEkrani extends StatefulWidget {
  final String kategoriAdi;
  final String kategoriKey;
  final List<dynamic> kelimeListesi;

  const CalismaEkrani({
    Key? key,
    required this.kategoriAdi,
    required this.kategoriKey,
    required this.kelimeListesi,
  }) : super(key: key);

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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu kategorideki tüm kelimeleri bitirdiniz!')),
      );
    }
  }

  // YENİ EKLENEN FONKSİYON: Önceki Kelime
  Future<void> _oncekiKelime() async {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        anlamiGoster = false; // Geri dönüldüğünde anlamı tekrar gizle ki kendini test edebil
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(widget.kategoriKey, currentIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.kelimeListesi.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.kategoriAdi)),
        body: const Center(child: Text("Bu kategoride kelime bulunamadı.")),
      );
    }

    var aktifKelime = widget.kelimeListesi[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kategoriAdi),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                "${currentIndex + 1} / ${widget.kelimeListesi.length}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "İngilizce Kelime:",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              aktifKelime['en'],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 40),
            if (anlamiGoster) ...[
              const Text(
                "Türkçe Anlamı:",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Text(
                aktifKelime['tr'],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: Colors.green),
              ),
            ] else ...[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.orangeAccent,
                ),
                onPressed: () {
                  setState(() {
                    anlamiGoster = true;
                  });
                },
                child: const Text("Anlamını Göster", style: TextStyle(fontSize: 20)),
              ),
            ],
            const Spacer(),
            
            // YENİ EKLENEN TASARIM: Önceki ve Sonraki Butonları Yan Yana
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: Colors.blueGrey,
                    ),
                    onPressed: currentIndex > 0 ? _oncekiKelime : null, // İlk kelimede pasif olur
                    child: const Text("Önceki", style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: Colors.indigo,
                    ),
                    onPressed: anlamiGoster ? _sonrakiKelime : null,
                    child: const Text("Sonraki Kelime", style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}