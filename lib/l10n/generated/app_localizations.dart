import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// No description provided for @common_back.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get common_back;

  /// No description provided for @common_cancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get common_cancel;

  /// No description provided for @common_confirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get common_confirm;

  /// No description provided for @common_save.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get common_save;

  /// No description provided for @common_close.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get common_close;

  /// No description provided for @common_continue.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get common_continue;

  /// No description provided for @common_next.
  ///
  /// In pt, this message translates to:
  /// **'Próximo'**
  String get common_next;

  /// No description provided for @common_ok.
  ///
  /// In pt, this message translates to:
  /// **'OK'**
  String get common_ok;

  /// No description provided for @common_retry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get common_retry;

  /// No description provided for @common_loading.
  ///
  /// In pt, this message translates to:
  /// **'Carregando...'**
  String get common_loading;

  /// No description provided for @common_processing.
  ///
  /// In pt, this message translates to:
  /// **'Processando...'**
  String get common_processing;

  /// No description provided for @common_sending.
  ///
  /// In pt, this message translates to:
  /// **'Enviando...'**
  String get common_sending;

  /// No description provided for @common_confirming.
  ///
  /// In pt, this message translates to:
  /// **'Confirmando...'**
  String get common_confirming;

  /// No description provided for @common_verifying.
  ///
  /// In pt, this message translates to:
  /// **'Verificando...'**
  String get common_verifying;

  /// No description provided for @common_understood.
  ///
  /// In pt, this message translates to:
  /// **'Entendi'**
  String get common_understood;

  /// No description provided for @common_no_thanks.
  ///
  /// In pt, this message translates to:
  /// **'Não, obrigado'**
  String get common_no_thanks;

  /// No description provided for @common_max.
  ///
  /// In pt, this message translates to:
  /// **'MAX'**
  String get common_max;

  /// No description provided for @common_yes.
  ///
  /// In pt, this message translates to:
  /// **'Sim'**
  String get common_yes;

  /// No description provided for @common_no.
  ///
  /// In pt, this message translates to:
  /// **'Não'**
  String get common_no;

  /// No description provided for @common_finish.
  ///
  /// In pt, this message translates to:
  /// **'Concluir'**
  String get common_finish;

  /// No description provided for @common_redo.
  ///
  /// In pt, this message translates to:
  /// **'Refazer'**
  String get common_redo;

  /// No description provided for @error_open_link.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir o link'**
  String get error_open_link;

  /// No description provided for @error_opening_link.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao abrir o link'**
  String get error_opening_link;

  /// No description provided for @error_open_browser.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir o navegador.'**
  String get error_open_browser;

  /// No description provided for @error_unexpected.
  ///
  /// In pt, this message translates to:
  /// **'Erro inesperado: {error}'**
  String error_unexpected(String error);

  /// No description provided for @error_generic.
  ///
  /// In pt, this message translates to:
  /// **'Erro: {error}'**
  String error_generic(String error);

  /// No description provided for @error_load_data.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar dados. Tente novamente.'**
  String get error_load_data;

  /// No description provided for @error_load_data_short.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar dados'**
  String get error_load_data_short;

  /// No description provided for @error_load_data_title.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao Carregar Dados'**
  String get error_load_data_title;

  /// No description provided for @error_no_internet.
  ///
  /// In pt, this message translates to:
  /// **'Sem conexão com a internet. Verifique sua conexão.'**
  String get error_no_internet;

  /// No description provided for @error_server_unavailable.
  ///
  /// In pt, this message translates to:
  /// **'Servidor temporariamente indisponível. Tente novamente.'**
  String get error_server_unavailable;

  /// No description provided for @error_server_communication.
  ///
  /// In pt, this message translates to:
  /// **'Erro de comunicação com o servidor. Tente novamente.'**
  String get error_server_communication;

  /// No description provided for @error_authentication_failed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível autenticar.'**
  String get error_authentication_failed;

  /// No description provided for @error_access_denied.
  ///
  /// In pt, this message translates to:
  /// **'Acesso negado. Verifique suas permissões.'**
  String get error_access_denied;

  /// No description provided for @error_service_not_found.
  ///
  /// In pt, this message translates to:
  /// **'Serviço não encontrado. Tente novamente mais tarde.'**
  String get error_service_not_found;

  /// No description provided for @settings_title.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get settings_title;

  /// No description provided for @settings_section_security.
  ///
  /// In pt, this message translates to:
  /// **'SEGURANÇA'**
  String get settings_section_security;

  /// No description provided for @settings_section_appearance.
  ///
  /// In pt, this message translates to:
  /// **'APARÊNCIA'**
  String get settings_section_appearance;

  /// No description provided for @settings_section_language.
  ///
  /// In pt, this message translates to:
  /// **'IDIOMA'**
  String get settings_section_language;

  /// No description provided for @settings_section_currency.
  ///
  /// In pt, this message translates to:
  /// **'MOEDA'**
  String get settings_section_currency;

  /// No description provided for @settings_section_account.
  ///
  /// In pt, this message translates to:
  /// **'CONTA E BENEFÍCIOS'**
  String get settings_section_account;

  /// No description provided for @settings_section_legal.
  ///
  /// In pt, this message translates to:
  /// **'LEGAL'**
  String get settings_section_legal;

  /// No description provided for @settings_section_developer.
  ///
  /// In pt, this message translates to:
  /// **'DESENVOLVEDOR'**
  String get settings_section_developer;

  /// No description provided for @settings_section_help.
  ///
  /// In pt, this message translates to:
  /// **'AJUDA'**
  String get settings_section_help;

  /// No description provided for @settings_view_recovery_phrase.
  ///
  /// In pt, this message translates to:
  /// **'Ver frase de recuperação'**
  String get settings_view_recovery_phrase;

  /// No description provided for @settings_change_pin.
  ///
  /// In pt, this message translates to:
  /// **'Mudar PIN'**
  String get settings_change_pin;

  /// No description provided for @settings_biometric_auth.
  ///
  /// In pt, this message translates to:
  /// **'Autenticação biométrica'**
  String get settings_biometric_auth;

  /// No description provided for @settings_delete_wallet.
  ///
  /// In pt, this message translates to:
  /// **'Deletar carteira'**
  String get settings_delete_wallet;

  /// No description provided for @settings_theme.
  ///
  /// In pt, this message translates to:
  /// **'Tema'**
  String get settings_theme;

  /// No description provided for @settings_language.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get settings_language;

  /// No description provided for @settings_change_currency.
  ///
  /// In pt, this message translates to:
  /// **'Alterar moeda'**
  String get settings_change_currency;

  /// No description provided for @settings_referral_code.
  ///
  /// In pt, this message translates to:
  /// **'Cupom de indicação'**
  String get settings_referral_code;

  /// No description provided for @settings_terms.
  ///
  /// In pt, this message translates to:
  /// **'Termos de uso'**
  String get settings_terms;

  /// No description provided for @settings_license.
  ///
  /// In pt, this message translates to:
  /// **'Licença GPL'**
  String get settings_license;

  /// No description provided for @settings_logs.
  ///
  /// In pt, this message translates to:
  /// **'Logs'**
  String get settings_logs;

  /// No description provided for @settings_log_details.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes do log'**
  String get settings_log_details;

  /// No description provided for @settings_contact_support.
  ///
  /// In pt, this message translates to:
  /// **'Contatar suporte'**
  String get settings_contact_support;

  /// No description provided for @settings_section_network.
  ///
  /// In pt, this message translates to:
  /// **'REDE'**
  String get settings_section_network;

  /// No description provided for @settings_node_config.
  ///
  /// In pt, this message translates to:
  /// **'Configuração de nodes'**
  String get settings_node_config;

  /// No description provided for @node_config_title.
  ///
  /// In pt, this message translates to:
  /// **'Configuração de nodes'**
  String get node_config_title;

  /// No description provided for @node_config_section_mode.
  ///
  /// In pt, this message translates to:
  /// **'MODO'**
  String get node_config_section_mode;

  /// No description provided for @node_config_section_custom.
  ///
  /// In pt, this message translates to:
  /// **'ENDPOINTS'**
  String get node_config_section_custom;

  /// No description provided for @node_config_section_advanced.
  ///
  /// In pt, this message translates to:
  /// **'AVANÇADO'**
  String get node_config_section_advanced;

  /// No description provided for @node_config_mode_default_title.
  ///
  /// In pt, this message translates to:
  /// **'Modo padrão'**
  String get node_config_mode_default_title;

  /// No description provided for @node_config_mode_default_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Usa os servidores recomendados pelo sistema, com fallback automático entre Bitcoin, Liquid e Lightning.'**
  String get node_config_mode_default_subtitle;

  /// No description provided for @node_config_mode_custom_title.
  ///
  /// In pt, this message translates to:
  /// **'Modo personalizado'**
  String get node_config_mode_custom_title;

  /// No description provided for @node_config_mode_custom_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Avançado — conecte-se aos seus próprios servidores Electrum.'**
  String get node_config_mode_custom_subtitle;

  /// No description provided for @node_config_advanced_warning.
  ///
  /// In pt, this message translates to:
  /// **'Configure apenas se você sabe o que está fazendo. URLs inválidas podem impedir o app de sincronizar.'**
  String get node_config_advanced_warning;

  /// No description provided for @node_config_bitcoin_label.
  ///
  /// In pt, this message translates to:
  /// **'Endpoint Bitcoin Mainnet'**
  String get node_config_bitcoin_label;

  /// No description provided for @node_config_bitcoin_hint.
  ///
  /// In pt, this message translates to:
  /// **'ssl://seu-node.tld:50002'**
  String get node_config_bitcoin_hint;

  /// No description provided for @node_config_bitcoin_helper.
  ///
  /// In pt, this message translates to:
  /// **'Formato: esquema://host:porta. Use ssl:// para conexões criptografadas.'**
  String get node_config_bitcoin_helper;

  /// No description provided for @node_config_liquid_label.
  ///
  /// In pt, this message translates to:
  /// **'Endpoint Liquid Network'**
  String get node_config_liquid_label;

  /// No description provided for @node_config_liquid_hint.
  ///
  /// In pt, this message translates to:
  /// **'seu-node.tld:50002'**
  String get node_config_liquid_hint;

  /// No description provided for @node_config_liquid_helper.
  ///
  /// In pt, this message translates to:
  /// **'Formato: host:porta. O LWK usa TLS automaticamente.'**
  String get node_config_liquid_helper;

  /// No description provided for @node_config_lightning_note.
  ///
  /// In pt, this message translates to:
  /// **'O node Lightning é gerenciado automaticamente pelo Breez SDK e não pode ser personalizado.'**
  String get node_config_lightning_note;

  /// No description provided for @node_config_fallback_toggle_title.
  ///
  /// In pt, this message translates to:
  /// **'Permitir fallback automático'**
  String get node_config_fallback_toggle_title;

  /// No description provided for @node_config_fallback_toggle_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Se o seu node falhar, o app tenta automaticamente os servidores padrão.'**
  String get node_config_fallback_toggle_subtitle;

  /// No description provided for @node_config_save.
  ///
  /// In pt, this message translates to:
  /// **'Salvar configurações'**
  String get node_config_save;

  /// No description provided for @node_config_url_required.
  ///
  /// In pt, this message translates to:
  /// **'Obrigatório no modo personalizado'**
  String get node_config_url_required;

  /// No description provided for @node_config_url_invalid.
  ///
  /// In pt, this message translates to:
  /// **'Use o formato host:porta (ou esquema://host:porta)'**
  String get node_config_url_invalid;

  /// No description provided for @node_config_unsaved_title.
  ///
  /// In pt, this message translates to:
  /// **'Alterações não salvas'**
  String get node_config_unsaved_title;

  /// No description provided for @node_config_unsaved_message.
  ///
  /// In pt, this message translates to:
  /// **'Você tem alterações que ainda não foram salvas. Deseja salvá-las antes de sair?'**
  String get node_config_unsaved_message;

  /// No description provided for @node_config_unsaved_discard.
  ///
  /// In pt, this message translates to:
  /// **'Descartar'**
  String get node_config_unsaved_discard;

  /// No description provided for @node_config_save_success.
  ///
  /// In pt, this message translates to:
  /// **'Configurações de node salvas'**
  String get node_config_save_success;

  /// No description provided for @node_config_save_error.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao salvar: {error}'**
  String node_config_save_error(String error);

  /// No description provided for @node_config_load_error.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as configurações de node'**
  String get node_config_load_error;

  /// No description provided for @support_telegram_open_error.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir o Telegram'**
  String get support_telegram_open_error;

  /// No description provided for @support_screen_title.
  ///
  /// In pt, this message translates to:
  /// **'Central de Suporte'**
  String get support_screen_title;

  /// No description provided for @support_help_title.
  ///
  /// In pt, this message translates to:
  /// **'Como podemos ajudar?'**
  String get support_help_title;

  /// No description provided for @support_help_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Para um atendimento mais eficiente, compartilhe o código abaixo com nosso suporte.'**
  String get support_help_subtitle;

  /// No description provided for @support_user_code_label.
  ///
  /// In pt, this message translates to:
  /// **'Seu código de identificação'**
  String get support_user_code_label;

  /// No description provided for @support_user_code_load_error_title.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar seu código'**
  String get support_user_code_load_error_title;

  /// No description provided for @support_user_code_load_error_msg.
  ///
  /// In pt, this message translates to:
  /// **'Ocorreu um erro ao carregar suas informações'**
  String get support_user_code_load_error_msg;

  /// No description provided for @support_user_code_not_found.
  ///
  /// In pt, this message translates to:
  /// **'Não encontramos suas informações'**
  String get support_user_code_not_found;

  /// No description provided for @support_contact_button.
  ///
  /// In pt, this message translates to:
  /// **'Falar com o suporte'**
  String get support_contact_button;

  /// No description provided for @biometric_auth_reason.
  ///
  /// In pt, this message translates to:
  /// **'Confirme sua identidade para ativar a autenticação biométrica'**
  String get biometric_auth_reason;

  /// No description provided for @biometric_enabled_success.
  ///
  /// In pt, this message translates to:
  /// **'Autenticação biométrica ativada.'**
  String get biometric_enabled_success;

  /// No description provided for @biometric_disabled_info.
  ///
  /// In pt, this message translates to:
  /// **'Autenticação biométrica desativada.'**
  String get biometric_disabled_info;

  /// No description provided for @biometric_disable_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao desativar biometria.'**
  String get biometric_disable_error;

  /// No description provided for @biometric_save_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar configuração.'**
  String get biometric_save_error;

  /// No description provided for @biometric_auth_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao autenticar: {error}'**
  String biometric_auth_error(String error);

  /// No description provided for @biometric_setup_enable_q.
  ///
  /// In pt, this message translates to:
  /// **'Ativar biometria?'**
  String get biometric_setup_enable_q;

  /// No description provided for @biometric_setup_explanation.
  ///
  /// In pt, this message translates to:
  /// **'Use Face ID, impressão digital ou a senha do dispositivo para acessar sua carteira com mais rapidez e segurança.'**
  String get biometric_setup_explanation;

  /// No description provided for @biometric_setup_enable.
  ///
  /// In pt, this message translates to:
  /// **'Ativar biometria'**
  String get biometric_setup_enable;

  /// No description provided for @seed_fetch_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro: {error}'**
  String seed_fetch_error(String error);

  /// No description provided for @seed_not_found.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma seed encontrada.'**
  String get seed_not_found;

  /// No description provided for @seed_screen_title.
  ///
  /// In pt, this message translates to:
  /// **'Frase de Recuperação'**
  String get seed_screen_title;

  /// No description provided for @seed_words_of.
  ///
  /// In pt, this message translates to:
  /// **'Palavras de '**
  String get seed_words_of;

  /// No description provided for @seed_recovery_word.
  ///
  /// In pt, this message translates to:
  /// **'Recuperação'**
  String get seed_recovery_word;

  /// No description provided for @seed_save_warning.
  ///
  /// In pt, this message translates to:
  /// **'Anote estas palavras em um local seguro. Elas são a única forma de recuperar sua carteira.'**
  String get seed_save_warning;

  /// No description provided for @seed_copy.
  ///
  /// In pt, this message translates to:
  /// **'Copiar seed'**
  String get seed_copy;

  /// No description provided for @seed_copied.
  ///
  /// In pt, this message translates to:
  /// **'Copiado'**
  String get seed_copied;

  /// No description provided for @seed_confirm_phrase.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar frase'**
  String get seed_confirm_phrase;

  /// No description provided for @seed_confirmed_words_count.
  ///
  /// In pt, this message translates to:
  /// **'Palavras confirmadas ({count})'**
  String seed_confirmed_words_count(int count);

  /// No description provided for @seed_remove_last.
  ///
  /// In pt, this message translates to:
  /// **'Remover última'**
  String get seed_remove_last;

  /// No description provided for @pin_confirm_title.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar PIN'**
  String get pin_confirm_title;

  /// No description provided for @pin_confirm_yours.
  ///
  /// In pt, this message translates to:
  /// **'Confirme seu '**
  String get pin_confirm_yours;

  /// No description provided for @pin_word.
  ///
  /// In pt, this message translates to:
  /// **'PIN'**
  String get pin_word;

  /// No description provided for @pin_confirm_instruction_1.
  ///
  /// In pt, this message translates to:
  /// **'Digite novamente o '**
  String get pin_confirm_instruction_1;

  /// No description provided for @pin_confirm_instruction_2.
  ///
  /// In pt, this message translates to:
  /// **'PIN '**
  String get pin_confirm_instruction_2;

  /// No description provided for @pin_confirm_instruction_3.
  ///
  /// In pt, this message translates to:
  /// **'que você acabou de criar.'**
  String get pin_confirm_instruction_3;

  /// No description provided for @pin_mismatch.
  ///
  /// In pt, this message translates to:
  /// **'PINs não coincidem'**
  String get pin_mismatch;

  /// No description provided for @pin_validate_title.
  ///
  /// In pt, this message translates to:
  /// **'Validar PIN'**
  String get pin_validate_title;

  /// No description provided for @pin_validate_security.
  ///
  /// In pt, this message translates to:
  /// **'Validação de segurança'**
  String get pin_validate_security;

  /// No description provided for @pin_validate_action.
  ///
  /// In pt, this message translates to:
  /// **'Validar '**
  String get pin_validate_action;

  /// No description provided for @pin_validate_body.
  ///
  /// In pt, this message translates to:
  /// **'Digite seu PIN para continuar com segurança.'**
  String get pin_validate_body;

  /// No description provided for @pin_incorrect.
  ///
  /// In pt, this message translates to:
  /// **'PIN incorreto. Tente novamente.'**
  String get pin_incorrect;

  /// No description provided for @pin_use_biometric.
  ///
  /// In pt, this message translates to:
  /// **'Usar biometria'**
  String get pin_use_biometric;

  /// No description provided for @pin_use_device_password.
  ///
  /// In pt, this message translates to:
  /// **'Use a senha do dispositivo'**
  String get pin_use_device_password;

  /// No description provided for @pin_forgot.
  ///
  /// In pt, this message translates to:
  /// **'Esqueceu seu PIN?'**
  String get pin_forgot;

  /// No description provided for @pin_biometric_unavailable.
  ///
  /// In pt, this message translates to:
  /// **'Biometria ou senha do sistema não disponível.'**
  String get pin_biometric_unavailable;

  /// No description provided for @pin_biometric_access_reason.
  ///
  /// In pt, this message translates to:
  /// **'Use sua biometria para acessar sua carteira'**
  String get pin_biometric_access_reason;

  /// No description provided for @pin_reset_biometric_reason.
  ///
  /// In pt, this message translates to:
  /// **'Use sua biometria ou senha do dispositivo para redefinir o PIN'**
  String get pin_reset_biometric_reason;

  /// No description provided for @theme_system.
  ///
  /// In pt, this message translates to:
  /// **'Sistema'**
  String get theme_system;

  /// No description provided for @theme_light.
  ///
  /// In pt, this message translates to:
  /// **'Claro'**
  String get theme_light;

  /// No description provided for @theme_dark.
  ///
  /// In pt, this message translates to:
  /// **'Escuro'**
  String get theme_dark;

  /// No description provided for @language_portuguese.
  ///
  /// In pt, this message translates to:
  /// **'Português'**
  String get language_portuguese;

  /// No description provided for @language_english.
  ///
  /// In pt, this message translates to:
  /// **'Inglês'**
  String get language_english;

  /// No description provided for @language_spanish.
  ///
  /// In pt, this message translates to:
  /// **'Espanhol'**
  String get language_spanish;

  /// No description provided for @language_system.
  ///
  /// In pt, this message translates to:
  /// **'Idioma do dispositivo'**
  String get language_system;

  /// No description provided for @delete_wallet_title.
  ///
  /// In pt, this message translates to:
  /// **'Deletar carteira'**
  String get delete_wallet_title;

  /// No description provided for @delete_wallet_warning_title.
  ///
  /// In pt, this message translates to:
  /// **'Atenção ao deletar sua '**
  String get delete_wallet_warning_title;

  /// No description provided for @delete_wallet_word.
  ///
  /// In pt, this message translates to:
  /// **'carteira'**
  String get delete_wallet_word;

  /// No description provided for @delete_wallet_warning_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Ao deletar, será necessário passar novamente pelo sistema TRUST e você perderá acesso aos fundos se não tiver salvo sua frase de recuperação.'**
  String get delete_wallet_warning_subtitle;

  /// No description provided for @delete_wallet_pix_limits_title.
  ///
  /// In pt, this message translates to:
  /// **'Limites PIX'**
  String get delete_wallet_pix_limits_title;

  /// No description provided for @delete_wallet_pix_limits_desc.
  ///
  /// In pt, this message translates to:
  /// **'Eu estou ciente de que precisarei passar novamente pelo sistema TRUST e que meus limites de PIX serão resetados.'**
  String get delete_wallet_pix_limits_desc;

  /// No description provided for @delete_wallet_funds_loss_title.
  ///
  /// In pt, this message translates to:
  /// **'Perda de fundos'**
  String get delete_wallet_funds_loss_title;

  /// No description provided for @delete_wallet_funds_loss_desc.
  ///
  /// In pt, this message translates to:
  /// **'Eu estou ciente que perderei acesso aos meus fundos caso não tenha guardado minha frase de recuperação.'**
  String get delete_wallet_funds_loss_desc;

  /// No description provided for @delete_wallet_button.
  ///
  /// In pt, this message translates to:
  /// **'Deletar carteira'**
  String get delete_wallet_button;

  /// No description provided for @delete_wallet_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao deletar carteira. Tente novamente.'**
  String get delete_wallet_error;

  /// No description provided for @referral_title.
  ///
  /// In pt, this message translates to:
  /// **'Código de Indicação'**
  String get referral_title;

  /// No description provided for @referral_applied_success.
  ///
  /// In pt, this message translates to:
  /// **'Código aplicado com sucesso!'**
  String get referral_applied_success;

  /// No description provided for @referral_error_empty_code.
  ///
  /// In pt, this message translates to:
  /// **'Código não pode ser vazio.'**
  String get referral_error_empty_code;

  /// No description provided for @referral_error_invalid_code.
  ///
  /// In pt, this message translates to:
  /// **'Código inválido. Verifique e tente novamente.'**
  String get referral_error_invalid_code;

  /// No description provided for @referral_error_apply_failed.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao adicionar código. Tente novamente.'**
  String get referral_error_apply_failed;

  /// No description provided for @referral_error_fetch_failed.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao buscar código de indicação.'**
  String get referral_error_fetch_failed;

  /// No description provided for @referral_error_validate_failed.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao validar código.'**
  String get referral_error_validate_failed;

  /// No description provided for @license_title.
  ///
  /// In pt, this message translates to:
  /// **'Licença GPL v3'**
  String get license_title;

  /// No description provided for @license_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'GNU General Public License'**
  String get license_subtitle;

  /// No description provided for @license_version_line.
  ///
  /// In pt, this message translates to:
  /// **'Versão 3, 29 de junho de 2007 • Free Software Foundation'**
  String get license_version_line;

  /// No description provided for @license_copyleft_title.
  ///
  /// In pt, this message translates to:
  /// **'Copyleft License'**
  String get license_copyleft_title;

  /// No description provided for @license_copyleft_desc.
  ///
  /// In pt, this message translates to:
  /// **'Esta licença garante que o software permaneça livre. Qualquer distribuição deve incluir o código-fonte.'**
  String get license_copyleft_desc;

  /// No description provided for @license_free_software_title.
  ///
  /// In pt, this message translates to:
  /// **'Software Livre'**
  String get license_free_software_title;

  /// No description provided for @license_free_software_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Liberdade garantida'**
  String get license_free_software_subtitle;

  /// No description provided for @license_redistributable_title.
  ///
  /// In pt, this message translates to:
  /// **'Redistribuível'**
  String get license_redistributable_title;

  /// No description provided for @license_redistributable_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Com código-fonte'**
  String get license_redistributable_subtitle;

  /// No description provided for @license_copyleft_short_title.
  ///
  /// In pt, this message translates to:
  /// **'Copyleft'**
  String get license_copyleft_short_title;

  /// No description provided for @license_copyleft_short_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Derivados livres'**
  String get license_copyleft_short_subtitle;

  /// No description provided for @license_copyright_line.
  ///
  /// In pt, this message translates to:
  /// **'Copyright © 2007 Free Software Foundation, Inc.'**
  String get license_copyright_line;

  /// No description provided for @license_fsf_link.
  ///
  /// In pt, this message translates to:
  /// **'Free Software Foundation'**
  String get license_fsf_link;

  /// No description provided for @license_full_link.
  ///
  /// In pt, this message translates to:
  /// **'Licença Completa'**
  String get license_full_link;

  /// No description provided for @license_section_preamble.
  ///
  /// In pt, this message translates to:
  /// **'Preâmbulo'**
  String get license_section_preamble;

  /// No description provided for @license_section_definitions.
  ///
  /// In pt, this message translates to:
  /// **'Definições'**
  String get license_section_definitions;

  /// No description provided for @license_section_source.
  ///
  /// In pt, this message translates to:
  /// **'Código-fonte'**
  String get license_section_source;

  /// No description provided for @license_section_basic_perms.
  ///
  /// In pt, this message translates to:
  /// **'Permissões Básicas'**
  String get license_section_basic_perms;

  /// No description provided for @license_section_legal_rights.
  ///
  /// In pt, this message translates to:
  /// **'Protegendo os Direitos Legais dos Usuários'**
  String get license_section_legal_rights;

  /// No description provided for @license_section_verbatim.
  ///
  /// In pt, this message translates to:
  /// **'Transmitindo Cópias Literais'**
  String get license_section_verbatim;

  /// No description provided for @license_section_modified.
  ///
  /// In pt, this message translates to:
  /// **'Transmitindo Versões Modificadas dos Fontes'**
  String get license_section_modified;

  /// No description provided for @license_section_non_source.
  ///
  /// In pt, this message translates to:
  /// **'Transmitindo Formas Não Fonte'**
  String get license_section_non_source;

  /// No description provided for @license_section_additional.
  ///
  /// In pt, this message translates to:
  /// **'Termos Adicionais'**
  String get license_section_additional;

  /// No description provided for @license_section_termination.
  ///
  /// In pt, this message translates to:
  /// **'Terminação'**
  String get license_section_termination;

  /// No description provided for @license_section_acceptance.
  ///
  /// In pt, this message translates to:
  /// **'Aceitação Não Exigida para Ter Cópias'**
  String get license_section_acceptance;

  /// No description provided for @license_section_downstream.
  ///
  /// In pt, this message translates to:
  /// **'Licenciamento Automático de Destinatários Downstream'**
  String get license_section_downstream;

  /// No description provided for @license_section_patents.
  ///
  /// In pt, this message translates to:
  /// **'Patentes'**
  String get license_section_patents;

  /// No description provided for @license_section_no_surrender.
  ///
  /// In pt, this message translates to:
  /// **'Não Entregar a Liberdade dos Outros'**
  String get license_section_no_surrender;

  /// No description provided for @license_section_agpl.
  ///
  /// In pt, this message translates to:
  /// **'Uso com a Licença Pública Geral Affero GNU'**
  String get license_section_agpl;

  /// No description provided for @license_section_revisions.
  ///
  /// In pt, this message translates to:
  /// **'Versões Revisadas desta Licença'**
  String get license_section_revisions;

  /// No description provided for @license_section_warranty.
  ///
  /// In pt, this message translates to:
  /// **'Aviso Legal de Garantia'**
  String get license_section_warranty;

  /// No description provided for @license_section_liability.
  ///
  /// In pt, this message translates to:
  /// **'Limitação de Responsabilidade'**
  String get license_section_liability;

  /// No description provided for @license_section_interpretation.
  ///
  /// In pt, this message translates to:
  /// **'Interpretação das Seções 15 e 16'**
  String get license_section_interpretation;

  /// No description provided for @license_section_preamble_body.
  ///
  /// In pt, this message translates to:
  /// **'A Licença Pública Geral GNU é uma licença livre, com copyleft, para softwares e outros tipos de trabalhos.\n\nAs licenças para a maioria dos softwares e outros trabalhos práticos são projetadas para tirar sua liberdade de compartilhar e alterar os trabalhos. Em contrapartida, a Licença Pública Geral GNU destina-se a garantir a sua liberdade de compartilhar e alterar todas as versões de um programa, para se certificar de que permaneça como software livre para todos os seus usuários.\n\nQuando falamos de software livre, estamos nos referindo à liberdade, não ao preço. Nossas Licenças Públicas Gerais são projetadas para garantir que você tenha a liberdade de distribuir cópias de software livre, que você receba o código-fonte ou possa obtê-lo, que você possa mudar o software ou usar partes dele em novos programas livres e que você saiba que pode fazer essas coisas.'**
  String get license_section_preamble_body;

  /// No description provided for @license_section_definitions_body.
  ///
  /// In pt, this message translates to:
  /// **'Esta Licença refere-se à versão 3 da Licença Pública Geral GNU.\n\nCopyright também significa leis do tipo direito autoral que se aplicam a outros tipos de trabalhos, tal como máscaras de semicondutores.\n\nO Programa refere-se a qualquer trabalho com direito autoral licenciado sob esta Licença. Cada licenciado é endereçado como você. Licenciados e destinatários podem ser indivíduos ou organizações.\n\nModificar um trabalho significa copiar ou adaptar tudo ou parte do trabalho de uma forma a ser necessário ter permissão de direitos autorais, além da criação de uma cópia exata.'**
  String get license_section_definitions_body;

  /// No description provided for @license_section_source_body.
  ///
  /// In pt, this message translates to:
  /// **'O código-fonte para um trabalho significa a forma preferida do trabalho para fazer modificações nele. Código objeto significa qualquer forma não fonte de um trabalho.\n\nUma Interface Padrão significa uma interface que seja um padrão oficial definido por um corpo de padrões reconhecido ou, no caso de interfaces especificadas para uma linguagem de programação específica, que seja amplamente utilizada entre desenvolvedores que trabalham naquela linguagem.'**
  String get license_section_source_body;

  /// No description provided for @license_section_basic_perms_body.
  ///
  /// In pt, this message translates to:
  /// **'Todos os direitos concedidos sob esta Licença são concedidos para o termo de direito autoral sobre o Programa e são irrevogáveis desde que as condições estabelecidas sejam atendidas. Esta Licença afirma explicitamente a sua permissão ilimitada para executar o Programa não modificado.\n\nVocê pode fazer, executar e propagar trabalhos cobertos que você não transmite, sem condições, desde que sua licença permaneça em vigor.'**
  String get license_section_basic_perms_body;

  /// No description provided for @license_section_legal_rights_body.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum trabalho coberto deve ser considerado parte de uma medida tecnológica efetiva sob qualquer lei aplicável que cumpra as obrigações previstas no artigo 11 do tratado de direitos autorais da OMPI.\n\nQuando você transmite um trabalho coberto, você renuncia a qualquer poder legal para proibir a evasão de medidas tecnológicas.'**
  String get license_section_legal_rights_body;

  /// No description provided for @license_section_verbatim_body.
  ///
  /// In pt, this message translates to:
  /// **'Você pode transmitir cópias literais do código-fonte do Programa na medida que você o recebe, em qualquer meio, desde que você publique de forma consistente e apropriada em cada cópia um aviso de direitos autorais apropriado.\n\nVocê pode cobrar qualquer preço ou nenhum preço por cada cópia que você transmite, e você pode oferecer proteção de suporte ou garantia por uma taxa.'**
  String get license_section_verbatim_body;

  /// No description provided for @license_section_modified_body.
  ///
  /// In pt, this message translates to:
  /// **'Você pode transmitir um trabalho baseado no Programa, ou as modificações para produzi-lo a partir do Programa, na forma de código-fonte sob os termos da seção 4, desde que você também atenda a todas essas condições:\n\na) O trabalho deve levar avisos proeminentes afirmando que você o modificou e dando uma data relevante.\nb) O trabalho deve levar avisos proeminentes afirmando que ele está lançado sob esta Licença.'**
  String get license_section_modified_body;

  /// No description provided for @license_section_non_source_body.
  ///
  /// In pt, this message translates to:
  /// **'Você pode transmitir um trabalho coberto na forma de código objeto nos termos das seções 4 e 5, desde que você também transmita o Fonte Correspondente legível por máquina sob os termos desta Licença.\n\nO Fonte Correspondente pode estar em um servidor diferente (operado por você ou um terceiro) que suporte instalações de cópia equivalentes.'**
  String get license_section_non_source_body;

  /// No description provided for @license_section_additional_body.
  ///
  /// In pt, this message translates to:
  /// **'Permissões adicionais são termos que complementam os termos desta Licença fazendo exceções de uma ou mais de suas condições. As permissões adicionais que são aplicáveis a todo o Programa devem ser tratadas como se estivessem incluídas nesta Licença.\n\nVocê pode colocar permissões adicionais em material, adicionado por você a um trabalho coberto, para o qual você tenha ou possa dar permissão de direitos autorais apropriados.'**
  String get license_section_additional_body;

  /// No description provided for @license_section_termination_body.
  ///
  /// In pt, this message translates to:
  /// **'Você não pode propagar ou modificar um trabalho coberto, exceto conforme expressamente previsto nesta Licença. Qualquer tentativa de propagar ou modificá-la é inválida e terminará automaticamente os seus direitos sob esta Licença.\n\nNo entanto, se você cessar toda violação desta Licença, a sua licença de um detentor de direitos autorais específicos é reintegrada provisoriamente.'**
  String get license_section_termination_body;

  /// No description provided for @license_section_acceptance_body.
  ///
  /// In pt, this message translates to:
  /// **'Você não é obrigado a aceitar esta Licença para receber ou executar uma cópia do Programa. A propagação auxiliar de um trabalho coberto que ocorre apenas como consequência da utilização da transmissão ponto a ponto para receber uma cópia também não exige aceitação.'**
  String get license_section_acceptance_body;

  /// No description provided for @license_section_downstream_body.
  ///
  /// In pt, this message translates to:
  /// **'Cada vez que você transmite um trabalho coberto, o destinatário recebe automaticamente uma licença dos licenciadores originais, para executar, modificar e propagar esse trabalho, sujeito a esta Licença.\n\nVocê não pode impor restrições adicionais sobre o exercício dos direitos concedidos ou afirmados sob esta Licença.'**
  String get license_section_downstream_body;

  /// No description provided for @license_section_patents_body.
  ///
  /// In pt, this message translates to:
  /// **'Um contribuidor é um detentor de direitos autorais que autoriza o uso sob esta Licença do Programa ou um trabalho no qual o Programa se baseia.\n\nCada contribuidor concede-lhe uma licença de patente não exclusiva, mundial, livre de royalties sob os principais pedidos de patente do contribuidor.'**
  String get license_section_patents_body;

  /// No description provided for @license_section_no_surrender_body.
  ///
  /// In pt, this message translates to:
  /// **'Se as condições que forem impostas a você (seja por ordem judicial, acordo ou de outra forma) contradizem as condições desta Licença, elas não lhe eximem das condições desta Licença.\n\nSe você não pode transmitir um trabalho coberto para satisfazer simultaneamente suas obrigações sob esta Licença e quaisquer outras obrigações pertinentes, então você não pode transmitir isso.'**
  String get license_section_no_surrender_body;

  /// No description provided for @license_section_agpl_body.
  ///
  /// In pt, this message translates to:
  /// **'Não obstante qualquer outra disposição desta Licença, você tem permissão para vincular ou combinar qualquer trabalho coberto com um trabalho licenciado sob a versão 3 da Licença Pública Geral Affero GNU em um único trabalho combinado.'**
  String get license_section_agpl_body;

  /// No description provided for @license_section_revisions_body.
  ///
  /// In pt, this message translates to:
  /// **'A Free Software Foundation pode publicar versões periódicas e/ou novas da Licença Pública Geral GNU de tempos em tempos. Essas novas versões serão semelhantes em espírito à versão atual, mas podem diferir em detalhes para resolver novos problemas ou preocupações.\n\nCada versão recebe um número de versão distinto.'**
  String get license_section_revisions_body;

  /// No description provided for @license_section_warranty_body.
  ///
  /// In pt, this message translates to:
  /// **'NÃO HÁ NENHUMA GARANTIA PARA O PROGRAMA, NA EXTENSÃO PERMITIDA PELA LEI APLICÁVEL. EXCETO QUANDO TUDO INDICADO POR ESCRITO, OS DETENTORES DE DIREITOS AUTORAIS E/OU OUTRAS PARTES FORNECEM O PROGRAMA COMO ESTÁ SEM GARANTIA DE QUALQUER TIPO.\n\nTODO O RISCO SOBRE A QUALIDADE E O DESEMPENHO DO PROGRAMA ESTÁ COM VOCÊ. SE O PROGRAMA APRESENTAR DEFEITO, VOCÊ ASSUME O CUSTO DE TODA A MANUTENÇÃO, REPARAÇÃO OU CORREÇÃO NECESSÁRIA.'**
  String get license_section_warranty_body;

  /// No description provided for @license_section_liability_body.
  ///
  /// In pt, this message translates to:
  /// **'EM NENHUM CASO, A MENOS QUE EXIGIDO PELA LEI APLICÁVEL OU ACORDADO POR ESCRITO, QUALQUER DETENTOR DE DIREITOS AUTORAIS, OU QUALQUER OUTRA PARTE QUE MODIFICA E/OU TRANSMITE O PROGRAMA COMO PERMITIDO ACIMA, SE RESPONSABILIZARÁ POR DANOS.\n\nISTO INCLUI QUALQUER DANO GERAL, ESPECIAL, INCIDENTAL OU CONSEQUENCIAL QUE SURGIR DO USO OU INCAPACIDADE DE USAR O PROGRAMA, MESMO SE TAL DETENTOR OU OUTRA PARTE TENHA SIDO AVISADO DA POSSIBILIDADE DE TAIS DANOS.'**
  String get license_section_liability_body;

  /// No description provided for @license_section_interpretation_body.
  ///
  /// In pt, this message translates to:
  /// **'Se a renúncia de garantia e a limitação de responsabilidade previstos acima não puderem ter efeito legal local de acordo com seus termos, os tribunais revisionais aplicarão a lei local que se aproxima mais de uma renúncia absoluta a toda a responsabilidade civil em conexão com o Programa, a menos que uma garantia ou suposição de responsabilidade acompanhe uma cópia do Programa em troca de uma taxa.'**
  String get license_section_interpretation_body;

  /// No description provided for @license_end_terms.
  ///
  /// In pt, this message translates to:
  /// **'FIM DOS TERMOS E CONDIÇÕES'**
  String get license_end_terms;

  /// No description provided for @terms_title.
  ///
  /// In pt, this message translates to:
  /// **'Termos de Uso'**
  String get terms_title;

  /// No description provided for @terms_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Mooze Wallet'**
  String get terms_subtitle;

  /// No description provided for @terms_intro.
  ///
  /// In pt, this message translates to:
  /// **'Ao utilizar o aplicativo Mooze, você concorda integralmente com estes termos. Leia atentamente antes de prosseguir.'**
  String get terms_intro;

  /// No description provided for @terms_warning_title.
  ///
  /// In pt, this message translates to:
  /// **'Aviso Importante'**
  String get terms_warning_title;

  /// No description provided for @terms_warning_message.
  ///
  /// In pt, this message translates to:
  /// **'Você é o único responsável por manter suas senhas de recuperação seguras. A perda dessas informações implica perda irreversível das unidades digitais.'**
  String get terms_warning_message;

  /// No description provided for @terms_self_custody_title.
  ///
  /// In pt, this message translates to:
  /// **'Autocustódia'**
  String get terms_self_custody_title;

  /// No description provided for @terms_self_custody_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Você controla seus fundos'**
  String get terms_self_custody_subtitle;

  /// No description provided for @terms_privacy_title.
  ///
  /// In pt, this message translates to:
  /// **'Privacidade'**
  String get terms_privacy_title;

  /// No description provided for @terms_privacy_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Dados protegidos'**
  String get terms_privacy_subtitle;

  /// No description provided for @terms_beta_title.
  ///
  /// In pt, this message translates to:
  /// **'Beta'**
  String get terms_beta_title;

  /// No description provided for @terms_beta_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Em desenvolvimento'**
  String get terms_beta_subtitle;

  /// No description provided for @terms_last_updated.
  ///
  /// In pt, this message translates to:
  /// **'Última atualização: 23/03/2026'**
  String get terms_last_updated;

  /// No description provided for @terms_privacy_policy_link.
  ///
  /// In pt, this message translates to:
  /// **'Ver Política de Privacidade'**
  String get terms_privacy_policy_link;

  /// No description provided for @terms_section_1.
  ///
  /// In pt, this message translates to:
  /// **'1. Aceitação dos Termos'**
  String get terms_section_1;

  /// No description provided for @terms_section_2.
  ///
  /// In pt, this message translates to:
  /// **'2. Natureza Jurídica e Enquadramento da Mooze'**
  String get terms_section_2;

  /// No description provided for @terms_section_3.
  ///
  /// In pt, this message translates to:
  /// **'3. Definições'**
  String get terms_section_3;

  /// No description provided for @terms_section_4.
  ///
  /// In pt, this message translates to:
  /// **'4. Descrição dos Serviços'**
  String get terms_section_4;

  /// No description provided for @terms_section_5.
  ///
  /// In pt, this message translates to:
  /// **'5. Modelo Não-Custodial e Autocustódia'**
  String get terms_section_5;

  /// No description provided for @terms_section_6.
  ///
  /// In pt, this message translates to:
  /// **'6. Responsabilidades do Usuário'**
  String get terms_section_6;

  /// No description provided for @terms_section_7.
  ///
  /// In pt, this message translates to:
  /// **'7. Tarifas e Taxas de Serviço'**
  String get terms_section_7;

  /// No description provided for @terms_section_8.
  ///
  /// In pt, this message translates to:
  /// **'8. Apreço Monetário e Referência de Preços'**
  String get terms_section_8;

  /// No description provided for @terms_section_9.
  ///
  /// In pt, this message translates to:
  /// **'9. Limitação de Responsabilidade'**
  String get terms_section_9;

  /// No description provided for @terms_section_10.
  ///
  /// In pt, this message translates to:
  /// **'10. Política Antifraude e Segurança'**
  String get terms_section_10;

  /// No description provided for @terms_section_11.
  ///
  /// In pt, this message translates to:
  /// **'11. Monitoramento, Prevenção a Fraudes e Suspensão de Serviços'**
  String get terms_section_11;

  /// No description provided for @terms_section_12.
  ///
  /// In pt, this message translates to:
  /// **'12. Obrigações Legais do Usuário'**
  String get terms_section_12;

  /// No description provided for @terms_section_13.
  ///
  /// In pt, this message translates to:
  /// **'13. Jurisdição e Lei Aplicável'**
  String get terms_section_13;

  /// No description provided for @terms_section_14.
  ///
  /// In pt, this message translates to:
  /// **'14. Resolução de Disputas'**
  String get terms_section_14;

  /// No description provided for @terms_section_15.
  ///
  /// In pt, this message translates to:
  /// **'15. Propriedade Intelectual'**
  String get terms_section_15;

  /// No description provided for @terms_section_16.
  ///
  /// In pt, this message translates to:
  /// **'16. Disposições Gerais'**
  String get terms_section_16;

  /// No description provided for @terms_section_17.
  ///
  /// In pt, this message translates to:
  /// **'17. Idade Mínima'**
  String get terms_section_17;

  /// No description provided for @terms_section_18.
  ///
  /// In pt, this message translates to:
  /// **'18. Alterações dos Termos'**
  String get terms_section_18;

  /// No description provided for @terms_section_19.
  ///
  /// In pt, this message translates to:
  /// **'19. Contato'**
  String get terms_section_19;

  /// No description provided for @privacy_section_header.
  ///
  /// In pt, this message translates to:
  /// **'Política de Privacidade — Mooze Wallet'**
  String get privacy_section_header;

  /// No description provided for @privacy_section_1.
  ///
  /// In pt, this message translates to:
  /// **'1. Compromisso com a Privacidade'**
  String get privacy_section_1;

  /// No description provided for @privacy_section_2.
  ///
  /// In pt, this message translates to:
  /// **'2. Definições'**
  String get privacy_section_2;

  /// No description provided for @privacy_section_3.
  ///
  /// In pt, this message translates to:
  /// **'3. Dados Coletados e Não Coletados'**
  String get privacy_section_3;

  /// No description provided for @privacy_section_4.
  ///
  /// In pt, this message translates to:
  /// **'4. Tratamento de Dados em Operações com Referencial Fiat'**
  String get privacy_section_4;

  /// No description provided for @privacy_section_5.
  ///
  /// In pt, this message translates to:
  /// **'5. Compartilhamento de Dados'**
  String get privacy_section_5;

  /// No description provided for @privacy_section_6.
  ///
  /// In pt, this message translates to:
  /// **'6. Comunicação com a Mooze'**
  String get privacy_section_6;

  /// No description provided for @privacy_section_7.
  ///
  /// In pt, this message translates to:
  /// **'7. Segurança'**
  String get privacy_section_7;

  /// No description provided for @privacy_section_8.
  ///
  /// In pt, this message translates to:
  /// **'8. Retenção de Dados'**
  String get privacy_section_8;

  /// No description provided for @privacy_section_9.
  ///
  /// In pt, this message translates to:
  /// **'9. Direitos do Usuário (LGPD)'**
  String get privacy_section_9;

  /// No description provided for @privacy_section_10.
  ///
  /// In pt, this message translates to:
  /// **'10. Jurisdição de Dados'**
  String get privacy_section_10;

  /// No description provided for @privacy_section_11.
  ///
  /// In pt, this message translates to:
  /// **'11. Alterações'**
  String get privacy_section_11;

  /// No description provided for @privacy_section_12.
  ///
  /// In pt, this message translates to:
  /// **'12. Contato'**
  String get privacy_section_12;

  /// No description provided for @terms_section_1_body.
  ///
  /// In pt, this message translates to:
  /// **'1.1. Ao acessar, instalar ou utilizar o aplicativo Mooze, o Usuário declara ter lido, compreendido e aceito integralmente os presentes Termos de Uso.\n\n1.2. A utilização do Aplicativo constitui aceitação tácita e irrevogável de todas as disposições contidas neste documento.\n\n1.3. Caso o Usuário não concorde com qualquer disposição destes Termos, deverá cessar imediatamente a utilização do Aplicativo e desinstalá-lo de seus dispositivos.\n\n1.4. Estes Termos constituem um contrato vinculante entre o Usuário e a Mooze Labs LLC, regido pelas leis da República das Ilhas Marshall.'**
  String get terms_section_1_body;

  /// No description provided for @terms_section_2_body.
  ///
  /// In pt, this message translates to:
  /// **'2.1. A Mooze Labs LLC é uma sociedade de responsabilidade limitada constituída sob a Associations Law da República das Ilhas Marshall.\n\n2.2. A Mooze atua exclusivamente como provedora de serviços de software para gerenciamento de carteiras digitais autocustodiais na rede Bitcoin e na Liquid Network.\n\n2.3. A Mooze NÃO é corretora, exchange, instituição financeira, prestadora de serviços de câmbio, transmissora de dinheiro, VASP, custodiante de ativos ou consultora de investimentos.\n\n2.4. A Mooze não exerce custódia, posse, controle discricionário ou domínio sobre quaisquer ativos digitais do Usuário. O processamento transitório pela infraestrutura da Mooze é análogo ao roteamento de pacotes de dados por um roteador de rede.\n\n2.5. A Mooze não realiza operações de câmbio ou intermediação financeira. Toda operação envolvendo reais brasileiros é processada por parceiras reguladas pelo Banco Central do Brasil.\n\n2.6. A Mooze opera exclusivamente como provedora de software não-custodial, sem acesso, controle ou custódia sobre ativos digitais dos Usuários.\n\n2.7. A Mooze é membro oficial da Liquid Federation (Blockstream), com PAK Entry ativo.'**
  String get terms_section_2_body;

  /// No description provided for @terms_section_3_body.
  ///
  /// In pt, this message translates to:
  /// **'3.1. Aplicativo ou Mooze Wallet: software de carteira digital autocustodial, disponível para iOS e Android.\n\n3.2. Usuário: toda pessoa natural que instala, acessa ou utiliza o Aplicativo.\n\n3.3. Autocustódia: modelo no qual o Usuário detém controle exclusivo sobre suas chaves privadas e frases-semente.\n\n3.4. Frase-Semente: sequência de 12 ou 24 palavras (padrão BIP39), único mecanismo de recuperação da carteira.\n\n3.5. Liquid Network: sidechain federada do Bitcoin, desenvolvida pela Blockstream.\n\n3.6. DEPIX: token digital na Liquid Network com valor pareado ao real brasileiro (R\$ 1,00 = 1 DEPIX).\n\n3.7. L-BTC: representação de Bitcoin na Liquid Network.\n\n3.8. Atomic Swap: troca direta entre ativos digitais sem intermediário custodiante.\n\n3.9. SideSwap: protocolo público para atomic swaps na Liquid Network.\n\n3.10. Confidential Transactions: tecnologia da Liquid Network que oculta valores e tipos de ativos em transações.\n\n3.11. APP ID: identificador único gerado pelo dispositivo, usado exclusivamente para prevenção a fraudes.\n\n3.12. Parceiras Reguladas: PLEBIT.COM.BR (CNPJ 43.375.652/0001-13), Fits Instituição de Pagamento (CNPJ 13.203.354/0001-85), Celcoin (CNPJ 13.935.893/0001-09), PLEBZ (CNPJ 45.808.899/0001-01).\n\n3.13. Eulen.app LLC: responsável pela emissão do token DEPIX.\n\n3.14. PIX: sistema de pagamentos instantâneos do Banco Central do Brasil.\n\n3.15. Serviços: funcionalidades de software disponibilizadas pela Mooze.'**
  String get terms_section_3_body;

  /// No description provided for @terms_section_4_body.
  ///
  /// In pt, this message translates to:
  /// **'4.1. SERVIÇO A — Orquestração de Software para Aquisição de Tokens Digitais\nA Mooze disponibiliza interface de software que orquestra automaticamente a comunicação entre o dispositivo do Usuário, as Parceiras Reguladas e a infraestrutura da Eulen.app LLC. O pagamento PIX é processado pelas Parceiras Reguladas; a Eulen.app LLC emite os tokens DEPIX; o software da Mooze roteia os tokens ao endereço de autocustódia do Usuário. A Mooze atua exclusivamente como orquestradora automatizada, sem adquirir titularidade sobre os ativos.\n\n4.2. SERVIÇO B — Interface para Protocolo Descentralizado de Conversão Entre Unidades Digitais\nA Mooze disponibiliza interface para o Usuário interagir com o protocolo SideSwap para atomic swaps na Liquid Network. A Mooze não participa como contraparte ou custodiante. A função da Mooze é análoga à de um navegador que provê acesso a websites. A Mooze também disponibiliza acesso via SDK Breez para a Lightning Network.\n\n4.3. MODO COMERCIANTE\nFuncionalidade que permite receber pagamentos via PIX em carteiras autocustodiais. O código QR PIX é gerado pelo próprio Usuário via Aplicativo. A Mooze não tem conhecimento da relação comercial subjacente. O Usuário NÃO deve entregar produto ou serviço antes da confirmação final do pagamento. Dúvidas: suporte@mooze.app.'**
  String get terms_section_4_body;

  /// No description provided for @terms_section_5_body.
  ///
  /// In pt, this message translates to:
  /// **'5.1. O Aplicativo opera sob modelo de autocustódia integral. As chaves privadas e frases-semente são geradas e armazenadas exclusivamente no dispositivo do Usuário, sendo inacessíveis à Mooze.\n\n5.2. A Mooze não tem, em nenhum momento, acesso, conhecimento, posse, controle ou cópia das chaves privadas, frases-semente ou senhas do Usuário.\n\n5.3. O Usuário é o único responsável pela guarda e segurança de suas chaves privadas e frases-semente. A perda desses elementos resulta na perda permanente e irreversível do acesso aos ativos digitais.\n\n5.4. A Mooze não possui capacidade técnica para recuperar, restaurar, acessar ou transferir ativos digitais do Usuário em caso de perda das chaves privadas ou frases-semente.\n\n5.5. Os endereços de carteira do Usuário são utilizados pela Mooze exclusivamente como parâmetro de roteamento automatizado durante a execução dos Serviços.'**
  String get terms_section_5_body;

  /// No description provided for @terms_section_6_body.
  ///
  /// In pt, this message translates to:
  /// **'6.1. GUARDA DE SENHAS E FRASES-SEMENTE\nO Usuário é integral e exclusivamente responsável pela criação, armazenamento e proteção de suas senhas, chaves privadas e frases-semente. A Mooze nunca solicitará ao Usuário suas chaves privadas, frases-semente ou senhas por qualquer meio de comunicação.\n\n6.2. CONSEQUÊNCIAS DA PERDA DE ACESSO\nA perda da frase-semente implica a perda permanente e irreversível do acesso a todos os ativos digitais. A Mooze não pode restaurar ou recuperar o acesso à carteira do Usuário em caso de perda.\n\n6.3. SEGURANÇA DO DISPOSITIVO\nO Usuário é responsável pela segurança do dispositivo, incluindo sistema operacional atualizado, autenticação biométrica e proteção contra malware. A Mooze não se responsabiliza por perdas decorrentes de comprometimento do dispositivo.'**
  String get terms_section_6_body;

  /// No description provided for @terms_section_7_body.
  ///
  /// In pt, this message translates to:
  /// **'7.1. A Mooze cobra Taxa de Serviço de Software pela utilização dos Serviços, calculada como percentual do valor da operação e deduzida dos ativos digitais entregues ao Usuário.\n\n7.2. O percentual vigente é exibido na tela de confirmação da operação, antes de sua efetivação.\n\n7.3. A Mooze reserva-se o direito de alterar os percentuais a qualquer momento. A continuidade de uso após alteração constitui aceitação.\n\n7.4. As Parceiras Reguladas, SideSwap, Breez Technologies e infratechs parceiras podem aplicar suas próprias tarifas, independentes da Taxa da Mooze.\n\n7.5. Custos de mineração (fees de rede) são de responsabilidade do Usuário e independentes da Taxa de Serviço. Os valores totais são exibidos na tela de confirmação antes da efetivação.'**
  String get terms_section_7_body;

  /// No description provided for @terms_section_8_body.
  ///
  /// In pt, this message translates to:
  /// **'8.1. Os valores de referência exibidos no Aplicativo para ativos digitais são obtidos de fontes públicas de mercado e servem exclusivamente como referência informativa.\n\n8.2. A Mooze não garante a exatidão ou atualização em tempo real dos preços exibidos. Variação de preço entre exibição e efetivação é inerente aos mercados de ativos digitais.\n\n8.3. A exibição de preços não constitui oferta, recomendação de investimento ou garantia de valor.\n\n8.4. O Usuário reconhece que ativos digitais estão sujeitos a alta volatilidade e que pode sofrer perdas significativas de valor.'**
  String get terms_section_8_body;

  /// No description provided for @terms_section_9_body.
  ///
  /// In pt, this message translates to:
  /// **'9.1. A Mooze fornece o Aplicativo e os Serviços no estado em que se encontram (as is), sem garantias de qualquer natureza.\n\n9.2. A Mooze não será responsável por: perdas de ativos por perda de chaves privadas; comprometimento do dispositivo; indisponibilidade de redes blockchain; falhas de Parceiras Reguladas, Eulen.app LLC ou SideSwap; atos de fraude por terceiros; erros na inserção de endereços de carteira; alterações regulatórias; variação de preços de ativos; decisões de investimento do Usuário; danos indiretos ou consequenciais.\n\n9.3. A responsabilidade total da Mooze está limitada ao valor das Taxas efetivamente pagas pelo Usuário nos últimos 12 meses.\n\n9.4. O Aplicativo encontra-se em modo BETA. O Usuário aceita todos os riscos associados.\n\n9.5. As frases-semente são compatíveis com BIP39 e com a Liquid Network. Em caso de indisponibilidade crítica, o Usuário pode recuperar ativos em qualquer carteira compatível (ex: Blockstream App).'**
  String get terms_section_9_body;

  /// No description provided for @terms_section_10_body.
  ///
  /// In pt, this message translates to:
  /// **'10.1. A Mooze implementa mecanismos de segurança incluindo:\n- Vinculação de APP ID a operações\n- Sistema de scoring por níveis de risco\n- Limites progressivos por APP ID\n- Detecção de padrões anômalos (smurfing, bursting, autopagamentos)\n\n10.2. As medidas antifraude da Mooze são de natureza exclusivamente tecnológica e não substituem as obrigações de AML e KYC das Parceiras Reguladas.\n\n10.3. As Parceiras Reguladas são as únicas responsáveis pelo cumprimento de obrigações de AML e KYC perante o Banco Central do Brasil.'**
  String get terms_section_10_body;

  /// No description provided for @terms_section_11_body.
  ///
  /// In pt, this message translates to:
  /// **'11.1. A Mooze reserva-se o direito de suspender, limitar ou encerrar o acesso de um APP ID aos Serviços sem aviso prévio em caso de: padrões indicativos de fraude; dispositivos comprometidos ou emuladores; tentativas de contornar mecanismos de segurança; padrões de lavagem de dinheiro ou financiamento ao terrorismo; solicitação de autoridade competente.\n\n11.2. A suspensão atinge apenas novas operações. Os ativos em autocustódia permanecem integralmente sob controle do Usuário, acessíveis pela frase-semente.\n\n11.3. A Mooze cooperará com autoridades competentes mediante determinação judicial, observadas as limitações técnicas do modelo autocustodial.'**
  String get terms_section_11_body;

  /// No description provided for @terms_section_12_body.
  ///
  /// In pt, this message translates to:
  /// **'12.1. O Usuário declara e garante que:\n- Utiliza os Serviços em conformidade com a legislação de sua jurisdição\n- Os recursos utilizados para pagamento via PIX são de origem lícita\n- Não utiliza os Serviços para lavagem de dinheiro, financiamento ao terrorismo ou evasão fiscal\n- É responsável exclusivo pela declaração e pagamento de tributos sobre ativos digitais\n- Tem conhecimento de que a Mooze não se enquadra como VASP nos termos da Lei n. 14.478/2022\n\n12.2. A Mooze não presta serviços de consultoria tributária, fiscal ou jurídica.\n\n12.3. A Mooze não realiza declarações fiscais em nome do Usuário.'**
  String get terms_section_12_body;

  /// No description provided for @terms_section_13_body.
  ///
  /// In pt, this message translates to:
  /// **'13.1. Estes Termos são regidos pelas leis da República das Ilhas Marshall.\n\n13.2. A Mooze Labs LLC é uma entidade constituída na República das Ilhas Marshall e opera a partir dessa jurisdição, sem presença física ou jurídica no Brasil.\n\n13.3. A relação entre a Mooze e as Parceiras Reguladas é regida por contratos internacionais independentes, sem criar responsabilidade solidária entre as partes.'**
  String get terms_section_13_body;

  /// No description provided for @terms_section_14_body.
  ///
  /// In pt, this message translates to:
  /// **'14.1. Qualquer disputa será resolvida, a exclusivo critério da Mooze, pelos tribunais da República das Ilhas Marshall ou por arbitragem internacional sob as Regras da UNCITRAL.\n\n14.2. O Usuário renuncia a qualquer foro que não os indicados, exceto quando vedado por lei imperativa de sua jurisdição.\n\n14.3. Antes de formalizar qualquer disputa, o Usuário deverá notificar a Mooze por escrito. As partes envidarão esforços de boa-fé para resolução amigável em 30 dias.'**
  String get terms_section_14_body;

  /// No description provided for @terms_section_15_body.
  ///
  /// In pt, this message translates to:
  /// **'15.1. Todo o software, código-fonte, design, marcas, logotipos e conteúdo do Aplicativo são de propriedade exclusiva da Mooze Labs LLC ou de seus licenciadores.\n\n15.2. A utilização do Aplicativo não confere ao Usuário qualquer direito de propriedade intelectual.\n\n15.3. É vedada a reprodução, modificação ou engenharia reversa do Aplicativo sem autorização expressa da Mooze.\n\n15.4. O código-fonte está disponível em https://github.com/mooze-labs/mooze-client sob os termos da licença ali indicada.'**
  String get terms_section_15_body;

  /// No description provided for @terms_section_16_body.
  ///
  /// In pt, this message translates to:
  /// **'16.1. INTEGRALIDADE\nEstes Termos e a Política de Privacidade constituem o acordo integral entre as partes, substituindo quaisquer acordos anteriores.\n\n16.2. SEVERABILIDADE\nSe qualquer disposição for declarada inválida, as demais permanecerão em pleno vigor.\n\n16.3. RENÚNCIA\nA omissão da Mooze em exigir o cumprimento de qualquer disposição não constitui renúncia ao direito de exigi-lo posteriormente.\n\n16.4. CESSÃO\nO Usuário não pode ceder seus direitos sem autorização prévia e por escrito da Mooze.\n\n16.5. FORÇA MAIOR\nA Mooze não será responsável por atrasos decorrentes de falhas em redes blockchain, indisponibilidade de Parceiras, ataques cibernéticos, decisões governamentais ou desastres naturais.\n\n16.6. INDENIZAÇÃO\nO Usuário concorda em indenizar a Mooze por reclamações decorrentes de uso indevido dos Serviços, violação de leis ou prestação de informações falsas.\n\n16.7. DISTRIBUIÇÃO\nA distribuição em plataformas digitais é realizada pela Mooze LLC (Delaware), como distribuidora autorizada, sem assumir responsabilidades de desenvolvimento ou operação.'**
  String get terms_section_16_body;

  /// No description provided for @terms_section_17_body.
  ///
  /// In pt, this message translates to:
  /// **'17.1. O Aplicativo e os Serviços são destinados exclusivamente a pessoas com idade igual ou superior a 18 anos.\n\n17.2. Ao utilizar o Aplicativo, o Usuário declara ter ao menos 18 anos e possuir capacidade civil plena.\n\n17.3. A Mooze reserva-se o direito de suspender o acesso de qualquer Usuário que se verifique ser menor de 18 anos.'**
  String get terms_section_17_body;

  /// No description provided for @terms_section_18_body.
  ///
  /// In pt, this message translates to:
  /// **'18.1. A Mooze reserva-se o direito de alterar estes Termos a qualquer momento, publicando a versão atualizada no Aplicativo e em https://mooze.app/termosdeuso/.\n\n18.2. Alterações relevantes serão comunicadas via Aplicativo, Telegram ou e-mail.\n\n18.3. A continuidade de uso após publicação de alterações constitui aceitação tácita dos Termos atualizados.\n\n18.4. O Usuário que não concordar com as alterações deverá cessar o uso. Os ativos em autocustódia permanecem acessíveis pela frase-semente.'**
  String get terms_section_18_body;

  /// No description provided for @terms_section_19_body.
  ///
  /// In pt, this message translates to:
  /// **'19.1. Para dúvidas, solicitações ou comunicações relacionadas a estes Termos:\n\n(a) E-mail: suporte@mooze.app\n(b) Telegram: https://t.me/+zkNS6KIDsEcyZDkx\n(c) FAQ automatizado via Telegram\n\n19.2. A Mooze envidará esforços para responder no prazo de 10 dias úteis.'**
  String get terms_section_19_body;

  /// No description provided for @privacy_section_header_body.
  ///
  /// In pt, this message translates to:
  /// **'Data da última atualização: 23/03/2026\n\nMooze Labs LLC, República das Ilhas Marshall'**
  String get privacy_section_header_body;

  /// No description provided for @privacy_section_1_body.
  ///
  /// In pt, this message translates to:
  /// **'1.1. A Mooze Labs LLC está comprometida com a proteção da privacidade e a minimização de dados pessoais no uso do Aplicativo.\n\n1.2. Esta Política descreve quais informações são coletadas, como são utilizadas, com quem são compartilhadas e quais direitos o Usuário possui.\n\n1.3. A Mooze adota o princípio de minimização de dados como pilar central de sua operação. O Aplicativo foi projetado para funcionar sem coleta de dados pessoais identificáveis.'**
  String get privacy_section_1_body;

  /// No description provided for @privacy_section_2_body.
  ///
  /// In pt, this message translates to:
  /// **'Todos os termos definidos nos Termos de Uso possuem os mesmos significados nesta Política. Aplicam-se adicionalmente:\n\n(a) Dados Pessoais: qualquer informação relacionada a pessoa natural identificada ou identificável (LGPD).\n(b) Tratamento: toda operação realizada com Dados Pessoais.\n(c) LGPD: Lei Geral de Proteção de Dados do Brasil (Lei n. 13.709/2018).'**
  String get privacy_section_2_body;

  /// No description provided for @privacy_section_3_body.
  ///
  /// In pt, this message translates to:
  /// **'A MOOZE NÃO ARMAZENA:\nCPF, RG, endereços MAC, número de telefone, endereço residencial, data de nascimento, biometria pessoal, chaves privadas ou frases-semente.\n\nA MOOZE COLETA EXCLUSIVAMENTE:\n(a) APP ID: hash criptográfico do dispositivo, utilizado apenas para prevenção a fraudes.\n(b) Endereços de carteira na Liquid Network: utilizados como parâmetro de roteamento automatizado.\n(c) Blinding keys: retidas para verificação e reconciliação de transações.\n(d) Dados de transação: valores, tipos de ativos, timestamps e status de execução.\n(e) Dados técnicos do dispositivo: versão do SO, modelo e versão do Aplicativo — não permitem identificação pessoal.'**
  String get privacy_section_3_body;

  /// No description provided for @privacy_section_4_body.
  ///
  /// In pt, this message translates to:
  /// **'4.1. Quando o Usuário realiza operações via PIX (Serviço A), os dados necessários para o processamento — incluindo KYC e AML — são coletados e processados exclusivamente pelas Parceiras Reguladas.\n\n4.2. Parceiras Reguladas: PLEBIT.COM.BR (CNPJ 43.375.652/0001-13), Fits Instituição de Pagamento (CNPJ 13.203.354/0001-85), Celcoin (CNPJ 13.935.893/0001-09), PLEBZ (CNPJ 45.808.899/0001-01).\n\n4.3. A Mooze não recebe, armazena ou tem acesso aos dados pessoais coletados pelas Parceiras Reguladas.'**
  String get privacy_section_4_body;

  /// No description provided for @privacy_section_5_body.
  ///
  /// In pt, this message translates to:
  /// **'5.1. A Mooze compartilha dados exclusivamente:\n(a) Com Parceiras Reguladas e Eulen.app LLC: endereços de carteira, valores e APP ID quando necessário para antifraude.\n(b) Mediante determinação judicial válida.\n(c) Para cumprimento de obrigação legal na jurisdição das Ilhas Marshall.\n\n5.2. A Mooze NÃO vende, aluga ou compartilha dados com terceiros para fins de marketing ou publicidade.\n\n5.3. A Mooze NÃO utiliza rastreadores de terceiros, pixels de rastreamento ou SDKs de analytics que coletam dados pessoais.'**
  String get privacy_section_5_body;

  /// No description provided for @privacy_section_6_body.
  ///
  /// In pt, this message translates to:
  /// **'6.1. Quando o Usuário contata a Mooze via e-mail (suporte@mooze.app) ou Telegram, os dados compartilhados voluntariamente serão utilizados exclusivamente para atendimento à solicitação.\n\n6.2. A Mooze não associa dados de comunicação a APP IDs ou endereços de carteira, exceto quando o próprio Usuário fornece tais informações voluntariamente.'**
  String get privacy_section_6_body;

  /// No description provided for @privacy_section_7_body.
  ///
  /// In pt, this message translates to:
  /// **'7.1. A Mooze adota medidas técnicas e organizacionais razoáveis para proteger os dados contra acesso não autorizado, destruição ou divulgação indevida.\n\n7.2. Os dados coletados são armazenados em infraestrutura protegida com controles de acesso e criptografia.\n\n7.3. Nenhum método de transmissão ou armazenamento eletrônico é integralmente seguro.'**
  String get privacy_section_7_body;

  /// No description provided for @privacy_section_8_body.
  ///
  /// In pt, this message translates to:
  /// **'Os dados coletados pela Mooze são retidos pelos seguintes períodos:\n\n(a) APP ID: 5 anos após a última operação.\n(b) Endereços de carteira e blinding keys: 5 anos para verificação e cumprimento de obrigações legais.\n(c) Dados de transação: 5 anos após a data da transação.\n(d) Dados técnicos de dispositivo: eliminados após 5 anos de inatividade.\n\nOs prazos podem ser estendidos para cumprimento de obrigação legal ou defesa em procedimento judicial.'**
  String get privacy_section_8_body;

  /// No description provided for @privacy_section_9_body.
  ///
  /// In pt, this message translates to:
  /// **'Em observância à LGPD (Lei n. 13.709/2018), a Mooze reconhece os seguintes direitos ao Usuário:\n\n(a) Confirmação da existência de tratamento de dados\n(b) Acesso aos dados tratados\n(c) Correção de dados incompletos ou inexatos\n(d) Eliminação de dados tratados com consentimento\n(e) Informação sobre compartilhamento de dados\n(f) Revogação de consentimento\n(g) Solicitação de eliminação do APP ID associado ao dispositivo\n\nSolicitações via canais indicados na Seção 12 desta Política. Prazo de resposta: 15 dias úteis.'**
  String get privacy_section_9_body;

  /// No description provided for @privacy_section_10_body.
  ///
  /// In pt, this message translates to:
  /// **'10.1. Os dados coletados pela Mooze são armazenados e processados em infraestrutura fora do território brasileiro.\n\n10.2. A jurisdição de dados aplicável é a República das Ilhas Marshall.\n\n10.3. Os dados operacionais transmitidos às Parceiras Reguladas durante o Serviço A são processados no Brasil, sob responsabilidade exclusiva das Parceiras Reguladas.'**
  String get privacy_section_10_body;

  /// No description provided for @privacy_section_11_body.
  ///
  /// In pt, this message translates to:
  /// **'11.1. A Mooze reserva-se o direito de alterar esta Política a qualquer momento, publicando a versão atualizada no Aplicativo e em https://mooze.app/termosdeuso/.\n\n11.2. A continuidade de uso após a publicação constitui aceitação tácita da Política atualizada.'**
  String get privacy_section_11_body;

  /// No description provided for @privacy_section_12_body.
  ///
  /// In pt, this message translates to:
  /// **'12.1. Para exercício de direitos, dúvidas ou solicitações:\n\n(a) E-mail: suporte@mooze.app\n(b) Telegram: https://t.me/+zkNS6KIDsEcyZDkx\n(c) FAQ automatizado via Telegram\n\n12.2. A Mooze envidará esforços para responder no prazo de 15 dias úteis.'**
  String get privacy_section_12_body;

  /// No description provided for @developer_title.
  ///
  /// In pt, this message translates to:
  /// **'Ferramentas de desenvolvedor'**
  String get developer_title;

  /// No description provided for @developer_copy_debug_tooltip.
  ///
  /// In pt, this message translates to:
  /// **'Copiar informações de debug'**
  String get developer_copy_debug_tooltip;

  /// No description provided for @developer_debug_copied.
  ///
  /// In pt, this message translates to:
  /// **'Informações de debug copiadas!'**
  String get developer_debug_copied;

  /// No description provided for @developer_sync_light_success.
  ///
  /// In pt, this message translates to:
  /// **'Sincronização rápida concluída!'**
  String get developer_sync_light_success;

  /// No description provided for @developer_sync_full_success.
  ///
  /// In pt, this message translates to:
  /// **'Sincronização completa concluída!'**
  String get developer_sync_full_success;

  /// No description provided for @developer_rescan_success.
  ///
  /// In pt, this message translates to:
  /// **'Swaps onchain reescaneados com sucesso!'**
  String get developer_rescan_success;

  /// No description provided for @developer_refundables_title.
  ///
  /// In pt, this message translates to:
  /// **'Reembolsos pendentes'**
  String get developer_refundables_title;

  /// No description provided for @developer_refundables_message.
  ///
  /// In pt, this message translates to:
  /// **'Encontrada(s) {count} transação(ões) pendente(s) que podem ser reembolsadas.\n\nDeseja visualizá-las agora?'**
  String developer_refundables_message(int count);

  /// No description provided for @developer_later.
  ///
  /// In pt, this message translates to:
  /// **'Mais tarde'**
  String get developer_later;

  /// No description provided for @developer_view_now.
  ///
  /// In pt, this message translates to:
  /// **'Ver agora'**
  String get developer_view_now;

  /// No description provided for @developer_email_ready.
  ///
  /// In pt, this message translates to:
  /// **'Email pronto para envio!'**
  String get developer_email_ready;

  /// No description provided for @developer_share_logs_success.
  ///
  /// In pt, this message translates to:
  /// **'Logs compartilhados com sucesso!'**
  String get developer_share_logs_success;

  /// No description provided for @developer_sync_light_error.
  ///
  /// In pt, this message translates to:
  /// **'Falha na sincronização rápida: {error}'**
  String developer_sync_light_error(String error);

  /// No description provided for @developer_sync_full_error.
  ///
  /// In pt, this message translates to:
  /// **'Falha na sincronização completa: {error}'**
  String developer_sync_full_error(String error);

  /// No description provided for @developer_rescan_error.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao reescanear swaps: {error}'**
  String developer_rescan_error(String error);

  /// No description provided for @developer_export_error.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao exportar logs: {error}'**
  String developer_export_error(String error);

  /// No description provided for @developer_share_logs_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao compartilhar logs: {error}'**
  String developer_share_logs_error(String error);

  /// No description provided for @developer_log_retention_days.
  ///
  /// In pt, this message translates to:
  /// **'{days} dias'**
  String developer_log_retention_days(int days);

  /// No description provided for @developer_clear_memory_success.
  ///
  /// In pt, this message translates to:
  /// **'Logs da memória limpos com sucesso!'**
  String get developer_clear_memory_success;

  /// No description provided for @developer_clear_db_success.
  ///
  /// In pt, this message translates to:
  /// **'Logs do banco limpos com sucesso!'**
  String get developer_clear_db_success;

  /// No description provided for @developer_clear_all_success.
  ///
  /// In pt, this message translates to:
  /// **'Todos os logs limpos com sucesso!'**
  String get developer_clear_all_success;

  /// No description provided for @developer_clear_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao limpar logs: {error}'**
  String developer_clear_error(String error);

  /// No description provided for @developer_system_info.
  ///
  /// In pt, this message translates to:
  /// **'Informações do sistema'**
  String get developer_system_info;

  /// No description provided for @developer_app_version.
  ///
  /// In pt, this message translates to:
  /// **'Versão do app'**
  String get developer_app_version;

  /// No description provided for @developer_sdk_version.
  ///
  /// In pt, this message translates to:
  /// **'Versão do SDK'**
  String get developer_sdk_version;

  /// No description provided for @developer_balance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo'**
  String get developer_balance;

  /// No description provided for @developer_pending_balance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo pendente'**
  String get developer_pending_balance;

  /// No description provided for @developer_logs_memory.
  ///
  /// In pt, this message translates to:
  /// **'Logs (Memória)'**
  String get developer_logs_memory;

  /// No description provided for @developer_logs_db.
  ///
  /// In pt, this message translates to:
  /// **'Logs (Banco)'**
  String get developer_logs_db;

  /// No description provided for @developer_log_retention_label.
  ///
  /// In pt, this message translates to:
  /// **'Retenção de logs'**
  String get developer_log_retention_label;

  /// No description provided for @developer_tools_title.
  ///
  /// In pt, this message translates to:
  /// **'Ferramentas'**
  String get developer_tools_title;

  /// No description provided for @developer_tools_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Sincronização, logs e diagnósticos'**
  String get developer_tools_subtitle;

  /// No description provided for @developer_action_light_sync.
  ///
  /// In pt, this message translates to:
  /// **'Light Sync'**
  String get developer_action_light_sync;

  /// No description provided for @developer_action_light_sync_tooltip.
  ///
  /// In pt, this message translates to:
  /// **'Sincronização rápida (transações, saldos, preços)'**
  String get developer_action_light_sync_tooltip;

  /// No description provided for @developer_action_full_sync.
  ///
  /// In pt, this message translates to:
  /// **'Full Sync'**
  String get developer_action_full_sync;

  /// No description provided for @developer_action_full_sync_tooltip.
  ///
  /// In pt, this message translates to:
  /// **'Sincronização completa da blockchain'**
  String get developer_action_full_sync_tooltip;

  /// No description provided for @developer_action_rescan.
  ///
  /// In pt, this message translates to:
  /// **'Rescan'**
  String get developer_action_rescan;

  /// No description provided for @developer_action_rescan_tooltip.
  ///
  /// In pt, this message translates to:
  /// **'Reescanear swaps onchain'**
  String get developer_action_rescan_tooltip;

  /// No description provided for @developer_action_refund.
  ///
  /// In pt, this message translates to:
  /// **'Reembolso'**
  String get developer_action_refund;

  /// No description provided for @developer_action_refund_tooltip.
  ///
  /// In pt, this message translates to:
  /// **'Ir para tela de reembolso'**
  String get developer_action_refund_tooltip;

  /// No description provided for @developer_action_view_logs.
  ///
  /// In pt, this message translates to:
  /// **'Ver Logs'**
  String get developer_action_view_logs;

  /// No description provided for @developer_action_view_logs_tooltip.
  ///
  /// In pt, this message translates to:
  /// **'Ver logs do aplicativo'**
  String get developer_action_view_logs_tooltip;

  /// No description provided for @developer_action_export.
  ///
  /// In pt, this message translates to:
  /// **'Exportar'**
  String get developer_action_export;

  /// No description provided for @developer_action_export_tooltip.
  ///
  /// In pt, this message translates to:
  /// **'Exportar logs como ZIP'**
  String get developer_action_export_tooltip;

  /// No description provided for @developer_action_clear_logs.
  ///
  /// In pt, this message translates to:
  /// **'Limpar Logs'**
  String get developer_action_clear_logs;

  /// No description provided for @developer_action_clear_logs_tooltip.
  ///
  /// In pt, this message translates to:
  /// **'Limpar todos os logs'**
  String get developer_action_clear_logs_tooltip;

  /// No description provided for @export_logs_title.
  ///
  /// In pt, this message translates to:
  /// **'Exportar Logs'**
  String get export_logs_title;

  /// No description provided for @export_logs_description.
  ///
  /// In pt, this message translates to:
  /// **'Os logs do aplicativo ajudam nossa equipe a resolver problemas. Como você gostaria de compartilhar?'**
  String get export_logs_description;

  /// No description provided for @export_logs_by_email.
  ///
  /// In pt, this message translates to:
  /// **'Enviar por E-mail'**
  String get export_logs_by_email;

  /// No description provided for @export_logs_share.
  ///
  /// In pt, this message translates to:
  /// **'Salvar/Compartilhar'**
  String get export_logs_share;

  /// No description provided for @clear_logs_title.
  ///
  /// In pt, this message translates to:
  /// **'Limpar Logs'**
  String get clear_logs_title;

  /// No description provided for @clear_logs_description.
  ///
  /// In pt, this message translates to:
  /// **'Escolha o que deseja limpar:'**
  String get clear_logs_description;

  /// No description provided for @clear_logs_option_memory.
  ///
  /// In pt, this message translates to:
  /// **'Memória'**
  String get clear_logs_option_memory;

  /// No description provided for @clear_logs_option_memory_desc.
  ///
  /// In pt, this message translates to:
  /// **'Limpar apenas logs em memória ({count} logs)'**
  String clear_logs_option_memory_desc(int count);

  /// No description provided for @clear_logs_option_db.
  ///
  /// In pt, this message translates to:
  /// **'Banco de dados'**
  String get clear_logs_option_db;

  /// No description provided for @clear_logs_option_db_desc.
  ///
  /// In pt, this message translates to:
  /// **'Limpar apenas logs do banco ({count} logs)'**
  String clear_logs_option_db_desc(int count);

  /// No description provided for @clear_logs_option_all.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get clear_logs_option_all;

  /// No description provided for @clear_logs_option_all_desc.
  ///
  /// In pt, this message translates to:
  /// **'Limpar memória, arquivos e banco'**
  String get clear_logs_option_all_desc;

  /// No description provided for @clear_logs_cancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get clear_logs_cancel;

  /// No description provided for @logs_viewer_title.
  ///
  /// In pt, this message translates to:
  /// **'Logs do aplicativo'**
  String get logs_viewer_title;

  /// No description provided for @logs_viewer_loading.
  ///
  /// In pt, this message translates to:
  /// **'Carregando logs...'**
  String get logs_viewer_loading;

  /// No description provided for @logs_viewer_empty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum log encontrado'**
  String get logs_viewer_empty;

  /// No description provided for @logs_source_memory.
  ///
  /// In pt, this message translates to:
  /// **'Memória'**
  String get logs_source_memory;

  /// No description provided for @logs_source_database.
  ///
  /// In pt, this message translates to:
  /// **'Banco de dados'**
  String get logs_source_database;

  /// No description provided for @logs_source_all.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get logs_source_all;

  /// No description provided for @logs_filter_search_hint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar logs...'**
  String get logs_filter_search_hint;

  /// No description provided for @logs_filter_all.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get logs_filter_all;

  /// No description provided for @logs_detail_level.
  ///
  /// In pt, this message translates to:
  /// **'Nível'**
  String get logs_detail_level;

  /// No description provided for @logs_detail_timestamp.
  ///
  /// In pt, this message translates to:
  /// **'Data/hora'**
  String get logs_detail_timestamp;

  /// No description provided for @logs_detail_message.
  ///
  /// In pt, this message translates to:
  /// **'Mensagem:'**
  String get logs_detail_message;

  /// No description provided for @logs_detail_error_label.
  ///
  /// In pt, this message translates to:
  /// **'Erro:'**
  String get logs_detail_error_label;

  /// No description provided for @logs_detail_stack_trace.
  ///
  /// In pt, this message translates to:
  /// **'Stack Trace:'**
  String get logs_detail_stack_trace;

  /// No description provided for @logs_detail_copy.
  ///
  /// In pt, this message translates to:
  /// **'Copiar log'**
  String get logs_detail_copy;

  /// No description provided for @logs_detail_copied.
  ///
  /// In pt, this message translates to:
  /// **'Log copiado!'**
  String get logs_detail_copied;

  /// No description provided for @receive_title.
  ///
  /// In pt, this message translates to:
  /// **'Receber Ativos'**
  String get receive_title;

  /// No description provided for @receive_info_title.
  ///
  /// In pt, this message translates to:
  /// **'Como receber ativos'**
  String get receive_info_title;

  /// No description provided for @receive_info_step1_title.
  ///
  /// In pt, this message translates to:
  /// **'Selecione o ativo'**
  String get receive_info_step1_title;

  /// No description provided for @receive_info_step1_desc.
  ///
  /// In pt, this message translates to:
  /// **'Escolha qual criptomoeda você deseja receber'**
  String get receive_info_step1_desc;

  /// No description provided for @receive_info_step2_title.
  ///
  /// In pt, this message translates to:
  /// **'Escolha a rede'**
  String get receive_info_step2_title;

  /// No description provided for @receive_info_step2_desc.
  ///
  /// In pt, this message translates to:
  /// **'Bitcoin (on-chain), Lightning ou Liquid'**
  String get receive_info_step2_desc;

  /// No description provided for @receive_info_step3_title.
  ///
  /// In pt, this message translates to:
  /// **'Gere o QR code'**
  String get receive_info_step3_title;

  /// No description provided for @receive_info_step3_desc.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhe com quem vai enviar o pagamento'**
  String get receive_info_step3_desc;

  /// No description provided for @receive_info_close_hint.
  ///
  /// In pt, this message translates to:
  /// **'Toque fora desta área para fechar'**
  String get receive_info_close_hint;

  /// No description provided for @receive_qr_title.
  ///
  /// In pt, this message translates to:
  /// **'Receber Pagamento'**
  String get receive_qr_title;

  /// No description provided for @receive_qr_amount_label.
  ///
  /// In pt, this message translates to:
  /// **'Valor:'**
  String get receive_qr_amount_label;

  /// No description provided for @receive_qr_description_label.
  ///
  /// In pt, this message translates to:
  /// **'Descrição:'**
  String get receive_qr_description_label;

  /// No description provided for @receive_qr_lightning_invoice.
  ///
  /// In pt, this message translates to:
  /// **'Lightning Invoice'**
  String get receive_qr_lightning_invoice;

  /// No description provided for @receive_qr_address_title.
  ///
  /// In pt, this message translates to:
  /// **'Endereço de Recebimento'**
  String get receive_qr_address_title;

  /// No description provided for @receive_qr_copy_address.
  ///
  /// In pt, this message translates to:
  /// **'Copiar Endereço'**
  String get receive_qr_copy_address;

  /// No description provided for @receive_qr_copied.
  ///
  /// In pt, this message translates to:
  /// **'Copiado!'**
  String get receive_qr_copied;

  /// No description provided for @receive_qr_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao gerar QR: {error}'**
  String receive_qr_error(String error);

  /// No description provided for @receive_network_bitcoin_onchain.
  ///
  /// In pt, this message translates to:
  /// **'Bitcoin On-chain'**
  String get receive_network_bitcoin_onchain;

  /// No description provided for @receive_network_lightning_network.
  ///
  /// In pt, this message translates to:
  /// **'Lightning Network'**
  String get receive_network_lightning_network;

  /// No description provided for @receive_network_liquid_network.
  ///
  /// In pt, this message translates to:
  /// **'Liquid Network'**
  String get receive_network_liquid_network;

  /// No description provided for @receive_network_unknown.
  ///
  /// In pt, this message translates to:
  /// **'Desconhecida'**
  String get receive_network_unknown;

  /// No description provided for @receive_select_asset.
  ///
  /// In pt, this message translates to:
  /// **'Selecione um ativo'**
  String get receive_select_asset;

  /// No description provided for @receive_select_network.
  ///
  /// In pt, this message translates to:
  /// **'Selecione a rede'**
  String get receive_select_network;

  /// No description provided for @receive_asset_hint_btc.
  ///
  /// In pt, this message translates to:
  /// **'Bitcoin on-chain é a única rede disponível para BTC'**
  String get receive_asset_hint_btc;

  /// No description provided for @receive_asset_hint_lbtc.
  ///
  /// In pt, this message translates to:
  /// **'Bitcoin L2 suporta Lightning e Liquid'**
  String get receive_asset_hint_lbtc;

  /// No description provided for @receive_asset_hint_liquid_only.
  ///
  /// In pt, this message translates to:
  /// **'{name} suporta apenas rede Liquid'**
  String receive_asset_hint_liquid_only(String name);

  /// No description provided for @receive_lightning_amount_required_hint.
  ///
  /// In pt, this message translates to:
  /// **'Para Lightning, o valor é obrigatório'**
  String get receive_lightning_amount_required_hint;

  /// No description provided for @receive_select_asset_first.
  ///
  /// In pt, this message translates to:
  /// **'Selecione um ativo primeiro'**
  String get receive_select_asset_first;

  /// No description provided for @receive_network_label_bitcoin.
  ///
  /// In pt, this message translates to:
  /// **'Bitcoin'**
  String get receive_network_label_bitcoin;

  /// No description provided for @receive_network_label_lightning.
  ///
  /// In pt, this message translates to:
  /// **'Lightning'**
  String get receive_network_label_lightning;

  /// No description provided for @receive_network_label_liquid.
  ///
  /// In pt, this message translates to:
  /// **'Liquid'**
  String get receive_network_label_liquid;

  /// No description provided for @receive_network_subtitle_onchain.
  ///
  /// In pt, this message translates to:
  /// **'On-chain'**
  String get receive_network_subtitle_onchain;

  /// No description provided for @receive_network_subtitle_instant.
  ///
  /// In pt, this message translates to:
  /// **'Instantâneo'**
  String get receive_network_subtitle_instant;

  /// No description provided for @receive_network_subtitle_private.
  ///
  /// In pt, this message translates to:
  /// **'Privado'**
  String get receive_network_subtitle_private;

  /// No description provided for @receive_amount_label.
  ///
  /// In pt, this message translates to:
  /// **'Valor'**
  String get receive_amount_label;

  /// No description provided for @receive_amount_hint_required.
  ///
  /// In pt, this message translates to:
  /// **'Digite o valor (obrigatório)'**
  String get receive_amount_hint_required;

  /// No description provided for @receive_amount_hint_optional.
  ///
  /// In pt, this message translates to:
  /// **'Digite o valor (opcional)'**
  String get receive_amount_hint_optional;

  /// No description provided for @receive_amount_helper_disabled.
  ///
  /// In pt, this message translates to:
  /// **'Selecione um ativo e rede primeiro'**
  String get receive_amount_helper_disabled;

  /// No description provided for @receive_amount_helper_lightning.
  ///
  /// In pt, this message translates to:
  /// **'Valor obrigatório para Lightning'**
  String get receive_amount_helper_lightning;

  /// No description provided for @receive_amount_helper_optional.
  ///
  /// In pt, this message translates to:
  /// **'Valor opcional para Bitcoin/Liquid'**
  String get receive_amount_helper_optional;

  /// No description provided for @receive_amount_sats_label.
  ///
  /// In pt, this message translates to:
  /// **'Valor em Satoshis:'**
  String get receive_amount_sats_label;

  /// No description provided for @receive_lightning_limits_unavailable.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar limites Lightning'**
  String get receive_lightning_limits_unavailable;

  /// No description provided for @receive_lightning_min_value.
  ///
  /// In pt, this message translates to:
  /// **'Valor mínimo: {amount} sats'**
  String receive_lightning_min_value(String amount);

  /// No description provided for @receive_lightning_max_value.
  ///
  /// In pt, this message translates to:
  /// **'Valor máximo: {amount} sats'**
  String receive_lightning_max_value(String amount);

  /// No description provided for @receive_lightning_valid.
  ///
  /// In pt, this message translates to:
  /// **'Valor válido para Lightning'**
  String get receive_lightning_valid;

  /// No description provided for @receive_lightning_limits_loading.
  ///
  /// In pt, this message translates to:
  /// **'Carregando limites Lightning...'**
  String get receive_lightning_limits_loading;

  /// No description provided for @receive_lightning_limits_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar limites Lightning'**
  String get receive_lightning_limits_error;

  /// No description provided for @receive_bitcoin_valid.
  ///
  /// In pt, this message translates to:
  /// **'Valor válido para Bitcoin'**
  String get receive_bitcoin_valid;

  /// No description provided for @receive_liquid_valid.
  ///
  /// In pt, this message translates to:
  /// **'Valor válido para Liquid'**
  String get receive_liquid_valid;

  /// No description provided for @receive_description_label.
  ///
  /// In pt, this message translates to:
  /// **'Descrição (opcional)'**
  String get receive_description_label;

  /// No description provided for @receive_description_hint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Pagamento do almoço'**
  String get receive_description_hint;

  /// No description provided for @receive_generate_qr.
  ///
  /// In pt, this message translates to:
  /// **'Gerar fatura'**
  String get receive_generate_qr;

  /// No description provided for @receive_select_asset_network.
  ///
  /// In pt, this message translates to:
  /// **'Selecione um ativo e rede'**
  String get receive_select_asset_network;

  /// No description provided for @receive_conversion_loading.
  ///
  /// In pt, this message translates to:
  /// **'Carregando conversões...'**
  String get receive_conversion_loading;

  /// No description provided for @receive_conversion_equivalent.
  ///
  /// In pt, this message translates to:
  /// **'Conversões equivalentes:'**
  String get receive_conversion_equivalent;

  /// No description provided for @receive_satoshis_label.
  ///
  /// In pt, this message translates to:
  /// **'Satoshis:'**
  String get receive_satoshis_label;

  /// No description provided for @wallet_title.
  ///
  /// In pt, this message translates to:
  /// **'Minha Carteira'**
  String get wallet_title;

  /// No description provided for @wallet_assets_tab.
  ///
  /// In pt, this message translates to:
  /// **'Ativos'**
  String get wallet_assets_tab;

  /// No description provided for @wallet_balance_available.
  ///
  /// In pt, this message translates to:
  /// **'Saldo disponível:'**
  String get wallet_balance_available;

  /// No description provided for @wallet_send.
  ///
  /// In pt, this message translates to:
  /// **'Enviar'**
  String get wallet_send;

  /// No description provided for @wallet_receive.
  ///
  /// In pt, this message translates to:
  /// **'Receber'**
  String get wallet_receive;

  /// No description provided for @wallet_send_title.
  ///
  /// In pt, this message translates to:
  /// **'Revisar Transação'**
  String get wallet_send_title;

  /// No description provided for @wallet_send_all_title.
  ///
  /// In pt, this message translates to:
  /// **'Revisar Envio Total'**
  String get wallet_send_all_title;

  /// No description provided for @wallet_send_calculating_total.
  ///
  /// In pt, this message translates to:
  /// **'Calculando envio total de fundos...'**
  String get wallet_send_calculating_total;

  /// No description provided for @wallet_send_preparing.
  ///
  /// In pt, this message translates to:
  /// **'Preparando transação...'**
  String get wallet_send_preparing;

  /// No description provided for @wallet_send_prepare_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao preparar transação'**
  String get wallet_send_prepare_error;

  /// No description provided for @wallet_send_dust_warning.
  ///
  /// In pt, this message translates to:
  /// **'Há problemas com esta transação. Verifique os dados.'**
  String get wallet_send_dust_warning;

  /// No description provided for @wallet_send_all_info.
  ///
  /// In pt, this message translates to:
  /// **'Enviando todos os fundos disponíveis. As taxas serão deduzidas automaticamente do valor total.'**
  String get wallet_send_all_info;

  /// No description provided for @wallet_send_destination_network.
  ///
  /// In pt, this message translates to:
  /// **'Rede de Destino'**
  String get wallet_send_destination_network;

  /// No description provided for @wallet_send_destination_address.
  ///
  /// In pt, this message translates to:
  /// **'Endereço de Destino'**
  String get wallet_send_destination_address;

  /// No description provided for @wallet_send_fee_details.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes das Taxas'**
  String get wallet_send_fee_details;

  /// No description provided for @wallet_send_network_fee.
  ///
  /// In pt, this message translates to:
  /// **'Taxa da Rede'**
  String get wallet_send_network_fee;

  /// No description provided for @wallet_send_service_fee.
  ///
  /// In pt, this message translates to:
  /// **'Taxa de Serviço'**
  String get wallet_send_service_fee;

  /// No description provided for @wallet_send_total_fees.
  ///
  /// In pt, this message translates to:
  /// **'Total das Taxas'**
  String get wallet_send_total_fees;

  /// No description provided for @wallet_send_free.
  ///
  /// In pt, this message translates to:
  /// **'Gratuito'**
  String get wallet_send_free;

  /// No description provided for @wallet_send_loading_price.
  ///
  /// In pt, this message translates to:
  /// **'Carregando preço...'**
  String get wallet_send_loading_price;

  /// No description provided for @wallet_send_calc_value_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao calcular valor'**
  String get wallet_send_calc_value_error;

  /// No description provided for @wallet_send_calculating_value.
  ///
  /// In pt, this message translates to:
  /// **'Calculando valor...'**
  String get wallet_send_calculating_value;

  /// No description provided for @wallet_send_tx_error_title.
  ///
  /// In pt, this message translates to:
  /// **'Erro na Transação'**
  String get wallet_send_tx_error_title;

  /// No description provided for @wallet_send_tx_error_desc.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível enviar a transação:'**
  String get wallet_send_tx_error_desc;

  /// No description provided for @wallet_send_tx_error_check.
  ///
  /// In pt, this message translates to:
  /// **'Verifique os dados e tente novamente.'**
  String get wallet_send_tx_error_check;

  /// No description provided for @wallet_send_wallet_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao acessar carteira: {description}'**
  String wallet_send_wallet_error(String description);

  /// No description provided for @wallet_send_send_all_label.
  ///
  /// In pt, this message translates to:
  /// **'Enviar Tudo'**
  String get wallet_send_send_all_label;

  /// No description provided for @wallet_send_asset_label.
  ///
  /// In pt, this message translates to:
  /// **'Enviar {asset}'**
  String wallet_send_asset_label(String asset);

  /// No description provided for @wallet_onchain_network.
  ///
  /// In pt, this message translates to:
  /// **'Bitcoin On-chain'**
  String get wallet_onchain_network;

  /// No description provided for @wallet_amount.
  ///
  /// In pt, this message translates to:
  /// **'Valor'**
  String get wallet_amount;

  /// No description provided for @wallet_network_fee.
  ///
  /// In pt, this message translates to:
  /// **'Taxa de rede'**
  String get wallet_network_fee;

  /// No description provided for @wallet_total.
  ///
  /// In pt, this message translates to:
  /// **'Total'**
  String get wallet_total;

  /// No description provided for @wallet_destination.
  ///
  /// In pt, this message translates to:
  /// **'Destino'**
  String get wallet_destination;

  /// No description provided for @wallet_fee_calculated_note.
  ///
  /// In pt, this message translates to:
  /// **'A taxa foi calculada com base na velocidade selecionada.'**
  String get wallet_fee_calculated_note;

  /// No description provided for @wallet_slide_to_confirm.
  ///
  /// In pt, this message translates to:
  /// **'Deslizar para confirmar'**
  String get wallet_slide_to_confirm;

  /// No description provided for @wallet_speed_economic.
  ///
  /// In pt, this message translates to:
  /// **'Econômica'**
  String get wallet_speed_economic;

  /// No description provided for @wallet_speed_economic_desc.
  ///
  /// In pt, this message translates to:
  /// **'Confirmação mais lenta, taxa menor'**
  String get wallet_speed_economic_desc;

  /// No description provided for @wallet_speed_normal.
  ///
  /// In pt, this message translates to:
  /// **'Normal'**
  String get wallet_speed_normal;

  /// No description provided for @wallet_speed_normal_desc.
  ///
  /// In pt, this message translates to:
  /// **'Equilíbrio entre velocidade e custo'**
  String get wallet_speed_normal_desc;

  /// No description provided for @wallet_speed_priority.
  ///
  /// In pt, this message translates to:
  /// **'Prioritária'**
  String get wallet_speed_priority;

  /// No description provided for @wallet_speed_priority_desc.
  ///
  /// In pt, this message translates to:
  /// **'Confirmação mais rápida, taxa maior'**
  String get wallet_speed_priority_desc;

  /// No description provided for @wallet_speed_label.
  ///
  /// In pt, this message translates to:
  /// **'Velocidade: {speed}'**
  String wallet_speed_label(String speed);

  /// No description provided for @wallet_tx_not_found.
  ///
  /// In pt, this message translates to:
  /// **'Transação não encontrada'**
  String get wallet_tx_not_found;

  /// No description provided for @wallet_tx_not_found_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro: Transação não encontrada'**
  String get wallet_tx_not_found_error;

  /// No description provided for @wallet_send_tx_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao enviar transação: {error}'**
  String wallet_send_tx_error(String error);

  /// No description provided for @wallet_fee_speed_title.
  ///
  /// In pt, this message translates to:
  /// **'Velocidade da transação'**
  String get wallet_fee_speed_title;

  /// No description provided for @wallet_fee_economic.
  ///
  /// In pt, this message translates to:
  /// **'Econômica'**
  String get wallet_fee_economic;

  /// No description provided for @wallet_fee_economic_eta.
  ///
  /// In pt, this message translates to:
  /// **'~60+ min'**
  String get wallet_fee_economic_eta;

  /// No description provided for @wallet_fee_normal.
  ///
  /// In pt, this message translates to:
  /// **'Normal'**
  String get wallet_fee_normal;

  /// No description provided for @wallet_fee_normal_eta.
  ///
  /// In pt, this message translates to:
  /// **'~30 min'**
  String get wallet_fee_normal_eta;

  /// No description provided for @wallet_fee_fast.
  ///
  /// In pt, this message translates to:
  /// **'Rápida'**
  String get wallet_fee_fast;

  /// No description provided for @wallet_fee_fast_eta.
  ///
  /// In pt, this message translates to:
  /// **'~10 min'**
  String get wallet_fee_fast_eta;

  /// No description provided for @tx_confirmed_title.
  ///
  /// In pt, this message translates to:
  /// **'Transação Confirmada!'**
  String get tx_confirmed_title;

  /// No description provided for @tx_received_asset.
  ///
  /// In pt, this message translates to:
  /// **'Você recebeu {ticker}'**
  String tx_received_asset(String ticker);

  /// No description provided for @tx_received.
  ///
  /// In pt, this message translates to:
  /// **'Recebido'**
  String get tx_received;

  /// No description provided for @tx_id.
  ///
  /// In pt, this message translates to:
  /// **'ID da Transação'**
  String get tx_id;

  /// No description provided for @tx_back_to_dashboard.
  ///
  /// In pt, this message translates to:
  /// **'Voltar para Dashboard'**
  String get tx_back_to_dashboard;

  /// No description provided for @tx_history_title.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de transações'**
  String get tx_history_title;

  /// No description provided for @tx_history_pix_title.
  ///
  /// In pt, this message translates to:
  /// **'Histórico do PIX'**
  String get tx_history_pix_title;

  /// No description provided for @tx_detail_title.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes da Transação'**
  String get tx_detail_title;

  /// No description provided for @tx_detail_swap_unfinished.
  ///
  /// In pt, this message translates to:
  /// **'Swap não concluído'**
  String get tx_detail_swap_unfinished;

  /// No description provided for @tx_detail_swap_refunded.
  ///
  /// In pt, this message translates to:
  /// **'Swap reembolsado'**
  String get tx_detail_swap_refunded;

  /// No description provided for @tx_detail_refund_available_msg.
  ///
  /// In pt, this message translates to:
  /// **'Esta transação não foi concluída com sucesso. Seus fundos estão seguros e disponíveis para reembolso. Use o botão abaixo para solicitar o reembolso.'**
  String get tx_detail_refund_available_msg;

  /// No description provided for @tx_detail_refund_processed_msg.
  ///
  /// In pt, this message translates to:
  /// **'O reembolso desta transação já foi processado ou está sendo enviado. Seus fundos foram ou serão devolvidos em breve.'**
  String get tx_detail_refund_processed_msg;

  /// No description provided for @tx_filter_title.
  ///
  /// In pt, this message translates to:
  /// **'Filtros'**
  String get tx_filter_title;

  /// No description provided for @tx_filter_sort_by.
  ///
  /// In pt, this message translates to:
  /// **'Ordenar por'**
  String get tx_filter_sort_by;

  /// No description provided for @tx_filter_type.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de transação'**
  String get tx_filter_type;

  /// No description provided for @tx_filter_status.
  ///
  /// In pt, this message translates to:
  /// **'Status'**
  String get tx_filter_status;

  /// No description provided for @tx_filter_currency.
  ///
  /// In pt, this message translates to:
  /// **'Moeda'**
  String get tx_filter_currency;

  /// No description provided for @tx_filter_period.
  ///
  /// In pt, this message translates to:
  /// **'Período'**
  String get tx_filter_period;

  /// No description provided for @tx_filter_period_custom.
  ///
  /// In pt, this message translates to:
  /// **'Período personalizado'**
  String get tx_filter_period_custom;

  /// No description provided for @tx_filter_clear_period.
  ///
  /// In pt, this message translates to:
  /// **'Limpar período'**
  String get tx_filter_clear_period;

  /// No description provided for @tx_filter_clear_filters.
  ///
  /// In pt, this message translates to:
  /// **'Limpar filtros'**
  String get tx_filter_clear_filters;

  /// No description provided for @tx_filter_apply.
  ///
  /// In pt, this message translates to:
  /// **'Aplicar filtros'**
  String get tx_filter_apply;

  /// No description provided for @tx_type_all.
  ///
  /// In pt, this message translates to:
  /// **'Todas'**
  String get tx_type_all;

  /// No description provided for @tx_type_send.
  ///
  /// In pt, this message translates to:
  /// **'Envio'**
  String get tx_type_send;

  /// No description provided for @tx_type_receive.
  ///
  /// In pt, this message translates to:
  /// **'Recebimento'**
  String get tx_type_receive;

  /// No description provided for @tx_type_swap.
  ///
  /// In pt, this message translates to:
  /// **'Swap'**
  String get tx_type_swap;

  /// No description provided for @tx_status_all.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get tx_status_all;

  /// No description provided for @tx_status_pending.
  ///
  /// In pt, this message translates to:
  /// **'Pendente'**
  String get tx_status_pending;

  /// No description provided for @tx_status_confirmed.
  ///
  /// In pt, this message translates to:
  /// **'Confirmado'**
  String get tx_status_confirmed;

  /// No description provided for @tx_status_failed.
  ///
  /// In pt, this message translates to:
  /// **'Falhou'**
  String get tx_status_failed;

  /// No description provided for @tx_status_refundable.
  ///
  /// In pt, this message translates to:
  /// **'Reembolsável'**
  String get tx_status_refundable;

  /// No description provided for @wallet_errors_insufficient_funds.
  ///
  /// In pt, this message translates to:
  /// **'Fundos insuficientes na carteira.'**
  String get wallet_errors_insufficient_funds;

  /// No description provided for @wallet_errors_invalid_address.
  ///
  /// In pt, this message translates to:
  /// **'Endereço inválido.'**
  String get wallet_errors_invalid_address;

  /// No description provided for @wallet_errors_connection_failed.
  ///
  /// In pt, this message translates to:
  /// **'Conexão falhou.'**
  String get wallet_errors_connection_failed;

  /// No description provided for @wallet_errors_tx_cannot_finalize.
  ///
  /// In pt, this message translates to:
  /// **'Transação não pode ser finalizada.'**
  String get wallet_errors_tx_cannot_finalize;

  /// No description provided for @wallet_errors_invalid_asset.
  ///
  /// In pt, this message translates to:
  /// **'Ativo inválido.'**
  String get wallet_errors_invalid_asset;

  /// No description provided for @wallet_errors_invalid_amount.
  ///
  /// In pt, this message translates to:
  /// **'Valor inválido.'**
  String get wallet_errors_invalid_amount;

  /// No description provided for @wallet_errors_connection.
  ///
  /// In pt, this message translates to:
  /// **'Erro de conexão'**
  String get wallet_errors_connection;

  /// No description provided for @wallet_errors_internal.
  ///
  /// In pt, this message translates to:
  /// **'Falha interna'**
  String get wallet_errors_internal;

  /// No description provided for @swap_title.
  ///
  /// In pt, this message translates to:
  /// **'Swap'**
  String get swap_title;

  /// No description provided for @swap_you_send.
  ///
  /// In pt, this message translates to:
  /// **'Você envia'**
  String get swap_you_send;

  /// No description provided for @swap_you_receive.
  ///
  /// In pt, this message translates to:
  /// **'Você recebe'**
  String get swap_you_receive;

  /// No description provided for @swap_rate_line.
  ///
  /// In pt, this message translates to:
  /// **'1 {from} = {rate} {to}'**
  String swap_rate_line(String from, String rate, String to);

  /// No description provided for @swap_insufficient_balance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo insuficiente para realizar o swap'**
  String get swap_insufficient_balance;

  /// No description provided for @swap_updating_quote.
  ///
  /// In pt, this message translates to:
  /// **'Atualizando cotação...'**
  String get swap_updating_quote;

  /// No description provided for @swap_min_value_sats.
  ///
  /// In pt, this message translates to:
  /// **'Valor mínimo: {sats} sats'**
  String swap_min_value_sats(String sats);

  /// No description provided for @swap_min_amount_sats.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade mínima é {sats} sats'**
  String swap_min_amount_sats(String sats);

  /// No description provided for @swap_no_liquidity_title.
  ///
  /// In pt, this message translates to:
  /// **'Sem Liquidez'**
  String get swap_no_liquidity_title;

  /// No description provided for @swap_no_liquidity_body.
  ///
  /// In pt, this message translates to:
  /// **'No momento não há liquidez disponível na Sideswap para realizar esta operação.'**
  String get swap_no_liquidity_body;

  /// No description provided for @swap_use_asset_value.
  ///
  /// In pt, this message translates to:
  /// **'Usar valor em ativo'**
  String get swap_use_asset_value;

  /// No description provided for @swap_use_currency_value.
  ///
  /// In pt, this message translates to:
  /// **'Usar valor em {currency}'**
  String swap_use_currency_value(String currency);

  /// No description provided for @swap_confirm_title.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Swap'**
  String get swap_confirm_title;

  /// No description provided for @swap_confirm_estimate.
  ///
  /// In pt, this message translates to:
  /// **'Estimativa'**
  String get swap_confirm_estimate;

  /// No description provided for @swap_confirm_sending.
  ///
  /// In pt, this message translates to:
  /// **'Enviando:'**
  String get swap_confirm_sending;

  /// No description provided for @swap_confirm_boltz_fee.
  ///
  /// In pt, this message translates to:
  /// **'Taxa de serviço da Boltz:'**
  String get swap_confirm_boltz_fee;

  /// No description provided for @swap_confirm_tx_fee.
  ///
  /// In pt, this message translates to:
  /// **'Taxa da transação:'**
  String get swap_confirm_tx_fee;

  /// No description provided for @swap_confirm_total_fees.
  ///
  /// In pt, this message translates to:
  /// **'Total de taxas:'**
  String get swap_confirm_total_fees;

  /// No description provided for @swap_confirm_receiving.
  ///
  /// In pt, this message translates to:
  /// **'Recebendo:'**
  String get swap_confirm_receiving;

  /// No description provided for @swap_confirm_server_fee.
  ///
  /// In pt, this message translates to:
  /// **'Taxa do servidor'**
  String get swap_confirm_server_fee;

  /// No description provided for @swap_confirm_fixed_fee.
  ///
  /// In pt, this message translates to:
  /// **'Taxa fixa'**
  String get swap_confirm_fixed_fee;

  /// No description provided for @swap_confirm_total_fees_short.
  ///
  /// In pt, this message translates to:
  /// **'Total de taxas'**
  String get swap_confirm_total_fees_short;

  /// No description provided for @swap_confirm_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro na confirmação: {error}'**
  String swap_confirm_error(String error);

  /// No description provided for @pix_confirm_title.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar transação'**
  String get pix_confirm_title;

  /// No description provided for @pix_generating_qr.
  ///
  /// In pt, this message translates to:
  /// **'Gerando QR Code...'**
  String get pix_generating_qr;

  /// No description provided for @pix_processing_unavailable.
  ///
  /// In pt, this message translates to:
  /// **'Não é possível processar transações PIX no momento. Por favor, tente novamente mais tarde.'**
  String get pix_processing_unavailable;

  /// No description provided for @pix_select_asset.
  ///
  /// In pt, this message translates to:
  /// **'Selecione um ativo'**
  String get pix_select_asset;

  /// No description provided for @pix_floating_rate_title.
  ///
  /// In pt, this message translates to:
  /// **'Câmbio Flutuante'**
  String get pix_floating_rate_title;

  /// No description provided for @pix_floating_rate_body.
  ///
  /// In pt, this message translates to:
  /// **'Importante: o LBTC tem variação de preço.\nPor isso, o valor em reais que você recebe pode ser diferente do valor esperado.\nA conversão para reais usa a cotação do momento da finalização.'**
  String get pix_floating_rate_body;

  /// No description provided for @pix_dont_show_again.
  ///
  /// In pt, this message translates to:
  /// **'Não exibir novamente'**
  String get pix_dont_show_again;

  /// No description provided for @pix_disclaimer_header.
  ///
  /// In pt, this message translates to:
  /// **'Para uma melhor experiência PIX:'**
  String get pix_disclaimer_header;

  /// No description provided for @pix_disclaimer_max_consecutive.
  ///
  /// In pt, this message translates to:
  /// **'Máx. 3 PIX consecutivos do mesmo titular em 30 min.'**
  String get pix_disclaimer_max_consecutive;

  /// No description provided for @pix_disclaimer_daily_limit.
  ///
  /// In pt, this message translates to:
  /// **'Limite R\$ 5.000/dia por titular (nível bancário).'**
  String get pix_disclaimer_daily_limit;

  /// No description provided for @pix_disclaimer_outside_rules.
  ///
  /// In pt, this message translates to:
  /// **'Transferências fora das regras são devolvidas ao pagador.'**
  String get pix_disclaimer_outside_rules;

  /// No description provided for @pix_disclaimer_analyzed.
  ///
  /// In pt, this message translates to:
  /// **'100% dos PIX são analisados por infra conjunta — estorno automático se suspeita de automação.'**
  String get pix_disclaimer_analyzed;

  /// No description provided for @pix_disclaimer_avg_time.
  ///
  /// In pt, this message translates to:
  /// **'Tempo médio: 5 a 25 min. PIX c/ sinal de risco bancário: 3–7 dias úteis (estornável).'**
  String get pix_disclaimer_avg_time;

  /// No description provided for @pix_deposit_title.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes do Depósito PIX'**
  String get pix_deposit_title;

  /// No description provided for @pix_deposit_label.
  ///
  /// In pt, this message translates to:
  /// **'Depósito PIX'**
  String get pix_deposit_label;

  /// No description provided for @pix_deposit_date.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get pix_deposit_date;

  /// No description provided for @pix_deposit_target_asset.
  ///
  /// In pt, this message translates to:
  /// **'Ativo de destino'**
  String get pix_deposit_target_asset;

  /// No description provided for @pix_deposit_value.
  ///
  /// In pt, this message translates to:
  /// **'Valor'**
  String get pix_deposit_value;

  /// No description provided for @pix_deposit_pix_key.
  ///
  /// In pt, this message translates to:
  /// **'Chave PIX'**
  String get pix_deposit_pix_key;

  /// No description provided for @pix_deposit_id.
  ///
  /// In pt, this message translates to:
  /// **'ID do Depósito'**
  String get pix_deposit_id;

  /// No description provided for @pix_deposit_received_value.
  ///
  /// In pt, this message translates to:
  /// **'Valor recebido'**
  String get pix_deposit_received_value;

  /// No description provided for @pix_deposit_tx_id.
  ///
  /// In pt, this message translates to:
  /// **'TX ID'**
  String get pix_deposit_tx_id;

  /// No description provided for @pix_deposit_expired.
  ///
  /// In pt, this message translates to:
  /// **'Prazo expirado'**
  String get pix_deposit_expired;

  /// No description provided for @pix_deposit_time_remaining.
  ///
  /// In pt, this message translates to:
  /// **'Tempo restante para pagar'**
  String get pix_deposit_time_remaining;

  /// No description provided for @pix_deposit_invalid.
  ///
  /// In pt, this message translates to:
  /// **'Este PIX não é mais válido'**
  String get pix_deposit_invalid;

  /// No description provided for @pix_deposit_info.
  ///
  /// In pt, this message translates to:
  /// **'Informações'**
  String get pix_deposit_info;

  /// No description provided for @pix_deposit_view_explorer.
  ///
  /// In pt, this message translates to:
  /// **'Ver no Explorer'**
  String get pix_deposit_view_explorer;

  /// No description provided for @pix_deposit_view_chain.
  ///
  /// In pt, this message translates to:
  /// **'Visualizar na blockchain'**
  String get pix_deposit_view_chain;

  /// No description provided for @human_verif_title.
  ///
  /// In pt, this message translates to:
  /// **'Verificação de Humanidade'**
  String get human_verif_title;

  /// No description provided for @human_verif_intro_title.
  ///
  /// In pt, this message translates to:
  /// **'Verifique sua humanidade'**
  String get human_verif_intro_title;

  /// No description provided for @human_verif_intro_body.
  ///
  /// In pt, this message translates to:
  /// **'Para garantir a segurança da plataforma, precisamos verificar que você é uma pessoa real.'**
  String get human_verif_intro_body;

  /// No description provided for @human_verif_step1_title.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento simbólico'**
  String get human_verif_step1_title;

  /// No description provided for @human_verif_step1_desc.
  ///
  /// In pt, this message translates to:
  /// **'Você fará um PIX de apenas R\$ 1,00 para nossa chave. O valor será devolvido imediatamente após o pagamento.'**
  String get human_verif_step1_desc;

  /// No description provided for @human_verif_step2_title.
  ///
  /// In pt, this message translates to:
  /// **'Receba o código'**
  String get human_verif_step2_title;

  /// No description provided for @human_verif_step2_desc.
  ///
  /// In pt, this message translates to:
  /// **'Você receberá o valor de volta com um código único na mensagem.'**
  String get human_verif_step2_desc;

  /// No description provided for @human_verif_step3_title.
  ///
  /// In pt, this message translates to:
  /// **'Valide sua identidade'**
  String get human_verif_step3_title;

  /// No description provided for @human_verif_step3_desc.
  ///
  /// In pt, this message translates to:
  /// **'Digite o código recebido para confirmar sua humanidade.'**
  String get human_verif_step3_desc;

  /// No description provided for @human_verif_payment_title.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento de Verificação'**
  String get human_verif_payment_title;

  /// No description provided for @human_verif_time_remaining_prefix.
  ///
  /// In pt, this message translates to:
  /// **'Você tem '**
  String get human_verif_time_remaining_prefix;

  /// No description provided for @human_verif_minutes_and.
  ///
  /// In pt, this message translates to:
  /// **'minutos e '**
  String get human_verif_minutes_and;

  /// No description provided for @human_verif_seconds.
  ///
  /// In pt, this message translates to:
  /// **'segundos '**
  String get human_verif_seconds;

  /// No description provided for @human_verif_to_pay.
  ///
  /// In pt, this message translates to:
  /// **'para concluir o pagamento.'**
  String get human_verif_to_pay;

  /// No description provided for @human_verif_pix_key.
  ///
  /// In pt, this message translates to:
  /// **'Chave PIX'**
  String get human_verif_pix_key;

  /// No description provided for @human_verif_time_expired_title.
  ///
  /// In pt, this message translates to:
  /// **'Tempo Esgotado'**
  String get human_verif_time_expired_title;

  /// No description provided for @human_verif_time_expired_body.
  ///
  /// In pt, this message translates to:
  /// **'O tempo para realizar o pagamento expirou. Por favor, tente novamente.'**
  String get human_verif_time_expired_body;

  /// No description provided for @human_verif_after_payment.
  ///
  /// In pt, this message translates to:
  /// **'Após o pagamento, você receberá um código na mensagem do PIX de retorno.'**
  String get human_verif_after_payment;

  /// No description provided for @human_verif_already_paid.
  ///
  /// In pt, this message translates to:
  /// **'Já fiz o pagamento'**
  String get human_verif_already_paid;

  /// No description provided for @human_verif_code_title.
  ///
  /// In pt, this message translates to:
  /// **'Validar Código'**
  String get human_verif_code_title;

  /// No description provided for @human_verif_code_prompt_prefix.
  ///
  /// In pt, this message translates to:
  /// **'Digite o '**
  String get human_verif_code_prompt_prefix;

  /// No description provided for @human_verif_code_word.
  ///
  /// In pt, this message translates to:
  /// **'código'**
  String get human_verif_code_word;

  /// No description provided for @human_verif_code_body.
  ///
  /// In pt, this message translates to:
  /// **'Insira o código de 6 dígitos que você recebeu na mensagem do PIX de retorno.'**
  String get human_verif_code_body;

  /// No description provided for @human_verif_code_invalid.
  ///
  /// In pt, this message translates to:
  /// **'Código inválido. Tente novamente.'**
  String get human_verif_code_invalid;

  /// No description provided for @human_verif_code_help.
  ///
  /// In pt, this message translates to:
  /// **'Verifique o campo de mensagem do PIX que você recebeu de volta.'**
  String get human_verif_code_help;

  /// No description provided for @human_verif_back_to_payment.
  ///
  /// In pt, this message translates to:
  /// **'Voltar para o pagamento'**
  String get human_verif_back_to_payment;

  /// No description provided for @phone_verif_title.
  ///
  /// In pt, this message translates to:
  /// **'Verificação'**
  String get phone_verif_title;

  /// No description provided for @phone_verif_humanity_title.
  ///
  /// In pt, this message translates to:
  /// **'Verificação de Humanidade'**
  String get phone_verif_humanity_title;

  /// No description provided for @phone_verif_humanity_body.
  ///
  /// In pt, this message translates to:
  /// **'Para garantir a segurança, precisamos confirmar que você é uma pessoa real. O número de telefone será usado apenas para enviar um código de verificação. Nenhum dado será armazenado ou vinculado à sua carteira.'**
  String get phone_verif_humanity_body;

  /// No description provided for @phone_verif_method_title.
  ///
  /// In pt, this message translates to:
  /// **'Escolher Método'**
  String get phone_verif_method_title;

  /// No description provided for @phone_verif_inform_prefix.
  ///
  /// In pt, this message translates to:
  /// **'Informe seu '**
  String get phone_verif_inform_prefix;

  /// No description provided for @phone_verif_phone_number.
  ///
  /// In pt, this message translates to:
  /// **'número de telefone'**
  String get phone_verif_phone_number;

  /// No description provided for @phone_verif_method_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Escolha como deseja receber o código de verificação'**
  String get phone_verif_method_subtitle;

  /// No description provided for @phone_verif_number_label.
  ///
  /// In pt, this message translates to:
  /// **'Número'**
  String get phone_verif_number_label;

  /// No description provided for @phone_verif_number_hint.
  ///
  /// In pt, this message translates to:
  /// **'Digite seu número'**
  String get phone_verif_number_hint;

  /// No description provided for @phone_verif_send_code.
  ///
  /// In pt, this message translates to:
  /// **'Enviar código'**
  String get phone_verif_send_code;

  /// No description provided for @phone_verif_code_title.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Código'**
  String get phone_verif_code_title;

  /// No description provided for @phone_verif_code_prompt_prefix.
  ///
  /// In pt, this message translates to:
  /// **'Digite o '**
  String get phone_verif_code_prompt_prefix;

  /// No description provided for @phone_verif_code_word.
  ///
  /// In pt, this message translates to:
  /// **'código recebido'**
  String get phone_verif_code_word;

  /// No description provided for @phone_verif_code_body.
  ///
  /// In pt, this message translates to:
  /// **'Enviamos um código de 6 dígitos para o número {phone} via Telegram.'**
  String phone_verif_code_body(String phone);

  /// No description provided for @phone_verif_verify.
  ///
  /// In pt, this message translates to:
  /// **'Verificar'**
  String get phone_verif_verify;

  /// No description provided for @phone_verif_resend_in.
  ///
  /// In pt, this message translates to:
  /// **'Reenviar em 00:{seconds}'**
  String phone_verif_resend_in(String seconds);

  /// No description provided for @phone_verif_resend_code.
  ///
  /// In pt, this message translates to:
  /// **'Reenviar código'**
  String get phone_verif_resend_code;

  /// No description provided for @refund_screen_title.
  ///
  /// In pt, this message translates to:
  /// **'Reembolso de Transação'**
  String get refund_screen_title;

  /// No description provided for @refund_available_title.
  ///
  /// In pt, this message translates to:
  /// **'Reembolsos Disponíveis'**
  String get refund_available_title;

  /// No description provided for @refund_retry_progress.
  ///
  /// In pt, this message translates to:
  /// **'Tentativa {current} de {max}'**
  String refund_retry_progress(int current, int max);

  /// No description provided for @refund_loading_long.
  ///
  /// In pt, this message translates to:
  /// **'Aguarde, pode demorar um pouco...'**
  String get refund_loading_long;

  /// No description provided for @refund_empty_title.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum Reembolso Disponível'**
  String get refund_empty_title;

  /// No description provided for @refund_empty_body.
  ///
  /// In pt, this message translates to:
  /// **'Você não tem transações pendentes de reembolso.'**
  String get refund_empty_body;

  /// No description provided for @refund_pull_to_refresh.
  ///
  /// In pt, this message translates to:
  /// **'Puxe para baixo para atualizar'**
  String get refund_pull_to_refresh;

  /// No description provided for @refund_speed_title.
  ///
  /// In pt, this message translates to:
  /// **'Velocidade da Transação'**
  String get refund_speed_title;

  /// No description provided for @refund_insufficient_for_fee.
  ///
  /// In pt, this message translates to:
  /// **'Fundos insuficientes para cobrir a taxa de transação'**
  String get refund_insufficient_for_fee;

  /// No description provided for @refund_fee_load_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao recuperar taxas: {error}'**
  String refund_fee_load_error(String error);

  /// No description provided for @refund_calculating_fees.
  ///
  /// In pt, this message translates to:
  /// **'Calculando taxas...'**
  String get refund_calculating_fees;

  /// No description provided for @refund_amount_too_small.
  ///
  /// In pt, this message translates to:
  /// **'Valor muito pequeno para cobrir as taxas de transação'**
  String get refund_amount_too_small;

  /// No description provided for @refund_confirm_button.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Reembolso'**
  String get refund_confirm_button;

  /// No description provided for @refund_process_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao processar reembolso: {error}'**
  String refund_process_error(String error);

  /// No description provided for @refund_none_found.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum swap reembolsável encontrado'**
  String get refund_none_found;

  /// No description provided for @refund_details_title.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes do Reembolso'**
  String get refund_details_title;

  /// No description provided for @refund_auto_send_info.
  ///
  /// In pt, this message translates to:
  /// **'Não se preocupe, o reembolso em Bitcoin será enviado automaticamente para o endereço da sua wallet.'**
  String get refund_auto_send_info;

  /// No description provided for @refund_info_title.
  ///
  /// In pt, this message translates to:
  /// **'Informações do Reembolso'**
  String get refund_info_title;

  /// No description provided for @refund_label_amount.
  ///
  /// In pt, this message translates to:
  /// **'Valor'**
  String get refund_label_amount;

  /// No description provided for @refund_label_transaction.
  ///
  /// In pt, this message translates to:
  /// **'Transação'**
  String get refund_label_transaction;

  /// No description provided for @refund_label_date.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get refund_label_date;

  /// No description provided for @refund_label_refund_amount.
  ///
  /// In pt, this message translates to:
  /// **'Valor do Reembolso'**
  String get refund_label_refund_amount;

  /// No description provided for @refund_address_label.
  ///
  /// In pt, this message translates to:
  /// **'Endereço Bitcoin'**
  String get refund_address_label;

  /// No description provided for @refund_address_hint.
  ///
  /// In pt, this message translates to:
  /// **'Insira o endereço Bitcoin'**
  String get refund_address_hint;

  /// No description provided for @refund_address_required.
  ///
  /// In pt, this message translates to:
  /// **'Por favor, insira um endereço Bitcoin'**
  String get refund_address_required;

  /// No description provided for @refund_address_invalid.
  ///
  /// In pt, this message translates to:
  /// **'Endereço Bitcoin inválido'**
  String get refund_address_invalid;

  /// No description provided for @refund_address_invalid_long.
  ///
  /// In pt, this message translates to:
  /// **'Endereço Bitcoin inválido. Use um endereço válido (ex: 1..., 3..., bc1...)'**
  String get refund_address_invalid_long;

  /// No description provided for @refund_status_pending.
  ///
  /// In pt, this message translates to:
  /// **'Pendente'**
  String get refund_status_pending;

  /// No description provided for @refund_status_available.
  ///
  /// In pt, this message translates to:
  /// **'Disponível'**
  String get refund_status_available;

  /// No description provided for @refund_action_retransmit.
  ///
  /// In pt, this message translates to:
  /// **'Retransmitir'**
  String get refund_action_retransmit;

  /// No description provided for @refund_speed_select_title.
  ///
  /// In pt, this message translates to:
  /// **'Selecione a velocidade da transação'**
  String get refund_speed_select_title;

  /// No description provided for @refund_amount_too_small_short.
  ///
  /// In pt, this message translates to:
  /// **'Valor muito pequeno para cobrir as taxas'**
  String get refund_amount_too_small_short;

  /// No description provided for @refund_fee_label_economy.
  ///
  /// In pt, this message translates to:
  /// **'Economia'**
  String get refund_fee_label_economy;

  /// No description provided for @refund_fee_label_standard.
  ///
  /// In pt, this message translates to:
  /// **'Padrão'**
  String get refund_fee_label_standard;

  /// No description provided for @refund_fee_label_fast.
  ///
  /// In pt, this message translates to:
  /// **'Rápido'**
  String get refund_fee_label_fast;

  /// No description provided for @refund_fee_label_urgent.
  ///
  /// In pt, this message translates to:
  /// **'Urgente'**
  String get refund_fee_label_urgent;

  /// No description provided for @refund_fee_time_24h.
  ///
  /// In pt, this message translates to:
  /// **'~24 horas'**
  String get refund_fee_time_24h;

  /// No description provided for @refund_fee_time_1h.
  ///
  /// In pt, this message translates to:
  /// **'~1 hora'**
  String get refund_fee_time_1h;

  /// No description provided for @refund_fee_time_30m.
  ///
  /// In pt, this message translates to:
  /// **'~30 minutos'**
  String get refund_fee_time_30m;

  /// No description provided for @refund_fee_time_10m.
  ///
  /// In pt, this message translates to:
  /// **'~10 minutos'**
  String get refund_fee_time_10m;

  /// No description provided for @refund_fee_rate.
  ///
  /// In pt, this message translates to:
  /// **'Taxa: {rate} sat/vB'**
  String refund_fee_rate(int rate);

  /// No description provided for @refund_fee_total.
  ///
  /// In pt, this message translates to:
  /// **'Total: {amount} sats'**
  String refund_fee_total(String amount);

  /// No description provided for @refund_success_title.
  ///
  /// In pt, this message translates to:
  /// **'Reembolso Iniciado!'**
  String get refund_success_title;

  /// No description provided for @refund_success_body.
  ///
  /// In pt, this message translates to:
  /// **'Seu reembolso foi processado com sucesso. Em breve os fundos estarão disponíveis no endereço informado.'**
  String get refund_success_body;

  /// No description provided for @refund_success_amount_label.
  ///
  /// In pt, this message translates to:
  /// **'Valor Reembolsado'**
  String get refund_success_amount_label;

  /// No description provided for @refund_success_txid_label.
  ///
  /// In pt, this message translates to:
  /// **'Transaction ID'**
  String get refund_success_txid_label;

  /// No description provided for @refund_success_back_dashboard.
  ///
  /// In pt, this message translates to:
  /// **'Voltar para Dashboard'**
  String get refund_success_back_dashboard;

  /// No description provided for @refund_test_title.
  ///
  /// In pt, this message translates to:
  /// **'🧪 Teste de Refund'**
  String get refund_test_title;

  /// No description provided for @refund_test_heading.
  ///
  /// In pt, this message translates to:
  /// **'Modo de Teste - Refund'**
  String get refund_test_heading;

  /// No description provided for @refund_test_description.
  ///
  /// In pt, this message translates to:
  /// **'Use esta tela para testar o fluxo completo de refund com dados simulados, sem precisar de transações reais.'**
  String get refund_test_description;

  /// No description provided for @refund_test_button_mock.
  ///
  /// In pt, this message translates to:
  /// **'Testar com Dados Mock'**
  String get refund_test_button_mock;

  /// No description provided for @refund_test_button_real_sdk.
  ///
  /// In pt, this message translates to:
  /// **'Testar com SDK Real'**
  String get refund_test_button_real_sdk;

  /// No description provided for @refund_test_mock_data_title.
  ///
  /// In pt, this message translates to:
  /// **'Dados Mock Incluídos'**
  String get refund_test_mock_data_title;

  /// No description provided for @refund_test_mock_item_swaps.
  ///
  /// In pt, this message translates to:
  /// **'• 3 swaps reembolsáveis'**
  String get refund_test_mock_item_swaps;

  /// No description provided for @refund_test_mock_item_amounts.
  ///
  /// In pt, this message translates to:
  /// **'• Valores: 0.001, 0.0025, 0.0005 BTC'**
  String get refund_test_mock_item_amounts;

  /// No description provided for @refund_test_mock_item_fees.
  ///
  /// In pt, this message translates to:
  /// **'• 4 opções de taxa diferentes'**
  String get refund_test_mock_item_fees;

  /// No description provided for @refund_test_mock_item_address.
  ///
  /// In pt, this message translates to:
  /// **'• Endereço Bitcoin pré-preenchido'**
  String get refund_test_mock_item_address;

  /// No description provided for @refund_test_mock_item_success.
  ///
  /// In pt, this message translates to:
  /// **'• Simula sucesso em 90% dos casos'**
  String get refund_test_mock_item_success;

  /// No description provided for @refund_test_advanced_title.
  ///
  /// In pt, this message translates to:
  /// **'🧪 Teste de Refund Avançado'**
  String get refund_test_advanced_title;

  /// No description provided for @refund_test_clear_tooltip.
  ///
  /// In pt, this message translates to:
  /// **'Limpar transações mock'**
  String get refund_test_clear_tooltip;

  /// No description provided for @refund_test_cleared_snack.
  ///
  /// In pt, this message translates to:
  /// **'Transações mockadas removidas'**
  String get refund_test_cleared_snack;

  /// No description provided for @refund_test_advanced_heading.
  ///
  /// In pt, this message translates to:
  /// **'Teste de Refund com\nTransações Reais'**
  String get refund_test_advanced_heading;

  /// No description provided for @refund_test_advanced_description.
  ///
  /// In pt, this message translates to:
  /// **'Simule transações Peg In refundable baseadas em\ndados reais para testar o fluxo completo de reembolso.'**
  String get refund_test_advanced_description;

  /// No description provided for @refund_test_load_mock_button.
  ///
  /// In pt, this message translates to:
  /// **'Carregar Transações Mock'**
  String get refund_test_load_mock_button;

  /// No description provided for @refund_test_loaded_snack.
  ///
  /// In pt, this message translates to:
  /// **'{count} transações mockadas carregadas'**
  String refund_test_loaded_snack(int count);

  /// No description provided for @refund_test_mock_list_title.
  ///
  /// In pt, this message translates to:
  /// **'Transações Mockadas ({count})'**
  String refund_test_mock_list_title(int count);

  /// No description provided for @refund_test_flow_button.
  ///
  /// In pt, this message translates to:
  /// **'Testar Fluxo de Refund (Mock SDK)'**
  String get refund_test_flow_button;

  /// No description provided for @refund_test_real_tx_title.
  ///
  /// In pt, this message translates to:
  /// **'Sobre a Transação Real'**
  String get refund_test_real_tx_title;

  /// No description provided for @refund_test_real_tx_type.
  ///
  /// In pt, this message translates to:
  /// **'🔹 Tipo: Peg In (BTC → LBTC)'**
  String get refund_test_real_tx_type;

  /// No description provided for @refund_test_real_tx_id.
  ///
  /// In pt, this message translates to:
  /// **'🔹 TX ID: 5e2159e9b5fbf7023b2800...'**
  String get refund_test_real_tx_id;

  /// No description provided for @refund_test_real_tx_sent.
  ///
  /// In pt, this message translates to:
  /// **'🔹 Valor enviado: 52574 sats (402 sats de taxa)'**
  String get refund_test_real_tx_sent;

  /// No description provided for @refund_test_real_tx_expected.
  ///
  /// In pt, this message translates to:
  /// **'🔹 Valor esperado: 52172 sats (LBTC)'**
  String get refund_test_real_tx_expected;

  /// No description provided for @refund_test_real_tx_date.
  ///
  /// In pt, this message translates to:
  /// **'🔹 Data: 04/02/2026 às 00:17:10'**
  String get refund_test_real_tx_date;

  /// No description provided for @refund_test_real_tx_lockup.
  ///
  /// In pt, this message translates to:
  /// **'🔹 Lockup TX: 2622dd4f5a1c69f7cea5...'**
  String get refund_test_real_tx_lockup;

  /// No description provided for @refund_test_real_tx_address.
  ///
  /// In pt, this message translates to:
  /// **'🔹 Endereço: bc1p62e2r4jnr3v985uqk...'**
  String get refund_test_real_tx_address;

  /// No description provided for @refund_test_real_tx_warning.
  ///
  /// In pt, this message translates to:
  /// **'Status: REFUNDABLE\nEsta transação falhou e os fundos podem ser reembolsados para o endereço Bitcoin original.'**
  String get refund_test_real_tx_warning;

  /// No description provided for @refund_test_badge_refundable.
  ///
  /// In pt, this message translates to:
  /// **'REFUNDABLE'**
  String get refund_test_badge_refundable;

  /// No description provided for @refund_test_badge_confirmed.
  ///
  /// In pt, this message translates to:
  /// **'CONFIRMED'**
  String get refund_test_badge_confirmed;

  /// No description provided for @refund_test_card_amount.
  ///
  /// In pt, this message translates to:
  /// **'Valor: {amount} sats'**
  String refund_test_card_amount(String amount);

  /// No description provided for @refund_test_card_id.
  ///
  /// In pt, this message translates to:
  /// **'ID: {id}'**
  String refund_test_card_id(String id);

  /// No description provided for @refund_test_card_to.
  ///
  /// In pt, this message translates to:
  /// **'Para: {address}'**
  String refund_test_card_to(String address);

  /// No description provided for @qr_scanner_searching.
  ///
  /// In pt, this message translates to:
  /// **'Procurando QR Code...'**
  String get qr_scanner_searching;

  /// No description provided for @qr_scanner_found.
  ///
  /// In pt, this message translates to:
  /// **'QR Code encontrado!'**
  String get qr_scanner_found;

  /// No description provided for @qr_scanner_position_hint.
  ///
  /// In pt, this message translates to:
  /// **'Posicione o QR code dentro da área destacada'**
  String get qr_scanner_position_hint;

  /// No description provided for @qr_scanner_supported_networks.
  ///
  /// In pt, this message translates to:
  /// **'Bitcoin • Lightning • Liquid'**
  String get qr_scanner_supported_networks;

  /// No description provided for @qr_scanner_flash_label.
  ///
  /// In pt, this message translates to:
  /// **'Flash'**
  String get qr_scanner_flash_label;

  /// No description provided for @qr_scanner_camera_label.
  ///
  /// In pt, this message translates to:
  /// **'Câmera'**
  String get qr_scanner_camera_label;

  /// No description provided for @qr_validation_empty.
  ///
  /// In pt, this message translates to:
  /// **'QR code vazio'**
  String get qr_validation_empty;

  /// No description provided for @qr_validation_unrecognized.
  ///
  /// In pt, this message translates to:
  /// **'Formato de QR code não reconhecido'**
  String get qr_validation_unrecognized;

  /// No description provided for @qr_validation_lightning_unsupported_symbols.
  ///
  /// In pt, this message translates to:
  /// **'Lightning com símbolos especiais (₿, #, \$) não é suportado'**
  String get qr_validation_lightning_unsupported_symbols;

  /// No description provided for @qr_validation_lnurl_bip353_unsupported.
  ///
  /// In pt, this message translates to:
  /// **'Formato LNURL BIP 353 não é suportado no momento. Use um endereço Lightning válido ou LNURL de walletofsatoshi.com'**
  String get qr_validation_lnurl_bip353_unsupported;

  /// No description provided for @qr_validation_boltz_invalid.
  ///
  /// In pt, this message translates to:
  /// **'Invoice BOLTZ inválido'**
  String get qr_validation_boltz_invalid;

  /// No description provided for @qr_validation_boltz_no_amount.
  ///
  /// In pt, this message translates to:
  /// **'Invoice BOLTZ sem valor não é suportado. Por favor, gere um invoice com valor definido'**
  String get qr_validation_boltz_no_amount;

  /// No description provided for @qr_validation_liquid_invalid.
  ///
  /// In pt, this message translates to:
  /// **'Endereço Liquid inválido no QR code'**
  String get qr_validation_liquid_invalid;

  /// No description provided for @qr_validation_liquid_format_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao processar QR Liquid: formato inválido'**
  String get qr_validation_liquid_format_error;

  /// No description provided for @qr_validation_bitcoin_invalid.
  ///
  /// In pt, this message translates to:
  /// **'Endereço Bitcoin inválido no QR code'**
  String get qr_validation_bitcoin_invalid;

  /// No description provided for @qr_validation_bitcoin_format_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao processar QR Bitcoin: formato inválido'**
  String get qr_validation_bitcoin_format_error;

  /// No description provided for @qr_validation_lightning_too_short.
  ///
  /// In pt, this message translates to:
  /// **'Lightning invoice muito curto'**
  String get qr_validation_lightning_too_short;

  /// No description provided for @qr_validation_lnurl_unsupported.
  ///
  /// In pt, this message translates to:
  /// **'LNURL não suportado. Use walletofsatoshi.com ou outro provedor compatível'**
  String get qr_validation_lnurl_unsupported;

  /// No description provided for @qr_validation_invalid_default.
  ///
  /// In pt, this message translates to:
  /// **'QR code inválido'**
  String get qr_validation_invalid_default;

  /// No description provided for @tx_sent_title.
  ///
  /// In pt, this message translates to:
  /// **'Transação Enviada!'**
  String get tx_sent_title;

  /// No description provided for @tx_sent_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Seu {ticker} foi enviado com sucesso'**
  String tx_sent_subtitle(String ticker);

  /// No description provided for @tx_sent_status_label.
  ///
  /// In pt, this message translates to:
  /// **'Enviado'**
  String get tx_sent_status_label;

  /// No description provided for @tx_sent_track_history.
  ///
  /// In pt, this message translates to:
  /// **'Você pode acompanhar o status na seção de histórico.'**
  String get tx_sent_track_history;

  /// No description provided for @setup_first_access_title.
  ///
  /// In pt, this message translates to:
  /// **'Como você quer começar?'**
  String get setup_first_access_title;

  /// No description provided for @setup_first_access_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Você pode criar uma nova carteira protegida por você, ou importar uma já existente com sua chave.'**
  String get setup_first_access_subtitle;

  /// No description provided for @setup_create_wallet_appbar.
  ///
  /// In pt, this message translates to:
  /// **'Criar carteira'**
  String get setup_create_wallet_appbar;

  /// No description provided for @setup_seed_length_title.
  ///
  /// In pt, this message translates to:
  /// **'Selecione o tamanho da '**
  String get setup_seed_length_title;

  /// No description provided for @setup_seed_length_highlight.
  ///
  /// In pt, this message translates to:
  /// **'frase-semente'**
  String get setup_seed_length_highlight;

  /// No description provided for @setup_seed_length_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Você pode criar sua carteira com 12 ou 24 palavras. Ambas são seguras, mas cada opção tem seu nível de praticidade e proteção.'**
  String get setup_seed_length_subtitle;

  /// No description provided for @setup_seed_12_title.
  ///
  /// In pt, this message translates to:
  /// **'12 Palavras'**
  String get setup_seed_12_title;

  /// No description provided for @setup_seed_12_desc.
  ///
  /// In pt, this message translates to:
  /// **'Mais prática e rápida de configurar. Recomendada\npara iniciantes ou quem prefere simplicidade sem\nabrir mão da segurança.'**
  String get setup_seed_12_desc;

  /// No description provided for @setup_seed_24_title.
  ///
  /// In pt, this message translates to:
  /// **'24 Palavras (recomendado)'**
  String get setup_seed_24_title;

  /// No description provided for @setup_seed_24_desc.
  ///
  /// In pt, this message translates to:
  /// **'Proporciona mais segurança. Recomendada para\nquem deseja proteger valores maiores ou busca o\nmáximo de segurança.'**
  String get setup_seed_24_desc;

  /// No description provided for @setup_generate_seed_button.
  ///
  /// In pt, this message translates to:
  /// **'Gerar frase de recuperação'**
  String get setup_generate_seed_button;

  /// No description provided for @setup_confirm_seed_appbar.
  ///
  /// In pt, this message translates to:
  /// **'Confirme sua frase'**
  String get setup_confirm_seed_appbar;

  /// No description provided for @setup_confirm_seed_title.
  ///
  /// In pt, this message translates to:
  /// **'Confirmação de '**
  String get setup_confirm_seed_title;

  /// No description provided for @setup_confirm_seed_highlight.
  ///
  /// In pt, this message translates to:
  /// **'Segurança'**
  String get setup_confirm_seed_highlight;

  /// No description provided for @setup_confirm_seed_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Selecione as palavras na ordem correta para confirmar sua frase de recuperação.'**
  String get setup_confirm_seed_subtitle;

  /// No description provided for @setup_confirm_seed_error.
  ///
  /// In pt, this message translates to:
  /// **'Uma ou mais palavras estão incorretas. Tente novamente.'**
  String get setup_confirm_seed_error;

  /// No description provided for @setup_seed_word_label.
  ///
  /// In pt, this message translates to:
  /// **'Palavra #{position}: '**
  String setup_seed_word_label(int position);

  /// No description provided for @setup_import_appbar.
  ///
  /// In pt, this message translates to:
  /// **'Importar Carteira'**
  String get setup_import_appbar;

  /// No description provided for @setup_import_restart_tooltip.
  ///
  /// In pt, this message translates to:
  /// **'Recomeçar'**
  String get setup_import_restart_tooltip;

  /// No description provided for @setup_import_instruction_title.
  ///
  /// In pt, this message translates to:
  /// **'Digite sua frase de recuperação'**
  String get setup_import_instruction_title;

  /// No description provided for @setup_import_instruction_body.
  ///
  /// In pt, this message translates to:
  /// **'Digite cada palavra da sua seed phrase (12 ou 24 palavras). O sistema oferecerá sugestões BIP39 conforme você digita. Pressione espaço ou clique para confirmar cada palavra.'**
  String get setup_import_instruction_body;

  /// No description provided for @setup_import_seed_valid.
  ///
  /// In pt, this message translates to:
  /// **'Seed phrase válida! Pronta para importar.'**
  String get setup_import_seed_valid;

  /// No description provided for @setup_import_checksum_invalid.
  ///
  /// In pt, this message translates to:
  /// **'Checksum inválido. Verifique as palavras.'**
  String get setup_import_checksum_invalid;

  /// No description provided for @setup_import_tip.
  ///
  /// In pt, this message translates to:
  /// **'Dica: Pressione espaço para confirmar a primeira sugestão rapidamente'**
  String get setup_import_tip;

  /// No description provided for @setup_import_button.
  ///
  /// In pt, this message translates to:
  /// **'Importar Carteira'**
  String get setup_import_button;

  /// No description provided for @setup_import_cleanup_warning.
  ///
  /// In pt, this message translates to:
  /// **'Aviso: Alguns arquivos antigos não puderam ser removidos. O app pode precisar ser reiniciado.'**
  String get setup_import_cleanup_warning;

  /// No description provided for @setup_clipboard_detected_title.
  ///
  /// In pt, this message translates to:
  /// **'Frase semente detectada'**
  String get setup_clipboard_detected_title;

  /// No description provided for @setup_clipboard_detected_body.
  ///
  /// In pt, this message translates to:
  /// **'Detectamos uma frase na área de transferência'**
  String get setup_clipboard_detected_body;

  /// No description provided for @setup_clipboard_paste_button.
  ///
  /// In pt, this message translates to:
  /// **'Colar'**
  String get setup_clipboard_paste_button;

  /// No description provided for @setup_clipboard_ignore_button.
  ///
  /// In pt, this message translates to:
  /// **'Ignorar'**
  String get setup_clipboard_ignore_button;

  /// No description provided for @setup_input_hint_press_space.
  ///
  /// In pt, this message translates to:
  /// **'Pressione espaço para confirmar \"{word}\"'**
  String setup_input_hint_press_space(String word);

  /// No description provided for @setup_input_hint_default.
  ///
  /// In pt, this message translates to:
  /// **'Digite uma palavra BIP39...'**
  String get setup_input_hint_default;

  /// No description provided for @setup_progress_label.
  ///
  /// In pt, this message translates to:
  /// **'Progresso'**
  String get setup_progress_label;

  /// No description provided for @setup_progress_count.
  ///
  /// In pt, this message translates to:
  /// **'{count}/{target} palavras'**
  String setup_progress_count(int count, int target);

  /// No description provided for @setup_seed_invalid_word.
  ///
  /// In pt, this message translates to:
  /// **'Palavra inválida: {word}'**
  String setup_seed_invalid_word(String word);

  /// No description provided for @setup_seed_wrong_count.
  ///
  /// In pt, this message translates to:
  /// **'Frase deve ter 12, 15, 18, 21 ou 24 palavras. Encontradas: {count}'**
  String setup_seed_wrong_count(int count);

  /// No description provided for @setup_seed_invalid_words_list.
  ///
  /// In pt, this message translates to:
  /// **'Palavras inválidas: {list}'**
  String setup_seed_invalid_words_list(String list);

  /// No description provided for @setup_seed_invalid_checksum.
  ///
  /// In pt, this message translates to:
  /// **'Frase inválida. Verifique o checksum.'**
  String get setup_seed_invalid_checksum;

  /// No description provided for @wallet_import_msg_processing.
  ///
  /// In pt, this message translates to:
  /// **'Processando...'**
  String get wallet_import_msg_processing;

  /// No description provided for @wallet_import_msg_verifying.
  ///
  /// In pt, this message translates to:
  /// **'Verificando dados...'**
  String get wallet_import_msg_verifying;

  /// No description provided for @wallet_import_msg_initializing.
  ///
  /// In pt, this message translates to:
  /// **'Inicializando carteira...'**
  String get wallet_import_msg_initializing;

  /// No description provided for @wallet_import_msg_loading_balances.
  ///
  /// In pt, this message translates to:
  /// **'Carregando saldos...'**
  String get wallet_import_msg_loading_balances;

  /// No description provided for @wallet_import_msg_loading_transactions.
  ///
  /// In pt, this message translates to:
  /// **'Carregando transações...'**
  String get wallet_import_msg_loading_transactions;

  /// No description provided for @wallet_import_msg_completed.
  ///
  /// In pt, this message translates to:
  /// **'Importação concluída ✓'**
  String get wallet_import_msg_completed;

  /// No description provided for @wallet_import_msg_synced.
  ///
  /// In pt, this message translates to:
  /// **'{name} sincronizado ✓'**
  String wallet_import_msg_synced(String name);

  /// No description provided for @wallet_import_msg_resynced.
  ///
  /// In pt, this message translates to:
  /// **'{name} - resincronizado...'**
  String wallet_import_msg_resynced(String name);

  /// No description provided for @wallet_import_datasource_liquid.
  ///
  /// In pt, this message translates to:
  /// **'Liquid Network'**
  String get wallet_import_datasource_liquid;

  /// No description provided for @wallet_import_datasource_bitcoin.
  ///
  /// In pt, this message translates to:
  /// **'Bitcoin'**
  String get wallet_import_datasource_bitcoin;

  /// No description provided for @wallet_import_datasource_lightning.
  ///
  /// In pt, this message translates to:
  /// **'Lightning'**
  String get wallet_import_datasource_lightning;

  /// No description provided for @wallet_import_error_reconnecting.
  ///
  /// In pt, this message translates to:
  /// **'Tentando reconectar...'**
  String get wallet_import_error_reconnecting;

  /// No description provided for @wallet_import_error_load_data.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar dados'**
  String get wallet_import_error_load_data;

  /// No description provided for @wallet_import_error_connection.
  ///
  /// In pt, this message translates to:
  /// **'Erro de conexão'**
  String get wallet_import_error_connection;

  /// No description provided for @wallet_import_error_servers.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao conectar servidores'**
  String get wallet_import_error_servers;

  /// No description provided for @wallet_import_error_servers_unavailable.
  ///
  /// In pt, this message translates to:
  /// **'Servidores indisponíveis'**
  String get wallet_import_error_servers_unavailable;

  /// No description provided for @wallet_import_error_generic.
  ///
  /// In pt, this message translates to:
  /// **'Erro na importação'**
  String get wallet_import_error_generic;

  /// No description provided for @wallet_import_error_occurred.
  ///
  /// In pt, this message translates to:
  /// **'Ocorreu um erro'**
  String get wallet_import_error_occurred;

  /// No description provided for @wallet_import_error_reconnecting_count.
  ///
  /// In pt, this message translates to:
  /// **'Reconectando ({current}/{max})'**
  String wallet_import_error_reconnecting_count(String current, String max);

  /// No description provided for @wallet_import_error_reconnecting_servers.
  ///
  /// In pt, this message translates to:
  /// **'Tentando reconectar aos servidores...'**
  String get wallet_import_error_reconnecting_servers;

  /// No description provided for @wallet_import_error_no_connection.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível conectar aos servidores.\nVerifique sua conexão e tente novamente.'**
  String get wallet_import_error_no_connection;

  /// No description provided for @wallet_import_error_servers_long.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao conectar aos servidores.\nTente novamente.'**
  String get wallet_import_error_servers_long;

  /// No description provided for @wallet_import_error_internet.
  ///
  /// In pt, this message translates to:
  /// **'Erro de conexão.\nVerifique sua internet.'**
  String get wallet_import_error_internet;

  /// No description provided for @wallet_import_error_wallet_data.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar dados da carteira.'**
  String get wallet_import_error_wallet_data;

  /// No description provided for @wallet_import_error_unknown.
  ///
  /// In pt, this message translates to:
  /// **'Erro desconhecido'**
  String get wallet_import_error_unknown;

  /// No description provided for @send_pix_appbar.
  ///
  /// In pt, this message translates to:
  /// **'Enviar PIX'**
  String get send_pix_appbar;

  /// No description provided for @send_pix_qr_title.
  ///
  /// In pt, this message translates to:
  /// **'Escanear QR Code PIX'**
  String get send_pix_qr_title;

  /// No description provided for @send_pix_empty_key_error.
  ///
  /// In pt, this message translates to:
  /// **'Digite ou escaneie uma chave PIX'**
  String get send_pix_empty_key_error;

  /// No description provided for @send_pix_insert_key.
  ///
  /// In pt, this message translates to:
  /// **'Insira a chave PIX'**
  String get send_pix_insert_key;

  /// No description provided for @send_pix_paste_or_scan.
  ///
  /// In pt, this message translates to:
  /// **'Cole a chave ou escaneie o QR Code'**
  String get send_pix_paste_or_scan;

  /// No description provided for @send_pix_key_label.
  ///
  /// In pt, this message translates to:
  /// **'Chave PIX'**
  String get send_pix_key_label;

  /// No description provided for @send_pix_key_hint.
  ///
  /// In pt, this message translates to:
  /// **'exemplo@email.com ou chave aleatória'**
  String get send_pix_key_hint;

  /// No description provided for @send_pix_accepted_types.
  ///
  /// In pt, this message translates to:
  /// **'Tipos de chave aceitos:'**
  String get send_pix_accepted_types;

  /// No description provided for @send_pix_type_email.
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get send_pix_type_email;

  /// No description provided for @send_pix_type_phone.
  ///
  /// In pt, this message translates to:
  /// **'Telefone'**
  String get send_pix_type_phone;

  /// No description provided for @send_pix_type_cpf_cnpj.
  ///
  /// In pt, this message translates to:
  /// **'CPF/CNPJ'**
  String get send_pix_type_cpf_cnpj;

  /// No description provided for @send_pix_type_random.
  ///
  /// In pt, this message translates to:
  /// **'Chave aleatória'**
  String get send_pix_type_random;

  /// No description provided for @send_pix_lightning_info.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento instantâneo usando Lightning Network'**
  String get send_pix_lightning_info;

  /// No description provided for @swap_success_title.
  ///
  /// In pt, this message translates to:
  /// **'Swap Realizado!'**
  String get swap_success_title;

  /// No description provided for @swap_success_body.
  ///
  /// In pt, this message translates to:
  /// **'Sua transação foi processada com sucesso, em instantes o saldo estará disponível na sua carteira.'**
  String get swap_success_body;

  /// No description provided for @swap_success_dialog_txid_copied.
  ///
  /// In pt, this message translates to:
  /// **'TX ID copiado!'**
  String get swap_success_dialog_txid_copied;

  /// No description provided for @send_pix_success_title.
  ///
  /// In pt, this message translates to:
  /// **'PIX Enviado!'**
  String get send_pix_success_title;

  /// No description provided for @send_pix_success_body.
  ///
  /// In pt, this message translates to:
  /// **'Seu pagamento PIX foi realizado com sucesso!'**
  String get send_pix_success_body;

  /// No description provided for @send_pix_success_value_sent.
  ///
  /// In pt, this message translates to:
  /// **'Valor enviado'**
  String get send_pix_success_value_sent;

  /// No description provided for @send_pix_success_recipient_info.
  ///
  /// In pt, this message translates to:
  /// **'O destinatário já pode verificar o recebimento do PIX.'**
  String get send_pix_success_recipient_info;

  /// No description provided for @pix_deposit_status_pending_label.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento Pendente'**
  String get pix_deposit_status_pending_label;

  /// No description provided for @pix_deposit_status_under_review_label.
  ///
  /// In pt, this message translates to:
  /// **'Revisão bancária'**
  String get pix_deposit_status_under_review_label;

  /// No description provided for @pix_deposit_status_processing_1_2_label.
  ///
  /// In pt, this message translates to:
  /// **'Processando 1/2'**
  String get pix_deposit_status_processing_1_2_label;

  /// No description provided for @pix_deposit_status_under_analysis_label.
  ///
  /// In pt, this message translates to:
  /// **'Em análise'**
  String get pix_deposit_status_under_analysis_label;

  /// No description provided for @pix_deposit_status_processing_2_2_label.
  ///
  /// In pt, this message translates to:
  /// **'Processando 2/2'**
  String get pix_deposit_status_processing_2_2_label;

  /// No description provided for @pix_deposit_status_finished_label.
  ///
  /// In pt, this message translates to:
  /// **'Enviado'**
  String get pix_deposit_status_finished_label;

  /// No description provided for @pix_deposit_status_expired_label.
  ///
  /// In pt, this message translates to:
  /// **'Expirado'**
  String get pix_deposit_status_expired_label;

  /// No description provided for @pix_deposit_status_refunded_label.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento estornado'**
  String get pix_deposit_status_refunded_label;

  /// No description provided for @pix_deposit_status_med_label.
  ///
  /// In pt, this message translates to:
  /// **'Contestado - MED'**
  String get pix_deposit_status_med_label;

  /// No description provided for @pix_deposit_status_processing_refund_1_2_label.
  ///
  /// In pt, this message translates to:
  /// **'Estornando 1/2'**
  String get pix_deposit_status_processing_refund_1_2_label;

  /// No description provided for @pix_deposit_status_processing_refund_2_2_label.
  ///
  /// In pt, this message translates to:
  /// **'Estornando 2/2'**
  String get pix_deposit_status_processing_refund_2_2_label;

  /// No description provided for @pix_deposit_status_completed_label.
  ///
  /// In pt, this message translates to:
  /// **'Concluído'**
  String get pix_deposit_status_completed_label;

  /// No description provided for @pix_deposit_status_unknown_label.
  ///
  /// In pt, this message translates to:
  /// **'Revisão manual'**
  String get pix_deposit_status_unknown_label;

  /// No description provided for @pix_deposit_status_pending_plural.
  ///
  /// In pt, this message translates to:
  /// **'Pagamentos Pendentes'**
  String get pix_deposit_status_pending_plural;

  /// No description provided for @pix_deposit_status_under_review_plural.
  ///
  /// In pt, this message translates to:
  /// **'Em Análise'**
  String get pix_deposit_status_under_review_plural;

  /// No description provided for @pix_deposit_status_processing_plural.
  ///
  /// In pt, this message translates to:
  /// **'Processando'**
  String get pix_deposit_status_processing_plural;

  /// No description provided for @pix_deposit_status_in_transit_plural.
  ///
  /// In pt, this message translates to:
  /// **'A caminho'**
  String get pix_deposit_status_in_transit_plural;

  /// No description provided for @pix_deposit_status_under_analysis_plural.
  ///
  /// In pt, this message translates to:
  /// **'Em análise'**
  String get pix_deposit_status_under_analysis_plural;

  /// No description provided for @pix_deposit_status_finished_plural.
  ///
  /// In pt, this message translates to:
  /// **'Enviados'**
  String get pix_deposit_status_finished_plural;

  /// No description provided for @pix_deposit_status_expired_plural.
  ///
  /// In pt, this message translates to:
  /// **'Expirados'**
  String get pix_deposit_status_expired_plural;

  /// No description provided for @pix_deposit_status_refunded_plural.
  ///
  /// In pt, this message translates to:
  /// **'Pagamentos estornados'**
  String get pix_deposit_status_refunded_plural;

  /// No description provided for @pix_deposit_status_processing_refunds_plural.
  ///
  /// In pt, this message translates to:
  /// **'Processando estornos'**
  String get pix_deposit_status_processing_refunds_plural;

  /// No description provided for @pix_deposit_status_completed_plural.
  ///
  /// In pt, this message translates to:
  /// **'Concluídos'**
  String get pix_deposit_status_completed_plural;

  /// No description provided for @swap_error_processing.
  ///
  /// In pt, this message translates to:
  /// **'Aguarde alguns instantes antes de realizar outro swap. Sua transação anterior ainda está sendo processada.'**
  String get swap_error_processing;

  /// No description provided for @swap_error_insufficient_balance_detailed.
  ///
  /// In pt, this message translates to:
  /// **'Saldo insuficiente para este swap. Disponível: {available} sats. Necessário (enviado + taxas): {required} sats.'**
  String swap_error_insufficient_balance_detailed(int available, int required);

  /// No description provided for @swap_error_no_active_quote.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum quote ativo'**
  String get swap_error_no_active_quote;

  /// No description provided for @swap_error_timeout.
  ///
  /// In pt, this message translates to:
  /// **'Timeout: A operação demorou muito. Tente novamente.'**
  String get swap_error_timeout;

  /// No description provided for @swap_error_unexpected.
  ///
  /// In pt, this message translates to:
  /// **'Erro inesperado: {error}'**
  String swap_error_unexpected(String error);

  /// No description provided for @tx_refund_failed_title.
  ///
  /// In pt, this message translates to:
  /// **'Transação Falhada'**
  String get tx_refund_failed_title;

  /// No description provided for @tx_refund_failed_body.
  ///
  /// In pt, this message translates to:
  /// **'Sua transação de peg-in não pode ser concluída. Clicando em OK, os seus bitcoins serão restituídos para sua carteira onchain.'**
  String get tx_refund_failed_body;

  /// No description provided for @tx_refund_status_label.
  ///
  /// In pt, this message translates to:
  /// **'Status'**
  String get tx_refund_status_label;

  /// No description provided for @tx_refund_status_failed.
  ///
  /// In pt, this message translates to:
  /// **'Falhada'**
  String get tx_refund_status_failed;

  /// No description provided for @tx_refund_address_label.
  ///
  /// In pt, this message translates to:
  /// **'Endereço Bitcoin para Reembolso'**
  String get tx_refund_address_label;

  /// No description provided for @tx_refund_address_hint.
  ///
  /// In pt, this message translates to:
  /// **'Insira o endereço Bitcoin'**
  String get tx_refund_address_hint;

  /// No description provided for @tx_refund_address_auto.
  ///
  /// In pt, this message translates to:
  /// **'Endereço gerado automaticamente da sua carteira'**
  String get tx_refund_address_auto;

  /// No description provided for @tx_refund_fees_fallback_warning.
  ///
  /// In pt, this message translates to:
  /// **'Usando taxas estimadas (API temporariamente indisponível)'**
  String get tx_refund_fees_fallback_warning;

  /// No description provided for @tx_refund_screen_deprecated.
  ///
  /// In pt, this message translates to:
  /// **'Esta tela está obsoleta. Por favor, use o novo fluxo de estorno.'**
  String get tx_refund_screen_deprecated;

  /// No description provided for @tx_refund_dialog_title.
  ///
  /// In pt, this message translates to:
  /// **'Reembolso Iniciado'**
  String get tx_refund_dialog_title;

  /// No description provided for @tx_refund_dialog_body.
  ///
  /// In pt, this message translates to:
  /// **'Seu reembolso foi processado com sucesso!'**
  String get tx_refund_dialog_body;

  /// No description provided for @tx_refund_dialog_txid_label.
  ///
  /// In pt, this message translates to:
  /// **'TX ID:'**
  String get tx_refund_dialog_txid_label;

  /// No description provided for @human_verif_success_title.
  ///
  /// In pt, this message translates to:
  /// **'Humanidade Confirmada!'**
  String get human_verif_success_title;

  /// No description provided for @human_verif_success_body.
  ///
  /// In pt, this message translates to:
  /// **'Sua identidade foi verificada com sucesso. Agora você pode utilizar todos os recursos da plataforma.'**
  String get human_verif_success_body;

  /// No description provided for @human_verif_success_card_title.
  ///
  /// In pt, this message translates to:
  /// **'Verificação completa'**
  String get human_verif_success_card_title;

  /// No description provided for @human_verif_success_card_body.
  ///
  /// In pt, this message translates to:
  /// **'Você é uma pessoa real'**
  String get human_verif_success_card_body;

  /// No description provided for @human_verif_success_refund_info.
  ///
  /// In pt, this message translates to:
  /// **'Seu PIX de R\$ 1,00 foi devolvido com sucesso.'**
  String get human_verif_success_refund_info;

  /// No description provided for @pix_received_title.
  ///
  /// In pt, this message translates to:
  /// **'PIX Recebido!'**
  String get pix_received_title;

  /// No description provided for @pix_received_body.
  ///
  /// In pt, this message translates to:
  /// **'Seu depósito está sendo processado'**
  String get pix_received_body;

  /// No description provided for @pix_deposit_id_label.
  ///
  /// In pt, this message translates to:
  /// **'ID do Depósito'**
  String get pix_deposit_id_label;

  /// No description provided for @pix_main_tab_receive.
  ///
  /// In pt, this message translates to:
  /// **'Receber'**
  String get pix_main_tab_receive;

  /// No description provided for @pix_main_tab_send.
  ///
  /// In pt, this message translates to:
  /// **'Enviar'**
  String get pix_main_tab_send;

  /// No description provided for @pix_info_title.
  ///
  /// In pt, this message translates to:
  /// **'Informações sobre PIX'**
  String get pix_info_title;

  /// No description provided for @pix_info_processing_title.
  ///
  /// In pt, this message translates to:
  /// **'Prazo de processamento'**
  String get pix_info_processing_title;

  /// No description provided for @pix_info_processing_body.
  ///
  /// In pt, this message translates to:
  /// **'Pagamentos via PIX podem ser processados em até 72 horas úteis após a confirmação.'**
  String get pix_info_processing_body;

  /// No description provided for @pix_info_lbtc_variation_title.
  ///
  /// In pt, this message translates to:
  /// **'Variação de câmbio (LBTC)'**
  String get pix_info_lbtc_variation_title;

  /// No description provided for @pix_info_lbtc_variation_body.
  ///
  /// In pt, this message translates to:
  /// **'Ao escolher receber em LBTC, o valor final pode variar devido à cotação do momento da conversão. Você pode receber mais ou menos que o calculado.'**
  String get pix_info_lbtc_variation_body;

  /// No description provided for @pix_info_fees_title.
  ///
  /// In pt, this message translates to:
  /// **'Sobre as taxas'**
  String get pix_info_fees_title;

  /// No description provided for @pix_info_fees_body.
  ///
  /// In pt, this message translates to:
  /// **'As taxas variam conforme o valor da transação. Valores menores têm taxas fixas, valores maiores têm taxas percentuais decrescentes.'**
  String get pix_info_fees_body;

  /// No description provided for @pix_info_fees_button.
  ///
  /// In pt, this message translates to:
  /// **'Ver detalhes das taxas'**
  String get pix_info_fees_button;

  /// No description provided for @pix_limits_title.
  ///
  /// In pt, this message translates to:
  /// **'Limites de Pagamento'**
  String get pix_limits_title;

  /// No description provided for @pix_limits_intro.
  ///
  /// In pt, this message translates to:
  /// **'Entenda como funciona os pagamentos PIX:'**
  String get pix_limits_intro;

  /// No description provided for @pix_limits_initial_label.
  ///
  /// In pt, this message translates to:
  /// **'Limite Inicial'**
  String get pix_limits_initial_label;

  /// No description provided for @pix_limits_initial_value.
  ///
  /// In pt, this message translates to:
  /// **'R\$ 20,00'**
  String get pix_limits_initial_value;

  /// No description provided for @pix_limits_max_label.
  ///
  /// In pt, this message translates to:
  /// **'Limite Máximo'**
  String get pix_limits_max_label;

  /// No description provided for @pix_limits_max_value.
  ///
  /// In pt, this message translates to:
  /// **'R\$ 3.000,00'**
  String get pix_limits_max_value;

  /// No description provided for @pix_limits_explanation.
  ///
  /// In pt, this message translates to:
  /// **'Ao decorrer de pagamentos efetuados, seus limites de transação podem evoluir até o limite máximo de R\$ 3.000,00 por transação, de acordo sua pontuação de confiança junto ao aplicativo da Mooze.'**
  String get pix_limits_explanation;

  /// No description provided for @pix_limits_trust_info.
  ///
  /// In pt, this message translates to:
  /// **'Consulte seus níveis de confiança no menu, opção \"Nível da carteira\".'**
  String get pix_limits_trust_info;

  /// No description provided for @pix_limits_increase_info.
  ///
  /// In pt, this message translates to:
  /// **'Para aumentar seus limites, o uso frequente de pagamentos vai elevar seus limites gradualmente.'**
  String get pix_limits_increase_info;

  /// No description provided for @pix_limits_button_understood_countdown.
  ///
  /// In pt, this message translates to:
  /// **'Entendi ({seconds})'**
  String pix_limits_button_understood_countdown(int seconds);

  /// No description provided for @swap_pending_dialog_title.
  ///
  /// In pt, this message translates to:
  /// **'Transação Pendente'**
  String get swap_pending_dialog_title;

  /// No description provided for @refund_mock_simulation_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro simulado: Falha na transmissão da transação'**
  String get refund_mock_simulation_error;

  /// No description provided for @merchant_welcome_title.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo ao Modo Comerciante!'**
  String get merchant_welcome_title;

  /// No description provided for @merchant_welcome_body.
  ///
  /// In pt, this message translates to:
  /// **'Aqui você tem um mini PDV: cadastre itens, some valores e cobre seus clientes de forma rápida.'**
  String get merchant_welcome_body;

  /// No description provided for @merchant_step_enter_value_title.
  ///
  /// In pt, this message translates to:
  /// **'Digite o valor desejado'**
  String get merchant_step_enter_value_title;

  /// No description provided for @merchant_step_enter_value_body.
  ///
  /// In pt, this message translates to:
  /// **'Vamos começar inserindo um valor de R\$ 20,00 usando o teclado abaixo.'**
  String get merchant_step_enter_value_body;

  /// No description provided for @merchant_step_add_value_title.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar valor'**
  String get merchant_step_add_value_title;

  /// No description provided for @merchant_step_add_value_body.
  ///
  /// In pt, this message translates to:
  /// **'Agora toque no botão \'+\' verde para adicionar o valor à lista de itens.'**
  String get merchant_step_add_value_body;

  /// No description provided for @merchant_step_items_tab_title.
  ///
  /// In pt, this message translates to:
  /// **'Aba de Itens'**
  String get merchant_step_items_tab_title;

  /// No description provided for @merchant_step_items_tab_body.
  ///
  /// In pt, this message translates to:
  /// **'Toque aqui para ver seus produtos cadastrados e criar novos itens.'**
  String get merchant_step_items_tab_body;

  /// No description provided for @merchant_step_create_product_title.
  ///
  /// In pt, this message translates to:
  /// **'Criar produto'**
  String get merchant_step_create_product_title;

  /// No description provided for @merchant_step_create_product_body.
  ///
  /// In pt, this message translates to:
  /// **'Toque no botão \'+\' para criar automaticamente o produto \'Produto 01\' com preço de R\$ 21,00.'**
  String get merchant_step_create_product_body;

  /// No description provided for @merchant_step_edit_delete_title.
  ///
  /// In pt, this message translates to:
  /// **'Editar e Deletar produtos'**
  String get merchant_step_edit_delete_title;

  /// No description provided for @merchant_step_edit_delete_body.
  ///
  /// In pt, this message translates to:
  /// **'Arraste este produto da direita para a esquerda para ver as opções de editar e excluir.'**
  String get merchant_step_edit_delete_body;

  /// No description provided for @merchant_step_finalize_title.
  ///
  /// In pt, this message translates to:
  /// **'Finalizar venda'**
  String get merchant_step_finalize_title;

  /// No description provided for @merchant_step_finalize_body.
  ///
  /// In pt, this message translates to:
  /// **'Quando tiver itens no carrinho (mínimo R\$ 20,00), toque aqui para finalizar a venda.'**
  String get merchant_step_finalize_body;

  /// No description provided for @merchant_step_clear_cart_title.
  ///
  /// In pt, this message translates to:
  /// **'Limpar carrinho'**
  String get merchant_step_clear_cart_title;

  /// No description provided for @merchant_step_clear_cart_body.
  ///
  /// In pt, this message translates to:
  /// **'Se quiser começar do zero, toque aqui para limpar todos os itens do carrinho.'**
  String get merchant_step_clear_cart_body;

  /// No description provided for @merchant_tutorial_done_title.
  ///
  /// In pt, this message translates to:
  /// **'Tutorial Concluído!'**
  String get merchant_tutorial_done_title;

  /// No description provided for @merchant_tutorial_done_body.
  ///
  /// In pt, this message translates to:
  /// **'Agora você já sabe usar todas as funcionalidades do Modo Comerciante. Pronto para começar?'**
  String get merchant_tutorial_done_body;

  /// No description provided for @merchant_default_product_name.
  ///
  /// In pt, this message translates to:
  /// **'Produto 01'**
  String get merchant_default_product_name;

  /// No description provided for @merchant_loose_value.
  ///
  /// In pt, this message translates to:
  /// **'Valor Avulso'**
  String get merchant_loose_value;

  /// No description provided for @merchant_add_item_first.
  ///
  /// In pt, this message translates to:
  /// **'Adicione itens ao carrinho antes de finalizar a venda'**
  String get merchant_add_item_first;

  /// No description provided for @merchant_min_sale_value.
  ///
  /// In pt, this message translates to:
  /// **'O valor mínimo para finalizar a venda é de R\$ 20,00'**
  String get merchant_min_sale_value;

  /// No description provided for @merchant_add_product_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao adicionar produto: {error}'**
  String merchant_add_product_error(String error);

  /// No description provided for @merchant_update_product_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao atualizar produto: {error}'**
  String merchant_update_product_error(String error);

  /// No description provided for @merchant_remove_product_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao remover produto: {error}'**
  String merchant_remove_product_error(String error);

  /// No description provided for @merchant_tab_keypad.
  ///
  /// In pt, this message translates to:
  /// **'Teclado'**
  String get merchant_tab_keypad;

  /// No description provided for @merchant_tab_items.
  ///
  /// In pt, this message translates to:
  /// **'Itens'**
  String get merchant_tab_items;

  /// No description provided for @merchant_load_products_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar produtos'**
  String get merchant_load_products_error;

  /// No description provided for @merchant_mode_header.
  ///
  /// In pt, this message translates to:
  /// **'Modo comerciante'**
  String get merchant_mode_header;

  /// No description provided for @merchant_clear_cart.
  ///
  /// In pt, this message translates to:
  /// **'Limpar'**
  String get merchant_clear_cart;

  /// No description provided for @merchant_no_products_title.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum produto cadastrado'**
  String get merchant_no_products_title;

  /// No description provided for @merchant_no_products_body.
  ///
  /// In pt, this message translates to:
  /// **'Comece adicionando seu primeiro produto\nclicando no botão + abaixo'**
  String get merchant_no_products_body;

  /// No description provided for @merchant_delete_item_title.
  ///
  /// In pt, this message translates to:
  /// **'Deletar item'**
  String get merchant_delete_item_title;

  /// No description provided for @merchant_delete_item_confirm.
  ///
  /// In pt, this message translates to:
  /// **'Deseja realmente deletar \"{name}\"?'**
  String merchant_delete_item_confirm(String name);

  /// No description provided for @merchant_delete_action.
  ///
  /// In pt, this message translates to:
  /// **'Deletar'**
  String get merchant_delete_action;

  /// No description provided for @merchant_add_product_title.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Produto'**
  String get merchant_add_product_title;

  /// No description provided for @merchant_edit_product_title.
  ///
  /// In pt, this message translates to:
  /// **'Editar Produto'**
  String get merchant_edit_product_title;

  /// No description provided for @merchant_product_name_label.
  ///
  /// In pt, this message translates to:
  /// **'Nome do produto'**
  String get merchant_product_name_label;

  /// No description provided for @merchant_product_name_hint.
  ///
  /// In pt, this message translates to:
  /// **'Digite o nome do produto'**
  String get merchant_product_name_hint;

  /// No description provided for @merchant_price_label.
  ///
  /// In pt, this message translates to:
  /// **'Preço'**
  String get merchant_price_label;

  /// No description provided for @merchant_add_action.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get merchant_add_action;

  /// No description provided for @merchant_min_sale_short.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo R\$ 20,00'**
  String get merchant_min_sale_short;

  /// No description provided for @merchant_finalize_sale_button.
  ///
  /// In pt, this message translates to:
  /// **'Finalizar Venda'**
  String get merchant_finalize_sale_button;

  /// No description provided for @merchant_charge_receive_title.
  ///
  /// In pt, this message translates to:
  /// **'Receber'**
  String get merchant_charge_receive_title;

  /// No description provided for @merchant_charge_instruction_prefix.
  ///
  /// In pt, this message translates to:
  /// **'Escolha o ativo que deseja receber na '**
  String get merchant_charge_instruction_prefix;

  /// No description provided for @merchant_limit_daily.
  ///
  /// In pt, this message translates to:
  /// **'Limite diário'**
  String get merchant_limit_daily;

  /// No description provided for @merchant_limit_per_transaction.
  ///
  /// In pt, this message translates to:
  /// **'Por transação'**
  String get merchant_limit_per_transaction;

  /// No description provided for @merchant_limit_min.
  ///
  /// In pt, this message translates to:
  /// **'Valor mínimo'**
  String get merchant_limit_min;

  /// No description provided for @merchant_limits_load_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar limites'**
  String get merchant_limits_load_error;

  /// No description provided for @merchant_generate_qr.
  ///
  /// In pt, this message translates to:
  /// **'Gerar QR Code'**
  String get merchant_generate_qr;

  /// No description provided for @merchant_validation_min_amount.
  ///
  /// In pt, this message translates to:
  /// **'Valor mínimo: R\$ {amount}'**
  String merchant_validation_min_amount(String amount);

  /// No description provided for @merchant_validation_max_per_tx.
  ///
  /// In pt, this message translates to:
  /// **'Limite por transação: R\$ {amount}'**
  String merchant_validation_max_per_tx(String amount);

  /// No description provided for @merchant_exit_ready.
  ///
  /// In pt, this message translates to:
  /// **'Pronto para vender?'**
  String get merchant_exit_ready;

  /// No description provided for @merchant_exit_new_payment.
  ///
  /// In pt, this message translates to:
  /// **'Receber novo pagamento'**
  String get merchant_exit_new_payment;

  /// No description provided for @merchant_exit_back_to_wallet.
  ///
  /// In pt, this message translates to:
  /// **'Quer acessar a carteira?'**
  String get merchant_exit_back_to_wallet;

  /// No description provided for @merchant_items_section.
  ///
  /// In pt, this message translates to:
  /// **'Itens'**
  String get merchant_items_section;

  /// No description provided for @merchant_qty_prefix.
  ///
  /// In pt, this message translates to:
  /// **'x{qty}'**
  String merchant_qty_prefix(int qty);

  /// No description provided for @common_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro'**
  String get common_error;

  /// No description provided for @error_open_browser_link_copied.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir o navegador. Link copiado para área de transferência.'**
  String get error_open_browser_link_copied;

  /// No description provided for @pix_you_will_receive.
  ///
  /// In pt, this message translates to:
  /// **'Você receberá'**
  String get pix_you_will_receive;

  /// No description provided for @pix_of_amount.
  ///
  /// In pt, this message translates to:
  /// **'de R\$ {amount}'**
  String pix_of_amount(String amount);

  /// No description provided for @pix_fees_applied.
  ///
  /// In pt, this message translates to:
  /// **'Taxas aplicadas'**
  String get pix_fees_applied;

  /// No description provided for @pix_fee_fixed_label.
  ///
  /// In pt, this message translates to:
  /// **'Taxa fixa'**
  String get pix_fee_fixed_label;

  /// No description provided for @pix_fee_fixed_mooze.
  ///
  /// In pt, this message translates to:
  /// **'Taxa fixa (Mooze)'**
  String get pix_fee_fixed_mooze;

  /// No description provided for @pix_fee_fixed_for_small_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Para valores até R\$ 55'**
  String get pix_fee_fixed_for_small_subtitle;

  /// No description provided for @pix_fee_mooze.
  ///
  /// In pt, this message translates to:
  /// **'Taxa Mooze'**
  String get pix_fee_mooze;

  /// No description provided for @pix_fee_processor.
  ///
  /// In pt, this message translates to:
  /// **'Taxa da processadora'**
  String get pix_fee_processor;

  /// No description provided for @pix_fee_referral_discount.
  ///
  /// In pt, this message translates to:
  /// **'Já com 15% de desconto aplicado'**
  String get pix_fee_referral_discount;

  /// No description provided for @pix_fee_savings.
  ///
  /// In pt, this message translates to:
  /// **'Você economizou R\$ {amount} com o código de indicação!'**
  String pix_fee_savings(String amount);

  /// No description provided for @pix_waiting_amount_title.
  ///
  /// In pt, this message translates to:
  /// **'Aguardando valor'**
  String get pix_waiting_amount_title;

  /// No description provided for @pix_waiting_amount_body.
  ///
  /// In pt, this message translates to:
  /// **'Digite um valor válido para ver\no resumo da transação'**
  String get pix_waiting_amount_body;

  /// No description provided for @pix_payment_screen_title.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento PIX'**
  String get pix_payment_screen_title;

  /// No description provided for @pix_qr_generation_error.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao gerar QR code: {error}'**
  String pix_qr_generation_error(String error);

  /// No description provided for @pix_payment_expired_body.
  ///
  /// In pt, this message translates to:
  /// **'O tempo para realizar o pagamento expirou. Por favor, gere um novo PIX.'**
  String get pix_payment_expired_body;

  /// No description provided for @pix_fees_screen_header_title.
  ///
  /// In pt, this message translates to:
  /// **'Taxas Transparentes'**
  String get pix_fees_screen_header_title;

  /// No description provided for @pix_fees_screen_header_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Conheça nossas taxas de depósito via PIX'**
  String get pix_fees_screen_header_subtitle;

  /// No description provided for @pix_fees_screen_fixed_fee_title.
  ///
  /// In pt, this message translates to:
  /// **'Taxa Fixa'**
  String get pix_fees_screen_fixed_fee_title;

  /// No description provided for @pix_fees_screen_fixed_fee_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Para depósitos até R\$ 55,00'**
  String get pix_fees_screen_fixed_fee_subtitle;

  /// No description provided for @pix_fees_screen_fixed_fee_breakdown.
  ///
  /// In pt, this message translates to:
  /// **'R\$ 1,00 Mooze + R\$ 1,00 Processadora'**
  String get pix_fees_screen_fixed_fee_breakdown;

  /// No description provided for @pix_fees_screen_percentage_title.
  ///
  /// In pt, this message translates to:
  /// **'Taxas Percentuais'**
  String get pix_fees_screen_percentage_title;

  /// No description provided for @pix_fees_screen_percentage_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Para depósitos acima de R\$ 55,00'**
  String get pix_fees_screen_percentage_subtitle;

  /// No description provided for @pix_fees_screen_tab_no_discount.
  ///
  /// In pt, this message translates to:
  /// **'Sem Desconto'**
  String get pix_fees_screen_tab_no_discount;

  /// No description provided for @pix_fees_screen_tab_with_discount.
  ///
  /// In pt, this message translates to:
  /// **'Com Desconto'**
  String get pix_fees_screen_tab_with_discount;

  /// No description provided for @pix_fees_screen_fee_range_before.
  ///
  /// In pt, this message translates to:
  /// **'antes {percentage}%'**
  String pix_fees_screen_fee_range_before(String percentage);

  /// No description provided for @pix_fees_screen_fee_range_label.
  ///
  /// In pt, this message translates to:
  /// **'R\$ {min} até R\$ {max}'**
  String pix_fees_screen_fee_range_label(String min, String max);

  /// No description provided for @pix_fees_screen_referral_title.
  ///
  /// In pt, this message translates to:
  /// **'Bônus de Indicação'**
  String get pix_fees_screen_referral_title;

  /// No description provided for @pix_fees_screen_referral_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Use um código de indicação'**
  String get pix_fees_screen_referral_subtitle;

  /// No description provided for @pix_fees_screen_referral_discount.
  ///
  /// In pt, this message translates to:
  /// **'15% de desconto'**
  String get pix_fees_screen_referral_discount;

  /// No description provided for @pix_fees_screen_referral_disclaimer.
  ///
  /// In pt, this message translates to:
  /// **'Todas as taxas percentuais são multiplicadas por 0,85'**
  String get pix_fees_screen_referral_disclaimer;

  /// No description provided for @pix_fees_screen_examples_title.
  ///
  /// In pt, this message translates to:
  /// **'Exemplos Práticos'**
  String get pix_fees_screen_examples_title;

  /// No description provided for @pix_fees_screen_example_deposit.
  ///
  /// In pt, this message translates to:
  /// **'Depósito'**
  String get pix_fees_screen_example_deposit;

  /// No description provided for @pix_fees_screen_example_receive.
  ///
  /// In pt, this message translates to:
  /// **'Você recebe'**
  String get pix_fees_screen_example_receive;

  /// No description provided for @pix_fees_screen_example_with_referral.
  ///
  /// In pt, this message translates to:
  /// **'Com indicação'**
  String get pix_fees_screen_example_with_referral;

  /// No description provided for @pix_fees_screen_example_fee_label.
  ///
  /// In pt, this message translates to:
  /// **'Taxa'**
  String get pix_fees_screen_example_fee_label;

  /// No description provided for @pix_fees_screen_fee_calculation_of.
  ///
  /// In pt, this message translates to:
  /// **'{percentage}% de R\$ {amount}'**
  String pix_fees_screen_fee_calculation_of(String percentage, String amount);

  /// No description provided for @pix_fees_screen_footer_title.
  ///
  /// In pt, this message translates to:
  /// **'Informações Importantes'**
  String get pix_fees_screen_footer_title;

  /// No description provided for @pix_fees_screen_footer_info_1.
  ///
  /// In pt, this message translates to:
  /// **'A taxa fixa de R\$ 2,00 se aplica apenas a depósitos até R\$ 55,00'**
  String get pix_fees_screen_footer_info_1;

  /// No description provided for @pix_fees_screen_footer_info_2.
  ///
  /// In pt, this message translates to:
  /// **'Para valores acima de R\$ 55,00, as taxas percentuais são aplicadas'**
  String get pix_fees_screen_footer_info_2;

  /// No description provided for @pix_fees_screen_footer_info_3.
  ///
  /// In pt, this message translates to:
  /// **'O desconto de 15% com indicação se aplica apenas às taxas percentuais'**
  String get pix_fees_screen_footer_info_3;

  /// No description provided for @pix_fees_screen_footer_info_4.
  ///
  /// In pt, this message translates to:
  /// **'As taxas são deduzidas automaticamente do valor depositado'**
  String get pix_fees_screen_footer_info_4;

  /// No description provided for @tx_detail_blockchain.
  ///
  /// In pt, this message translates to:
  /// **'Blockchain'**
  String get tx_detail_blockchain;

  /// No description provided for @tx_detail_swap_label.
  ///
  /// In pt, this message translates to:
  /// **'Troca entre ativos'**
  String get tx_detail_swap_label;

  /// No description provided for @tx_detail_sent.
  ///
  /// In pt, this message translates to:
  /// **'Enviado'**
  String get tx_detail_sent;

  /// No description provided for @tx_detail_expected.
  ///
  /// In pt, this message translates to:
  /// **'Esperado'**
  String get tx_detail_expected;

  /// No description provided for @tx_type_redeposit.
  ///
  /// In pt, this message translates to:
  /// **'Auto-redepósito'**
  String get tx_type_redeposit;

  /// No description provided for @tx_type_unknown.
  ///
  /// In pt, this message translates to:
  /// **'Desconhecido'**
  String get tx_type_unknown;

  /// No description provided for @tx_status_failed_processed.
  ///
  /// In pt, this message translates to:
  /// **'Reembolso Processado'**
  String get tx_status_failed_processed;

  /// No description provided for @tx_status_refundable_pending.
  ///
  /// In pt, this message translates to:
  /// **'Aguardando Reembolso'**
  String get tx_status_refundable_pending;

  /// No description provided for @tx_status_confirmed_fem.
  ///
  /// In pt, this message translates to:
  /// **'Confirmada'**
  String get tx_status_confirmed_fem;

  /// No description provided for @tx_detail_confirmations.
  ///
  /// In pt, this message translates to:
  /// **'Confirmações'**
  String get tx_detail_confirmations;

  /// No description provided for @tx_detail_confirmations_full.
  ///
  /// In pt, this message translates to:
  /// **'6+ confirmações'**
  String get tx_detail_confirmations_full;

  /// No description provided for @tx_detail_confirmations_progress.
  ///
  /// In pt, this message translates to:
  /// **'{count}/6 confirmações'**
  String tx_detail_confirmations_progress(int count);

  /// No description provided for @tx_detail_preimage_label.
  ///
  /// In pt, this message translates to:
  /// **'Preimagem'**
  String get tx_detail_preimage_label;

  /// No description provided for @tx_detail_preimage_pending.
  ///
  /// In pt, this message translates to:
  /// **'Preimagem pendente: Assim que sua transação for confirmada, a preimagem aparecerá aqui'**
  String get tx_detail_preimage_pending;

  /// No description provided for @tx_detail_submarine_btc_to_lbtc.
  ///
  /// In pt, this message translates to:
  /// **'Swap de rede: Você enviou {from} e receberá {to}. Assim que a transação onchain for confirmada, os fundos aparecerão automaticamente na Liquid Network.'**
  String tx_detail_submarine_btc_to_lbtc(String from, String to);

  /// No description provided for @tx_detail_submarine_lbtc_to_btc.
  ///
  /// In pt, this message translates to:
  /// **'Swap de rede: Você enviou {from} e receberá {to}. Assim que processado, a transação será enviada para a blockchain Bitcoin.'**
  String tx_detail_submarine_lbtc_to_btc(String from, String to);

  /// No description provided for @tx_detail_submarine_generic.
  ///
  /// In pt, this message translates to:
  /// **'Swap de rede: Transação entre diferentes redes. Aguarde a confirmação.'**
  String get tx_detail_submarine_generic;

  /// No description provided for @tx_detail_submarine_default.
  ///
  /// In pt, this message translates to:
  /// **'Esta transação representa uma troca de rede. Assim que confirmada, você receberá os fundos na rede de destino.'**
  String get tx_detail_submarine_default;

  /// No description provided for @tx_detail_request_refund.
  ///
  /// In pt, this message translates to:
  /// **'Solicitar Reembolso'**
  String get tx_detail_request_refund;

  /// No description provided for @tx_detail_request_refund_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Recuperar seus fundos agora'**
  String get tx_detail_request_refund_subtitle;

  /// No description provided for @tx_detail_view_send.
  ///
  /// In pt, this message translates to:
  /// **'Ver Envio'**
  String get tx_detail_view_send;

  /// No description provided for @tx_detail_view_receive.
  ///
  /// In pt, this message translates to:
  /// **'Ver Recebimento'**
  String get tx_detail_view_receive;

  /// No description provided for @tx_detail_validate_payment.
  ///
  /// In pt, this message translates to:
  /// **'Validar Pagamento'**
  String get tx_detail_validate_payment;

  /// No description provided for @tx_detail_verify_preimage.
  ///
  /// In pt, this message translates to:
  /// **'Verificar preimagem'**
  String get tx_detail_verify_preimage;

  /// No description provided for @tx_detail_send_id_label.
  ///
  /// In pt, this message translates to:
  /// **'ID Envio ({chain})'**
  String tx_detail_send_id_label(String chain);

  /// No description provided for @tx_detail_receive_id_label.
  ///
  /// In pt, this message translates to:
  /// **'ID Recebimento ({chain})'**
  String tx_detail_receive_id_label(String chain);

  /// No description provided for @main_settings_title.
  ///
  /// In pt, this message translates to:
  /// **'Ajustes'**
  String get main_settings_title;

  /// No description provided for @main_settings_section_merchant.
  ///
  /// In pt, this message translates to:
  /// **'COMERCIANTE'**
  String get main_settings_section_merchant;

  /// No description provided for @main_settings_section_transactions.
  ///
  /// In pt, this message translates to:
  /// **'TRANSAÇÕES'**
  String get main_settings_section_transactions;

  /// No description provided for @main_settings_section_settings.
  ///
  /// In pt, this message translates to:
  /// **'CONFIGURAÇÕES'**
  String get main_settings_section_settings;

  /// No description provided for @main_settings_section_wallet.
  ///
  /// In pt, this message translates to:
  /// **'CARTEIRA'**
  String get main_settings_section_wallet;

  /// No description provided for @main_settings_section_external_links.
  ///
  /// In pt, this message translates to:
  /// **'LINKS EXTERNOS'**
  String get main_settings_section_external_links;

  /// No description provided for @main_settings_section_fees.
  ///
  /// In pt, this message translates to:
  /// **'TAXAS'**
  String get main_settings_section_fees;

  /// No description provided for @main_settings_section_version.
  ///
  /// In pt, this message translates to:
  /// **'VERSÃO'**
  String get main_settings_section_version;

  /// No description provided for @main_settings_settings_label.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get main_settings_settings_label;

  /// No description provided for @main_settings_wallet_level.
  ///
  /// In pt, this message translates to:
  /// **'Nível da carteira'**
  String get main_settings_wallet_level;

  /// No description provided for @main_settings_pix_fees.
  ///
  /// In pt, this message translates to:
  /// **'Taxas do PIX'**
  String get main_settings_pix_fees;

  /// No description provided for @main_settings_btc_services.
  ///
  /// In pt, this message translates to:
  /// **'Serviços via Bitcoin'**
  String get main_settings_btc_services;

  /// No description provided for @main_settings_support.
  ///
  /// In pt, this message translates to:
  /// **'Suporte'**
  String get main_settings_support;

  /// No description provided for @onboarding_1_title.
  ///
  /// In pt, this message translates to:
  /// **'Seu dinheiro, sob seu controle'**
  String get onboarding_1_title;

  /// No description provided for @onboarding_1_body.
  ///
  /// In pt, this message translates to:
  /// **'Receba, envie e gerencie Bitcoin com privacidade real. Uma carteira feita pra quem valoriza liberdade.'**
  String get onboarding_1_body;

  /// No description provided for @onboarding_2_title.
  ///
  /// In pt, this message translates to:
  /// **'Segurança em primeiro lugar'**
  String get onboarding_2_title;

  /// No description provided for @onboarding_2_body.
  ///
  /// In pt, this message translates to:
  /// **'Sua chave, sua responsabilidade. Proteja seu patrimônio com criptografia e backups locais.'**
  String get onboarding_2_body;

  /// No description provided for @onboarding_3_title.
  ///
  /// In pt, this message translates to:
  /// **'Pronto para começar?'**
  String get onboarding_3_title;

  /// No description provided for @onboarding_3_body.
  ///
  /// In pt, this message translates to:
  /// **'Crie ou importe sua carteira em segundos e assuma o controle do seu Bitcoin.'**
  String get onboarding_3_body;

  /// No description provided for @first_access_create_wallet.
  ///
  /// In pt, this message translates to:
  /// **'Criar Carteira'**
  String get first_access_create_wallet;

  /// No description provided for @first_access_import_wallet.
  ///
  /// In pt, this message translates to:
  /// **'Importar carteira'**
  String get first_access_import_wallet;

  /// No description provided for @first_access_terms_prefix.
  ///
  /// In pt, this message translates to:
  /// **'Eu li e concordo com os '**
  String get first_access_terms_prefix;

  /// No description provided for @first_access_terms_link.
  ///
  /// In pt, this message translates to:
  /// **'Termos e Condições'**
  String get first_access_terms_link;

  /// No description provided for @level_my_levels.
  ///
  /// In pt, this message translates to:
  /// **'Meus Níveis'**
  String get level_my_levels;

  /// No description provided for @level_label.
  ///
  /// In pt, this message translates to:
  /// **'Nível {n}'**
  String level_label(int n);

  /// No description provided for @level_current.
  ///
  /// In pt, this message translates to:
  /// **'Nível atual: '**
  String get level_current;

  /// No description provided for @level_progress.
  ///
  /// In pt, this message translates to:
  /// **'Progresso: {percent}%'**
  String level_progress(int percent);

  /// No description provided for @level_next.
  ///
  /// In pt, this message translates to:
  /// **'Próximo: {name}'**
  String level_next(String name);

  /// No description provided for @level_load_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar nível'**
  String get level_load_error;

  /// No description provided for @level_load_retry.
  ///
  /// In pt, this message translates to:
  /// **'Tente novamente mais tarde.'**
  String get level_load_retry;

  /// No description provided for @level_user_label.
  ///
  /// In pt, this message translates to:
  /// **'Nível de usuário'**
  String get level_user_label;

  /// No description provided for @level_desc_bronze.
  ///
  /// In pt, this message translates to:
  /// **'Comece movimentando pequenos valores e desbloqueie os primeiros benefícios.'**
  String get level_desc_bronze;

  /// No description provided for @level_desc_silver.
  ///
  /// In pt, this message translates to:
  /// **'Quanto mais você gasta, mais sobe de nível. Alcance o nível Prata.'**
  String get level_desc_silver;

  /// No description provided for @level_desc_gold.
  ///
  /// In pt, this message translates to:
  /// **'Nível Gold com limites aumentados para movimentações maiores.'**
  String get level_desc_gold;

  /// No description provided for @level_desc_max.
  ///
  /// In pt, this message translates to:
  /// **'Nível máximo com os maiores limites e benefícios exclusivos.'**
  String get level_desc_max;

  /// No description provided for @wallet_levels_title.
  ///
  /// In pt, this message translates to:
  /// **'Níveis da Carteira'**
  String get wallet_levels_title;

  /// No description provided for @wallet_levels_api_down_title.
  ///
  /// In pt, this message translates to:
  /// **'API Indisponível'**
  String get wallet_levels_api_down_title;

  /// No description provided for @wallet_levels_api_down_body.
  ///
  /// In pt, this message translates to:
  /// **'Os dados podem estar desatualizados. Algumas funcionalidades estão temporariamente indisponíveis.'**
  String get wallet_levels_api_down_body;

  /// No description provided for @wallet_levels_load_error_title.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar níveis da carteira'**
  String get wallet_levels_load_error_title;

  /// No description provided for @wallet_levels_load_error_body.
  ///
  /// In pt, this message translates to:
  /// **'Verifique sua conexão com a internet e tente novamente'**
  String get wallet_levels_load_error_body;

  /// No description provided for @wallet_levels_header_title.
  ///
  /// In pt, this message translates to:
  /// **'Cresça com a Mooze'**
  String get wallet_levels_header_title;

  /// No description provided for @wallet_levels_header_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Quanto mais você movimenta, mais benefícios e limites desbloqueia.'**
  String get wallet_levels_header_subtitle;

  /// No description provided for @wallet_levels_quick_unlock_title.
  ///
  /// In pt, this message translates to:
  /// **'Desbloqueie'**
  String get wallet_levels_quick_unlock_title;

  /// No description provided for @wallet_levels_quick_unlock_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Aumente limites'**
  String get wallet_levels_quick_unlock_subtitle;

  /// No description provided for @wallet_levels_quick_earn_title.
  ///
  /// In pt, this message translates to:
  /// **'Ganhe'**
  String get wallet_levels_quick_earn_title;

  /// No description provided for @wallet_levels_quick_earn_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Benefícios extras'**
  String get wallet_levels_quick_earn_subtitle;

  /// No description provided for @wallet_levels_quick_status_title.
  ///
  /// In pt, this message translates to:
  /// **'Status'**
  String get wallet_levels_quick_status_title;

  /// No description provided for @wallet_levels_quick_status_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Reconhecimento VIP'**
  String get wallet_levels_quick_status_subtitle;

  /// No description provided for @wallet_levels_current_limits_title.
  ///
  /// In pt, this message translates to:
  /// **'Seus Limites Atuais'**
  String get wallet_levels_current_limits_title;

  /// No description provided for @wallet_levels_current_level.
  ///
  /// In pt, this message translates to:
  /// **'Nível: {levelName}'**
  String wallet_levels_current_level(String levelName);

  /// No description provided for @wallet_levels_limit_per_transaction.
  ///
  /// In pt, this message translates to:
  /// **'Por transação'**
  String get wallet_levels_limit_per_transaction;

  /// No description provided for @wallet_levels_limit_daily.
  ///
  /// In pt, this message translates to:
  /// **'Limite diário'**
  String get wallet_levels_limit_daily;

  /// No description provided for @wallet_levels_limit_minimum.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo'**
  String get wallet_levels_limit_minimum;

  /// No description provided for @wallet_levels_next_level_hint.
  ///
  /// In pt, this message translates to:
  /// **'Continue usando para desbloquear o próximo nível!'**
  String get wallet_levels_next_level_hint;

  /// No description provided for @wallet_levels_next_level_hint_named.
  ///
  /// In pt, this message translates to:
  /// **'Continue usando para desbloquear o próximo nível {nextLevelName}!'**
  String wallet_levels_next_level_hint_named(String nextLevelName);

  /// No description provided for @wallet_levels_load_limits_error_title.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar limites'**
  String get wallet_levels_load_limits_error_title;

  /// No description provided for @wallet_levels_load_limits_error_body.
  ///
  /// In pt, this message translates to:
  /// **'Tente novamente mais tarde ou contate o suporte.'**
  String get wallet_levels_load_limits_error_body;

  /// No description provided for @update_available_short.
  ///
  /// In pt, this message translates to:
  /// **'Nova atualização disponível'**
  String get update_available_short;

  /// No description provided for @update_available_body.
  ///
  /// In pt, this message translates to:
  /// **'Atualize para obter melhorias e correções'**
  String get update_available_body;

  /// No description provided for @update_available_button.
  ///
  /// In pt, this message translates to:
  /// **'ATUALIZAR'**
  String get update_available_button;

  /// No description provided for @update_dialog_title.
  ///
  /// In pt, this message translates to:
  /// **'Atualização Disponível'**
  String get update_dialog_title;

  /// No description provided for @update_dialog_body.
  ///
  /// In pt, this message translates to:
  /// **'Uma nova versão do aplicativo está disponível.'**
  String get update_dialog_body;

  /// No description provided for @update_current_version.
  ///
  /// In pt, this message translates to:
  /// **'Versão atual:'**
  String get update_current_version;

  /// No description provided for @update_new_version.
  ///
  /// In pt, this message translates to:
  /// **'Nova versão:'**
  String get update_new_version;

  /// No description provided for @update_dialog_recommend.
  ///
  /// In pt, this message translates to:
  /// **'Recomendamos atualizar para obter as melhorias mais recentes e correções de bugs.'**
  String get update_dialog_recommend;

  /// No description provided for @update_later.
  ///
  /// In pt, this message translates to:
  /// **'MAIS TARDE'**
  String get update_later;

  /// No description provided for @info_overlay_dismiss_hint.
  ///
  /// In pt, this message translates to:
  /// **'Toque fora desta área para fechar'**
  String get info_overlay_dismiss_hint;

  /// No description provided for @auth_syncing.
  ///
  /// In pt, this message translates to:
  /// **'Sincronizando...'**
  String get auth_syncing;

  /// No description provided for @api_down_dialog_title.
  ///
  /// In pt, this message translates to:
  /// **'API Indisponível'**
  String get api_down_dialog_title;

  /// No description provided for @api_down_dialog_body.
  ///
  /// In pt, this message translates to:
  /// **'A API da Mooze está temporariamente indisponível.'**
  String get api_down_dialog_body;

  /// No description provided for @api_down_maintenance_title.
  ///
  /// In pt, this message translates to:
  /// **'O servidor pode estar em manutenção'**
  String get api_down_maintenance_title;

  /// No description provided for @api_down_warning_list.
  ///
  /// In pt, this message translates to:
  /// **'• PIX não disponível\n• Sincronização pausada\n• Dados em cache sendo usados'**
  String get api_down_warning_list;

  /// No description provided for @api_down_dialog_footer.
  ///
  /// In pt, this message translates to:
  /// **'Por favor, tente novamente em alguns minutos.'**
  String get api_down_dialog_footer;

  /// No description provided for @api_down_indicator.
  ///
  /// In pt, this message translates to:
  /// **'API Indisponível'**
  String get api_down_indicator;

  /// No description provided for @sync_error_indicator.
  ///
  /// In pt, this message translates to:
  /// **'Erro de Sync'**
  String get sync_error_indicator;

  /// No description provided for @sync_error_dialog_title.
  ///
  /// In pt, this message translates to:
  /// **'Erro de Sincronização'**
  String get sync_error_dialog_title;

  /// No description provided for @sync_error_dialog_body.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível sincronizar com a API da Mooze.'**
  String get sync_error_dialog_body;

  /// No description provided for @sync_error_warning.
  ///
  /// In pt, this message translates to:
  /// **'Sem sincronização, não é possível usar o PIX'**
  String get sync_error_warning;

  /// No description provided for @sync_error_details.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes: {message}'**
  String sync_error_details(String message);

  /// No description provided for @pin_create_title.
  ///
  /// In pt, this message translates to:
  /// **'Criar PIN'**
  String get pin_create_title;

  /// No description provided for @pin_create_min_length.
  ///
  /// In pt, this message translates to:
  /// **'PIN deve ter pelo menos 6 caracteres'**
  String get pin_create_min_length;

  /// No description provided for @pin_create_yours.
  ///
  /// In pt, this message translates to:
  /// **'Crie seu '**
  String get pin_create_yours;

  /// No description provided for @pin_create_intro_prefix.
  ///
  /// In pt, this message translates to:
  /// **'O '**
  String get pin_create_intro_prefix;

  /// No description provided for @pin_create_intro_suffix.
  ///
  /// In pt, this message translates to:
  /// **'será utilizado para autorizar transações e acessar sua carteira.'**
  String get pin_create_intro_suffix;

  /// No description provided for @currency_select_title.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar Moeda'**
  String get currency_select_title;

  /// No description provided for @currency_display_label.
  ///
  /// In pt, this message translates to:
  /// **'Moeda de exibição'**
  String get currency_display_label;

  /// No description provided for @currency_display_description.
  ///
  /// In pt, this message translates to:
  /// **'Escolha a moeda usada para exibir preços e valores em todo o app.'**
  String get currency_display_description;

  /// No description provided for @currency_brl_name.
  ///
  /// In pt, this message translates to:
  /// **'Brasil (Real Brasileiro)'**
  String get currency_brl_name;

  /// No description provided for @currency_usd_name.
  ///
  /// In pt, this message translates to:
  /// **'Estados Unidos (Dólar)'**
  String get currency_usd_name;

  /// No description provided for @referral_save_title.
  ///
  /// In pt, this message translates to:
  /// **'Economize com indicações!'**
  String get referral_save_title;

  /// No description provided for @referral_discount_badge.
  ///
  /// In pt, this message translates to:
  /// **'ATÉ 15% DE DESCONTO'**
  String get referral_discount_badge;

  /// No description provided for @referral_save_description.
  ///
  /// In pt, this message translates to:
  /// **'Digite seu código de indicação e aproveite descontos exclusivos em todas as taxas da plataforma.'**
  String get referral_save_description;

  /// No description provided for @referral_active_title.
  ///
  /// In pt, this message translates to:
  /// **'Desconto Ativo'**
  String get referral_active_title;

  /// No description provided for @referral_code_with_value.
  ///
  /// In pt, this message translates to:
  /// **'Código: {code}'**
  String referral_code_with_value(String code);

  /// No description provided for @referral_savings_message.
  ///
  /// In pt, this message translates to:
  /// **'Você está economizando em todas as transações!'**
  String get referral_savings_message;

  /// No description provided for @referral_apply_code.
  ///
  /// In pt, this message translates to:
  /// **'Aplicar Código'**
  String get referral_apply_code;

  /// No description provided for @referral_validating.
  ///
  /// In pt, this message translates to:
  /// **'Validando...'**
  String get referral_validating;

  /// No description provided for @referral_api_down_warning.
  ///
  /// In pt, this message translates to:
  /// **'A API está indisponível. Não é possível aplicar códigos de indicação no momento.'**
  String get referral_api_down_warning;

  /// No description provided for @referral_input_unavailable.
  ///
  /// In pt, this message translates to:
  /// **'Indisponível'**
  String get referral_input_unavailable;

  /// No description provided for @referral_input_hint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: MOOZE123'**
  String get referral_input_hint;

  /// No description provided for @referral_input_label.
  ///
  /// In pt, this message translates to:
  /// **'Código de Indicação'**
  String get referral_input_label;

  /// No description provided for @pix_fee_conversion_title.
  ///
  /// In pt, this message translates to:
  /// **'Taxas de conversão'**
  String get pix_fee_conversion_title;

  /// No description provided for @pix_fee_discount_active_short.
  ///
  /// In pt, this message translates to:
  /// **'Desconto ativo'**
  String get pix_fee_discount_active_short;

  /// No description provided for @pix_fee_tier1_range.
  ///
  /// In pt, this message translates to:
  /// **'R\$ 20 a R\$ 55'**
  String get pix_fee_tier1_range;

  /// No description provided for @pix_fee_tier1_value.
  ///
  /// In pt, this message translates to:
  /// **'R\$ 2,00 fixo *'**
  String get pix_fee_tier1_value;

  /// No description provided for @pix_fee_tier2_range.
  ///
  /// In pt, this message translates to:
  /// **'R\$ 55 a R\$ 499'**
  String get pix_fee_tier2_range;

  /// No description provided for @pix_fee_tier2_value.
  ///
  /// In pt, this message translates to:
  /// **'3,5%'**
  String get pix_fee_tier2_value;

  /// No description provided for @pix_fee_tier3_range.
  ///
  /// In pt, this message translates to:
  /// **'R\$ 500 a R\$ 3.000'**
  String get pix_fee_tier3_range;

  /// No description provided for @pix_fee_tier3_value.
  ///
  /// In pt, this message translates to:
  /// **'3% *'**
  String get pix_fee_tier3_value;

  /// No description provided for @pix_fee_footnote_discount.
  ///
  /// In pt, this message translates to:
  /// **'* 15% de desconto para usuários com código de indicação.'**
  String get pix_fee_footnote_discount;

  /// No description provided for @pix_fee_footnote_network.
  ///
  /// In pt, this message translates to:
  /// **'* Taxas de rede/spread variável por conta do usuário.'**
  String get pix_fee_footnote_network;

  /// No description provided for @pix_fee_discount_chip_15.
  ///
  /// In pt, this message translates to:
  /// **'−15%'**
  String get pix_fee_discount_chip_15;

  /// No description provided for @support_user_code_load_error_inline.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar código'**
  String get support_user_code_load_error_inline;

  /// No description provided for @support_user_code_unique.
  ///
  /// In pt, this message translates to:
  /// **'Código único'**
  String get support_user_code_unique;

  /// No description provided for @wallet_send_appbar_title.
  ///
  /// In pt, this message translates to:
  /// **'Enviar ativos'**
  String get wallet_send_appbar_title;

  /// No description provided for @wallet_send_instruction_prefix.
  ///
  /// In pt, this message translates to:
  /// **'Escolha o ativo que quer enviar na '**
  String get wallet_send_instruction_prefix;

  /// No description provided for @wallet_send_address_label.
  ///
  /// In pt, this message translates to:
  /// **'Endereço de destino'**
  String get wallet_send_address_label;

  /// No description provided for @wallet_send_address_hint.
  ///
  /// In pt, this message translates to:
  /// **'Digite ou cole o endereço'**
  String get wallet_send_address_hint;

  /// No description provided for @wallet_send_address_scan_qr.
  ///
  /// In pt, this message translates to:
  /// **'Escanear QR Code'**
  String get wallet_send_address_scan_qr;

  /// No description provided for @wallet_send_select_asset.
  ///
  /// In pt, this message translates to:
  /// **'Selecione um ativo'**
  String get wallet_send_select_asset;

  /// No description provided for @wallet_send_available_balance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo disponível'**
  String get wallet_send_available_balance;

  /// No description provided for @wallet_send_balance_unavailable.
  ///
  /// In pt, this message translates to:
  /// **'Indisponível'**
  String get wallet_send_balance_unavailable;

  /// No description provided for @wallet_send_balance_load_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar'**
  String get wallet_send_balance_load_error;

  /// No description provided for @wallet_send_amount_label.
  ///
  /// In pt, this message translates to:
  /// **'Valor'**
  String get wallet_send_amount_label;

  /// No description provided for @wallet_send_amount_hint.
  ///
  /// In pt, this message translates to:
  /// **'Digite o valor'**
  String get wallet_send_amount_hint;

  /// No description provided for @wallet_send_amount_in_sats.
  ///
  /// In pt, this message translates to:
  /// **'Valor em Satoshis:'**
  String get wallet_send_amount_in_sats;

  /// No description provided for @wallet_send_amount_valid.
  ///
  /// In pt, this message translates to:
  /// **'Valor válido!'**
  String get wallet_send_amount_valid;

  /// No description provided for @wallet_send_conversion_asset.
  ///
  /// In pt, this message translates to:
  /// **'Ativo'**
  String get wallet_send_conversion_asset;

  /// No description provided for @wallet_send_conversion_sats.
  ///
  /// In pt, this message translates to:
  /// **'Satoshis'**
  String get wallet_send_conversion_sats;

  /// No description provided for @wallet_send_conversion_fiat.
  ///
  /// In pt, this message translates to:
  /// **'Fiat'**
  String get wallet_send_conversion_fiat;

  /// No description provided for @wallet_send_drain_title.
  ///
  /// In pt, this message translates to:
  /// **'Envio Total de Fundos'**
  String get wallet_send_drain_title;

  /// No description provided for @wallet_send_drain_body.
  ///
  /// In pt, this message translates to:
  /// **'Você selecionou enviar todos os fundos do ativo {asset}.'**
  String wallet_send_drain_body(String asset);

  /// No description provided for @wallet_send_drain_ready.
  ///
  /// In pt, this message translates to:
  /// **'Pronto para revisar - as taxas serão deduzidas do valor total'**
  String get wallet_send_drain_ready;

  /// No description provided for @wallet_send_fee_estimated.
  ///
  /// In pt, this message translates to:
  /// **'Taxa estimada'**
  String get wallet_send_fee_estimated;

  /// No description provided for @wallet_send_fee_calculating.
  ///
  /// In pt, this message translates to:
  /// **'Calculando taxa...'**
  String get wallet_send_fee_calculating;

  /// No description provided for @wallet_send_fee_calc_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao calcular taxa'**
  String get wallet_send_fee_calc_error;

  /// No description provided for @wallet_send_fee_free.
  ///
  /// In pt, this message translates to:
  /// **'Gratuito'**
  String get wallet_send_fee_free;

  /// No description provided for @wallet_send_lbtc_disclaimer_title.
  ///
  /// In pt, this message translates to:
  /// **'Como funciona o envio de ativos'**
  String get wallet_send_lbtc_disclaimer_title;

  /// No description provided for @wallet_send_lbtc_disclaimer_body.
  ///
  /// In pt, this message translates to:
  /// **'Para enviar ativos (Bitcoin L2, DePIX ou USDT), você precisa manter um saldo de Bitcoin L2 na sua carteira.'**
  String get wallet_send_lbtc_disclaimer_body;

  /// No description provided for @wallet_send_lbtc_network_fees_title.
  ///
  /// In pt, this message translates to:
  /// **'Taxas de rede'**
  String get wallet_send_lbtc_network_fees_title;

  /// No description provided for @wallet_send_lbtc_network_fees_desc.
  ///
  /// In pt, this message translates to:
  /// **'O saldo de Bitcoin L2 é usado para pagar as taxas dos mineradores da rede Liquid.'**
  String get wallet_send_lbtc_network_fees_desc;

  /// No description provided for @wallet_send_lbtc_obtain_title.
  ///
  /// In pt, this message translates to:
  /// **'Como obter Bitcoin L2'**
  String get wallet_send_lbtc_obtain_title;

  /// No description provided for @wallet_send_lbtc_obtain_desc_disclaimer.
  ///
  /// In pt, this message translates to:
  /// **'Use a função SWAP ou receba Bitcoin via Lightning ou Liquid.'**
  String get wallet_send_lbtc_obtain_desc_disclaimer;

  /// No description provided for @wallet_send_lbtc_obtain_desc_info.
  ///
  /// In pt, this message translates to:
  /// **'Use a função SWAP para converter Bitcoin (Lightning ou on-chain) em Bitcoin L2 diretamente no aplicativo.'**
  String get wallet_send_lbtc_obtain_desc_info;

  /// No description provided for @wallet_send_lbtc_disclaimer_tip.
  ///
  /// In pt, this message translates to:
  /// **'Mantenha um pequeno saldo de Bitcoin L2 para garantir que suas transações sejam processadas.'**
  String get wallet_send_lbtc_disclaimer_tip;

  /// No description provided for @wallet_send_lbtc_disclaimer_understood_countdown.
  ///
  /// In pt, this message translates to:
  /// **'Entendi ({seconds})'**
  String wallet_send_lbtc_disclaimer_understood_countdown(int seconds);

  /// No description provided for @wallet_send_lbtc_info_title.
  ///
  /// In pt, this message translates to:
  /// **'Informações sobre taxas'**
  String get wallet_send_lbtc_info_title;

  /// No description provided for @wallet_send_lbtc_info_step1_title.
  ///
  /// In pt, this message translates to:
  /// **'Bitcoin L2 para taxas de rede'**
  String get wallet_send_lbtc_info_step1_title;

  /// No description provided for @wallet_send_lbtc_info_step1_desc.
  ///
  /// In pt, this message translates to:
  /// **'Para enviar DePIX, USDT ou qualquer ativo da rede Liquid, você precisa ter Bitcoin L2 (Liquid Bitcoin) na carteira. Ele é usado para pagar os mineradores da rede.'**
  String get wallet_send_lbtc_info_step1_desc;

  /// No description provided for @wallet_send_lbtc_info_step3_title.
  ///
  /// In pt, this message translates to:
  /// **'Receba via Lightning ou Liquid'**
  String get wallet_send_lbtc_info_step3_title;

  /// No description provided for @wallet_send_lbtc_info_step3_desc.
  ///
  /// In pt, this message translates to:
  /// **'Receba Bitcoin via Lightning Network ou Liquid para obter Bitcoin L2 na sua carteira sem usar o SWAP.'**
  String get wallet_send_lbtc_info_step3_desc;

  /// No description provided for @wallet_send_lbtc_go_swap.
  ///
  /// In pt, this message translates to:
  /// **'Ir para SWAP'**
  String get wallet_send_lbtc_go_swap;

  /// No description provided for @wallet_send_lbtc_insufficient_title.
  ///
  /// In pt, this message translates to:
  /// **'Bitcoin L2 insuficiente'**
  String get wallet_send_lbtc_insufficient_title;

  /// No description provided for @wallet_send_lbtc_insufficient_body.
  ///
  /// In pt, this message translates to:
  /// **'Você precisa de Bitcoin L2 para pagar as taxas dos mineradores ao enviar {asset}:'**
  String wallet_send_lbtc_insufficient_body(String asset);

  /// No description provided for @wallet_send_lbtc_insufficient_swap_prefix.
  ///
  /// In pt, this message translates to:
  /// **'Use a função '**
  String get wallet_send_lbtc_insufficient_swap_prefix;

  /// No description provided for @wallet_send_lbtc_insufficient_swap_suffix.
  ///
  /// In pt, this message translates to:
  /// **' para obter Bitcoin L2'**
  String get wallet_send_lbtc_insufficient_swap_suffix;

  /// No description provided for @wallet_send_lbtc_insufficient_lightning.
  ///
  /// In pt, this message translates to:
  /// **'Receba Bitcoin via Lightning ou Liquid para obter Bitcoin L2'**
  String get wallet_send_lbtc_insufficient_lightning;

  /// No description provided for @wallet_send_lbtc_banner_title.
  ///
  /// In pt, this message translates to:
  /// **'Bitcoin L2 necessário para taxas'**
  String get wallet_send_lbtc_banner_title;

  /// No description provided for @wallet_send_lbtc_banner_body.
  ///
  /// In pt, this message translates to:
  /// **'Para enviar DePIX ou USDT, você precisa ter Bitcoin L2 na carteira para pagar as taxas da rede.'**
  String get wallet_send_lbtc_banner_body;

  /// No description provided for @wallet_send_lbtc_banner_action.
  ///
  /// In pt, this message translates to:
  /// **'Obter via SWAP'**
  String get wallet_send_lbtc_banner_action;

  /// No description provided for @wallet_send_network_unidentified.
  ///
  /// In pt, this message translates to:
  /// **'Rede não identificada'**
  String get wallet_send_network_unidentified;

  /// No description provided for @wallet_send_network_bitcoin.
  ///
  /// In pt, this message translates to:
  /// **'Bitcoin On-chain'**
  String get wallet_send_network_bitcoin;

  /// No description provided for @wallet_send_network_lightning.
  ///
  /// In pt, this message translates to:
  /// **'Lightning Network'**
  String get wallet_send_network_lightning;

  /// No description provided for @wallet_send_network_liquid.
  ///
  /// In pt, this message translates to:
  /// **'Liquid Network'**
  String get wallet_send_network_liquid;

  /// No description provided for @wallet_send_network_unknown.
  ///
  /// In pt, this message translates to:
  /// **'Rede desconhecida'**
  String get wallet_send_network_unknown;

  /// No description provided for @wallet_send_predefined_label.
  ///
  /// In pt, this message translates to:
  /// **'Valor pré-definido'**
  String get wallet_send_predefined_label;

  /// No description provided for @wallet_send_predefined_body.
  ///
  /// In pt, this message translates to:
  /// **'Este invoice/endereço possui um valor pré-definido. O campo de quantia foi automaticamente preenchido.'**
  String get wallet_send_predefined_body;

  /// No description provided for @wallet_send_predefined_label_value.
  ///
  /// In pt, this message translates to:
  /// **'Label: {label}'**
  String wallet_send_predefined_label_value(String label);

  /// No description provided for @wallet_send_predefined_message_value.
  ///
  /// In pt, this message translates to:
  /// **'Mensagem: {message}'**
  String wallet_send_predefined_message_value(String message);

  /// No description provided for @wallet_send_review_preparing.
  ///
  /// In pt, this message translates to:
  /// **'Preparando...'**
  String get wallet_send_review_preparing;

  /// No description provided for @wallet_send_review_drain.
  ///
  /// In pt, this message translates to:
  /// **'Revisar Envio Total'**
  String get wallet_send_review_drain;

  /// No description provided for @wallet_send_review_transaction.
  ///
  /// In pt, this message translates to:
  /// **'Revisar Transação'**
  String get wallet_send_review_transaction;

  /// No description provided for @wallet_send_review_lbtc_insufficient_error.
  ///
  /// In pt, this message translates to:
  /// **'Saldo de Bitcoin L2 insuficiente para taxas.\n\nPara enviar {asset}, você precisa de Bitcoin L2 para pagar os mineradores da rede. Use a função SWAP ou receba Bitcoin via Lightning ou Liquid.'**
  String wallet_send_review_lbtc_insufficient_error(String asset);

  /// No description provided for @wallet_send_review_insufficient_error.
  ///
  /// In pt, this message translates to:
  /// **'Saldo insuficiente para realizar o envio.\n\nVerifique se você tem saldo suficiente no ativo selecionado e Bitcoin L2 para pagar as taxas da rede.'**
  String get wallet_send_review_insufficient_error;

  /// No description provided for @wallet_send_review_prepare_error.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível preparar a transação. Tente novamente.'**
  String get wallet_send_review_prepare_error;

  /// No description provided for @wallet_send_loading_conversions.
  ///
  /// In pt, this message translates to:
  /// **'Carregando conversões...'**
  String get wallet_send_loading_conversions;

  /// No description provided for @wallet_send_equivalent_conversions.
  ///
  /// In pt, this message translates to:
  /// **'Conversões equivalentes:'**
  String get wallet_send_equivalent_conversions;

  /// No description provided for @wallet_send_satoshis_label.
  ///
  /// In pt, this message translates to:
  /// **'Satoshis:'**
  String get wallet_send_satoshis_label;

  /// No description provided for @wallet_send_validation_attention.
  ///
  /// In pt, this message translates to:
  /// **'Atenção'**
  String get wallet_send_validation_attention;

  /// No description provided for @wallet_send_validation_help.
  ///
  /// In pt, this message translates to:
  /// **'As validações são verificadas automaticamente conforme você digita.'**
  String get wallet_send_validation_help;

  /// No description provided for @wallet_send_error_address_required.
  ///
  /// In pt, this message translates to:
  /// **'Endereço é obrigatório'**
  String get wallet_send_error_address_required;

  /// No description provided for @wallet_send_error_address_invalid.
  ///
  /// In pt, this message translates to:
  /// **'Endereço inválido ou não suportado'**
  String get wallet_send_error_address_invalid;

  /// No description provided for @wallet_send_error_asset_liquid_only.
  ///
  /// In pt, this message translates to:
  /// **'{asset} só pode ser enviado pela rede Liquid ou Lightning'**
  String wallet_send_error_asset_liquid_only(String asset);

  /// No description provided for @wallet_send_error_liquid_only.
  ///
  /// In pt, this message translates to:
  /// **'Para enviar ativos Liquid use Bitcoin L2, Depix ou USDT'**
  String get wallet_send_error_liquid_only;

  /// No description provided for @wallet_send_error_amount_positive.
  ///
  /// In pt, this message translates to:
  /// **'Valor deve ser maior que zero'**
  String get wallet_send_error_amount_positive;

  /// No description provided for @wallet_send_error_balance_check.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao verificar saldo disponível'**
  String get wallet_send_error_balance_check;

  /// No description provided for @wallet_send_error_insufficient_balance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo insuficiente'**
  String get wallet_send_error_insufficient_balance;

  /// No description provided for @wallet_send_error_address_unrecognized.
  ///
  /// In pt, this message translates to:
  /// **'Endereço inválido ou não reconhecido'**
  String get wallet_send_error_address_unrecognized;

  /// No description provided for @wallet_send_error_pending_payments.
  ///
  /// In pt, this message translates to:
  /// **'Não é possível enviar o saldo total enquanto há pagamentos pendentes. Aguarde a conclusão dos pagamentos e tente novamente.'**
  String get wallet_send_error_pending_payments;

  /// No description provided for @wallet_send_error_validation_failed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível validar a transação: {error}'**
  String wallet_send_error_validation_failed(String error);

  /// No description provided for @wallet_send_error_amount_exceeds_balance.
  ///
  /// In pt, this message translates to:
  /// **'Valor informado é maior que o saldo disponível'**
  String get wallet_send_error_amount_exceeds_balance;

  /// No description provided for @wallet_send_error_insufficient_with_fees.
  ///
  /// In pt, this message translates to:
  /// **'Saldo insuficiente. Você precisa de {total} sats ({amount} + {fee} {satText} de taxa), mas tem apenas {balance} sats disponíveis'**
  String wallet_send_error_insufficient_with_fees(
    String total,
    String amount,
    String fee,
    String satText,
    String balance,
  );

  /// No description provided for @wallet_send_error_fee_calc_failed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível calcular as taxas: {error}'**
  String wallet_send_error_fee_calc_failed(String error);

  /// No description provided for @wallet_send_error_validate_balance_fees.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao validar saldo e taxas: {error}'**
  String wallet_send_error_validate_balance_fees(String error);

  /// No description provided for @wallet_send_error_min_lightning.
  ///
  /// In pt, this message translates to:
  /// **'Valor mínimo para lightning é {amount} sats'**
  String wallet_send_error_min_lightning(int amount);

  /// No description provided for @wallet_send_error_max_lightning.
  ///
  /// In pt, this message translates to:
  /// **'Valor máximo para lightning é {amount} sats'**
  String wallet_send_error_max_lightning(int amount);

  /// No description provided for @wallet_send_error_min_usdt.
  ///
  /// In pt, this message translates to:
  /// **'Valor mínimo para USDT é 0.5 USDT'**
  String get wallet_send_error_min_usdt;

  /// No description provided for @wallet_send_error_min_depix.
  ///
  /// In pt, this message translates to:
  /// **'Valor mínimo para Depix é 1.0 Depix'**
  String get wallet_send_error_min_depix;

  /// No description provided for @wallet_send_error_validate_limits.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao validar limites de envio: {error}'**
  String wallet_send_error_validate_limits(String error);

  /// No description provided for @wallet_action_receive.
  ///
  /// In pt, this message translates to:
  /// **'RECEBER'**
  String get wallet_action_receive;

  /// No description provided for @wallet_action_send.
  ///
  /// In pt, this message translates to:
  /// **'ENVIAR'**
  String get wallet_action_send;

  /// No description provided for @wallet_assets_section_title.
  ///
  /// In pt, this message translates to:
  /// **'Ativos'**
  String get wallet_assets_section_title;

  /// No description provided for @wallet_transactions_section_title.
  ///
  /// In pt, this message translates to:
  /// **'Transações'**
  String get wallet_transactions_section_title;

  /// No description provided for @wallet_section_see_more.
  ///
  /// In pt, this message translates to:
  /// **'Ver mais'**
  String get wallet_section_see_more;

  /// No description provided for @wallet_tx_sent.
  ///
  /// In pt, this message translates to:
  /// **'Enviou {ticker}'**
  String wallet_tx_sent(String ticker);

  /// No description provided for @wallet_tx_received.
  ///
  /// In pt, this message translates to:
  /// **'Recebeu {ticker}'**
  String wallet_tx_received(String ticker);

  /// No description provided for @wallet_tx_swap_pair.
  ///
  /// In pt, this message translates to:
  /// **'Swap: {from} para {to}'**
  String wallet_tx_swap_pair(String from, String to);

  /// No description provided for @wallet_tx_redeposit.
  ///
  /// In pt, this message translates to:
  /// **'Autodepositou {ticker}'**
  String wallet_tx_redeposit(String ticker);

  /// No description provided for @wallet_tx_unknown.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de transação desconhecido'**
  String get wallet_tx_unknown;

  /// No description provided for @wallet_tx_load_error_title.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar transações'**
  String get wallet_tx_load_error_title;

  /// No description provided for @wallet_tx_load_error_retry.
  ///
  /// In pt, this message translates to:
  /// **'Tente novamente mais tarde'**
  String get wallet_tx_load_error_retry;

  /// No description provided for @wallet_tx_empty_title.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma transação encontrada'**
  String get wallet_tx_empty_title;

  /// No description provided for @wallet_tx_empty_body.
  ///
  /// In pt, this message translates to:
  /// **'Seu histórico de transações aparecerá aqui assim que você realizar alguma movimentação.'**
  String get wallet_tx_empty_body;

  /// No description provided for @wallet_all_assets_title.
  ///
  /// In pt, this message translates to:
  /// **'Todos os Ativos'**
  String get wallet_all_assets_title;

  /// No description provided for @wallet_all_assets_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Acompanhe a cotação de todos os ativos disponíveis'**
  String get wallet_all_assets_subtitle;

  /// No description provided for @wallet_all_assets_favorite_hint.
  ///
  /// In pt, this message translates to:
  /// **'Toque no ícone para favoritar — '**
  String get wallet_all_assets_favorite_hint;

  /// No description provided for @wallet_all_assets_favorite_count.
  ///
  /// In pt, this message translates to:
  /// **'{count}/2 selecionados'**
  String wallet_all_assets_favorite_count(int count);

  /// No description provided for @wallet_asset_chart_title.
  ///
  /// In pt, this message translates to:
  /// **'Gráfico - {period}'**
  String wallet_asset_chart_title(String period);

  /// No description provided for @wallet_asset_chart_unavailable.
  ///
  /// In pt, this message translates to:
  /// **'Gráfico Indisponível'**
  String get wallet_asset_chart_unavailable;

  /// No description provided for @wallet_asset_chart_load_error.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar o gráfico'**
  String get wallet_asset_chart_load_error;

  /// No description provided for @wallet_holding_appbar_title.
  ///
  /// In pt, this message translates to:
  /// **'Ativos'**
  String get wallet_holding_appbar_title;

  /// No description provided for @wallet_holding_action_send.
  ///
  /// In pt, this message translates to:
  /// **'Enviar'**
  String get wallet_holding_action_send;

  /// No description provided for @wallet_holding_action_receive.
  ///
  /// In pt, this message translates to:
  /// **'Receber'**
  String get wallet_holding_action_receive;

  /// No description provided for @wallet_holding_action_swap.
  ///
  /// In pt, this message translates to:
  /// **'Swap'**
  String get wallet_holding_action_swap;

  /// No description provided for @wallet_holding_unexpected_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro inesperado: {error}'**
  String wallet_holding_unexpected_error(String error);

  /// No description provided for @wallet_holding_empty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum ativo encontrado'**
  String get wallet_holding_empty;

  /// No description provided for @wallet_holding_no_balance.
  ///
  /// In pt, this message translates to:
  /// **'Sem saldo'**
  String get wallet_holding_no_balance;

  /// No description provided for @wallet_holding_load_error_title.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar ativos'**
  String get wallet_holding_load_error_title;

  /// No description provided for @wallet_holding_pending_payments_title.
  ///
  /// In pt, this message translates to:
  /// **'Pagamentos em análise'**
  String get wallet_holding_pending_payments_title;

  /// No description provided for @wallet_holding_pending_payments_total.
  ///
  /// In pt, this message translates to:
  /// **'Total: {currency} {value}'**
  String wallet_holding_pending_payments_total(String currency, String value);

  /// No description provided for @wallet_holding_calculating.
  ///
  /// In pt, this message translates to:
  /// **'Calculando...'**
  String get wallet_holding_calculating;

  /// No description provided for @pix_receive_appbar_title.
  ///
  /// In pt, this message translates to:
  /// **'Receber PIX'**
  String get pix_receive_appbar_title;

  /// No description provided for @pix_receive_api_unavailable.
  ///
  /// In pt, this message translates to:
  /// **'Não é possível processar transações PIX no momento. Por favor, tente novamente mais tarde.'**
  String get pix_receive_api_unavailable;

  /// No description provided for @pix_receive_info_title.
  ///
  /// In pt, this message translates to:
  /// **'Informações sobre PIX'**
  String get pix_receive_info_title;

  /// No description provided for @pix_receive_info_step1_title.
  ///
  /// In pt, this message translates to:
  /// **'Prazo de processamento'**
  String get pix_receive_info_step1_title;

  /// No description provided for @pix_receive_info_step1_desc.
  ///
  /// In pt, this message translates to:
  /// **'Pagamentos via PIX podem ser processados em até 72 horas úteis após a confirmação.'**
  String get pix_receive_info_step1_desc;

  /// No description provided for @pix_receive_info_step2_title.
  ///
  /// In pt, this message translates to:
  /// **'Variação de câmbio (LBTC)'**
  String get pix_receive_info_step2_title;

  /// No description provided for @pix_receive_info_step2_desc.
  ///
  /// In pt, this message translates to:
  /// **'Ao escolher receber em LBTC, o valor final pode variar devido à cotação do momento da conversão. Você pode receber mais ou menos que o calculado.'**
  String get pix_receive_info_step2_desc;

  /// No description provided for @pix_receive_info_step3_title.
  ///
  /// In pt, this message translates to:
  /// **'Sobre as taxas'**
  String get pix_receive_info_step3_title;

  /// No description provided for @pix_receive_info_step3_desc.
  ///
  /// In pt, this message translates to:
  /// **'As taxas variam conforme o valor da transação. Valores menores têm taxas fixas, valores maiores têm taxas percentuais decrescentes.'**
  String get pix_receive_info_step3_desc;

  /// No description provided for @pix_receive_info_see_fees.
  ///
  /// In pt, this message translates to:
  /// **'Ver detalhes das taxas'**
  String get pix_receive_info_see_fees;

  /// No description provided for @pix_receive_instruction_prefix.
  ///
  /// In pt, this message translates to:
  /// **'Escolha o ativo que deseja receber na '**
  String get pix_receive_instruction_prefix;

  /// No description provided for @pix_receive_tip_more_payments.
  ///
  /// In pt, this message translates to:
  /// **'Faça mais pagamentos para liberar novos limites'**
  String get pix_receive_tip_more_payments;

  /// No description provided for @pix_receive_advance.
  ///
  /// In pt, this message translates to:
  /// **'Avançar'**
  String get pix_receive_advance;

  /// No description provided for @pix_receive_my_level.
  ///
  /// In pt, this message translates to:
  /// **'Meu Nível'**
  String get pix_receive_my_level;

  /// No description provided for @pix_receive_you_add.
  ///
  /// In pt, this message translates to:
  /// **'Você adiciona'**
  String get pix_receive_you_add;

  /// No description provided for @pix_receive_my_limits.
  ///
  /// In pt, this message translates to:
  /// **'Meus limites'**
  String get pix_receive_my_limits;

  /// No description provided for @pix_receive_see_levels.
  ///
  /// In pt, this message translates to:
  /// **'Ver níveis'**
  String get pix_receive_see_levels;

  /// No description provided for @pix_receive_daily_limit.
  ///
  /// In pt, this message translates to:
  /// **'Limite diário'**
  String get pix_receive_daily_limit;

  /// No description provided for @pix_receive_per_transaction.
  ///
  /// In pt, this message translates to:
  /// **'Por transação'**
  String get pix_receive_per_transaction;

  /// No description provided for @pix_receive_min.
  ///
  /// In pt, this message translates to:
  /// **'Mín.'**
  String get pix_receive_min;

  /// No description provided for @pix_receive_limits_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar limites'**
  String get pix_receive_limits_error;

  /// No description provided for @pix_receive_details.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes: {detail}'**
  String pix_receive_details(String detail);

  /// No description provided for @pix_receive_validation_invalid_amount.
  ///
  /// In pt, this message translates to:
  /// **'Digite um valor válido'**
  String get pix_receive_validation_invalid_amount;

  /// No description provided for @pix_receive_validation_below_min.
  ///
  /// In pt, this message translates to:
  /// **'Valor mínimo: R\$ {amount}'**
  String pix_receive_validation_below_min(String amount);

  /// No description provided for @pix_receive_validation_above_transaction.
  ///
  /// In pt, this message translates to:
  /// **'Limite por transação: R\$ {amount}'**
  String pix_receive_validation_above_transaction(String amount);

  /// No description provided for @pix_tip_consecutive_daily.
  ///
  /// In pt, this message translates to:
  /// **'Máx. 3 PIX seguidos do mesmo titular em 30 min · Limite de R\$ 5.000/dia por titular.'**
  String get pix_tip_consecutive_daily;

  /// No description provided for @pix_tip_outside_rules_returned.
  ///
  /// In pt, this message translates to:
  /// **'Pagamentos fora das regras são devolvidos automaticamente ao remetente.'**
  String get pix_tip_outside_rules_returned;

  /// No description provided for @pix_tip_processing_avg_time.
  ///
  /// In pt, this message translates to:
  /// **'Processamento em 5–25 min. PIX com sinal de risco bancário pode levar 3–7 dias (estornável).'**
  String get pix_tip_processing_avg_time;

  /// No description provided for @pix_payment_appbar_title.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento PIX'**
  String get pix_payment_appbar_title;

  /// No description provided for @pix_payment_qr_error.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao gerar QR code: {error}'**
  String pix_payment_qr_error(String error);

  /// No description provided for @pix_payment_time_expired_body.
  ///
  /// In pt, this message translates to:
  /// **'O tempo para realizar o pagamento expirou. Por favor, gere um novo PIX.'**
  String get pix_payment_time_expired_body;

  /// No description provided for @tx_filter_pix_title.
  ///
  /// In pt, this message translates to:
  /// **'Filtros PIX'**
  String get tx_filter_pix_title;

  /// No description provided for @tx_filter_deposit_status.
  ///
  /// In pt, this message translates to:
  /// **'Status do depósito'**
  String get tx_filter_deposit_status;

  /// No description provided for @tx_filter_most_recent.
  ///
  /// In pt, this message translates to:
  /// **'Mais Recente'**
  String get tx_filter_most_recent;

  /// No description provided for @tx_filter_oldest.
  ///
  /// In pt, this message translates to:
  /// **'Mais Antigo'**
  String get tx_filter_oldest;

  /// No description provided for @tx_filter_select_period.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar Período'**
  String get tx_filter_select_period;

  /// No description provided for @tx_filter_select.
  ///
  /// In pt, this message translates to:
  /// **'Selecione'**
  String get tx_filter_select;

  /// No description provided for @tx_filter_to.
  ///
  /// In pt, this message translates to:
  /// **'para'**
  String get tx_filter_to;

  /// No description provided for @tx_filter_start_after_end_error.
  ///
  /// In pt, this message translates to:
  /// **'A data de início não pode ser posterior à data de término.'**
  String get tx_filter_start_after_end_error;

  /// No description provided for @tx_history_refresh_debug.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar (Debug)'**
  String get tx_history_refresh_debug;

  /// No description provided for @tx_history_filters_active.
  ///
  /// In pt, this message translates to:
  /// **'Filtros ativos - {description}'**
  String tx_history_filters_active(String description);

  /// No description provided for @tx_history_clear.
  ///
  /// In pt, this message translates to:
  /// **'Limpar'**
  String get tx_history_clear;

  /// No description provided for @tx_history_filter_count.
  ///
  /// In pt, this message translates to:
  /// **'{filtered} de {total} transações - {description}'**
  String tx_history_filter_count(int filtered, int total, String description);

  /// No description provided for @tx_history_filter_refunds.
  ///
  /// In pt, this message translates to:
  /// **'Reembolsos'**
  String get tx_history_filter_refunds;

  /// No description provided for @tx_history_filter_from.
  ///
  /// In pt, this message translates to:
  /// **'A partir de {date}'**
  String tx_history_filter_from(String date);

  /// No description provided for @tx_history_filter_until.
  ///
  /// In pt, this message translates to:
  /// **'Até {date}'**
  String tx_history_filter_until(String date);

  /// No description provided for @tx_history_filter_oldest_first.
  ///
  /// In pt, this message translates to:
  /// **'Mais antigos primeiro'**
  String get tx_history_filter_oldest_first;

  /// No description provided for @tx_history_filter_default.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get tx_history_filter_default;

  /// No description provided for @pix_filter_status_pending.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento Pendente'**
  String get pix_filter_status_pending;

  /// No description provided for @pix_filter_status_processing.
  ///
  /// In pt, this message translates to:
  /// **'Processando 1/2'**
  String get pix_filter_status_processing;

  /// No description provided for @pix_filter_status_finished.
  ///
  /// In pt, this message translates to:
  /// **'Enviado'**
  String get pix_filter_status_finished;

  /// No description provided for @pix_filter_status_expired.
  ///
  /// In pt, this message translates to:
  /// **'Expirado'**
  String get pix_filter_status_expired;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
