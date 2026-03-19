import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const YdsApp());
}

class YdsApp extends StatelessWidget {
  const YdsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YDS Kelime Asistanı',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade900),
        useMaterial3: true,
      ),
      home: const MainMenu(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  Map<String, dynamic> allWords = {};
  SharedPreferences? prefs;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initApp();
  }

  Future<void> initApp() async {
    prefs = await SharedPreferences.getInstance();
    try {
      final String response = await rootBundle.loadString('assets/words.json');
      final data = await json.decode(response);
      setState(() {
        allWords = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Hata: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text("YDS Kelime Menü"), centerTitle: true),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 7,
        itemBuilder: (context, index) {
          String dayKey = (index + 1).toString();
          if (!allWords.containsKey(dayKey)) return const SizedBox();
          List words = allWords[dayKey];
          int correct = 0, wrong = 0;

          for (var w in words) {
            String status = prefs?.getString('status_${dayKey}_${w['en']}') ?? 'none';
            if (status == 'correct') correct++;
            if (status == 'wrong') wrong++;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text("$dayKey. Gün Kelimeleri"),
              subtitle: Text("Doğru: $correct | Yanlış: $wrong | Kalan: ${words.length - (correct + wrong)}"),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => PracticeScreen(dayKey: dayKey, words: words, prefs: prefs!)))
                .then((_) => setState(() {}));
              },
            ),
          );
        },
      ),
    );
  }
}

class PracticeScreen extends StatefulWidget {
  final String dayKey;
  final List words;
  final SharedPreferences prefs;
  const PracticeScreen({super.key, required this.dayKey, required this.words, required this.prefs});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  int index = 0;
  final TextEditingController _ctrl = TextEditingController();
  bool isChecked = false;
  String feedback = "";

  void check() {
    String user = _ctrl.text.trim().toLowerCase();
    String correct = widget.words[index]['tr'].toString().toLowerCase();
    setState(() {
      isChecked = true;
      if (user.isNotEmpty && (user.contains(correct) || correct.contains(user))) {
        feedback = "✅ Doğru!";
        widget.prefs.setString('status_${widget.dayKey}_${widget.words[index]['en']}', 'correct');
      } else {
        feedback = "❌ Yanlış!";
        widget.prefs.setString('status_${widget.dayKey}_${widget.words[index]['en']}', 'wrong');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var word = widget.words[index];
    return Scaffold(
      appBar: AppBar(title: Text("${widget.dayKey}. Gün")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Text("${index + 1} / ${widget.words.length}"),
          const SizedBox(height: 20),
          Text(word['en'], style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          TextField(controller: _ctrl, enabled: !isChecked, textAlign: TextAlign.center, decoration: const InputDecoration(border: OutlineInputBorder())),
          const SizedBox(height: 20),
          if (!isChecked) ElevatedButton(onPressed: check, child: const Text("Kontrol Et")),
          if (isChecked) ...[
            Text(feedback, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(word['tr'], style: const TextStyle(fontSize: 26, color: Colors.blue)),
            const Spacer(),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              OutlinedButton(onPressed: index > 0 ? () => setState(() { index--; isChecked = false; _ctrl.clear(); }) : null, child: const Text("Önceki")),
              FilledButton(onPressed: () {
                if (index < widget.words.length - 1) {
                  setState(() { index++; isChecked = false; _ctrl.clear(); });
                } else { Navigator.pop(context); }
              }, child: Text(index == widget.words.length - 1 ? "Bitir" : "Sonraki")),
            ])
          ]
        ]),
      ),
    );
  }
}