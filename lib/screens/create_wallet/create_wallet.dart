import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:flutter/material.dart';
import 'package:mooze_mobile/widgets/appbar.dart';
import 'package:mooze_mobile/widgets/buttons.dart';
import 'package:no_screenshot/no_screenshot.dart';

class CreateWalletScreen extends StatefulWidget {
  @override
  _CreateWalletScreenState createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends State<CreateWalletScreen> {
  Language selectedLanguage = Language.english; // default to English
  bool extendedPhrase = false; // default to 12 words

  final languageNames = {
    Language.english: "English",
    Language.portuguese: "Português",
  };

  String enumToString(Language lang) {
    return lang.name[0].toUpperCase() + lang.name.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MoozeAppBar(title: "Criar carteira"),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /*
                Text(
                  "Selecione a linguagem da frase de recuperação",
                  style: TextStyle(
                    fontFamily: "roboto",
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                ...Language.values
                    .where(
                      (lang) =>
                          (lang == Language.portuguese) ||
                          (lang == Language.english),
                    )
                    .map(
                      (lang) => RadioListTile<Language>(
                        title: Text(languageNames[lang] ?? enumToString(lang)),
                        value: lang,
                        groupValue: selectedLanguage,
                        onChanged: (Language? newValue) {
                          setState(() {
                            selectedLanguage = newValue!;
                          });
                        },
                      ),
                    ),
                SizedBox(height: 20),
                */
                Text(
                  "Selecione o tamanho da frase",
                  style: TextStyle(
                    fontFamily: "roboto",
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center, // Center text
                ),
                RadioListTile<bool>(
                  title: Text("12 palavras"),
                  value: false,
                  groupValue: extendedPhrase,
                  onChanged: (bool? newValue) {
                    setState(() {
                      extendedPhrase = newValue!;
                    });
                  },
                ),
                RadioListTile<bool>(
                  title: Text("24 palavras (recomendado)"),
                  value: true,
                  groupValue: extendedPhrase,
                  onChanged: (bool? newValue) {
                    setState(() {
                      extendedPhrase = newValue!;
                    });
                  },
                ),
                SizedBox(height: 20),

                PrimaryButton(
                  text: "Gerar frase de recuperação",
                  onPressed: () async {
                    final noScreenshot = NoScreenshot.instance;
                    await noScreenshot.screenshotOff();

                    if (context.mounted) {
                      Navigator.pushNamed(
                        context,
                        '/generate_mnemonic',
                        arguments: {
                          'language': selectedLanguage,
                          'extendedPhrase': extendedPhrase,
                        },
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
