import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:english_words/english_words.dart';
import 'dart:math';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class LetraResultado {
  final String letra;
  final int codigoCor;

  LetraResultado(this.letra, this.codigoCor);
}

class _HomeState extends State<Home> {
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  String _rightWord = "start";
  final List<List<LetraResultado>> _tentativas = [];
  bool _jogoFinalizado = false;

  int mode = 0;
  String userName = "";
  String? _dificuldadeSelecionada = 'easy';
  int _tamanhoPalavraSelecionado = 5;
  int _maxTentativas = 20;

  void _gerarPalavraCorreta() {
    late List<String> palavrasFiltradas;
    final Map<String, List<int>> rangesDificuldade = {
      'easy': [0, 1500],
      'medium': [1500, 4000],
      'hard': [4000, all.length],
    };

    final range = rangesDificuldade[_dificuldadeSelecionada]!;
    palavrasFiltradas = all
        .getRange(range[0], range[1])
        .where((word) => word.length == _tamanhoPalavraSelecionado)
        .toList();

    if (palavrasFiltradas.isEmpty) {
      palavrasFiltradas = all
          .where((word) => word.length == _tamanhoPalavraSelecionado)
          .toList();
    }
    _rightWord = palavrasFiltradas[Random().nextInt(palavrasFiltradas.length)];
  }

  void _iniciarJogo() {
    setState(() {
      userName =
          userNameController.text.isNotEmpty ? userNameController.text : "Player";
      
      switch (_dificuldadeSelecionada) {
        case 'easy':
          _maxTentativas = 20;
          break;
        case 'medium':
          _maxTentativas = 15;
          break;
        case 'hard':
          _maxTentativas = 6;
          break;
      }

      _gerarPalavraCorreta();
      _resetarJogoState();
      mode = 1;
    });
  }

  void _resetarJogoState() {
    _tentativas.clear();
    _jogoFinalizado = false;
    nameController.clear();
  }

  void _resetarJogo() {
    setState(() {
      _gerarPalavraCorreta();
      _resetarJogoState();
    });
  }

  int compareChars(String right, String responseChar, int pos) {
    if (right[pos] == responseChar) {
      return 1;
    }
    if (right.contains(responseChar)) {
      return 2;
    }
    return 0;
  }

  void _send() {
    final word = nameController.text.toLowerCase();
    if (word.length != _rightWord.length) return;

    final List<LetraResultado> comparedWord = [];
    for (int i = 0; i < word.length; i++) {
      var char = word[i];
      int color = compareChars(_rightWord, char, i);
      comparedWord.add(LetraResultado(char, color));
    }

    setState(() {
      _tentativas.insert(0, comparedWord);
      nameController.clear();
    });

    if (word == _rightWord) {
      setState(() {
        _jogoFinalizado = true;
      });
      Future.delayed(const Duration(milliseconds: 200), () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Congratulations!'),
              content:
                  Text('You got the word right: "${_rightWord.toUpperCase()}"'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Play again'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _resetarJogo();
                  },
                ),
              ],
            );
          },
        );
      });
    } else if (_tentativas.length >= _maxTentativas) {
        setState(() {
          _jogoFinalizado = true;
        });
        Future.delayed(const Duration(milliseconds: 200), () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Game Over!'),
                content: Text(
                    'You couldnt guess the word: "${_rightWord.toUpperCase()}"'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Play Again'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _resetarJogo();
                    },
                  ),
                ],
              );
            },
          );
        });
    }
  }

  Color _getColor(int code) {
    switch (code) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.yellow;
      case 0:
      default:
        return Colors.grey[300]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case 1:
        return Scaffold(
          appBar: AppBar(
            title: const Text("Letroso"),
            backgroundColor: Colors.blueGrey,
            foregroundColor: Colors.white,
            actions: <Widget>[
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Text("Hello, $userName!"),
                ),
              ),
            ],
          ),
          body: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  keyboardType: TextInputType.text,
                  controller: nameController,
                  enabled: !_jogoFinalizado,
                  decoration: const InputDecoration(
                      labelText: "Enter the word:",
                      labelStyle:
                          TextStyle(fontSize: 20, color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      )),
                  maxLength: _rightWord.length,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  style: const TextStyle(fontSize: 30, color: Colors.white),
                  onSubmitted: (_) => _send(),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _jogoFinalizado ? null : _send,
                  child: const Text("Send"),
                ),
                const SizedBox(height: 20),
                Text(
                  "Remaining attempts: ${_maxTentativas - _tentativas.length}",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: _tentativas.length,
                    itemBuilder: (context, index) {
                      final tentativa = _tentativas[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: tentativa.map((resultadoDaLetra) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Text(
                                resultadoDaLetra.letra.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: _getColor(resultadoDaLetra.codigoCor),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 38, 38, 56),
        );

      default:
        return Scaffold(
          appBar: AppBar(
            title: const Text("Letroso - Settings"),
            backgroundColor: Colors.blueGrey,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                    keyboardType: TextInputType.text,
                    controller: userNameController,
                    decoration: const InputDecoration(
                        labelText: "Your nickname:",
                        labelStyle:
                            TextStyle(fontSize: 20, color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white70),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        )),
                    maxLength: 15,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    style: const TextStyle(fontSize: 30, color: Colors.white)),
                const SizedBox(height: 30),
                const Text("Difficulty:",
                    style: TextStyle(color: Colors.white, fontSize: 18)),
                ...[
                  {'id': 'easy', 'label': 'Easy'},
                  {'id': 'medium', 'label': 'Normal'},
                  {'id': 'hard', 'label': 'Hard'}
                ].map((dificuldade) => RadioListTile<String>(
                      title: Text(dificuldade['label']!,
                          style: const TextStyle(color: Colors.white)),
                      value: dificuldade['id']!,
                      groupValue: _dificuldadeSelecionada,
                      onChanged: (val) {
                        setState(() {
                          _dificuldadeSelecionada = val;
                        });
                      },
                    )),
                const SizedBox(height: 30),
                const Text("Word length:",
                    style: TextStyle(color: Colors.white, fontSize: 18)),
                Wrap(
                  spacing: 4.0,
                  runSpacing: 0.0,
                  children: List<int>.generate(6, (i) => i + 5).map((tamanho) {
                    return SizedBox(
                      width: 150,
                      child: RadioListTile<int>(
                        title: Text('$tamanho letters',
                            style: const TextStyle(color: Colors.white)),
                        value: tamanho,
                        groupValue: _tamanhoPalavraSelecionado,
                        onChanged: (val) {
                          setState(() {
                            _tamanhoPalavraSelecionado = val!;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 40),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                        textStyle: const TextStyle(fontSize: 20)),
                    onPressed: _iniciarJogo,
                    child: const Text("Start Game!"),
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 38, 38, 56),
        );
    }
  }
}