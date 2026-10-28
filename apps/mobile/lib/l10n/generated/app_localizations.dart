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

  /// No description provided for @nav_home.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get nav_home;

  /// No description provided for @nav_menu.
  ///
  /// In pt, this message translates to:
  /// **'Menu'**
  String get nav_menu;

  /// No description provided for @nav_pix.
  ///
  /// In pt, this message translates to:
  /// **'Pix'**
  String get nav_pix;

  /// No description provided for @onboarding_get_started.
  ///
  /// In pt, this message translates to:
  /// **'Começar'**
  String get onboarding_get_started;

  /// No description provided for @pix_send_confirm_title.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar pagamento'**
  String get pix_send_confirm_title;

  /// No description provided for @pix_send_error_title.
  ///
  /// In pt, this message translates to:
  /// **'Erro no pagamento'**
  String get pix_send_error_title;

  /// No description provided for @pix_send_processing_payment.
  ///
  /// In pt, this message translates to:
  /// **'Processando pagamento...'**
  String get pix_send_processing_payment;

  /// No description provided for @common_taking_longer.
  ///
  /// In pt, this message translates to:
  /// **'Está demorando mais que o normal. Verifique sua conexão.'**
  String get common_taking_longer;

  /// No description provided for @error_something_went_wrong.
  ///
  /// In pt, this message translates to:
  /// **'Algo deu errado. Tente novamente.'**
  String get error_something_went_wrong;

  /// No description provided for @send_clipboard_address_found.
  ///
  /// In pt, this message translates to:
  /// **'Endereço copiado detectado'**
  String get send_clipboard_address_found;

  /// No description provided for @send_clipboard_use.
  ///
  /// In pt, this message translates to:
  /// **'Usar'**
  String get send_clipboard_use;

  /// No description provided for @pix_clipboard_key_found.
  ///
  /// In pt, this message translates to:
  /// **'Chave PIX copiada detectada'**
  String get pix_clipboard_key_found;

  /// No description provided for @deeplink_invalid_payment.
  ///
  /// In pt, this message translates to:
  /// **'Link de pagamento inválido'**
  String get deeplink_invalid_payment;

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

  /// No description provided for @settings_security.
  ///
  /// In pt, this message translates to:
  /// **'Segurança'**
  String get settings_security;

  /// No description provided for @security_session_lock_title.
  ///
  /// In pt, this message translates to:
  /// **'Usar bloqueio por Biometria/PIN'**
  String get security_session_lock_title;

  /// No description provided for @security_session_lock_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Exigir autenticação após um período de inatividade'**
  String get security_session_lock_subtitle;

  /// No description provided for @security_privacy_shield_title.
  ///
  /// In pt, this message translates to:
  /// **'Proteger o alternador de apps'**
  String get security_privacy_shield_title;

  /// No description provided for @security_privacy_shield_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Ocultar o conteúdo da carteira no alternador de apps'**
  String get security_privacy_shield_subtitle;

  /// No description provided for @security_lock_after.
  ///
  /// In pt, this message translates to:
  /// **'Bloquear após'**
  String get security_lock_after;

  /// No description provided for @security_timeout_immediate.
  ///
  /// In pt, this message translates to:
  /// **'Imediatamente'**
  String get security_timeout_immediate;

  /// No description provided for @security_timeout_15s.
  ///
  /// In pt, this message translates to:
  /// **'15 segundos'**
  String get security_timeout_15s;

  /// No description provided for @security_timeout_30s.
  ///
  /// In pt, this message translates to:
  /// **'30 segundos'**
  String get security_timeout_30s;

  /// No description provided for @security_timeout_1m.
  ///
  /// In pt, this message translates to:
  /// **'1 minuto'**
  String get security_timeout_1m;

  /// No description provided for @security_timeout_5m.
  ///
  /// In pt, this message translates to:
  /// **'5 minutos'**
  String get security_timeout_5m;

  /// No description provided for @privacy_shield_locked_title.
  ///
  /// In pt, this message translates to:
  /// **'Aplicativo bloqueado'**
  String get privacy_shield_locked_title;

  /// No description provided for @privacy_shield_locked_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Autentique-se para continuar'**
  String get privacy_shield_locked_subtitle;

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
  /// **'Formato: esquema://host:porta. Use ssl:// para conexões criptografadas. Deixe vazio para usar o node padrão.'**
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
  /// **'Formato: host:porta. O LWK usa TLS automaticamente. Deixe vazio para usar o node padrão.'**
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

  /// No description provided for @node_config_at_least_one.
  ///
  /// In pt, this message translates to:
  /// **'Configure ao menos um endpoint, ou volte ao modo padrão.'**
  String get node_config_at_least_one;

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
  /// **'{error}'**
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

  /// No description provided for @screenshot_blocked_title.
  ///
  /// In pt, this message translates to:
  /// **'Captura de tela bloqueada'**
  String get screenshot_blocked_title;

  /// No description provided for @screenshot_blocked_message.
  ///
  /// In pt, this message translates to:
  /// **'Esta tela contém informações sensíveis da sua carteira e não pode ser capturada.'**
  String get screenshot_blocked_message;

  /// No description provided for @screenshot_blocked_warning.
  ///
  /// In pt, this message translates to:
  /// **'Para sua segurança, nunca tire capturas de tela da sua frase de recuperação (seed phrase). Qualquer pessoa com acesso à sua frase de recuperação pode obter controle total da sua carteira.'**
  String get screenshot_blocked_warning;

  /// No description provided for @screenshot_blocked_acknowledge.
  ///
  /// In pt, this message translates to:
  /// **'Entendi'**
  String get screenshot_blocked_acknowledge;

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

  /// No description provided for @pin_use_pin.
  ///
  /// In pt, this message translates to:
  /// **'Usar PIN'**
  String get pin_use_pin;

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
  /// **'Última atualização: 18/04/2026'**
  String get terms_last_updated;

  /// No description provided for @terms_privacy_policy_link.
  ///
  /// In pt, this message translates to:
  /// **'Ver Política de Privacidade'**
  String get terms_privacy_policy_link;

  /// No description provided for @terms_preamble.
  ///
  /// In pt, this message translates to:
  /// **'Preâmbulo — Oferta Passiva e Auto-Acesso'**
  String get terms_preamble;

  /// No description provided for @terms_preamble_body.
  ///
  /// In pt, this message translates to:
  /// **'Os presentes Termos de Uso regem a relação entre a Mooze Labs LLC e o Usuário que, por iniciativa própria e exclusiva, obtém, instala e utiliza o aplicativo Mooze Wallet.\n\nA disponibilização do Aplicativo em plataformas de distribuição global (Google Play Store, Apple App Store, lojas similares ou repositório público de APK) constitui mera colocação passiva de software. Qualquer utilização do Aplicativo decorre de busca ativa e em interesse voluntário do Usuário, o qual declara acessar a Mooze por decisão pessoal.'**
  String get terms_preamble_body;

  /// No description provided for @terms_section_1.
  ///
  /// In pt, this message translates to:
  /// **'1. Aceitação dos Termos'**
  String get terms_section_1;

  /// No description provided for @terms_section_2.
  ///
  /// In pt, this message translates to:
  /// **'2. Natureza Jurídica da Mooze'**
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
  /// **'8. Referência de Preços e Ausência de Recomendação de Investimento'**
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
  /// **'12. Obrigações Legais do Usuário e Restrições Jurisdicionais'**
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
  /// **'9. Direitos do Usuário (LGPD e Jurisdições Equivalentes)'**
  String get privacy_section_9;

  /// No description provided for @privacy_section_10.
  ///
  /// In pt, this message translates to:
  /// **'10. Jurisdição de Dados e Transferências Internacionais'**
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
  /// **'1.1. Ao acessar, instalar ou utilizar o aplicativo Mooze Wallet (\"Aplicativo\"), o Usuário declara ter lido, compreendido e aceito integralmente os presentes Termos de Uso (\"Termos\") e a Política de Privacidade que os acompanha.\n\n1.2. A utilização do Aplicativo constitui aceitação expressa, informada, consciente e irrevogável de todas as disposições contidas neste documento.\n\n1.3. Caso o Usuário não concorde com qualquer disposição destes Termos, deverá cessar imediatamente a utilização do Aplicativo, desinstalá-lo de seus dispositivos e abster-se de qualquer interação com os Serviços. A continuidade de uso do Aplicativo, após a publicação destes Termos ou de versões atualizadas posteriormente, constitui concordância integral com os termos vigentes.\n\n1.4. Estes Termos constituem contrato vinculante internacional entre o Usuário e a Mooze Labs LLC, regido exclusivamente pelas leis da República das Ilhas Marshall (\"RMI\"), nos limites estabelecidos na Seção 13.\n\n1.5. O Usuário reconhece que obteve o Aplicativo através de informação livre e conhecida, com decisão própria final, sendo o único responsável capaz.'**
  String get terms_section_1_body;

  /// No description provided for @terms_section_2_body.
  ///
  /// In pt, this message translates to:
  /// **'2.1. A Mooze Labs LLC (\"Mooze\") é sociedade de responsabilidade limitada regularmente constituída sob a Associations Law da República das Ilhas Marshall (Título 52, Marshall Islands Revised Code), RMI.\n\n2.2. A Mooze atua exclusivamente como provedora de serviços de software (Software-as-a-Service). Sua atividade consiste no desenvolvimento, manutenção e disponibilização de infraestrutura tecnológica para operação de carteiras digitais autocustodiais nas redes Bitcoin, Liquid Network e Lightning Network, bem como na orquestração programática de chamadas de software (API calls) entre o dispositivo do Usuário e infraestruturas de terceiros.\n\n2.3. A Mooze NÃO é, não opera como, não se apresenta como, e não deve ser interpretada como:\n(a) corretora, exchange, plataforma de negociação, plataforma de trading, formador de mercado (market maker) ou plataforma de liquidez de ativos digitais;\n(b) instituição financeira, instituição de pagamento, sociedade de crédito, cooperativa de crédito ou entidade equiparada;\n(c) prestadora de serviços de câmbio, casa de câmbio ou operadora de câmbio;\n(d) transmissora de dinheiro (money transmitter) ou prestadora de serviços monetários (money services business — MSB);\n(e) prestadora de serviços de ativos virtuais (Virtual Asset Service Provider — VASP) nos termos da Banking (Amendment) Act, 2020 — P.L. 2020-61, Seção 102(ii), da República das Ilhas Marshall;\n(f) prestadora de serviços de ativos virtuais nos termos da Lei n. 14.478/2022 (Marco Legal dos Criptoativos do Brasil) ou da Resolução CVM n. 175;\n(g) entidade sujeita às obrigações da FATF Recommendation 15 enquanto VASP;\n(h) custodiante, depositária, fiel depositária ou administradora de ativos digitais ou de recursos financeiros de terceiros;\n(i) consultora de investimentos, prestadora de aconselhamento financeiro ou analista de valores mobiliários.\n\n2.4. A Mooze não exerce custódia, posse, controle discricionário de saldos em nome de usuários, titularidade, domínio, direito de uso, fruição ou disposição sobre quaisquer ativos digitais ou valores monetários pertencentes ao usuário. O processamento transitório, programático e automatizado de ativos digitais pela infraestrutura da Mooze durante a execução dos Serviços constitui roteamento técnico, análogo ao processamento de pacotes de dados por equipamento de rede (roteador), sem que a Mooze adquira, em qualquer momento ou sob qualquer forma, direito, interesse, titularidade beneficiária (beneficial ownership).\n\n2.5. A Mooze não realiza, em nenhuma hipótese: (i) operações de exchange; (ii) conversão entre moedas fiduciárias; (iii) conversão entre moeda fiduciária e ativo digital ou entre ativos digitais executada em nome do Usuário e sua titularidade; (iv) intermediação financeira; (v) transmissão de valores em nome de terceiros. Toda e qualquer operação envolvendo moeda fiduciária (reais brasileiros) é processada integralmente por parceiras reguladas pelo Banco Central do Brasil, conforme descrito na Seção 4. Toda e qualquer conversão entre ativos digitais é executada diretamente pelo Usuário, por meio de protocolos descentralizados peer-to-peer (atomic swap), sem que a Mooze atue como contraparte.\n\n2.6. Nos termos da Banking (Amendment) Act, 2020 (P.L. 2020-61) da República das Ilhas Marshall, Capítulo 1, Seção 102(ii), a definição de VASP (Virtual Asset Service Provider) abrange exclusivamente pessoas naturais ou jurídicas que, como atividade empresarial e \"por conta ou em nome de outra pessoa natural ou jurídica\" (\"for or on behalf of another natural or legal person\"), realizam uma ou mais das seguintes atividades: (i) câmbio entre ativos virtuais e moedas fiduciárias; (ii) câmbio entre formas de ativos virtuais; (iii) transferência de ativos virtuais; (iv) guarda e/ou administração de ativos virtuais ou de instrumentos que permitam controle sobre ativos virtuais; (v) participação e provisão de serviços financeiros relacionados à oferta e/ou venda de um ativo virtual por um emissor. A Mooze não realiza nenhuma das atividades (i) a (v) \"por conta ou em nome\" de terceiros, uma vez que: (a) opera exclusivamente como provedora de software não-custodial; (b) não detém, nem tem capacidade técnica de deter, chaves privadas do Usuário; (c) não executa conversões em nome do Usuário, limitando-se a orquestrar chamadas programáticas entre o Usuário e provedores terceiros; (d) não participa como contraparte em qualquer transferência ou atomic swap.\n\n2.7. A Mooze não está sujeita às AML Regulations 2002 da República das Ilhas Marshall (com emendas) enquanto VASP, por não satisfazer o critério legal de prestação de serviço \"por conta ou em nome\" de terceiros. O cumprimento de obrigações de prevenção à lavagem de dinheiro (AML), conheça seu cliente (KYC) e da \"Travel Rule\" relativa a transferências acima de USD 1.000,00 cabe exclusivamente às Parceiras Reguladas e demais VASPs intervenientes no fluxo operacional descrito na Seção 4.\n\n2.8. A Mooze é membro oficial da Liquid Federation (Blockstream), com PAK Entry ativo, atestando sua participação no ecossistema da Liquid Network como entidade tecnológica. A participação na Liquid Federation constitui vínculo técnico-operacional, e não vínculo societário, de representação ou de responsabilidade solidária com a Blockstream ou com demais membros da federação.'**
  String get terms_section_2_body;

  /// No description provided for @terms_section_3_body.
  ///
  /// In pt, this message translates to:
  /// **'Para fins destes Termos, os seguintes termos possuem os significados indicados:\n\n3.1. \"Aplicativo\" ou \"Mooze Wallet\": software de carteira digital autocustodial desenvolvido pela Mooze, disponibilizado para dispositivos móveis iOS e Android (via lojas como Google Play Store, Apple App Store e similares, também via arquivo APK de distribuição direta).\n\n3.2. \"Usuário\": pessoa natural, maior de 18 (dezoito) anos e com capacidade civil plena, que instala, acessa ou utiliza o Aplicativo por iniciativa própria.\n\n3.3. \"Autocustódia\" ou \"Self-Custody\": modelo no qual o Usuário detém controle técnico exclusivo sobre suas chaves privadas e frases-semente (seed phrases), sem que a Mooze ou qualquer terceiro tenha acesso, cópia, conhecimento ou capacidade técnica de reconstruir tais informações.\n\n3.4. \"Frase-Semente\" ou \"Seed Phrase\": sequência de 12 (doze) ou 24 (vinte e quatro) palavras, gerada localmente no dispositivo do Usuário de acordo com o padrão aberto BIP39, que constitui o único mecanismo de recuperação da carteira digital do Usuário.\n\n3.5. \"Liquid Network\": sidechain federada do Bitcoin, desenvolvida e mantida pela Blockstream e pela Liquid Federation, que permite a emissão e transferência de ativos digitais com tecnologia de Confidential Transactions.\n\n3.6. \"DEPIX\": token digital emitido na Liquid Network pela Eulen.app LLC (entidade constituída em São Cristóvão e Neves — Saint Kitts and Nevis) em cooperação com o projeto depix.info, cujo valor é pareado ao real brasileiro (BRL) na razão de 1 (um) DEPIX para R\$ 1,00 (um real). Conforme descrito no whitepaper público disponível em depix.info, o DEPIX é colateralizado parcialmente em moedas fiduciárias e majoritariamente em Bitcoin, por meio de protocolos NITI (Non-custodial Interlinked Tokenization Infrastructure) nas redes on-chain e na Liquid Network. A Mooze NÃO é emissora, administradora, garantidora ou responsável pela paridade, lastro ou liquidez do DEPIX.\n\n3.7. \"L-BTC\": representação técnica de Bitcoin na Liquid Network, emitida 1:1 contra Bitcoin depositado no peg-in federado, utilizada para transações dentro dessa rede.\n\n3.8. \"Atomic Swap\": mecanismo criptográfico de troca direta entre dois ativos digitais, executado diretamente na blockchain ou sidechain, sem intermediário custodiante, no qual ambas as pontas da transação se concretizam simultaneamente ou nenhuma delas se efetiva (all-or-nothing).\n\n3.9. \"SideSwap\": protocolo público e de código aberto para execução de atomic swaps na Liquid Network.\n\n3.10. \"Confidential Transactions\": tecnologia nativa da Liquid Network que oculta valores e tipos de ativos em transações, sendo visíveis apenas para as partes envolvidas mediante os respectivos blinding keys (chaves de ocultação).\n\n3.11. \"APP ID\": identificador técnico gerado a partir de funcionalidades criptográficas do dispositivo do Usuário (MediaDRM em Android, DeviceCheck em iOS), resultando em hash unidirecional. O APP ID é utilizado exclusivamente para prevenção a fraudes e controle de limites operacionais, não permite identificação pessoal do Usuário e não constitui dado pessoal identificável nos termos da LGPD ou de legislação equivalente.\n\n3.12. \"Parceiras Reguladas\": instituições financeiras e de pagamento brasileiras, devidamente autorizadas e reguladas pelo Banco Central do Brasil, que participam do processamento de operações envolvendo moeda fiduciária (PIX). Sendo estas, e não se limitando somente às citadas:\n(a) PLEBIT.COM.BR Soluções em Tecnologia Ltda — CNPJ 43.375.652/0001-13;\n(b) Fits Instituição de Pagamento — CNPJ 13.203.354/0001-85;\n(c) Celcoin — CNPJ 13.935.893/0001-09;\n(d) PLEBZ INTERMEDIACAO DE PAGAMENTOS LTDA — CNPJ 45.808.899/0001-01.\n\n3.13. \"Eulen.app LLC\": sociedade constituída em São Cristóvão e Neves (Saint Kitts and Nevis), emissora do token DEPIX e responsável pela infraestrutura tecnológica de tokenização descrita em seu whitepaper público.\n\n3.14. \"PIX\": sistema de pagamentos instantâneos instituído, regulado e operado pelo Banco Central do Brasil.\n\n3.15. \"Serviços\": conjunto de funcionalidades de software disponibilizadas pela Mooze ao Usuário por meio do Aplicativo, conforme descritas na Seção 4.\n\n3.16. \"Protocolo NITI\": protocolo descentralizado utilizado para verificação e roteamento de transações na Liquid Network.\n\n3.17. \"Blinding Key\" ou \"Chave de Ocultação\": chave criptográfica associada a uma Confidential Transaction na Liquid Network, que permite ao detentor visualizar os valores e tipos de ativos transacionados naquela transação específica.\n\n3.18. \"MED\" (\"Mecanismo Especial de Devolução\"): mecanismo instituído pelo Banco Central do Brasil para devolução de valores em transações PIX, aplicável em casos de fraude ou falha operacional, regido pela Resolução BCB aplicável e operado exclusivamente pelas instituições participantes do arranjo PIX.\n\n3.19. \"Breez\" ou \"Breez SDK\": kit de desenvolvimento de software (SDK) de terceiro, utilizado pela Mooze para integração técnica com a Lightning Network.\n\n3.20. “Hodle”: serviço de terceiro utilizado para funcionalidades complementares envolvendo o sistema PIX.\n\n3.21. “Infratechs Parceiras”: empresas terceiras que fornecem serviços de infraestrutura tecnológica financeira utilizados pela Mooze na orquestração de seus Serviços de software, sem prestar serviços diretamente aos Usuários finais do Aplicativo e sem qualquer vínculo contratual direto com o Usuário.\n\n3.22. \"FATF\": Financial Action Task Force — Grupo de Ação Financeira Internacional, organismo intergovernamental referenciado nestes Termos para fins de definição de VASP e aplicação da Recommendation 15.\n\n3.23. \"Oferta Passiva\" ou \"Reverse Solicitation\": modalidade de disponibilização de serviço em que o cliente busca o provedor por decisão e iniciativa própria.'**
  String get terms_section_3_body;

  /// No description provided for @terms_section_4_body.
  ///
  /// In pt, this message translates to:
  /// **'A Mooze disponibiliza ao Usuário, por meio do Aplicativo, serviços de software organizados em modalidades independentes entre si. Cada modalidade constitui serviço tecnológico autônomo, com objeto, funcionamento e base contratual distintos. A utilização de uma modalidade não obriga nem condiciona a utilização das demais.\n\n4.1. SERVIÇO A — ORQUESTRAÇÃO DE SOFTWARE PARA AQUISIÇÃO DE TOKENS DIGITAIS\n\n4.1.1. O Serviço A consiste na disponibilização, pela Mooze, de interface de software que orquestra programaticamente a comunicação entre o dispositivo do Usuário, as Parceiras Reguladas e a infraestrutura de emissão de tokens digitais operada pela Eulen.app LLC e demais Infratechs Parceiras.\n\n4.1.2. O fluxo operacional do Serviço A ocorre conforme descrito a seguir:\n(a) O Usuário, por meio do Aplicativo, informa o valor em reais (BRL) que deseja utilizar para aquisição de DEPIX e gera um código QR PIX, no qual via sua plataforma de início da operação, fornece todos os dados necessários para transação, podendo ser, chaves públicas, endereços de wallet, valores e informações de dispositivo gerais;\n(b) O pagamento PIX é recebido, processado e liquidado integralmente por uma das Parceiras Reguladas (PLEBIT.COM.BR, Fits Instituição de Pagamento, Celcoin ou PLEBZ), que são as únicas entidades autorizadas a receber e processar recursos em moeda fiduciária em ambas as direções de fluxos de transações FIAT;\n(c) A Parceira Regulada comunica os dados de liquidação do PIX à Eulen.app LLC;\n(d) A Eulen.app LLC emite a quantidade correspondente de tokens DEPIX na Liquid Network;\n(e) O software da Mooze captura o endereço de carteira do Usuário — endereço público derivado matematicamente das chaves privadas sob controle exclusivo do Usuário — e transmite esse endereço à infraestrutura da Eulen.app LLC para que os tokens DEPIX sejam entregues diretamente ao endereço de autocustódia do Usuário;\n(f) Os tokens DEPIX são entregues, por meio do sistema conjunto de processamento iniciado via software com a Eulen.app LLC, diretamente via roteamento programático direcionada ao endereço de autocustódia do Usuário na Liquid Network.\n\n4.1.3. O Serviço A constitui prestação de serviços tecnológicos de software, realizada por meio de infraestrutura integrada entre a Mooze, parceiros especializados e prestadores de serviço do ecossistema. A Mooze coordena chamadas de API (application programming interface) entre o dispositivo do Usuário, as Parceiras Reguladas, a Eulen.app LLC e as Infratechs Parceiras, incluindo o sistema de verificação automatizado descrito na cláusula 4.1.4, sem adquirir titularidade, posse beneficiária ou controle sobre os ativos roteados fora de escopos programáticos predefinidos.\n\n4.1.4. O processamento de ativos digitais no âmbito do Serviço A envolve múltiplas camadas de verificação técnica e operacional realizadas por sistemas integrados de parceiros e prestadores de serviço especializados. A conclusão do processamento pode decorrer de procedimentos de análise conjunta que, conforme a natureza e características da operação, são regidos pelas seguintes características:\n(a) O processamento é regido por sistemas automatizados integrados, cujos critérios são determinados por participantes do ecossistema tecnológico; os desfechos possíveis são: (i) conclusão da operação, com entrega dos ativos ao endereço de autocustódia do Usuário; ou (ii) reversão da operação, com retorno dos ativos à Eulen.app LLC e comunicação de estorno do pagamento PIX às Parceiras Reguladas;\n(b) não existem destinos técnicos alternativos para os ativos além dos descritos em (a)(i) e (a)(ii) — a estrutura do sistema não comporta desvios;\n(c) os sistemas automatizados integrados não comportam intervenção discricionária em operações individuais;\n(d) a Mooze não adquire, em nenhum momento, titularidade beneficiária (beneficial ownership), direito real, direito de uso, fruição ou disposição sobre os tokens em trânsito;\n(e) os tokens em trânsito não são comingled (misturados) com ativos da Mooze, nem utilizados como lastro, garantia ou reserva para qualquer obrigação da Mooze;\n(f) a operação de entrega constitui handoff atômico (atomic handoff): até o momento imediatamente anterior à liberação ao Usuário, os tokens permanecem sob controle técnico programático com destino predefinido à própria operação;\n(g) a manutenção técnica do sistema antifraude (correção de defeitos, atualização de regras programáticas, calibragem de thresholds) constitui desenvolvimento de software e não configura intervenção discricionária sobre operações individuais.\n\n4.1.5. Operações no âmbito do Serviço A podem ser submetidas a procedimentos de verificação realizados por sistemas automatizados integrados de parceiros do ecossistema tecnológico. A duração e a metodologia dos procedimentos de verificação são determinadas por esses sistemas automatizados, podendo resultar em processamento imediato ou em análise adicional por período variável conforme a natureza e características da operação. Durante o processamento:\n(a) os ativos permanecem em trânsito automatizado, sem comingling com ativos de outras operações e sem fungibilidade com patrimônio da Mooze;\n(b) a Mooze não exerce, nem pode exercer, uso, fruição, empréstimo, investimento, rehipoteca ou qualquer forma de aproveitamento econômico sobre os tokens em transição;\n(c) expirado o período de verificação sem sinalização de inconsistência, os ativos são liberados automaticamente ao endereço de autocustódia do Usuário;\n(d) o processamento transitório não constitui custódia, guarda, depósito ou administração de ativos em nome do Usuário, uma vez que (i) não decorre de acordo de guarda ou depósito com o Usuário, mas de procedimento técnico do ecossistema aplicado via rota de processamento para a entrega, e (ii) em nenhum momento a Mooze adquire titularidade beneficiária ou poder discricionário sobre os ativos.\n\n4.1.6. Operações podem ser revertidas quando sistemas automatizados integrados ou Parceiras Reguladas detectarem sinalizações de risco, inconsistências técnicas ou requisitos regulatórios aplicáveis (incluindo MED). Nesse caso, os ativos digitais são revertidos à Eulen.app LLC via blockchain dentro do tempo de processamento das respectivas redes utilizadas. O processamento do estorno do pagamento PIX em moeda fiduciária é de responsabilidade exclusiva das Parceiras Reguladas, sob jurisdição e regulação do Banco Central do Brasil, podendo levar até 7 (sete) dias corridos contados em média do início da operação. O prazo adicional entre a reversão do processo dos tokens à Eulen.app LLC e a conclusão do estorno PIX refere-se exclusivamente ao tempo de processamento do sistema bancário brasileiro pelas Parceiras Reguladas, período no qual a Mooze não detém quaisquer tokens ou recursos financeiros relacionados à operação.\n\n4.1.7. O processamento do pagamento PIX, incluindo a verificação de identidade do pagador (KYC), a prevenção à lavagem de dinheiro (AML), o cumprimento da \"Travel Rule\" em transferências cross-border de ativos virtuais em eventos de triggers de valores regulados e demais obrigações regulatórias perante o Banco Central do Brasil, o Conselho de Controle de Atividades Financeiras (COAF) e a Receita Federal do Brasil, é de responsabilidade exclusiva das Parceiras Reguladas e demais VASPs intervenientes, nos limites de suas respectivas atividades.\n\n4.1.8. A emissão de tokens DEPIX é de responsabilidade exclusiva da Eulen.app LLC e do projeto depix.info, que operam de forma independente da Mooze. A Mooze não garante a paridade, a liquidez, o lastro, a solvência ou a continuidade da operação do DEPIX, nem a Mooze representa ou responde pelas operações relacionadas ao DEPIX, à Eulen.app LLC e suas parcerias contratuais.\n\n4.1.9. O Serviço A constitui prestação de serviço de software (SaaS), não configurando: (a) serviço financeiro; (b) operação exchange; (c) intermediação financeira; (d) transmissão de valores; (e) prestação de serviço de ativos virtuais (VASP) nos termos da Banking (Amendment) Act, 2020 (RMI) ou de leis regulatórias de território brasileiro; (f) qualquer atividade sujeita a regulação financeira, bancária ou securitária.\n\n4.2. SERVIÇO B — INTERFACE PARA PROTOCOLO DESCENTRALIZADO DE CONVERSÃO ENTRE UNIDADES DIGITAIS\n\n4.2.1. O Serviço B consiste na disponibilização, pela Mooze, de interface de software que permite ao Usuário interagir com o protocolo SideSwap para execução de atomic swaps entre ativos digitais na Liquid Network, bem como, quando aplicável, com o Breez SDK para acesso à Lightning Network.\n\n4.2.2. O Serviço B é inteiramente independente do Serviço A. A utilização de um Serviço não implica nem obriga a utilização do outro.\n\n4.2.3. O fluxo operacional do Serviço B ocorre conforme descrito a seguir:\n(a) O Usuário, a partir de sua carteira autocustodial no Aplicativo, inicia voluntariamente uma solicitação de conversão entre ativos digitais (por exemplo, DEPIX para L-BTC);\n(b) O software da Mooze apresenta ao Usuário interface gráfica para interação com o protocolo SideSwap (ou Breez SDK, quando aplicável);\n(c) O atomic swap é executado diretamente na Liquid Network (ou na Lightning Network, quando aplicável), por meio do protocolo correspondente, entre o Usuário e a liquidez disponível no protocolo;\n(d) A Mooze não participa como contraparte, custodiante, formadora de mercado ou provedora de liquidez em qualquer etapa do atomic swap;\n(e) A conversão ocorre de forma peer-to-peer, diretamente na blockchain ou sidechain, garantida criptograficamente pelo mecanismo de atomic swap — não há, em nenhum momento, intermediário detendo ambos os lados da operação.\n\n4.2.4. A função da Mooze no Serviço B é análoga à de um navegador de internet (web browser) que provê acesso a um sítio eletrônico: a Mooze fornece a interface de software para que o Usuário interaja com protocolo descentralizado, sem participar da execução do protocolo em si.\n\n4.2.5. O protocolo SideSwap é público, de código aberto e opera de forma descentralizada na Liquid Network. O Breez SDK é software de terceiro, público, utilizado para acesso à Lightning Network. A Mooze não controla, opera, administra, governa ou mantém qualquer um desses protocolos ou SDKs.\n\n4.2.6. O Serviço B não constitui atividade de corretagem, exchange, intermediação financeira, câmbio, negociação, formação de mercado ou liquidação de ativos. Constitui exclusivamente a prestação de interface de software para acesso a protocolos descentralizados.\n\n4.2.7. A Mooze não garante: (a) a disponibilidade de liquidez nos protocolos utilizados; (b) a execução bem-sucedida de atomic swaps; (c) as taxas de conversão praticadas pelos protocolos; (d) a continuidade operacional dos protocolos ou SDKs de terceiros.\n\n4.2.8. Para acesso à Lightning Network, a Mooze disponibiliza a integração técnica com o Breez SDK público, sujeito aos mesmos termos aqui descritos para o SideSwap.\n\n4.2.9. Quando o Usuário seleciona, por decisão própria e voluntária, ativo digital final distinto do DEPIX (por exemplo, L-BTC), o software da Mooze orquestra sequencialmente a execução do Serviço A (aquisição de DEPIX) seguida do Serviço B (conversão de DEPIX para o ativo selecionado via protocolo descentralizado Sideswap). A conversão é executada integralmente pelo protocolo descentralizado. A Mooze limita-se a orquestrar as chamadas de software necessárias para que o ativo final se encontre disponível via endereço de autocustódia do Usuário. O Usuário reconhece que essa orquestração sequencial constitui prestação de serviço de software (SaaS) automatizado e não configura atividade de câmbio de responsabilidade da Mooze, corretagem, intermediação financeira ou atividade de VASP, em razão da execução exclusiva via protocolo Sideswap.\n\n4.3. MODO COMERCIANTE\n\n4.3.1. O Aplicativo disponibiliza funcionalidade denominada \"Modo Comerciante\", que permite ao Usuário receber pagamentos via PIX diretamente em sua carteira autocustodial no Aplicativo, tanto de terceiros pagadores quanto na forma de autopagamentos.\n\n4.3.2. O Modo Comerciante utiliza a mesma infraestrutura tecnológica descrita no Serviço A (cláusula 4.1), aplicando-se integralmente as mesmas disposições relativas à natureza do serviço, às responsabilidades das Parceiras Reguladas e à ausência de custódia pela Mooze.\n\n4.3.3. O Modo Comerciante constitui funcionalidade de software, não configurando serviço de adquirência, subadquirência, credenciamento, arranjo de pagamento, gateway de pagamento ou qualquer serviço financeiro regulado. O código QR de pagamento PIX é gerado pelo próprio Usuário-comerciante por meio do Aplicativo, utilizando a infraestrutura das Parceiras Reguladas. A Mooze não participa, intermedia, conhece, valida ou endossa a relação comercial subjacente entre o Usuário-comerciante e o pagador. O pagador realiza pagamento PIX convencional à Parceira Regulada, sem qualquer interação, vínculo contratual ou comunicação direta com a Mooze.\n\n4.3.4. Pagamentos recebidos através do Modo Comerciante estão sujeitos a procedimentos de verificação realizados por sistemas de parceiros e prestadores de serviço integrados. A conclusão do processamento pode decorrer de períodos variáveis, desde minutos até vários dias, conforme os procedimentos aplicáveis determinados por cada participante da cadeia de processamento.\n\n4.3.5. Pagamentos podem ser revertidos quando sistemas integrados de análise detectarem inconsistências técnicas, requisitos regulatórios ou outras condições que resultem em não-conclusão da operação. A reversão será processada pelos prestadores de serviço responsáveis pelo fluxo original. O Usuário que utilizar o Modo Comerciante NÃO deverá entregar produto ou serviço ao pagador antes da confirmação final do pagamento por meio das funções de acompanhamento disponíveis no Aplicativo.\n\n4.3.6. Quaisquer prejuízos, danos ou conflitos decorrentes de entrega de produto ou serviço antes da confirmação final do processamento do pagamento são de responsabilidade exclusiva do Usuário-comerciante, não cabendo responsabilidade à Mooze, às Parceiras Reguladas ou às Infratechs Parceiras.\n\n4.3.7. O Usuário que utilizar o Modo Comerciante responsabiliza-se integralmente, na esfera civil, tributária e criminal, pelas operações realizadas por meio do Aplicativo, incluindo operações realizadas por terceiros que utilizem o dispositivo sob sua tutela física.\n\n4.3.8. Dúvidas operacionais sobre pagamentos devem ser direcionadas ao suporte da Mooze via suporte@mooze.app.\n\n4.4. NATUREZA DO ECOSSISTEMA TECNOLÓGICO INTEGRADO\n\n4.4.1. Os Serviços disponibilizados pela Mooze operam em ecossistema tecnológico complexo envolvendo múltiplos prestadores de serviço, infraestruturas de terceiros, protocolos descentralizados e sistemas integrados.\n\n4.4.2. A execução de operações no âmbito dos Serviços envolve, de forma não exaustiva: (a) infraestrutura de software desenvolvida pela Mooze; (b) sistemas de parceiros e prestadores especializados; (c) infraestruturas das Parceiras Reguladas; (d) protocolos blockchain públicos; (e) sistemas de análise e verificação operados conjuntamente por participantes do ecossistema.\n\n4.4.3. A Mooze não possui controle exclusivo sobre a totalidade dos componentes, sistemas e processos envolvidos na execução dos Serviços. Decisões sobre processamento, aprovação, prazo, reversão ou não-realização de operações podem decorrer de sistemas automatizados, procedimentos de terceiros, requisitos regulatórios ou condições técnicas aplicadas por qualquer participante do ecossistema.\n\n4.4.4. O Usuário reconhece que a prestação dos Serviços constitui coordenação tecnológica entre múltiplos agentes, não configurando relação unilateral ou serviço prestado exclusivamente pela Mooze. A Mooze atua como provedora de componentes de integração de software dentro de ecossistema mais amplo.'**
  String get terms_section_4_body;

  /// No description provided for @terms_section_5_body.
  ///
  /// In pt, this message translates to:
  /// **'5.1. O Aplicativo opera sob modelo de autocustódia integral. As chaves privadas e frases-semente são geradas e armazenadas exclusivamente no dispositivo do Usuário, sendo tecnicamente inacessíveis à Mooze.\n\n5.2. A Mooze não tem, em nenhum momento e sob nenhuma circunstância, acesso, conhecimento, posse, controle, cópia, backup, custódia ou capacidade técnica de reconstrução das chaves privadas, frases-semente ou senhas do Usuário.\n\n5.3. O Usuário é único e exclusivo responsável pela guarda, segurança e integridade de suas chaves privadas, frases-semente e senhas. A perda desses elementos resulta na perda permanente e irreversível do acesso aos ativos digitais armazenados na carteira.\n\n5.4. A Mooze não possui capacidade técnica para recuperar, restaurar, acessar, transferir ou recriar ativos digitais do Usuário em caso de perda das chaves privadas ou frases-semente. Solicitações nesse sentido são tecnicamente impossíveis de atender.\n\n5.5. Os endereços de carteira do Usuário e chaves públicas são derivados matematicamente, por meio de algoritmo criptográfico determinístico, de suas chaves privadas. A Mooze utiliza esses dados exclusivamente como parâmetro técnico de roteamento automatizado durante a execução dos Serviços, transmitindo-os via infraestrutura para entrega direta dos ativos ao Usuário.\n\n5.6. O Usuário reconhece que a autocustódia é o pilar estrutural do modelo da Mooze e elemento determinante do seu enquadramento jurídico como não-VASP. Qualquer tentativa de contornar o modelo de autocustódia (por exemplo, exigir da Mooze a guarda de chaves, a custódia de ativos ou a recuperação discricionária de frases-semente) é incompatível com a natureza do Serviço, não será atendida.'**
  String get terms_section_5_body;

  /// No description provided for @terms_section_6_body.
  ///
  /// In pt, this message translates to:
  /// **'6.1. GUARDA DE SENHAS E FRASES-SEMENTE\n\n6.1.1. O Usuário é integral e exclusivamente responsável pela criação, armazenamento e proteção de suas senhas, chaves privadas e frases-semente.\n\n6.1.2. O Usuário deve armazenar sua frase-semente em local seguro, preferencialmente offline (em suporte físico como papel, aço gravado ou dispositivo dedicado), e nunca compartilhá-la com terceiros, inclusive com a Mooze ou qualquer pessoa que se apresente como representante da Mooze.\n\n6.1.3. A Mooze NUNCA solicita ao Usuário, por qualquer meio de comunicação (e-mail, Telegram, telefone, redes sociais, anúncios, chat in-app), suas chaves privadas, frases-semente ou senhas. Qualquer solicitação nesse sentido deve ser considerada tentativa de fraude e reportada ao suporte oficial via suporte@mooze.app.\n\n6.1.4. O usuário é o único responsável na verificação de legitimidade em casos de comunicação ou tentativas de phishing, comunicação via canais homógrafos se passando pela Mooze, sob esse conhecimento via estes termos, orienta-se que, comunicados com domínio homógrafo ou suspeito similar o da Mooze, usuário deve contatar reencaminhando contatos ou mensagens suspeitas (vide seção 6.1.3.) para suporte@mooze.app para auxílio e certificação, a Mooze opera comunicação com clientes exclusivamente via domínio mooze.app.\n\n6.2. CONSEQUÊNCIAS DA PERDA DE ACESSO\n\n6.2.1. A perda da frase-semente implica a perda permanente e irreversível do acesso a todos os ativos digitais armazenados na carteira associada.\n\n6.2.2. A Mooze não pode restaurar, recuperar ou recriar o acesso à carteira do Usuário em caso de perda da frase-semente.\n\n6.2.3. O Usuário reconhece e aceita que a autocustódia implica responsabilidade integral e exclusiva sobre seus ativos digitais, incluindo o risco de perda total e definitiva por ato ou omissão e imperícia próprios em relação às tecnologias Blockchain e criptomoedas.\n\n6.2.4. O usuário ao desinstalar o aplicativo da Mooze, rotacionar dados via plataformas de acesso aos serviços via Mooze, rotacionar carteiras, frases sementes sob mesmo aparelho ou em aparelhos diferentes, fica ciente do fato da possibilidade de perda de dados, como armazenamento de históricos blockchain, históricos de pagamentos via processadoras parceiras, possibilidade de perda de avaliação sobre scores internos de reputação de usuário via sistemas e serviços da Mooze (score e limite de transações relacionados a transações bancárias via parceiras reguladas) e quaisquer dados não limitados a estes que salvos localmente para privacidade e segurança, essas ações podem decorrer destas consequências, o usuário aqui se declara completamente ciente das consequências dessas ações.\n\n6.3. SEGURANÇA DO DISPOSITIVO E FONTE DE OBTENÇÃO DOS SERVIÇOS\n\n6.3.1. O Usuário é responsável pela segurança do dispositivo móvel utilizado para acessar o Aplicativo, incluindo: (a) manutenção do sistema operacional atualizado; (b) utilização de autenticação biométrica ou senha forte de dispositivo; (c) proteção contra malware e aplicativos de origem não confiável; (d) abstenção de realizar root, jailbreak ou utilização de emuladores, o usuário pode baixar o aplicativo via lojas autorizadas oficiais via identificação da Mooze ou através de fontes como seu Github oficial (github.com/mooze-labs), quais ambas as fontes possuem formas de verificação de autenticidade da fonte de serviços e aplicações como, verificação de autenticidade do aplicativo e sua integridade via verificações de ID hash nos repositórios públicos, a Mooze não se responsabiliza por qualquer problema advindo de usuários que usem fontes de download de aplicação ou fontes de serviços adulterados e ou fraudulentos, nem prejuízos decorrentes da não verificação de fonte de serviços ou obtenção de aplicações, o usuário consente aqui que pode utilizar-se de verificação via Github oficial da Mooze e métodos seguros de segurança de lojas oficiais disponíveis.\n\n6.3.2. A Mooze não se responsabiliza por perdas decorrentes de comprometimento do dispositivo do Usuário, incluindo infecção por malware, acesso não autorizado ao dispositivo, interceptação de dados por terceiros ou uso de dispositivos modificados.'**
  String get terms_section_6_body;

  /// No description provided for @terms_section_7_body.
  ///
  /// In pt, this message translates to:
  /// **'7.1. A utilização dos Serviços está sujeita a taxas de processamento e tecnologia (\"Taxa de Serviço\" ou \"Taxa de Serviço de Software\") cobradas em razão da operação do ecossistema tecnológico descrito na Seção 4.\n\n7.2. As Taxas de Serviço remuneram os prestadores de infraestrutura tecnológica envolvidos na operação, incluindo mas não limitado a: desenvolvimento e manutenção de software, integração de sistemas, processamento de operações, infraestrutura de rede, segurança e demais serviços técnicos necessários ao funcionamento do ecossistema.\n\n7.3. A Taxa de Serviço de Software é calculada como percentual do valor da operação e deduzida do montante de ativos digitais entregues ao Usuário. O percentual vigente é exibido ao Usuário na tela de confirmação da operação, antes de sua efetivação, e também divulgado nos menus informativos do Aplicativo.\n\n7.4. A Mooze reserva-se o direito de alterar os percentuais da Taxa de Serviço de Software a qualquer momento, mediante atualização no Aplicativo ou necessidades de pareamento referencial em cotações Bitcoin (exemplo: taxas de rede Bitcoin Liquid e referenciais similares em Bitcoin podem sofrer ajuste devido cotação flutuante). A continuidade de utilização do Aplicativo após a alteração constitui aceitação dos novos percentuais ou necessidades de valores referenciais não fixados.\n\n7.5. A Taxa de Serviço de Software constitui remuneração por serviço de software (SaaS), de natureza análoga às taxas cobradas por plataformas tecnológicas por utilização de seus serviços. Não constitui tarifa financeira, comissão de corretagem, taxa de câmbio, spread cambial ou encargo financeiro de qualquer natureza.\n\n7.6. As Parceiras Reguladas, os protocolos descentralizados (SideSwap, Breez, Lightning) e as Infratechs Parceiras podem aplicar suas próprias tarifas, spreads, taxas ou custos de rede, independentes da Taxa de Serviço de Software da Mooze, sobre os quais a Mooze não exerce controle nem responsabilidade. A Mooze informa esses repasses ao Usuário na tela de confirmação da operação de forma fixa ou flutuante na plataforma utilizada.\n\n7.7. Custos de mineração e taxas de rede (network fees) relativos a transações nas redes Bitcoin, Liquid Network ou Lightning Network são de responsabilidade do Usuário e independentes da Taxa de Serviço de Software. Taxas de rede incorridas durante a execução dos Serviços pelas Parceiras Reguladas, Infratechs Parceiras ou protocolos utilizados poderão ser repassadas ao Usuário, somando-se à Taxa de Serviço de Software, conforme exibido na tela de confirmação antes da efetivação.'**
  String get terms_section_7_body;

  /// No description provided for @terms_section_8_body.
  ///
  /// In pt, this message translates to:
  /// **'8.1. Os valores de referência exibidos no Aplicativo para ativos digitais (Bitcoin, L-BTC, DEPIX, L-USDT e outros) são obtidos de fontes públicas de mercado e servem exclusivamente como referência informativa.\n\n8.2. A Mooze não garante a exatidão, a precisão ou a atualização em tempo real dos preços exibidos. A variação de preço entre o momento da exibição e o momento da efetivação de uma operação é inerente ao funcionamento de mercados de ativos digitais.\n\n8.3. A exibição de preços no Aplicativo: (a) não constitui oferta, oferta pública, recomendação, aconselhamento de investimento, análise de valor mobiliário ou garantia de valor; (b) não configura oferta pública de valores mobiliários nos termos da Lei n. 6.385/76 ou de legislação equivalente; (c) não se qualifica como \"investment advice\" ou \"solicitation\" nos termos das regulações dos Estados Unidos, União Europeia, Reino Unido ou qualquer outra jurisdição.\n\n8.4. O Usuário reconhece que ativos digitais estão sujeitos a alta volatilidade e que pode sofrer perdas significativas de valor. A Mooze não se responsabiliza por perdas decorrentes de variação de preços.'**
  String get terms_section_8_body;

  /// No description provided for @terms_section_9_body.
  ///
  /// In pt, this message translates to:
  /// **'9.1. A Mooze fornece o Aplicativo e os Serviços \"no estado em que se encontram\" (as is) e \"conforme disponibilidade\" (as available), sem garantias de qualquer natureza, expressas ou implícitas, incluindo, sem limitação, garantias de comerciabilidade, adequação a propósito específico ou não-infringência.\n\n9.2. A Mooze não será responsável por:\n(a) perdas de ativos digitais decorrentes de perda, comprometimento ou uso indevido de chaves privadas, frases-semente ou senhas pelo Usuário;\n(b) perdas decorrentes de comprometimento do dispositivo do Usuário e utilização de Plataforma falsa (homógrafa / domínio falso) ou aplicativo adulterado ou baixado em fonte não oficial;\n(c) indisponibilidade, falhas, atrasos, forks, reorganizações ou interrupções na Liquid Network, na rede Bitcoin, na Lightning Network ou em qualquer outra rede blockchain ou sidechain;\n(d) falhas, indisponibilidade ou atrasos nos serviços prestados pelas Parceiras Reguladas, pela Eulen.app LLC, pelo projeto depix.info, pelo protocolo SideSwap, pelo Breez SDK ou por quaisquer provedores de infraestrutura de terceiros;\n(e) atos de fraude, phishing, engenharia social, SIM swap ou qualquer forma de ataque dirigido ao Usuário por terceiros (incluindo obtenção de aplicação ou serviço software fraudulento qual o usuário consentiu uso sem verificação de fonte como comentado no item 6.3), inclusive por comunicação enganosa, uso de contatos de e-mail homógrafos, domínios semelhantes ao domínio oficial da Mooze, aplicativos adulterados, perfis falsos em redes sociais ou mensageiros, e quaisquer outras modalidades de ataque dirigidas ao Usuário, cuja prevenção não está sob controle da Mooze;\n(f) erros na inserção de endereços de carteira pelo Usuário, resultando em envio de ativos digitais a endereços incorretos; falhas de envio ou recebimento de ativos em plataformas e serviços de terceiros; recusa de ativos por serviços de terceiros; falhas em contratos inteligentes em quaisquer redes blockchain iniciados direta ou indiretamente pelo Usuário por meio de sua autocustódia; utilização de taxas de rede (fees) insuficientes que acarretem não mineração ou atraso da transação; utilização dos Serviços via PIX, por terceiros, para atividades dolosas ou ilícitas, não obstante a existência de sistemas antifraude conjuntos — casos nos quais a Mooze não se responsabiliza, por não intermediar, endossar ou validar a relação subjacente entre o Usuário-comerciante e o pagador;\n(g) alterações regulatórias que afetem a disponibilidade dos Serviços em determinada jurisdição, incluindo interrupção ou descontinuação total em resposta a exigências legais supervenientes;\n(h) variação no valor de ativos digitais;\n(i) decisões de investimento tomadas pelo Usuário com base em informações exibidas no Aplicativo ou em qualquer outro material da Mooze;\n(j) danos indiretos, incidentais, consequenciais, punitivos, lucros cessantes, perda de oportunidade, perda de dados ou perda reputacional.\n\n9.2.1. A Mooze não se responsabiliza por: (i) decisões tomadas por sistemas programáticos automatizados participantes do ecossistema; (ii) prazos de processamento determinados por infraestruturas de terceiros ou Parceiras Reguladas; (iii) critérios de análise aplicados por prestadores de serviço especializados; (iv) reversões solicitadas por instituições financeiras, Parceiras Reguladas ou autoridades reguladoras.\n\n9.3. A Mooze não se responsabiliza por quaisquer obrigações tributárias, fiscais, regulatórias, trabalhistas ou legais do Usuário decorrentes da posse, utilização, conversão, alienação, recebimento ou movimentação de ativos digitais. A responsabilidade pelo cumprimento de obrigações tributárias — incluindo, quando aplicável, quaisquer instruções normativas ou obrigações acessórias relacionadas a criptoativos e ou declaração de rendimentos sob sua legislação de residência fiscal — é integralmente do Usuário, incluindo a responsabilidade de monitorar transações próprias onchain para cumprir obrigações de caráter pessoal e próprio.\n\n9.4. O Aplicativo pode operar em versão BETA, podendo coexistir com versões de release estável por tempo determinado. O Usuário concorda que, durante o período BETA, podem ocorrer defeitos, instabilidades ou interrupções, e aceita todos os riscos decorrentes.\n\n9.5. As frases-semente geradas no Aplicativo são compatíveis com o padrão aberto BIP39 e com a Liquid Network. Em caso de indisponibilidade crítica do Aplicativo, descontinuação dos Serviços ou encerramento das atividades da Mooze, o Usuário poderá recuperar o acesso a seus ativos digitais importando suas frases-semente em qualquer software de carteira compatível com a rede correspondente (por exemplo, o Blockstream App para a Liquid Network e rede Bitcoin onchain qual automaticamente deriva todos os saldos em posse de usuário e seus históricos blockchains). Esta previsão constitui garantia estrutural da autocustódia e elemento integrante do modelo não-custodial da Mooze.'**
  String get terms_section_9_body;

  /// No description provided for @terms_section_10_body.
  ///
  /// In pt, this message translates to:
  /// **'10.1. A Mooze implementa mecanismos de segurança em nível de software para prevenção de fraudes, incluindo:\n(a) vinculação de APP ID (identificador técnico de dispositivo) a operações realizadas;\n(b) sistema de scoring por níveis de risco;\n(c) limites progressivos por operação conforme histórico do APP ID;\n(d) detecção de padrões anômalos (smurfing, bursting, autopagamentos coordenados, uso de múltiplos dispositivos para uma mesma operação, uso de emuladores, uso de dispositivos modificados).\n\n10.2. As medidas antifraude da Mooze são de natureza exclusivamente tecnológica, aplicadas ao fluxo de software, e não substituem as obrigações de prevenção à lavagem de dinheiro (AML), de identificação de clientes (KYC) e da \"Travel Rule\" das Parceiras Reguladas e demais VASPs intervenientes.\n\n10.3. As Parceiras Reguladas são as únicas responsáveis pelo cumprimento de obrigações de AML e KYC perante o Banco Central do Brasil, o COAF e demais autoridades competentes, nos termos da Lei n. 9.613/1998, da Lei n. 14.478/2022 e da regulamentação aplicável ou demais leis futuras que venham a ser acessórias.'**
  String get terms_section_10_body;

  /// No description provided for @terms_section_11_body.
  ///
  /// In pt, this message translates to:
  /// **'11.1. A Mooze reserva-se o direito de suspender, limitar ou encerrar o acesso de um APP ID aos Serviços, com ou sem aviso prévio, nas seguintes hipóteses:\n(a) detecção de padrão indicativo de fraude, atividade ilícita ou tentativa de abuso dos Serviços;\n(b) utilização de dispositivos comprometidos, rooted, com jailbreak, emuladores ou ferramentas de manipulação;\n(c) tentativa de contornar os mecanismos de segurança, antifraude, limites operacionais do Aplicativo, tentativas de sabotagem ou ataques a infraestrutura Mooze;\n(d) padrões indicativos de utilização dos Serviços para lavagem de dinheiro, financiamento ao terrorismo, sanções ou qualquer finalidade ilícita;\n(e) solicitação fundamentada de autoridade competente ou determinação judicial válida;\n(f) utilização a partir de jurisdição restrita nos termos da cláusula 12.1(a).\n\n11.2. A suspensão de acesso atinge exclusivamente a capacidade do APP ID de iniciar novas operações que utilizam-se de conexões ao sistema PIX das parceiras reguladas por meio do Aplicativo. Os ativos digitais em autocustódia do Usuário permanecem integralmente sob seu controle, uma vez que estão armazenados em sua própria carteira e são acessíveis por meio de sua frase-semente em qualquer software de carteira compatível com a rede correspondente.\n\n11.3. A Mooze cooperará com autoridades competentes mediante determinação judicial válida, observadas as limitações técnicas inerentes ao modelo autocustodial (a Mooze não possui acesso a chaves privadas, frases-semente ou ativos digitais do Usuário). A cooperação da Mooze limita-se ao fornecimento dos dados efetivamente sob sua posse técnica (APP ID, endereços públicos, dados de transação, blinding keys), nos termos da Seção 5 da Política de Privacidade.\n\n11.4. Os procedimentos de MED são processados pelas Parceiras Reguladas, entidades participantes do sistema PIX. A Mooze colabora tecnologicamente com as Parceiras Reguladas, fornecendo informações de APP ID e dados de transação quando solicitada, mas não opera como participante do sistema PIX.'**
  String get terms_section_11_body;

  /// No description provided for @terms_section_12_body.
  ///
  /// In pt, this message translates to:
  /// **'12.1. O Usuário declara, garante e assume, de forma expressa e informada, que:\n(a) utiliza os Serviços em conformidade com a legislação aplicável em sua jurisdição de domicílio e residência. O Usuário declara não ser residente, domiciliado, cidadão, nacional ou \"US Person\" nos termos da Regulation S (SEC), nem residente, nacional ou cidadão de: (i) Estados Unidos da América e seus territórios; (ii) Reino Unido; (iii) Estados-Membros da União Europeia e do Espaço Econômico Europeu; (iv) jurisdições constantes das listas de sanções OFAC (U.S. Office of Foreign Assets Control), das sanções do Conselho de Segurança das Nações Unidas, das sanções da União Europeia ou do Reino Unido; (v) jurisdições classificadas pelo FATF como High-Risk Jurisdictions Subject to a Call for Action, a Mooze poderá fazer uso de meios de verificação de regionalidade para cumprir tais verificações, qual o usuário fica ciente e de acordo. Caso se constate, a qualquer tempo, que o Usuário é residente, nacional ou cidadão de jurisdição restrita, o acesso do APP ID aos Serviços poderá ser imediatamente suspenso ou encerrado. A presente cláusula não estende, em nenhuma hipótese, jurisdição regulatória sobre a Mooze Labs LLC em relação a tais jurisdições, tendo efeito exclusivamente de filtro contratual;\n(b) os recursos utilizados em operações via PIX são de origem lícita e comprovável, decorrentes de atividades legalmente exercidas;\n(c) não utiliza os Serviços para lavagem de dinheiro, financiamento ao terrorismo, evasão fiscal, evasão de sanções, tráfico de pessoas, tráfico de entorpecentes, corrupção ou qualquer finalidade ilícita;\n(d) é o responsável exclusivo pela declaração e pagamento de tributos incidentes sobre a posse, utilização, recebimento, conversão ou alienação de ativos digitais em sua jurisdição, incluindo, quando aplicável, o cumprimento da Instruções Normativas nacionais relativas à sua residência fiscal ou cidadania atual.\n(e) deve utilizar os Serviços somente com conhecimento das obrigações de regimento de criptoativos de sua residência fiscal ou nacionalidade e reconhece que a Mooze não se enquadra como prestadora de serviços de ativos virtuais (PSAV) nos termos da referida lei, uma vez que (i) não realiza custódia, intermediação, administração, negociação ou corretagem de ativos virtuais em nome ou por conta de terceiros, (ii) opera exclusivamente como provedora de software não-custodial, (iii) tem sede fora do território brasileiro, em jurisdição estrangeira;\n(f) compreende e aceita que obteve acesso aos Serviços por busca ativa e voluntária própria (reverse solicitation), sem que tenha sido objeto de coerção ou persuasão linguística de nenhuma natureza iniciada pela Mooze;\n(g) compreende e aceita os riscos inerentes à tecnologia blockchain, incluindo volatilidade, risco regulatório, risco de forks, risco tecnológico e risco de perda total.\n\n12.2. A Mooze não presta serviços de consultoria tributária, fiscal ou jurídica. O Usuário deve buscar orientação profissional independente para o cumprimento de suas obrigações legais.\n\n12.3. A Mooze não realiza, em nome do Usuário, declarações fiscais, relatórios de operações, informes de rendimentos ou comunicações a qualquer autoridade tributária. O Usuário é o único responsável por tais obrigações.\n\n12.4. A Mooze não presta Serviços a pessoas politicamente expostas (PEPs) sujeitas a restrições específicas de jurisdições sancionadoras, devendo o Usuário declarar-se adequadamente e abster-se de utilizar os Serviços em violação a tais restrições.'**
  String get terms_section_12_body;

  /// No description provided for @terms_section_13_body.
  ///
  /// In pt, this message translates to:
  /// **'13.1. Estes Termos são regidos exclusivamente pelas leis da República das Ilhas Marshall, incluindo, em especial, a Associations Law (Título 52, MIRC) e a Banking (Amendment) Act, 2020 (P.L. 2020-61).\n\n13.2. A Mooze Labs LLC é entidade regularmente constituída na República das Ilhas Marshall e opera a partir dessa jurisdição. A Mooze NÃO possui estabelecimento permanente, filial, sucursal, escritório de representação, agência, preposto ou qualquer forma de presença física, operacional ou jurídica no Brasil ou em qualquer outra jurisdição, exceto pela jurisdição de constituição.\n\n13.3. A relação entre a Mooze e as Parceiras Reguladas é regida por contratos internacionais independentes, os quais não criam qualquer vínculo societário, relação de representação, agência, mandato, preposição, consórcio ou responsabilidade solidária entre a Mooze e tais parceiras.\n\n13.4. A eventual utilização dos Serviços por Usuário domiciliado no Brasil não implica, por si só, submissão da Mooze à jurisdição brasileira, em razão do caráter de Oferta Passiva e da ausência de estabelecimento no país, observados os limites das leis imperativas aplicáveis.'**
  String get terms_section_13_body;

  /// No description provided for @terms_section_14_body.
  ///
  /// In pt, this message translates to:
  /// **'14.1. Qualquer disputa, controvérsia ou reclamação decorrente destes Termos, ou a eles relacionada, será resolvida, a exclusivo critério da Mooze:\n(a) pelos tribunais competentes da República das Ilhas Marshall; ou\n(b) por arbitragem internacional conduzida sob as Regras de Arbitragem da UNCITRAL (Comissão das Nações Unidas para o Direito Comercial Internacional), por árbitro único, no idioma inglês, com sede da arbitragem a ser definida pela Mooze.\n\n14.2. O Usuário renuncia a qualquer foro que não os indicados na cláusula 14.1, exceto quando a renúncia for vedada por lei imperativa de sua jurisdição de domicílio.\n\n14.3. Antes de iniciar qualquer procedimento formal, o Usuário deverá enviar notificação redigida à Mooze mediante dados completos obtidos de aplicativo ou Plataforma Mooze, pelo canal indicado na Seção 19, descrevendo detalhadamente a necessidade. As partes envidarão esforços de boa-fé para resolução amigável no prazo de 30 (trinta) dias corridos a partir do recebimento da notificação.\n\n14.4. Em caso de arbitragem, cada parte arcará com seus próprios custos e honorários, e os custos administrativos da arbitragem serão suportados pela parte vencida, na medida do permitido pelas Regras UNCITRAL.'**
  String get terms_section_14_body;

  /// No description provided for @terms_section_15_body.
  ///
  /// In pt, this message translates to:
  /// **'15.1. Todo o software, código-fonte, design, interface gráfica, marcas, logotipos, nomes comerciais, conteúdo editorial e documentação do Aplicativo são de propriedade exclusiva da Mooze Labs LLC ou de seus licenciadores, salvo quando expressamente disponibilizados como código aberto em repositório oficial da Mooze no GitHub. O que não for expressamente disponibilizado como código aberto permanece protegido pela legislação aplicável de propriedade intelectual.\n\n15.2. A utilização do Aplicativo não confere ao Usuário qualquer direito de propriedade intelectual sobre o Aplicativo ou seus componentes, salvo os direitos limitados de uso pessoal decorrentes destes Termos.\n\n15.3. É vedada a reprodução, modificação, distribuição, engenharia reversa, descompilação, desmontagem ou criação de obras derivadas do Aplicativo sem autorização expressa e por escrito da Mooze, à exceção do que for expressamente disponibilizado como código aberto no repositório oficial da Mooze e utilizado nos termos da licença ali indicada.\n\n15.4. O código-fonte do Aplicativo está disponibilizado publicamente em https://github.com/mooze-labs/mooze-client sob os termos da licença ali indicada. O uso do código-fonte está sujeito exclusivamente aos termos dessa licença, independentemente dos presentes Termos.'**
  String get terms_section_15_body;

  /// No description provided for @terms_section_16_body.
  ///
  /// In pt, this message translates to:
  /// **'16.1. INTEGRALIDADE\nEstes Termos, conjuntamente com a Política de Privacidade que os acompanha, constituem o acordo integral entre a Mooze e o Usuário em relação ao objeto aqui tratado, substituindo quaisquer acordos, entendimentos, memorandos ou comunicações anteriores, orais ou escritos.\n\n16.2. SEVERABILIDADE\nSe qualquer disposição destes Termos for declarada inválida, nula, ilegal ou inexequível por tribunal ou árbitro competente, as demais disposições permanecerão em pleno vigor e efeito. A disposição inválida será interpretada e, sendo possível, substituída por disposição válida que mais se aproxime da intenção original das partes e do equilíbrio econômico-jurídico do contrato.\n\n16.3. RENÚNCIA\nA omissão ou tolerância da Mooze em exigir o cumprimento de qualquer disposição destes Termos, em uma ou mais ocasiões, não constituirá renúncia ao direito de exigi-la posteriormente.\n\n16.4. CESSÃO\nO Usuário não pode ceder, transferir, sublicenciar ou onerar seus direitos ou obrigações decorrentes destes Termos sem autorização prévia e por escrito da Mooze. A Mooze pode ceder livremente seus direitos e obrigações decorrentes destes Termos a qualquer entidade afiliada, sucessora, adquirente ou cessionária, mediante notificação ao Usuário pelos canais oficiais.\n\n16.5. FORÇA MAIOR E ILEGALIDADE SUPERVENIENTE\nA Mooze não será responsável por atraso ou impossibilidade de cumprimento de suas obrigações decorrente de eventos fora de seu controle razoável, incluindo, sem limitação:\n(a) falhas ou interrupções na Liquid Network, na rede Bitcoin, na Lightning Network ou em qualquer rede blockchain;\n(b) indisponibilidade de serviços das Parceiras Reguladas ou de provedores de infraestrutura de terceiros;\n(c) ataques cibernéticos, falhas de infraestrutura de internet ou de telecomunicações;\n(d) decisões governamentais, regulatórias ou judiciais, em qualquer jurisdição, que restrinjam ou inviabilizem a operação;\n(e) desastres naturais, pandemias, guerras, greves, distúrbios civis ou estados de emergência;\n(f) alterações legislativas ou regulatórias que tornem a prestação dos Serviços ilegal ou inviável em determinada jurisdição, caso no qual a Mooze poderá suspender ou encerrar os Serviços na respectiva jurisdição sem responsabilidade adicional, observada a autocustódia dos ativos do Usuário.\n\n16.6. INDENIZAÇÃO\nO Usuário concorda em indenizar, defender e isentar a Mooze, suas afiliadas, diretores, membros, empregados, contratados, agentes e licenciadores de quaisquer reclamações, danos, perdas, custos (incluindo honorários advocatícios razoáveis) e responsabilidades decorrentes de:\n(a) utilização dos Serviços pelo Usuário em desconformidade com estes Termos;\n(b) violação de qualquer lei ou regulamento aplicável pelo Usuário;\n(c) reclamações de terceiros relacionadas a atos ou omissões do Usuário;\n(d) prestação de informações falsas, inexatas ou omissas pelo Usuário, inclusive quanto a declarações falsas sobre não-residência em jurisdições restritas e sobre a origem lícita de recursos.\n\n16.7. DISTRIBUIÇÃO DO APLICATIVO\nA distribuição do Aplicativo em plataformas digitais, incluindo Google Play Store, Apple App Store e demais canais, é realizada conjuntamente pela Mooze LLC, sociedade de responsabilidade limitada constituída no Estado de Delaware, Estados Unidos, na qualidade de distribuidora autorizada da Mooze Labs LLC, nos termos de contrato de distribuição independente celebrado entre as partes. A Mooze LLC (Delaware) atua exclusivamente como distribuidora e representante para fins de publicação em plataformas digitais, sem assumir quaisquer responsabilidades de desenvolvimento, operação, suporte ao usuário, conformidade regulatória ou custódia de ativos. A titularidade, o desenvolvimento, a operação e todas as responsabilidades legais, regulatórias e contratuais relativas ao Aplicativo e aos Serviços permanecem exclusivamente com a Mooze Labs LLC (República das Ilhas Marshall). A relação entre a Mooze Labs LLC e a Mooze LLC (Delaware) não altera a natureza jurídica, o enquadramento regulatório, a jurisdição aplicável ou quaisquer disposições destes Termos. O cumprimento das políticas de distribuição das lojas de aplicativos (incluindo, sem limitação, as políticas Cryptocurrency Exchanges and Software Wallets — Google Play e App Store Review Guidelines 3.1.5 — Apple) é realizado mediante declaração de que a Mooze Wallet é carteira exclusivamente não-custodial, fora do escopo que exige licença VASP para publicação.\n\n16.8. IDIOMA\nEstes Termos são redigidos originalmente em português do Brasil. Em caso de traduções para outros idiomas, a versão em português prevalece em eventual divergência de interpretação, todos os termos aqui redigidos apresentados, principalmente em português brasileiro, existem com o único e exclusivo fim de esclarecimento ao público regional do LATAM, principal região onde os serviços PIX do Brasil existem com maior alcance, não devendo ser interpretado este fato de comunicação como intenção de sede e ou execução de serviços software sob territórios além da constituição da Mooze Labs LLC.'**
  String get terms_section_16_body;

  /// No description provided for @terms_section_17_body.
  ///
  /// In pt, this message translates to:
  /// **'17.1. O Aplicativo e os Serviços são destinados exclusivamente a pessoas naturais com idade igual ou superior a 18 (dezoito) anos.\n\n17.2. Ao utilizar o Aplicativo, o Usuário declara ter pelo menos 18 (dezoito) anos de idade e possuir capacidade civil plena para celebrar contratos vinculantes.\n\n17.3. A Mooze reserva-se o direito de suspender ou encerrar o acesso de qualquer Usuário em relação ao qual se verifique ser menor de 18 (dezoito) anos não emancipado.\n\n17.4. O Aplicativo constitui exclusivamente software de gestão de carteira digital autocustodial e instrumentação de operações financeiras com ativos digitais, não configurando rede social, plataforma de mídia social, serviço de mensageria, plataforma de streaming, serviço de entretenimento, aplicação de jogos eletrônicos ou qualquer modalidade de plataforma digital com funcionalidades de engajamento ou interação social entre usuários.\n\nEm razão dessa natureza, a Mooze não se enquadra no escopo de aplicação da Lei n. 15.211/2025 (Lei de Proteção de Crianças e Adolescentes no Ambiente Digital — \"ECA Digital\"), cujas obrigações se dirigem a redes sociais, plataformas de entretenimento, jogos eletrônicos e serviços com funcionalidades aditivas ou de engajamento comportamental. A Mooze não disponibiliza, e não possui capacidade técnica de disponibilizar:\n\n(a) funcionalidades de criação, publicação ou compartilhamento de conteúdo entre usuários;\n(b) mecanismos de interação social (curtidas, comentários, reações, compartilhamentos);\n(c) redes de contatos, seguidores, amizades ou conexões entre usuários;\n(d) algoritmos de recomendação de conteúdo, feeds personalizados ou scroll infinito;\n(e) chat, mensageria, comunicação direta ou indireta entre usuários do Aplicativo;\n(f) perfis públicos de usuários, timelines ou espaços de conteúdo gerado por usuários;\n(g) mecanismos de gamificação, recompensas por engajamento, notificações comportamentais ou recursos projetados para maximizar o tempo de uso.\n\nA utilização dos Serviços por brasileiros pressupõe, de forma estrutural e inafastável, a capacidade civil plena do Usuário, nos termos dos artigos 3º, 4º e 5º da Lei n. 10.406/2002 (Código Civil Brasileiro), uma vez que os Serviços envolvem celebração de contratos vinculantes e disposição de ativos financeiros — atos jurídicos que menores não emancipados são legalmente inaptos a praticar por conta própria. Esse requisito estrutural configura, por si só, mecanismo jurídico de exclusão do público infanto-juvenil incompatível com qualquer enquadramento como plataforma digital sujeita às obrigações da Lei n. 15.211/2025 ou às disposições do Estatuto da Criança e do Adolescente (Lei n. 8.069/1990) aplicáveis a serviços de entretenimento e conteúdo.'**
  String get terms_section_17_body;

  /// No description provided for @terms_section_18_body.
  ///
  /// In pt, this message translates to:
  /// **'18.1. A Mooze reserva-se o direito de alterar estes Termos a qualquer momento, publicando a versão atualizada no Aplicativo e em https://mooze.app/termosdeuso/, com indicação da data da nova versão.\n\n18.2. Alterações relevantes serão comunicadas ao Usuário por meio do Aplicativo, canal de suporte no Telegram ou comunicação via e-mail, quando disponível.\n\n18.3. A continuidade de utilização do Aplicativo após a publicação de alterações constitui aceitação tácita dos Termos atualizados.\n\n18.4. O Usuário que não concordar com as alterações deverá cessar a utilização do Aplicativo. Os ativos digitais em autocustódia do Usuário permanecem sob seu exclusivo controle e são acessíveis por meio de sua frase-semente em qualquer software de carteira compatível.'**
  String get terms_section_18_body;

  /// No description provided for @terms_section_19_body.
  ///
  /// In pt, this message translates to:
  /// **'19.1. Para dúvidas, solicitações ou comunicações relacionadas a estes Termos, o Usuário poderá contatar a Mooze pelos seguintes canais oficiais:\n(a) E-mail de suporte: suporte@mooze.app\n(b) Canal de suporte no Telegram: https://t.me/+zkNS6KIDsEcyZDkx (também acessível via https://moozeapp.keepo.bio)\n(c) FAQ automatizado via Telegram\n\n19.2. Notificações formais de natureza jurídica (incluindo notificações de disputa nos termos da cláusula 14.3, intimações, citações ou ordens judiciais) devem ser endereçadas por escrito à Mooze Labs LLC, Trust Company Complex, Ajeltake Island, Ajeltake Road, Majuro, Marshall Islands MH96960, República das Ilhas Marshall, com cópia para o e-mail suporte@mooze.app, não constituindo citação válida o envio por quaisquer outros canais ou jurisdições.\n\n19.3. A Mooze envidará esforços para responder a comunicações de suporte no prazo de 2 (dois) a 10 (dez) dias úteis. Notificações formais serão respondidas nos prazos aplicáveis da legislação de RMI ou da arbitragem UNCITRAL, conforme o caso.'**
  String get terms_section_19_body;

  /// No description provided for @privacy_section_header_body.
  ///
  /// In pt, this message translates to:
  /// **'Data da última atualização: 18/04/2026\n\nMooze Labs LLC\nRepública das Ilhas Marshall\nhttps://mooze.app'**
  String get privacy_section_header_body;

  /// No description provided for @privacy_section_1_body.
  ///
  /// In pt, this message translates to:
  /// **'1.1. A Mooze Labs LLC (\"Mooze\"), sociedade regularmente constituída na República das Ilhas Marshall, está comprometida com a proteção da privacidade e com a minimização de dados pessoais no uso do aplicativo Mooze Wallet (\"Aplicativo\").\n\n1.2. Esta Política de Privacidade (\"Política\") descreve quais informações são coletadas, como são utilizadas, com quem são compartilhadas e quais direitos o Usuário possui em relação a seus dados.\n\n1.3. A Mooze adota o princípio de minimização de dados como pilar central de sua operação. O Aplicativo foi projetado para funcionar sem a coleta de dados pessoais identificáveis pela Mooze.\n\n1.4. Esta Política deve ser lida em conjunto com os Termos de Uso do Aplicativo.'**
  String get privacy_section_1_body;

  /// No description provided for @privacy_section_2_body.
  ///
  /// In pt, this message translates to:
  /// **'2.1. Todos os termos definidos nos Termos de Uso e utilizados nesta Política possuem os mesmos significados atribuídos na Seção 3 dos Termos de Uso, salvo disposição expressa em contrário neste documento.\n\n2.2. Para fins desta Política, aplicam-se adicionalmente as seguintes definições:\n(a) \"Dados Pessoais\": qualquer informação relacionada a pessoa natural identificada ou identificável, nos termos da Lei Geral de Proteção de Dados (Lei n. 13.709/2018 — LGPD) ou de legislação equivalente.\n(b) \"Tratamento\": toda operação realizada com Dados Pessoais, incluindo coleta, armazenamento, uso, compartilhamento e eliminação.\n(c) \"LGPD\": Lei Geral de Proteção de Dados do Brasil (Lei n. 13.709/2018).\n(d) \"Controlador\" e \"Operador\": as figuras definidas na LGPD, aplicáveis, quando cabível, às relações entre a Mooze, o Usuário e as Parceiras Reguladas.'**
  String get privacy_section_2_body;

  /// No description provided for @privacy_section_3_body.
  ///
  /// In pt, this message translates to:
  /// **'3.1. DADOS QUE A MOOZE NÃO COLETA NEM ARMAZENA\nA Mooze NÃO faz coleta em seus sistemas ou servidores, em relação a Usuários do Aplicativo:\n(a) CPF, RG, passaporte ou qualquer documento de identificação civil;\n(b) nome civil completo;\n(c) número de telefone;\n(d) endereço residencial ou de correspondência;\n(e) data de nascimento;\n(f) dados biométricos (a identificação de dispositivo utilizada é hash criptográfico unidirecional, não constituindo biometria pessoal);\n(g) chaves privadas, frases-semente ou senhas do Usuário;\n(h) imagens, fotografias ou vídeos: a câmera do dispositivo é acessada exclusivamente para leitura de códigos QR (endereços e faturas de pagamento), com processamento realizado localmente no próprio dispositivo; nenhuma imagem ou captura é coletada, armazenada ou transmitida à Mooze ou a terceiros.\n\n3.2. DADOS QUE A MOOZE COLETA\nA Mooze coleta exclusivamente os seguintes dados:\n(a) APP ID: identificador técnico de dispositivo, gerado a partir de funcionalidades do sistema operacional (MediaDRM em dispositivos Android, DeviceCheck em dispositivos iOS). O APP ID é hash criptográfico unidirecional que, isoladamente, não permite a identificação pessoal do Usuário. É utilizado exclusivamente para prevenção a fraudes e controle de limites operacionais.\n(b) Dados de carteira: descriptors, endereços e chaves públicas derivados matematicamente das chaves do Usuário, utilizados como parâmetro técnico de roteamento automatizado para a entrega de ativos digitais ao Usuário durante a execução dos Serviços, nenhum desses dados permite à Mooze mover ou acessar fundos de usuários.\n(c) Blinding keys (chaves de ocultação): chaves criptográficas associadas a Confidential Transactions na Liquid Network, retidas pela Mooze exclusivamente para verificação e reconciliação de transações processadas por meio do Aplicativo nas funções envolvendo Infratechs Parceiras via PIX.\n(d) Dados de transação: registros das operações realizadas por meio do Aplicativo, incluindo valores, tipos de ativos, carimbos temporais (timestamps), hashes de transação e status de execução. Esses dados são retidos para fins de prestação do Serviço, suporte ao Usuário, reconciliação com parceiros e cumprimento de eventuais obrigações legais aplicáveis à Mooze enquanto entidade não-VASP.\n(e) Dados técnicos de dispositivo: informações genéricas de funcionamento do Aplicativo, como versão do sistema operacional, modelo do dispositivo, versão do Aplicativo instalada e logs internos essenciais para resolução de suporte e depuração técnica. Esses dados não permitem a identificação pessoal do Usuário.\n(f) Token de notificação (push): identificador técnico gerado pelo serviço Firebase Cloud Messaging (Google LLC), utilizado exclusivamente para o envio de notificações operacionais, como alertas de transação, ao dispositivo do Usuário. O token não contém dados pessoais identificáveis, não é utilizado para publicidade, e sua geração depende de permissão de notificações concedida pelo Usuário no dispositivo.\n\n3.3. PERMISSÕES DO DISPOSITIVO\nO Aplicativo solicita as seguintes permissões do dispositivo, sempre mediante autorização do Usuário no sistema operacional e com as finalidades a seguir indicadas:\n(a) Câmera: exclusivamente para leitura de códigos QR (endereços e faturas de pagamento), com processamento local; imagens não são coletadas, armazenadas nem transmitidas;\n(b) Notificações: exclusivamente para o envio de alertas operacionais de transação, por meio do serviço Firebase Cloud Messaging (Google LLC);\n(c) Autenticação biométrica ou credencial do dispositivo: exclusivamente para bloqueio de acesso local ao Aplicativo, processada pelo próprio sistema operacional do dispositivo; a Mooze não coleta, acessa nem armazena dados biométricos;\n(d) Acesso à rede e à internet: para comunicação com as redes Bitcoin, Liquid Network e Lightning Network e com os provedores de infraestrutura descritos nesta Política.'**
  String get privacy_section_3_body;

  /// No description provided for @privacy_section_4_body.
  ///
  /// In pt, this message translates to:
  /// **'4.1. Quando o Usuário realiza operações que envolvem pagamento via PIX (Serviço A relativos termos de uso), os dados necessários ao processamento do pagamento — incluindo nome civil do pagador, CPF do pagador, chave PIX, dados bancários e demais dados necessários ao cumprimento de obrigações de KYC, AML e Travel Rule — são coletados e processados exclusivamente pelas Parceiras Reguladas no Brasil via serviços indiretos ou diretos com nossas parceiras tecnológicas, nos limites de suas respectivas atividades via automações em sistemas vínculados ao sistema financeiro brasileiro.\n\n4.2. As Parceiras Reguladas são:\n\n(a) PLEBIT.COM.BR Soluções em Tecnologia Ltda — CNPJ 43.375.652/0001-13;\n(b) Fits Instituição de Pagamento — CNPJ 13.203.354/0001-85;\n(c) Celcoin — CNPJ 13.935.893/0001-09;\n(d) PLEBZ INTERMEDIACAO DE PAGAMENTOS LTDA — CNPJ 45.808.899/0001-01.\n\nEsta lista de parceiras pode diminuir ou ser acrescentada, de acordo modificações ou mudanças contratuais e suas disponibilidades.\n\n4.3. A coleta, o armazenamento e o tratamento de dados pessoais pelas Parceiras Reguladas são regidos pelas respectivas políticas de privacidade dessas entidades, em conformidade com a LGPD e com a regulamentação do Banco Central do Brasil. Cada Parceira Regulada atua como Controlador autônomo dos dados pessoais por ela tratados.\n\n4.4. A comunicação entre o software da Mooze e as Parceiras Reguladas limita-se a dados estritamente necessários ao roteamento automatizado da operação (valor, chaves públicas, endereço de carteira de destino, identificador da operação, identificadores criptográficos irreversíveis derivados de dados do pagador e quando necessário, APP ID para fins antifraude).\n\n4.5. A Eulen.app LLC, enquanto provedora de infraestrutura tecnológica e emissora do token DEPIX e demais parceiras infratechs podem coletar e processar dados operacionais necessários para a emissão dos tokens e atividades correlacionadas, conforme políticas de privacidade próprias, sem que a Mooze atue como Controlador de tais dados.'**
  String get privacy_section_4_body;

  /// No description provided for @privacy_section_5_body.
  ///
  /// In pt, this message translates to:
  /// **'5.1. A Mooze compartilha dados exclusivamente nas seguintes hipóteses:\n(a) Com as Parceiras Reguladas e com a Eulen.app LLC: dados estritamente necessários ao roteamento automatizado das operações (endereços de carteira, valores, identificadores de operação e APP ID quando necessário para fins antifraude).\n(b) Mediante determinação judicial: a Mooze poderá fornecer os dados sob sua posse (APP ID, endereços de carteira, blinding keys e dados correlacionados coletados) mediante ordem judicial válida emanada de tribunal competente, observadas as regras de reconhecimento internacional de decisões judiciais aplicáveis a entidades sediadas na República das Ilhas Marshall.\n(c) Para cumprimento de obrigação legal: quando exigido por lei aplicável na jurisdição da República das Ilhas Marshall.\n(d) Em procedimentos de MED conduzidos pelas Parceiras Reguladas: fornecimento técnico de APP ID e dados correlacionados necessários quando relatórios probatórios de execução de serviço ou exigências sob necessidade de defesa das mesmas for requisitado via demandas legais, regulatórias ou de compliance.\n\n5.2. A Mooze NÃO vende, aluga, comercializa, cede ou compartilha dados com terceiros para fins de marketing, publicidade, analytics comportamental ou qualquer finalidade não descrita nesta Política.\n\n5.3. Para viabilizar o envio de notificações push, o token de notificação do dispositivo é processado pelo serviço Firebase Cloud Messaging, fornecido pelo Google LLC, exclusivamente com essa finalidade. Nenhum outro dado pessoal é compartilhado com o Google para o envio de notificações.'**
  String get privacy_section_5_body;

  /// No description provided for @privacy_section_6_body.
  ///
  /// In pt, this message translates to:
  /// **'6.1. Quando o Usuário contata a Mooze por meio dos canais de suporte (e-mail suporte@mooze.app ou Telegram), os dados compartilhados voluntariamente pelo Usuário durante a comunicação (como nome de usuário em plataformas de mensagens, conteúdo das mensagens e eventuais capturas de tela) serão utilizados exclusivamente para fins de atendimento à solicitação.\n\n6.2. A Mooze não associa, como regra, dados de comunicação de suporte a APP IDs ou endereços de carteira, exceto quando o próprio Usuário fornecer tais informações voluntariamente para fins de resolução de problema específico.'**
  String get privacy_section_6_body;

  /// No description provided for @privacy_section_7_body.
  ///
  /// In pt, this message translates to:
  /// **'7.1. A Mooze adota medidas técnicas e organizacionais razoáveis, compatíveis com o estado da arte aplicável, para proteger os dados sob sua responsabilidade contra acesso não autorizado, destruição, perda, alteração, comunicação ou divulgação indevidas.\n\n7.2. Os dados coletados pela Mooze são armazenados em infraestrutura protegida, com controles de acesso e criptografia em trânsito e em repouso.\n\n7.3. A Mooze não pode garantir segurança absoluta na transmissão de dados pela internet ou em sistemas de armazenamento eletrônico. O Usuário reconhece que nenhum método de transmissão ou armazenamento eletrônico é integralmente imune a falhas.'**
  String get privacy_section_7_body;

  /// No description provided for @privacy_section_8_body.
  ///
  /// In pt, this message translates to:
  /// **'8.1. Os dados coletados pela Mooze são retidos pelos seguintes períodos:\n(a) APP ID: 5 (cinco) anos contados da última operação. Após esse período, será eliminado, salvo obrigação legal de retenção.\n(b) Endereços de carteira, descriptors, chaves públicas e blinding keys: 5 (cinco) anos contados da última operação, para fins de verificação, reconciliação e cumprimento de eventuais obrigações legais.\n(c) Dados de transação: 5 (cinco) anos contados da data da transação.\n(d) Dados técnicos de dispositivo: eliminados após 5 (cinco) anos de inatividade.\n\n8.2. Os prazos acima poderão ser estendidos quando necessário para: (a) cumprimento de obrigação legal; (b) atendimento a ordem judicial; (c) defesa em procedimento judicial, administrativo ou arbitral; (d) aprimoramento de sistemas antifraude próprios ou conjuntos com Parceiras Reguladas e Infratechs Parceiras, em volume minimamente necessário e de forma pseudonimizada sempre que possível.'**
  String get privacy_section_8_body;

  /// No description provided for @privacy_section_9_body.
  ///
  /// In pt, this message translates to:
  /// **'9.1. Em observância à LGPD, e sem prejuízo de a Mooze não estar estabelecida no Brasil, a Mooze reconhece ao Usuário, na medida aplicável ao tratamento efetivamente realizado, os seguintes direitos:\n(a) confirmação da existência de tratamento de dados pseudoanônimos;\n(b) avaliação de solicitação de eliminação do APP ID associado a seu dispositivo e usuário de serviço software Mooze\n\n9.2. O exercício dos direitos previstos na cláusula 9.1 pode ser solicitado pelo Usuário por meio dos canais indicados na Seção 12 desta Política.\n\n9.3. A Mooze responderá às solicitações no prazo de 15 (quinze) dias úteis, nos termos da LGPD, admitida prorrogação fundamentada em casos de complexidade técnica ou volume.\n\n9.4. A eliminação do APP ID, uma vez atendida a solicitação, resultará na desativação do acesso do dispositivo aos Serviços que envolvam referencial FIAT (Serviço A e Modo Comerciante de acordo termos de uso). Em caso de reinstalação do Aplicativo, o acesso do aparelho aos Serviços via meios FIAT permanecerá bloqueado até nova solicitação formal, encaminhada pelo mesmo e-mail utilizado na solicitação de exclusão, com aceitação expressa e integral destes Termos e da Política de Privacidade.\n\n9.5. Determinados dados poderão ser retidos ou negados de exclusão mesmo após solicitação de eliminação, quando necessário para: (a) cumprimento de obrigação legal; (b) exercício regular de direitos em processo judicial, administrativo ou arbitral; (c) prevenção a fraudes (principalmente se o usuário com seu APP ID tiver andamento em envolvimentos sob contestações de pagamentos ocorridas, exemplo, MED), nos termos do art. 7º, IX, e do art. 16 da LGPD; conforme prazos indicados na Seção 8.'**
  String get privacy_section_9_body;

  /// No description provided for @privacy_section_10_body.
  ///
  /// In pt, this message translates to:
  /// **'10.1. Os dados coletados pela Mooze são armazenados e processados em infraestrutura tecnológica localizada fora do território brasileiro.\n\n10.2. A jurisdição de dados aplicável à atividade de tratamento pela Mooze é a República das Ilhas Marshall, onde a Mooze está constituída e opera.\n\n10.3. Os dados operacionais transmitidos às Parceiras Reguladas durante a execução do Serviço A sob os termos de uso, são processados e armazenados no Brasil, sob a jurisdição brasileira e em conformidade com a LGPD, sob responsabilidade exclusiva das Parceiras Reguladas na qualidade de Controladores autônomos.\n\n10.4. A transferência de dados do Brasil para a infraestrutura da Mooze (quando houver), na medida em que constitua transferência internacional para fins da LGPD, é realizada com base nas hipóteses legais aplicáveis (art. 33 da LGPD), incluindo, conforme o caso, a necessidade de execução de contrato do qual o Usuário é parte e o cumprimento de obrigação legal.'**
  String get privacy_section_10_body;

  /// No description provided for @privacy_section_11_body.
  ///
  /// In pt, this message translates to:
  /// **'11.1. A Mooze reserva-se o direito de alterar esta Política a qualquer momento, publicando a versão atualizada no Aplicativo e em https://mooze.app/, com indicação da data da nova versão.\n\n11.2. Alterações relevantes serão comunicadas ao Usuário por meio do Aplicativo ou do canal de suporte no Telegram.\n\n11.3. A continuidade de utilização do Aplicativo após a publicação de alterações constitui aceitação tácita da Política atualizada.'**
  String get privacy_section_11_body;

  /// No description provided for @privacy_section_12_body.
  ///
  /// In pt, this message translates to:
  /// **'12.1. Para dúvidas ou solicitações relacionadas a esta Política de Privacidade, o Usuário poderá contatar a Mooze pelos seguintes canais oficiais:\n(a) E-mail: suporte@mooze.app\n(b) Canal de suporte no Telegram: https://t.me/+zkNS6KIDsEcyZDkx (também acessível via https://moozeapp.keepo.bio)\n(c) FAQ automatizado via Telegram\n\n12.2. Notificações formais relacionadas a dados pessoais devem ser endereçadas à Mooze Labs LLC, Trust Company Complex, Ajeltake Island, Ajeltake Road, Majuro, Marshall Islands MH96960, República das Ilhas Marshall, com cópia para o e-mail suporte@mooze.app, tais dados de encaminhamento poderão ser obtidos mediante contato por este mesmo e-mail.\n\n12.3. A Mooze envidará esforços para responder às comunicações no prazo de 15 (quinze) dias úteis.'**
  String get privacy_section_12_body;

  /// No description provided for @developer_title.
  ///
  /// In pt, this message translates to:
  /// **'Hub da Carteira'**
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

  /// No description provided for @developer_bitcoin_tip.
  ///
  /// In pt, this message translates to:
  /// **'Bloco Bitcoin atual'**
  String get developer_bitcoin_tip;

  /// No description provided for @developer_unavailable.
  ///
  /// In pt, this message translates to:
  /// **'indisponível'**
  String get developer_unavailable;

  /// No description provided for @developer_liquid_balances.
  ///
  /// In pt, this message translates to:
  /// **'Saldos Liquid'**
  String get developer_liquid_balances;

  /// No description provided for @developer_section_synchronisation.
  ///
  /// In pt, this message translates to:
  /// **'Sincronização'**
  String get developer_section_synchronisation;

  /// No description provided for @developer_section_diagnostics.
  ///
  /// In pt, this message translates to:
  /// **'Diagnósticos'**
  String get developer_section_diagnostics;

  /// No description provided for @developer_time_just_now.
  ///
  /// In pt, this message translates to:
  /// **'agora mesmo'**
  String get developer_time_just_now;

  /// No description provided for @developer_time_seconds_ago.
  ///
  /// In pt, this message translates to:
  /// **'há {seconds}s'**
  String developer_time_seconds_ago(int seconds);

  /// No description provided for @developer_time_minutes_ago.
  ///
  /// In pt, this message translates to:
  /// **'há {minutes}min'**
  String developer_time_minutes_ago(int minutes);

  /// No description provided for @developer_time_hours_ago.
  ///
  /// In pt, this message translates to:
  /// **'há {hours}h'**
  String developer_time_hours_ago(int hours);

  /// No description provided for @developer_time_days_ago.
  ///
  /// In pt, this message translates to:
  /// **'há {days}d'**
  String developer_time_days_ago(int days);

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

  /// No description provided for @logs_overview_title.
  ///
  /// In pt, this message translates to:
  /// **'Atividade de logs'**
  String get logs_overview_title;

  /// No description provided for @logs_overview_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Diagnóstico do app em tempo real'**
  String get logs_overview_subtitle;

  /// No description provided for @logs_source_label.
  ///
  /// In pt, this message translates to:
  /// **'Origem'**
  String get logs_source_label;

  /// No description provided for @logs_levels_label.
  ///
  /// In pt, this message translates to:
  /// **'Níveis'**
  String get logs_levels_label;

  /// No description provided for @logs_entries_label.
  ///
  /// In pt, this message translates to:
  /// **'entradas'**
  String get logs_entries_label;

  /// No description provided for @logs_detail_tag.
  ///
  /// In pt, this message translates to:
  /// **'Tag'**
  String get logs_detail_tag;

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

  /// No description provided for @receive_connection_error.
  ///
  /// In pt, this message translates to:
  /// **'Houve um problema de conexão. Por favor, tente novamente.'**
  String get receive_connection_error;

  /// No description provided for @receive_network_bitcoin_onchain.
  ///
  /// In pt, this message translates to:
  /// **'Bitcoin On-chain'**
  String get receive_network_bitcoin_onchain;

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

  /// No description provided for @receive_description_add.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar descrição'**
  String get receive_description_add;

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

  /// No description provided for @tx_detail_swap_completed.
  ///
  /// In pt, this message translates to:
  /// **'Troca concluída'**
  String get tx_detail_swap_completed;

  /// No description provided for @tx_detail_swap_in_progress.
  ///
  /// In pt, this message translates to:
  /// **'Troca em andamento'**
  String get tx_detail_swap_in_progress;

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

  /// No description provided for @swap_amount_bounds.
  ///
  /// In pt, this message translates to:
  /// **'Mín: {min} sats · Máx: {max} sats (saldo)'**
  String swap_amount_bounds(Object max, Object min);

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

  /// No description provided for @swap_expires_in.
  ///
  /// In pt, this message translates to:
  /// **'Expira em {seconds}s'**
  String swap_expires_in(int seconds);

  /// No description provided for @swap_quote_refreshing.
  ///
  /// In pt, this message translates to:
  /// **'Atualizando cotação...'**
  String get swap_quote_refreshing;

  /// No description provided for @swap_quote_outdated_title.
  ///
  /// In pt, this message translates to:
  /// **'Cotação desatualizada'**
  String get swap_quote_outdated_title;

  /// No description provided for @swap_quote_outdated_body.
  ///
  /// In pt, this message translates to:
  /// **'Toque em atualizar para obter a cotação mais recente.'**
  String get swap_quote_outdated_body;

  /// No description provided for @swap_refresh_action.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar'**
  String get swap_refresh_action;

  /// No description provided for @swap_rate_label.
  ///
  /// In pt, this message translates to:
  /// **'Cotação'**
  String get swap_rate_label;

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
  /// **'Bitcoin • Liquid'**
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

  /// No description provided for @qr_validation_lightning_unsupported.
  ///
  /// In pt, this message translates to:
  /// **'Lightning não é suportado para envio'**
  String get qr_validation_lightning_unsupported;

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

  /// No description provided for @wallet_import_phase_platform.
  ///
  /// In pt, this message translates to:
  /// **'Inicializando plataforma...'**
  String get wallet_import_phase_platform;

  /// No description provided for @wallet_import_phase_database.
  ///
  /// In pt, this message translates to:
  /// **'Preparando banco de dados...'**
  String get wallet_import_phase_database;

  /// No description provided for @wallet_import_phase_credentials.
  ///
  /// In pt, this message translates to:
  /// **'Carregando credenciais...'**
  String get wallet_import_phase_credentials;

  /// No description provided for @wallet_import_phase_connecting.
  ///
  /// In pt, this message translates to:
  /// **'Conectando às redes...'**
  String get wallet_import_phase_connecting;

  /// No description provided for @wallet_import_phase_authenticating.
  ///
  /// In pt, this message translates to:
  /// **'Autenticando sessão...'**
  String get wallet_import_phase_authenticating;

  /// No description provided for @wallet_import_phase_finalizing.
  ///
  /// In pt, this message translates to:
  /// **'Finalizando carteira...'**
  String get wallet_import_phase_finalizing;

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

  /// No description provided for @cpf_screen_title.
  ///
  /// In pt, this message translates to:
  /// **'Identificação do pagador'**
  String get cpf_screen_title;

  /// No description provided for @cpf_screen_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Informe o CPF ou CNPJ do pagador para gerar o QR Code Pix.'**
  String get cpf_screen_subtitle;

  /// No description provided for @cpf_field_label.
  ///
  /// In pt, this message translates to:
  /// **'CPF / CNPJ'**
  String get cpf_field_label;

  /// No description provided for @cpf_field_hint.
  ///
  /// In pt, this message translates to:
  /// **'000.000.000-00'**
  String get cpf_field_hint;

  /// No description provided for @cpf_error_required.
  ///
  /// In pt, this message translates to:
  /// **'Informe o CPF'**
  String get cpf_error_required;

  /// No description provided for @cpf_error_incomplete.
  ///
  /// In pt, this message translates to:
  /// **'Digite um CPF ou CNPJ válido'**
  String get cpf_error_incomplete;

  /// No description provided for @cpf_error_invalid.
  ///
  /// In pt, this message translates to:
  /// **'CPF ou CNPJ inválido'**
  String get cpf_error_invalid;

  /// No description provided for @cpf_continue.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get cpf_continue;

  /// No description provided for @cpf_save_as_favorite.
  ///
  /// In pt, this message translates to:
  /// **'Salvar como favorito'**
  String get cpf_save_as_favorite;

  /// No description provided for @cpf_save_this_payer.
  ///
  /// In pt, this message translates to:
  /// **'Salvar este pagador'**
  String get cpf_save_this_payer;

  /// No description provided for @cpf_favorite_label.
  ///
  /// In pt, this message translates to:
  /// **'Nome do pagador'**
  String get cpf_favorite_label;

  /// No description provided for @cpf_favorite_label_hint.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: João Silva'**
  String get cpf_favorite_label_hint;

  /// No description provided for @cpf_favorites_title.
  ///
  /// In pt, this message translates to:
  /// **'Pagadores favoritos'**
  String get cpf_favorites_title;

  /// No description provided for @cpf_favorites_empty_title.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum pagador salvo'**
  String get cpf_favorites_empty_title;

  /// No description provided for @cpf_favorites_empty_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Adicione um pagador para reutilizar o CPF nas próximas cobranças.'**
  String get cpf_favorites_empty_subtitle;

  /// No description provided for @cpf_favorites_add.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar pagador'**
  String get cpf_favorites_add;

  /// No description provided for @cpf_favorites_use_another.
  ///
  /// In pt, this message translates to:
  /// **'Usar outro CPF'**
  String get cpf_favorites_use_another;

  /// No description provided for @cpf_favorites_remove.
  ///
  /// In pt, this message translates to:
  /// **'Remover'**
  String get cpf_favorites_remove;

  /// No description provided for @cpf_favorites_section.
  ///
  /// In pt, this message translates to:
  /// **'Pagadores salvos'**
  String get cpf_favorites_section;

  /// No description provided for @cpf_favorites_view_all.
  ///
  /// In pt, this message translates to:
  /// **'Ver todos'**
  String get cpf_favorites_view_all;

  /// No description provided for @cpf_or_enter_manually.
  ///
  /// In pt, this message translates to:
  /// **'Ou digite um CPF'**
  String get cpf_or_enter_manually;

  /// No description provided for @cpf_favorites_label_required.
  ///
  /// In pt, this message translates to:
  /// **'Informe um nome'**
  String get cpf_favorites_label_required;

  /// No description provided for @cpf_favorites_duplicate.
  ///
  /// In pt, this message translates to:
  /// **'Este CPF já está salvo'**
  String get cpf_favorites_duplicate;

  /// No description provided for @cpf_favorites_add_title.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar pagador'**
  String get cpf_favorites_add_title;

  /// No description provided for @cpf_favorites_edit_title.
  ///
  /// In pt, this message translates to:
  /// **'Editar pagador'**
  String get cpf_favorites_edit_title;

  /// No description provided for @cpf_favorites_save.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get cpf_favorites_save;

  /// No description provided for @cpf_favorites_search_hint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar por nome'**
  String get cpf_favorites_search_hint;

  /// No description provided for @cpf_favorites_search_empty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum pagador encontrado'**
  String get cpf_favorites_search_empty;

  /// No description provided for @cpf_favorites_edit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get cpf_favorites_edit;

  /// No description provided for @cpf_favorites_actions.
  ///
  /// In pt, this message translates to:
  /// **'Ações'**
  String get cpf_favorites_actions;

  /// No description provided for @cpf_favorites_error.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os pagadores'**
  String get cpf_favorites_error;

  /// No description provided for @cpf_favorites_removed.
  ///
  /// In pt, this message translates to:
  /// **'Pagador removido'**
  String get cpf_favorites_removed;

  /// No description provided for @cpf_favorites_delete_title.
  ///
  /// In pt, this message translates to:
  /// **'Remover pagador?'**
  String get cpf_favorites_delete_title;

  /// No description provided for @cpf_favorites_delete_body.
  ///
  /// In pt, this message translates to:
  /// **'Remover {label} dos pagadores favoritos?'**
  String cpf_favorites_delete_body(String label);

  /// No description provided for @cpf_payment_warning.
  ///
  /// In pt, this message translates to:
  /// **'Use uma conta Pix vinculada ao CPF informado. Pagamentos de outra titularidade serão recusados.'**
  String get cpf_payment_warning;

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

  /// No description provided for @pix_deposit_status_processing_refund_1_3_label.
  ///
  /// In pt, this message translates to:
  /// **'Estornando 1/3'**
  String get pix_deposit_status_processing_refund_1_3_label;

  /// No description provided for @pix_deposit_status_processing_refund_2_3_label.
  ///
  /// In pt, this message translates to:
  /// **'Estornando 2/3'**
  String get pix_deposit_status_processing_refund_2_3_label;

  /// No description provided for @pix_deposit_status_processing_refund_3_3_label.
  ///
  /// In pt, this message translates to:
  /// **'Estornando 3/3'**
  String get pix_deposit_status_processing_refund_3_3_label;

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

  /// No description provided for @pix_tutorial_step1_title.
  ///
  /// In pt, this message translates to:
  /// **'Receba pagamentos com PIX'**
  String get pix_tutorial_step1_title;

  /// No description provided for @pix_tutorial_step1_body.
  ///
  /// In pt, this message translates to:
  /// **'Toque aqui para acessar a área PIX e começar a receber pagamentos rapidamente.'**
  String get pix_tutorial_step1_body;

  /// No description provided for @pix_tutorial_step2_title.
  ///
  /// In pt, this message translates to:
  /// **'Acesso rápido'**
  String get pix_tutorial_step2_title;

  /// No description provided for @pix_tutorial_step2_body.
  ///
  /// In pt, this message translates to:
  /// **'Você também pode acessar a área PIX por este atalho disponível em todo o aplicativo.'**
  String get pix_tutorial_step2_body;

  /// No description provided for @pix_tutorial_step3_title.
  ///
  /// In pt, this message translates to:
  /// **'Como você recebe pagamentos'**
  String get pix_tutorial_step3_title;

  /// No description provided for @pix_tutorial_step3_body.
  ///
  /// In pt, this message translates to:
  /// **'Por padrão, os pagamentos são recebidos em DEPIX, um ativo digital atrelado 1:1 ao Real. Cada 1 DEPIX equivale a R\$1,00.'**
  String get pix_tutorial_step3_body;

  /// No description provided for @pix_tutorial_step4_title.
  ///
  /// In pt, this message translates to:
  /// **'Escolha outro ativo'**
  String get pix_tutorial_step4_title;

  /// No description provided for @pix_tutorial_step4_body.
  ///
  /// In pt, this message translates to:
  /// **'Se preferir, você pode alterar o ativo de recebimento e receber pagamentos diretamente em Liquid Bitcoin (L-BTC).'**
  String get pix_tutorial_step4_body;

  /// No description provided for @pix_tutorial_step5_title.
  ///
  /// In pt, this message translates to:
  /// **'Converta quando quiser'**
  String get pix_tutorial_step5_title;

  /// No description provided for @pix_tutorial_step5_body.
  ///
  /// In pt, this message translates to:
  /// **'Mesmo recebendo pagamentos em DEPIX, você pode converter seu saldo para L-BTC ou USDT depois, usando a tela de Swap.'**
  String get pix_tutorial_step5_body;

  /// No description provided for @pix_tutorial_step6_title.
  ///
  /// In pt, this message translates to:
  /// **'Seu limite de recebimento'**
  String get pix_tutorial_step6_title;

  /// No description provided for @pix_tutorial_step6_body.
  ///
  /// In pt, this message translates to:
  /// **'Confira seus limites mínimos, máximos e o limite diário. Seus limites podem aumentar conforme o uso do aplicativo.'**
  String get pix_tutorial_step6_body;

  /// No description provided for @pix_tutorial_step7_title.
  ///
  /// In pt, this message translates to:
  /// **'Informe o valor'**
  String get pix_tutorial_step7_title;

  /// No description provided for @pix_tutorial_step7_body.
  ///
  /// In pt, this message translates to:
  /// **'Escolha o valor que deseja receber. Para este tutorial, usaremos R\$50,00 como exemplo.'**
  String get pix_tutorial_step7_body;

  /// No description provided for @pix_tutorial_step8_title.
  ///
  /// In pt, this message translates to:
  /// **'Gere uma cobrança PIX'**
  String get pix_tutorial_step8_title;

  /// No description provided for @pix_tutorial_step8_body.
  ///
  /// In pt, this message translates to:
  /// **'Depois de informar um valor, basta arrastar este botão até o fim para criar uma solicitação de pagamento PIX.'**
  String get pix_tutorial_step8_body;

  /// No description provided for @pix_tutorial_step9_title.
  ///
  /// In pt, this message translates to:
  /// **'QR Code pronto'**
  String get pix_tutorial_step9_title;

  /// No description provided for @pix_tutorial_step9_body.
  ///
  /// In pt, this message translates to:
  /// **'Após arrastar o botão, um QR Code PIX será gerado.'**
  String get pix_tutorial_step9_body;

  /// No description provided for @pix_tutorial_done_title.
  ///
  /// In pt, this message translates to:
  /// **'Tutorial concluído'**
  String get pix_tutorial_done_title;

  /// No description provided for @pix_tutorial_done_body.
  ///
  /// In pt, this message translates to:
  /// **'Agora você sabe como receber pagamentos com PIX, escolher seu ativo de recebimento, entender os limites e gerar QR Codes de pagamento.'**
  String get pix_tutorial_done_body;

  /// No description provided for @pix_tutorial_restart.
  ///
  /// In pt, this message translates to:
  /// **'Reiniciar tutorial'**
  String get pix_tutorial_restart;

  /// No description provided for @pix_tutorial_settings_replay.
  ///
  /// In pt, this message translates to:
  /// **'Rever tutorial do PIX'**
  String get pix_tutorial_settings_replay;

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

  /// No description provided for @merchant_payment_method_title.
  ///
  /// In pt, this message translates to:
  /// **'Como o cliente vai pagar?'**
  String get merchant_payment_method_title;

  /// No description provided for @merchant_payment_method_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Escolha uma opção para continuar.'**
  String get merchant_payment_method_subtitle;

  /// No description provided for @merchant_payment_method_qr_title.
  ///
  /// In pt, this message translates to:
  /// **'QR Code Pix'**
  String get merchant_payment_method_qr_title;

  /// No description provided for @merchant_payment_method_qr_description.
  ///
  /// In pt, this message translates to:
  /// **'Mostre o QR Code. O cliente paga no app do banco.'**
  String get merchant_payment_method_qr_description;

  /// No description provided for @merchant_payment_method_link_title.
  ///
  /// In pt, this message translates to:
  /// **'Link de pagamento'**
  String get merchant_payment_method_link_title;

  /// No description provided for @merchant_payment_method_link_description.
  ///
  /// In pt, this message translates to:
  /// **'Gere um link para o cliente pagar de onde estiver.'**
  String get merchant_payment_method_link_description;

  /// No description provided for @merchant_payment_method_tag_instant.
  ///
  /// In pt, this message translates to:
  /// **'Na hora'**
  String get merchant_payment_method_tag_instant;

  /// No description provided for @merchant_payment_method_tag_cpf.
  ///
  /// In pt, this message translates to:
  /// **'Pede CPF'**
  String get merchant_payment_method_tag_cpf;

  /// No description provided for @merchant_payment_method_tag_remote.
  ///
  /// In pt, this message translates to:
  /// **'À distância'**
  String get merchant_payment_method_tag_remote;

  /// No description provided for @merchant_payment_method_tag_browser.
  ///
  /// In pt, this message translates to:
  /// **'No navegador'**
  String get merchant_payment_method_tag_browser;

  /// No description provided for @merchant_payment_receive_in.
  ///
  /// In pt, this message translates to:
  /// **'Você recebe em {asset}'**
  String merchant_payment_receive_in(String asset);

  /// No description provided for @merchant_payment_link_scan_hint.
  ///
  /// In pt, this message translates to:
  /// **'O cliente escaneia o QR Code com a câmera do celular e paga pelo navegador.'**
  String get merchant_payment_link_scan_hint;

  /// No description provided for @merchant_payment_link_share.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar link'**
  String get merchant_payment_link_share;

  /// No description provided for @merchant_payment_link_creating.
  ///
  /// In pt, this message translates to:
  /// **'Gerando link de pagamento...'**
  String get merchant_payment_link_creating;

  /// No description provided for @merchant_payment_link_open.
  ///
  /// In pt, this message translates to:
  /// **'Abrir no navegador'**
  String get merchant_payment_link_open;

  /// No description provided for @merchant_payment_link_open_failed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir o navegador.'**
  String get merchant_payment_link_open_failed;

  /// No description provided for @merchant_payment_link_share_message.
  ///
  /// In pt, this message translates to:
  /// **'Pague {amount} com Pix: {url}'**
  String merchant_payment_link_share_message(String amount, String url);

  /// No description provided for @merchant_payment_link_done.
  ///
  /// In pt, this message translates to:
  /// **'Concluir venda'**
  String get merchant_payment_link_done;

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

  /// No description provided for @merchant_tutorial_skip.
  ///
  /// In pt, this message translates to:
  /// **'Pular'**
  String get merchant_tutorial_skip;

  /// No description provided for @merchant_total_label.
  ///
  /// In pt, this message translates to:
  /// **'Total da venda'**
  String get merchant_total_label;

  /// No description provided for @merchant_edit_action.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get merchant_edit_action;

  /// No description provided for @merchant_clear_cart_confirm_title.
  ///
  /// In pt, this message translates to:
  /// **'Limpar carrinho?'**
  String get merchant_clear_cart_confirm_title;

  /// No description provided for @merchant_clear_cart_confirm_body.
  ///
  /// In pt, this message translates to:
  /// **'Os itens desta venda serão removidos.'**
  String get merchant_clear_cart_confirm_body;

  /// No description provided for @merchant_product_name_required.
  ///
  /// In pt, this message translates to:
  /// **'Informe o nome do produto.'**
  String get merchant_product_name_required;

  /// No description provided for @merchant_product_price_required.
  ///
  /// In pt, this message translates to:
  /// **'Informe um preço maior que zero.'**
  String get merchant_product_price_required;

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

  /// No description provided for @pix_fees_back_to_top.
  ///
  /// In pt, this message translates to:
  /// **'Voltar ao topo'**
  String get pix_fees_back_to_top;

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

  /// No description provided for @tx_detail_fee.
  ///
  /// In pt, this message translates to:
  /// **'Taxa'**
  String get tx_detail_fee;

  /// No description provided for @tx_detail_datetime.
  ///
  /// In pt, this message translates to:
  /// **'{date} às {time}'**
  String tx_detail_datetime(String date, String time);

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

  /// No description provided for @tx_detail_received.
  ///
  /// In pt, this message translates to:
  /// **'Recebido'**
  String get tx_detail_received;

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

  /// No description provided for @tx_detail_view_send_tx.
  ///
  /// In pt, this message translates to:
  /// **'Ver transação de envio'**
  String get tx_detail_view_send_tx;

  /// No description provided for @tx_detail_view_refund_tx.
  ///
  /// In pt, this message translates to:
  /// **'Ver transação de reembolso'**
  String get tx_detail_view_refund_tx;

  /// No description provided for @tx_detail_send_tx_id.
  ///
  /// In pt, this message translates to:
  /// **'ID TX Envio'**
  String get tx_detail_send_tx_id;

  /// No description provided for @tx_detail_refund_tx_id.
  ///
  /// In pt, this message translates to:
  /// **'ID TX Reembolso'**
  String get tx_detail_refund_tx_id;

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
  /// **'Não foi possível sincronizar os serviços Mooze.'**
  String get sync_error_dialog_body;

  /// No description provided for @sync_error_warning.
  ///
  /// In pt, this message translates to:
  /// **'Operação não autorizada'**
  String get sync_error_warning;

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

  /// No description provided for @pin_change_title.
  ///
  /// In pt, this message translates to:
  /// **'Alterar PIN'**
  String get pin_change_title;

  /// No description provided for @pin_change_min_length.
  ///
  /// In pt, this message translates to:
  /// **'PIN deve ter pelo menos 6 caracteres'**
  String get pin_change_min_length;

  /// No description provided for @pin_change_yours.
  ///
  /// In pt, this message translates to:
  /// **'Crie seu novo '**
  String get pin_change_yours;

  /// No description provided for @pin_change_intro_prefix.
  ///
  /// In pt, this message translates to:
  /// **'Seu novo '**
  String get pin_change_intro_prefix;

  /// No description provided for @pin_change_intro_suffix.
  ///
  /// In pt, this message translates to:
  /// **'será utilizado para autorizar transações e acessar sua carteira.'**
  String get pin_change_intro_suffix;

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

  /// No description provided for @wallet_send_address_paste.
  ///
  /// In pt, this message translates to:
  /// **'Colar'**
  String get wallet_send_address_paste;

  /// No description provided for @wallet_send_address_clear.
  ///
  /// In pt, this message translates to:
  /// **'Limpar'**
  String get wallet_send_address_clear;

  /// No description provided for @wallet_send_address_paste_empty.
  ///
  /// In pt, this message translates to:
  /// **'Área de transferência vazia'**
  String get wallet_send_address_paste_empty;

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
  /// **'Saldo insuficiente para realizar o envio.\n\nVerifique se você tem saldo suficiente para cobrir o valor e as taxas da rede.'**
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

  /// No description provided for @wallet_send_error_self_transfer.
  ///
  /// In pt, this message translates to:
  /// **'Você não pode enviar para o seu próprio endereço'**
  String get wallet_send_error_self_transfer;

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

  /// No description provided for @wallet_action_buy.
  ///
  /// In pt, this message translates to:
  /// **'PIX'**
  String get wallet_action_buy;

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

  /// No description provided for @wallet_holding_allocation_title.
  ///
  /// In pt, this message translates to:
  /// **'Distribuição'**
  String get wallet_holding_allocation_title;

  /// No description provided for @wallet_tx_date_today.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get wallet_tx_date_today;

  /// No description provided for @wallet_tx_date_yesterday.
  ///
  /// In pt, this message translates to:
  /// **'Ontem'**
  String get wallet_tx_date_yesterday;

  /// No description provided for @wallet_action_more.
  ///
  /// In pt, this message translates to:
  /// **'Mais'**
  String get wallet_action_more;

  /// No description provided for @wallet_more_sheet_title.
  ///
  /// In pt, this message translates to:
  /// **'Mais ações'**
  String get wallet_more_sheet_title;

  /// No description provided for @wallet_more_buy_pix.
  ///
  /// In pt, this message translates to:
  /// **'Comprar com PIX'**
  String get wallet_more_buy_pix;

  /// No description provided for @wallet_balance_show.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar saldo'**
  String get wallet_balance_show;

  /// No description provided for @wallet_balance_hide.
  ///
  /// In pt, this message translates to:
  /// **'Ocultar saldo'**
  String get wallet_balance_hide;

  /// No description provided for @wallet_balance_hidden.
  ///
  /// In pt, this message translates to:
  /// **'Saldo oculto'**
  String get wallet_balance_hidden;

  /// No description provided for @wallet_balance_change_unit_hint.
  ///
  /// In pt, this message translates to:
  /// **'Alterar unidade'**
  String get wallet_balance_change_unit_hint;

  /// No description provided for @wallet_amount_hidden.
  ///
  /// In pt, this message translates to:
  /// **'Valor oculto'**
  String get wallet_amount_hidden;

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

  /// No description provided for @wallet_asset_stats_high.
  ///
  /// In pt, this message translates to:
  /// **'Máxima'**
  String get wallet_asset_stats_high;

  /// No description provided for @wallet_asset_stats_low.
  ///
  /// In pt, this message translates to:
  /// **'Mínima'**
  String get wallet_asset_stats_low;

  /// No description provided for @wallet_asset_stats_current.
  ///
  /// In pt, this message translates to:
  /// **'Atual'**
  String get wallet_asset_stats_current;

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

  /// No description provided for @address_explorer_title.
  ///
  /// In pt, this message translates to:
  /// **'Endereços e UTXOs'**
  String get address_explorer_title;

  /// No description provided for @address_explorer_search_hint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar endereço…'**
  String get address_explorer_search_hint;

  /// No description provided for @address_explorer_search_match_onchain.
  ///
  /// In pt, this message translates to:
  /// **'Endereço encontrado em On-chain.'**
  String get address_explorer_search_match_onchain;

  /// No description provided for @address_explorer_search_match_liquid.
  ///
  /// In pt, this message translates to:
  /// **'Endereço encontrado em Liquid.'**
  String get address_explorer_search_match_liquid;

  /// No description provided for @address_explorer_search_match_at_index.
  ///
  /// In pt, this message translates to:
  /// **'{chain} · índice {index}'**
  String address_explorer_search_match_at_index(String chain, int index);

  /// No description provided for @address_explorer_search_no_match.
  ///
  /// In pt, this message translates to:
  /// **'Endereço não pertence à sua carteira.'**
  String get address_explorer_search_no_match;

  /// No description provided for @address_explorer_tab_onchain.
  ///
  /// In pt, this message translates to:
  /// **'On-chain'**
  String get address_explorer_tab_onchain;

  /// No description provided for @address_explorer_tab_liquid.
  ///
  /// In pt, this message translates to:
  /// **'Liquid'**
  String get address_explorer_tab_liquid;

  /// No description provided for @address_explorer_load_more.
  ///
  /// In pt, this message translates to:
  /// **'Carregar mais {count} endereços'**
  String address_explorer_load_more(int count);

  /// No description provided for @address_explorer_loading_more.
  ///
  /// In pt, this message translates to:
  /// **'Carregando…'**
  String get address_explorer_loading_more;

  /// No description provided for @address_explorer_loading.
  ///
  /// In pt, this message translates to:
  /// **'Carregando endereços…'**
  String get address_explorer_loading;

  /// No description provided for @address_explorer_empty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum endereço encontrado.'**
  String get address_explorer_empty;

  /// No description provided for @address_explorer_load_error.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao carregar endereços: {error}'**
  String address_explorer_load_error(String error);

  /// No description provided for @address_explorer_address_copied.
  ///
  /// In pt, this message translates to:
  /// **'Endereço copiado'**
  String get address_explorer_address_copied;

  /// No description provided for @address_explorer_status_used.
  ///
  /// In pt, this message translates to:
  /// **'USADO'**
  String get address_explorer_status_used;

  /// No description provided for @address_explorer_status_unused.
  ///
  /// In pt, this message translates to:
  /// **'NÃO UTILIZADO'**
  String get address_explorer_status_unused;

  /// No description provided for @address_explorer_utxo_count.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{sem UTXOs} =1{1 UTXO} other{{count} UTXOs}}'**
  String address_explorer_utxo_count(int count);

  /// No description provided for @address_explorer_utxos_section.
  ///
  /// In pt, this message translates to:
  /// **'UTXOs'**
  String get address_explorer_utxos_section;

  /// No description provided for @address_explorer_utxos_tap_to_expand.
  ///
  /// In pt, this message translates to:
  /// **'toque para expandir'**
  String get address_explorer_utxos_tap_to_expand;

  /// No description provided for @address_explorer_utxos_tap_to_collapse.
  ///
  /// In pt, this message translates to:
  /// **'toque para recolher'**
  String get address_explorer_utxos_tap_to_collapse;

  /// No description provided for @address_explorer_summary.
  ///
  /// In pt, this message translates to:
  /// **'{total} endereços · {used} usados · {utxos} UTXOs'**
  String address_explorer_summary(int total, int used, int utxos);

  /// No description provided for @address_explorer_summary_addresses.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 endereço} other{{count} endereços}}'**
  String address_explorer_summary_addresses(int count);

  /// No description provided for @address_explorer_summary_status.
  ///
  /// In pt, this message translates to:
  /// **'{used} usados • {unused} não utilizados'**
  String address_explorer_summary_status(int used, int unused);

  /// No description provided for @address_explorer_summary_utxos_total.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{sem UTXOs} =1{1 UTXO} other{{count} UTXOs}}'**
  String address_explorer_summary_utxos_total(int count);

  /// No description provided for @address_explorer_total_received.
  ///
  /// In pt, this message translates to:
  /// **'Recebido: {amount}'**
  String address_explorer_total_received(String amount);

  /// No description provided for @address_explorer_filter_all.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get address_explorer_filter_all;

  /// No description provided for @address_explorer_filter_used.
  ///
  /// In pt, this message translates to:
  /// **'Usados'**
  String get address_explorer_filter_used;

  /// No description provided for @address_explorer_filter_unused.
  ///
  /// In pt, this message translates to:
  /// **'Não utilizados'**
  String get address_explorer_filter_unused;

  /// No description provided for @address_explorer_filter_with_utxos.
  ///
  /// In pt, this message translates to:
  /// **'Com UTXOs'**
  String get address_explorer_filter_with_utxos;

  /// No description provided for @address_explorer_filter_empty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum endereço corresponde ao filtro atual.'**
  String get address_explorer_filter_empty;

  /// No description provided for @address_explorer_full_address_title.
  ///
  /// In pt, this message translates to:
  /// **'Endereço'**
  String get address_explorer_full_address_title;

  /// No description provided for @address_explorer_full_address_copy.
  ///
  /// In pt, this message translates to:
  /// **'Copiar endereço'**
  String get address_explorer_full_address_copy;

  /// No description provided for @address_explorer_close.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get address_explorer_close;

  /// No description provided for @address_ownership_title.
  ///
  /// In pt, this message translates to:
  /// **'Verificar endereço'**
  String get address_ownership_title;

  /// No description provided for @address_ownership_description.
  ///
  /// In pt, this message translates to:
  /// **'Cole um endereço para verificar a propriedade'**
  String get address_ownership_description;

  /// No description provided for @address_ownership_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Suporta Bitcoin e Liquid'**
  String get address_ownership_subtitle;

  /// No description provided for @address_ownership_input_hint.
  ///
  /// In pt, this message translates to:
  /// **'bc1q… / lq1… / 1A1z…'**
  String get address_ownership_input_hint;

  /// No description provided for @address_ownership_paste_tooltip.
  ///
  /// In pt, this message translates to:
  /// **'Colar'**
  String get address_ownership_paste_tooltip;

  /// No description provided for @address_ownership_clear_tooltip.
  ///
  /// In pt, this message translates to:
  /// **'Limpar'**
  String get address_ownership_clear_tooltip;

  /// No description provided for @address_ownership_verify.
  ///
  /// In pt, this message translates to:
  /// **'Verificar'**
  String get address_ownership_verify;

  /// No description provided for @address_ownership_verifying.
  ///
  /// In pt, this message translates to:
  /// **'Verificando…'**
  String get address_ownership_verifying;

  /// No description provided for @address_ownership_clear.
  ///
  /// In pt, this message translates to:
  /// **'Limpar'**
  String get address_ownership_clear;

  /// No description provided for @address_ownership_paste_feedback.
  ///
  /// In pt, this message translates to:
  /// **'Colado da área de transferência'**
  String get address_ownership_paste_feedback;

  /// No description provided for @address_ownership_clear_feedback.
  ///
  /// In pt, this message translates to:
  /// **'Limpo'**
  String get address_ownership_clear_feedback;

  /// No description provided for @address_ownership_detected.
  ///
  /// In pt, this message translates to:
  /// **'Detectado: {chain}'**
  String address_ownership_detected(String chain);

  /// No description provided for @address_ownership_invalid_format.
  ///
  /// In pt, this message translates to:
  /// **'Formato de endereço inválido'**
  String get address_ownership_invalid_format;

  /// No description provided for @address_ownership_owned_title.
  ///
  /// In pt, this message translates to:
  /// **'Seu endereço'**
  String get address_ownership_owned_title;

  /// No description provided for @address_ownership_not_owned_title.
  ///
  /// In pt, this message translates to:
  /// **'Não é o seu endereço'**
  String get address_ownership_not_owned_title;

  /// No description provided for @address_ownership_field_type.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get address_ownership_field_type;

  /// No description provided for @address_ownership_field_utxos.
  ///
  /// In pt, this message translates to:
  /// **'UTXOs'**
  String get address_ownership_field_utxos;

  /// No description provided for @address_ownership_field_used.
  ///
  /// In pt, this message translates to:
  /// **'Usado'**
  String get address_ownership_field_used;

  /// No description provided for @address_ownership_field_balance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo'**
  String get address_ownership_field_balance;

  /// No description provided for @address_ownership_yes.
  ///
  /// In pt, this message translates to:
  /// **'Sim'**
  String get address_ownership_yes;

  /// No description provided for @address_ownership_no.
  ///
  /// In pt, this message translates to:
  /// **'Não'**
  String get address_ownership_no;

  /// No description provided for @address_ownership_chain_bitcoin.
  ///
  /// In pt, this message translates to:
  /// **'Bitcoin'**
  String get address_ownership_chain_bitcoin;

  /// No description provided for @address_ownership_chain_liquid.
  ///
  /// In pt, this message translates to:
  /// **'Liquid'**
  String get address_ownership_chain_liquid;

  /// No description provided for @address_ownership_index_label.
  ///
  /// In pt, this message translates to:
  /// **'índice {index}'**
  String address_ownership_index_label(int index);

  /// No description provided for @address_ownership_status_used.
  ///
  /// In pt, this message translates to:
  /// **'usado'**
  String get address_ownership_status_used;

  /// No description provided for @address_ownership_status_unused.
  ///
  /// In pt, this message translates to:
  /// **'não utilizado'**
  String get address_ownership_status_unused;

  /// No description provided for @settings_section_addresses.
  ///
  /// In pt, this message translates to:
  /// **'ENDEREÇOS'**
  String get settings_section_addresses;

  /// No description provided for @settings_verify_address.
  ///
  /// In pt, this message translates to:
  /// **'Verificar endereço'**
  String get settings_verify_address;

  /// No description provided for @settings_address_explorer.
  ///
  /// In pt, this message translates to:
  /// **'Endereços e UTXOs'**
  String get settings_address_explorer;

  /// No description provided for @converting_details_title.
  ///
  /// In pt, this message translates to:
  /// **'Conversão em andamento'**
  String get converting_details_title;

  /// No description provided for @converting_details_refund_title.
  ///
  /// In pt, this message translates to:
  /// **'O swap não pôde ser concluído'**
  String get converting_details_refund_title;

  /// No description provided for @converting_details_refund_message.
  ///
  /// In pt, this message translates to:
  /// **'A Boltz sinalizou este swap como reembolsável. Seus fundos estão seguros — recupere-os para sua carteira usando o fluxo de reembolso abaixo.'**
  String get converting_details_refund_message;

  /// No description provided for @converting_details_refund_button.
  ///
  /// In pt, this message translates to:
  /// **'Obter reembolso'**
  String get converting_details_refund_button;

  /// No description provided for @converting_details_completed_title.
  ///
  /// In pt, this message translates to:
  /// **'Conversão concluída'**
  String get converting_details_completed_title;

  /// No description provided for @converting_details_completed_message.
  ///
  /// In pt, this message translates to:
  /// **'Os fundos chegaram à rede de destino. O swap completo já aparece no seu histórico de transações.'**
  String get converting_details_completed_message;

  /// No description provided for @converting_details_back_to_home.
  ///
  /// In pt, this message translates to:
  /// **'Voltar para início'**
  String get converting_details_back_to_home;

  /// No description provided for @converting_details_converting_label.
  ///
  /// In pt, this message translates to:
  /// **'Convertendo {from} → {to}'**
  String converting_details_converting_label(String from, String to);

  /// No description provided for @converting_details_peg_in.
  ///
  /// In pt, this message translates to:
  /// **'Peg-in'**
  String get converting_details_peg_in;

  /// No description provided for @converting_details_peg_out.
  ///
  /// In pt, this message translates to:
  /// **'Peg-out'**
  String get converting_details_peg_out;

  /// No description provided for @converting_details_you_sent.
  ///
  /// In pt, this message translates to:
  /// **'Você enviou'**
  String get converting_details_you_sent;

  /// No description provided for @converting_details_youll_receive.
  ///
  /// In pt, this message translates to:
  /// **'Você receberá'**
  String get converting_details_youll_receive;

  /// No description provided for @converting_details_phase_preparing.
  ///
  /// In pt, this message translates to:
  /// **'Preparando'**
  String get converting_details_phase_preparing;

  /// No description provided for @converting_details_phase_broadcasting.
  ///
  /// In pt, this message translates to:
  /// **'Transmitindo'**
  String get converting_details_phase_broadcasting;

  /// No description provided for @converting_details_phase_awaiting_confirmations.
  ///
  /// In pt, this message translates to:
  /// **'Aguardando confirmações'**
  String get converting_details_phase_awaiting_confirmations;

  /// No description provided for @converting_details_phase_failed.
  ///
  /// In pt, this message translates to:
  /// **'Falhou'**
  String get converting_details_phase_failed;

  /// No description provided for @converting_details_phase_refundable.
  ///
  /// In pt, this message translates to:
  /// **'Reembolsável'**
  String get converting_details_phase_refundable;

  /// No description provided for @converting_details_direction.
  ///
  /// In pt, this message translates to:
  /// **'Direção'**
  String get converting_details_direction;

  /// No description provided for @converting_details_direction_peg_in.
  ///
  /// In pt, this message translates to:
  /// **'Peg-in (BTC on-chain → LBTC)'**
  String get converting_details_direction_peg_in;

  /// No description provided for @converting_details_direction_peg_out.
  ///
  /// In pt, this message translates to:
  /// **'Peg-out (LBTC → BTC on-chain)'**
  String get converting_details_direction_peg_out;

  /// No description provided for @converting_details_sent.
  ///
  /// In pt, this message translates to:
  /// **'Enviado'**
  String get converting_details_sent;

  /// No description provided for @converting_details_estimated_receive.
  ///
  /// In pt, this message translates to:
  /// **'Recebimento estimado'**
  String get converting_details_estimated_receive;

  /// No description provided for @converting_details_started.
  ///
  /// In pt, this message translates to:
  /// **'Iniciado'**
  String get converting_details_started;

  /// No description provided for @converting_details_destination_address.
  ///
  /// In pt, this message translates to:
  /// **'Endereço de destino'**
  String get converting_details_destination_address;

  /// No description provided for @converting_details_swap_id.
  ///
  /// In pt, this message translates to:
  /// **'ID do swap'**
  String get converting_details_swap_id;

  /// No description provided for @converting_details_bitcoin_send_tx.
  ///
  /// In pt, this message translates to:
  /// **'Transação de envio Bitcoin'**
  String get converting_details_bitcoin_send_tx;

  /// No description provided for @converting_details_liquid_send_tx.
  ///
  /// In pt, this message translates to:
  /// **'Transação de envio Liquid'**
  String get converting_details_liquid_send_tx;

  /// No description provided for @converting_details_local_id.
  ///
  /// In pt, this message translates to:
  /// **'ID local'**
  String get converting_details_local_id;

  /// No description provided for @converting_details_help_footer.
  ///
  /// In pt, this message translates to:
  /// **'Os chain swaps movem fundos entre Bitcoin e Liquid Bitcoin (L-BTC) e geralmente são liquidados em 30 a 60 minutos após a confirmação da transação de bloqueio. Seus fundos não estão perdidos — eles ficam temporariamente bloqueados no contrato do swap enquanto a rede de destino se atualiza.'**
  String get converting_details_help_footer;

  /// No description provided for @converting_details_explanation_preparing.
  ///
  /// In pt, this message translates to:
  /// **'Construindo a transação de bloqueio e reservando o swap com o serviço de chain-swap.'**
  String get converting_details_explanation_preparing;

  /// No description provided for @converting_details_explanation_broadcasting_bitcoin.
  ///
  /// In pt, this message translates to:
  /// **'Assinando e transmitindo a transação de bloqueio para a rede Bitcoin.'**
  String get converting_details_explanation_broadcasting_bitcoin;

  /// No description provided for @converting_details_explanation_broadcasting_liquid.
  ///
  /// In pt, this message translates to:
  /// **'Assinando e transmitindo a transação de bloqueio para a rede Liquid.'**
  String get converting_details_explanation_broadcasting_liquid;

  /// No description provided for @converting_details_explanation_broadcasted_peg_in.
  ///
  /// In pt, this message translates to:
  /// **'Seu bloqueio de Bitcoin foi transmitido. Assim que confirmar, o serviço de chain-swap irá reivindicá-lo e enviar LBTC para sua carteira.'**
  String get converting_details_explanation_broadcasted_peg_in;

  /// No description provided for @converting_details_explanation_broadcasted_peg_out.
  ///
  /// In pt, this message translates to:
  /// **'Seu LBTC foi enviado para o serviço de chain-swap. Assim que for processado, você receberá BTC na rede Bitcoin.'**
  String get converting_details_explanation_broadcasted_peg_out;

  /// No description provided for @converting_details_explanation_failed.
  ///
  /// In pt, this message translates to:
  /// **'O swap não pôde ser concluído. Quaisquer fundos reservados para o swap serão reembolsados automaticamente.'**
  String get converting_details_explanation_failed;

  /// No description provided for @converting_details_explanation_refundable.
  ///
  /// In pt, this message translates to:
  /// **'A Boltz sinalizou o swap como reembolsável. Toque em \"Obter reembolso\" para enviar os fundos bloqueados de volta para sua carteira.'**
  String get converting_details_explanation_refundable;

  /// No description provided for @pending_swap_refund_available.
  ///
  /// In pt, this message translates to:
  /// **'Reembolso de swap disponível'**
  String get pending_swap_refund_available;

  /// No description provided for @pending_swap_status_preparing.
  ///
  /// In pt, this message translates to:
  /// **'Preparando swap…'**
  String get pending_swap_status_preparing;

  /// No description provided for @pending_swap_status_broadcasting.
  ///
  /// In pt, this message translates to:
  /// **'Transmitindo para a rede…'**
  String get pending_swap_status_broadcasting;

  /// No description provided for @pending_swap_status_broadcasted.
  ///
  /// In pt, this message translates to:
  /// **'Transmitido — aguardando confirmações'**
  String get pending_swap_status_broadcasted;

  /// No description provided for @pending_swap_status_failed.
  ///
  /// In pt, this message translates to:
  /// **'Falha no swap'**
  String get pending_swap_status_failed;

  /// No description provided for @pending_swap_status_refundable.
  ///
  /// In pt, this message translates to:
  /// **'Toque para solicitar seu reembolso'**
  String get pending_swap_status_refundable;

  /// No description provided for @pending_swap_refundable_amount.
  ///
  /// In pt, this message translates to:
  /// **'Reembolsável: {amount}'**
  String pending_swap_refundable_amount(String amount);

  /// No description provided for @pix_first_time_title.
  ///
  /// In pt, this message translates to:
  /// **'Atenção sobre pagamentos PIX'**
  String get pix_first_time_title;

  /// No description provided for @pix_first_time_description.
  ///
  /// In pt, this message translates to:
  /// **'Todos os pagamentos PIX passam por análise de segurança e podem ser:'**
  String get pix_first_time_description;

  /// No description provided for @pix_first_time_item_completed.
  ///
  /// In pt, this message translates to:
  /// **'Efetivados em até 72 horas'**
  String get pix_first_time_item_completed;

  /// No description provided for @pix_first_time_item_refunded.
  ///
  /// In pt, this message translates to:
  /// **'Estornados para o pagante'**
  String get pix_first_time_item_refunded;

  /// No description provided for @pix_first_time_security_note.
  ///
  /// In pt, this message translates to:
  /// **'Esta análise é necessária para garantir a segurança de todos os usuários.'**
  String get pix_first_time_security_note;

  /// No description provided for @pix_first_time_accept_button.
  ///
  /// In pt, this message translates to:
  /// **'Compreendo e aceito'**
  String get pix_first_time_accept_button;

  /// No description provided for @pix_first_time_accept_button_counting.
  ///
  /// In pt, this message translates to:
  /// **'Compreendo e aceito ({seconds})'**
  String pix_first_time_accept_button_counting(int seconds);

  /// No description provided for @swap_btc_lbtc_warning_title.
  ///
  /// In pt, this message translates to:
  /// **'Atenção: Swap entre Redes'**
  String get swap_btc_lbtc_warning_title;

  /// No description provided for @swap_btc_lbtc_warning_intro.
  ///
  /// In pt, this message translates to:
  /// **'Informações importantes sobre o swap BTC para LBTC:'**
  String get swap_btc_lbtc_warning_intro;

  /// No description provided for @swap_btc_lbtc_warning_cross_chain.
  ///
  /// In pt, this message translates to:
  /// **'Este é um swap entre diferentes blockchains (Bitcoin e Liquid Network).'**
  String get swap_btc_lbtc_warning_cross_chain;

  /// No description provided for @swap_btc_lbtc_warning_confirmations.
  ///
  /// In pt, this message translates to:
  /// **'O swap depende de confirmações em ambas as blockchains, o que pode levar algum tempo.'**
  String get swap_btc_lbtc_warning_confirmations;

  /// No description provided for @swap_btc_lbtc_warning_fee_changes.
  ///
  /// In pt, this message translates to:
  /// **'Em casos de mudanças nas taxas da rede, a Breez pode deixar o ativo como \"estorno\" (reembolso).'**
  String get swap_btc_lbtc_warning_fee_changes;

  /// No description provided for @swap_btc_lbtc_warning_manual_refund.
  ///
  /// In pt, this message translates to:
  /// **'Se isso acontecer, você deverá solicitar o reembolso manualmente dentro do aplicativo.'**
  String get swap_btc_lbtc_warning_manual_refund;

  /// No description provided for @swap_btc_lbtc_warning_funds_safe.
  ///
  /// In pt, this message translates to:
  /// **'Seus fundos estão sempre seguros, mesmo em caso de estorno.'**
  String get swap_btc_lbtc_warning_funds_safe;

  /// No description provided for @swap_btc_lbtc_warning_accept_button.
  ///
  /// In pt, this message translates to:
  /// **'Entendi e Aceito'**
  String get swap_btc_lbtc_warning_accept_button;

  /// No description provided for @swap_btc_lbtc_warning_accept_button_counting.
  ///
  /// In pt, this message translates to:
  /// **'Entendi e Aceito ({seconds})'**
  String swap_btc_lbtc_warning_accept_button_counting(int seconds);

  /// No description provided for @asset_activity_market_price.
  ///
  /// In pt, this message translates to:
  /// **'Preço {ticker}'**
  String asset_activity_market_price(String ticker);

  /// No description provided for @asset_activity_summary_title.
  ///
  /// In pt, this message translates to:
  /// **'Resumo'**
  String get asset_activity_summary_title;

  /// No description provided for @asset_activity_received_total.
  ///
  /// In pt, this message translates to:
  /// **'Recebido total'**
  String get asset_activity_received_total;

  /// No description provided for @asset_activity_sent_total.
  ///
  /// In pt, this message translates to:
  /// **'Enviado total'**
  String get asset_activity_sent_total;

  /// No description provided for @asset_activity_current_balance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo atual'**
  String get asset_activity_current_balance;

  /// No description provided for @asset_activity_transactions.
  ///
  /// In pt, this message translates to:
  /// **'Transações'**
  String get asset_activity_transactions;

  /// No description provided for @asset_activity_section_title.
  ///
  /// In pt, this message translates to:
  /// **'Movimentações'**
  String get asset_activity_section_title;

  /// No description provided for @asset_activity_first.
  ///
  /// In pt, this message translates to:
  /// **'Primeira movimentação'**
  String get asset_activity_first;

  /// No description provided for @asset_activity_last.
  ///
  /// In pt, this message translates to:
  /// **'Última movimentação'**
  String get asset_activity_last;

  /// No description provided for @asset_activity_highlights_title.
  ///
  /// In pt, this message translates to:
  /// **'Destaques'**
  String get asset_activity_highlights_title;

  /// No description provided for @asset_activity_largest_receive.
  ///
  /// In pt, this message translates to:
  /// **'Maior recebimento'**
  String get asset_activity_largest_receive;

  /// No description provided for @asset_activity_largest_send.
  ///
  /// In pt, this message translates to:
  /// **'Maior envio'**
  String get asset_activity_largest_send;

  /// No description provided for @asset_activity_total_volume.
  ///
  /// In pt, this message translates to:
  /// **'Volume movimentado'**
  String get asset_activity_total_volume;

  /// No description provided for @asset_activity_history_title.
  ///
  /// In pt, this message translates to:
  /// **'Transações'**
  String get asset_activity_history_title;

  /// No description provided for @analytics_opt_in.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar dados de uso (opcional)'**
  String get analytics_opt_in;

  /// No description provided for @analytics_description.
  ///
  /// In pt, this message translates to:
  /// **'Ajude a melhorar o Mooze enviando ao PostHog telas visitadas e resultados de ações, com um identificador aleatório e informações básicas do aplicativo e dispositivo. Não enviamos sua frase, PIN, endereços, saldos ou valores. Sem gravação de tela. Você pode desativar a qualquer momento nos Ajustes.'**
  String get analytics_description;

  /// No description provided for @analytics_save_error.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível atualizar a preferência de dados de uso. Tente novamente.'**
  String get analytics_save_error;

  /// No description provided for @pix_hub_title.
  ///
  /// In pt, this message translates to:
  /// **'Área Pix'**
  String get pix_hub_title;

  /// No description provided for @pix_hub_demo_badge.
  ///
  /// In pt, this message translates to:
  /// **'Demonstração'**
  String get pix_hub_demo_badge;

  /// No description provided for @pix_hub_demo_badge_semantics.
  ///
  /// In pt, this message translates to:
  /// **'Conteúdo de demonstração'**
  String get pix_hub_demo_badge_semantics;

  /// No description provided for @pix_hub_demo_notice_title.
  ///
  /// In pt, this message translates to:
  /// **'Modo demonstração'**
  String get pix_hub_demo_notice_title;

  /// No description provided for @pix_hub_demo_notice_body.
  ///
  /// In pt, this message translates to:
  /// **'Enviar, receber, chaves, links e histórico usam dados fictícios. Nenhum valor sai da sua conta. Apenas o depósito na carteira usa o serviço real da Mooze.'**
  String get pix_hub_demo_notice_body;

  /// No description provided for @pix_hub_shortcut_send.
  ///
  /// In pt, this message translates to:
  /// **'Enviar'**
  String get pix_hub_shortcut_send;

  /// No description provided for @pix_hub_shortcut_receive.
  ///
  /// In pt, this message translates to:
  /// **'Receber'**
  String get pix_hub_shortcut_receive;

  /// No description provided for @pix_hub_shortcut_deposit.
  ///
  /// In pt, this message translates to:
  /// **'Depositar'**
  String get pix_hub_shortcut_deposit;

  /// No description provided for @pix_hub_more_operations.
  ///
  /// In pt, this message translates to:
  /// **'Mais operações'**
  String get pix_hub_more_operations;

  /// No description provided for @pix_hub_action_pay_key.
  ///
  /// In pt, this message translates to:
  /// **'Pagar com chave Pix'**
  String get pix_hub_action_pay_key;

  /// No description provided for @pix_hub_action_pay_key_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Informe CPF, CNPJ, celular, e-mail ou chave aleatória.'**
  String get pix_hub_action_pay_key_subtitle;

  /// No description provided for @pix_hub_action_pay_qr.
  ///
  /// In pt, this message translates to:
  /// **'Pagar com QR Code'**
  String get pix_hub_action_pay_qr;

  /// No description provided for @pix_hub_action_pay_qr_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Use a câmera para ler o código.'**
  String get pix_hub_action_pay_qr_subtitle;

  /// No description provided for @pix_hub_action_copy_paste.
  ///
  /// In pt, this message translates to:
  /// **'Pix Copia e Cola'**
  String get pix_hub_action_copy_paste;

  /// No description provided for @pix_hub_action_copy_paste_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Cole o código da cobrança.'**
  String get pix_hub_action_copy_paste_subtitle;

  /// No description provided for @pix_hub_action_links.
  ///
  /// In pt, this message translates to:
  /// **'Links de pagamento'**
  String get pix_hub_action_links;

  /// No description provided for @pix_hub_action_links_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Crie e compartilhe cobranças.'**
  String get pix_hub_action_links_subtitle;

  /// No description provided for @pix_hub_action_keys.
  ///
  /// In pt, this message translates to:
  /// **'Minhas chaves Pix'**
  String get pix_hub_action_keys;

  /// No description provided for @pix_hub_action_keys_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Veja, copie e compartilhe suas chaves.'**
  String get pix_hub_action_keys_subtitle;

  /// No description provided for @pix_hub_action_history.
  ///
  /// In pt, this message translates to:
  /// **'Histórico Pix'**
  String get pix_hub_action_history;

  /// No description provided for @pix_hub_action_history_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Veja apenas movimentações Pix.'**
  String get pix_hub_action_history_subtitle;

  /// No description provided for @pix_hub_recent_recipients.
  ///
  /// In pt, this message translates to:
  /// **'Contatos recentes'**
  String get pix_hub_recent_recipients;

  /// No description provided for @pix_hub_view_all.
  ///
  /// In pt, this message translates to:
  /// **'Ver todos'**
  String get pix_hub_view_all;

  /// No description provided for @pix_hub_pending_links.
  ///
  /// In pt, this message translates to:
  /// **'Cobranças pendentes'**
  String get pix_hub_pending_links;

  /// No description provided for @pix_hub_recent_activity.
  ///
  /// In pt, this message translates to:
  /// **'Últimas movimentações'**
  String get pix_hub_recent_activity;

  /// No description provided for @pix_hub_manage.
  ///
  /// In pt, this message translates to:
  /// **'Gerenciar'**
  String get pix_hub_manage;

  /// No description provided for @pix_hub_empty_recipients_title.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum contato recente'**
  String get pix_hub_empty_recipients_title;

  /// No description provided for @pix_hub_empty_recipients_body.
  ///
  /// In pt, this message translates to:
  /// **'Os contatos aparecem aqui depois do primeiro pagamento.'**
  String get pix_hub_empty_recipients_body;

  /// No description provided for @pix_hub_empty_links_title.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma cobrança pendente'**
  String get pix_hub_empty_links_title;

  /// No description provided for @pix_hub_empty_links_body.
  ///
  /// In pt, this message translates to:
  /// **'Crie um link de pagamento para receber de outra pessoa.'**
  String get pix_hub_empty_links_body;

  /// No description provided for @pix_hub_empty_transactions_title.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma movimentação Pix'**
  String get pix_hub_empty_transactions_title;

  /// No description provided for @pix_hub_empty_transactions_body.
  ///
  /// In pt, this message translates to:
  /// **'As movimentações aparecem aqui depois da primeira operação.'**
  String get pix_hub_empty_transactions_body;

  /// No description provided for @pix_hub_empty_keys_title.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma chave cadastrada'**
  String get pix_hub_empty_keys_title;

  /// No description provided for @pix_hub_empty_keys_body.
  ///
  /// In pt, this message translates to:
  /// **'O cadastro de chaves depende de um serviço Pix que a Mooze ainda não possui.'**
  String get pix_hub_empty_keys_body;

  /// No description provided for @pix_hub_error_title.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar'**
  String get pix_hub_error_title;

  /// No description provided for @pix_hub_error_body.
  ///
  /// In pt, this message translates to:
  /// **'Verifique a conexão e tente novamente.'**
  String get pix_hub_error_body;

  /// No description provided for @pix_hub_menu_fees.
  ///
  /// In pt, this message translates to:
  /// **'Ver taxas'**
  String get pix_hub_menu_fees;

  /// No description provided for @pix_hub_menu_empty_preview_on.
  ///
  /// In pt, this message translates to:
  /// **'Ver estados vazios'**
  String get pix_hub_menu_empty_preview_on;

  /// No description provided for @pix_hub_menu_empty_preview_off.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar dados de demonstração'**
  String get pix_hub_menu_empty_preview_off;

  /// No description provided for @pix_hub_send_title.
  ///
  /// In pt, this message translates to:
  /// **'Enviar Pix'**
  String get pix_hub_send_title;

  /// No description provided for @pix_hub_key_input_title.
  ///
  /// In pt, this message translates to:
  /// **'Qual é a chave Pix?'**
  String get pix_hub_key_input_title;

  /// No description provided for @pix_hub_key_input_hint.
  ///
  /// In pt, this message translates to:
  /// **'A Mooze aceita CPF, CNPJ, celular, e-mail e chave aleatória. O aplicativo confere apenas o formato.'**
  String get pix_hub_key_input_hint;

  /// No description provided for @pix_hub_key_input_label.
  ///
  /// In pt, this message translates to:
  /// **'Chave Pix'**
  String get pix_hub_key_input_label;

  /// No description provided for @pix_hub_key_input_placeholder.
  ///
  /// In pt, this message translates to:
  /// **'exemplo@email.com'**
  String get pix_hub_key_input_placeholder;

  /// No description provided for @pix_hub_key_detected.
  ///
  /// In pt, this message translates to:
  /// **'Formato reconhecido: {type}.'**
  String pix_hub_key_detected(String type);

  /// No description provided for @pix_hub_key_error_empty.
  ///
  /// In pt, this message translates to:
  /// **'Informe a chave Pix.'**
  String get pix_hub_key_error_empty;

  /// No description provided for @pix_hub_key_error_unrecognized.
  ///
  /// In pt, this message translates to:
  /// **'A chave não corresponde a nenhum formato Pix.'**
  String get pix_hub_key_error_unrecognized;

  /// No description provided for @pix_hub_key_error_document.
  ///
  /// In pt, this message translates to:
  /// **'Os dígitos verificadores do CPF ou do CNPJ não conferem.'**
  String get pix_hub_key_error_document;

  /// No description provided for @pix_hub_key_error_phone.
  ///
  /// In pt, this message translates to:
  /// **'Informe o celular com DDI e DDD. Exemplo: +5511999990000.'**
  String get pix_hub_key_error_phone;

  /// No description provided for @pix_hub_key_error_email.
  ///
  /// In pt, this message translates to:
  /// **'O e-mail é inválido.'**
  String get pix_hub_key_error_email;

  /// No description provided for @pix_hub_key_error_random.
  ///
  /// In pt, this message translates to:
  /// **'A chave aleatória tem 32 caracteres e quatro hífens.'**
  String get pix_hub_key_error_random;

  /// No description provided for @pix_hub_key_type_cpf.
  ///
  /// In pt, this message translates to:
  /// **'CPF'**
  String get pix_hub_key_type_cpf;

  /// No description provided for @pix_hub_key_type_cnpj.
  ///
  /// In pt, this message translates to:
  /// **'CNPJ'**
  String get pix_hub_key_type_cnpj;

  /// No description provided for @pix_hub_key_type_phone.
  ///
  /// In pt, this message translates to:
  /// **'Celular'**
  String get pix_hub_key_type_phone;

  /// No description provided for @pix_hub_key_type_email.
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get pix_hub_key_type_email;

  /// No description provided for @pix_hub_key_type_random.
  ///
  /// In pt, this message translates to:
  /// **'Chave aleatória'**
  String get pix_hub_key_type_random;

  /// No description provided for @pix_hub_code_input_title.
  ///
  /// In pt, this message translates to:
  /// **'Cole o código Pix'**
  String get pix_hub_code_input_title;

  /// No description provided for @pix_hub_code_input_hint.
  ///
  /// In pt, this message translates to:
  /// **'A Mooze confere a estrutura e o dígito de verificação do código. Essa checagem não confirma que a cobrança existe.'**
  String get pix_hub_code_input_hint;

  /// No description provided for @pix_hub_code_input_placeholder.
  ///
  /// In pt, this message translates to:
  /// **'00020126...'**
  String get pix_hub_code_input_placeholder;

  /// No description provided for @pix_hub_code_paste.
  ///
  /// In pt, this message translates to:
  /// **'Colar'**
  String get pix_hub_code_paste;

  /// No description provided for @pix_hub_code_sample.
  ///
  /// In pt, this message translates to:
  /// **'Usar código de demonstração'**
  String get pix_hub_code_sample;

  /// No description provided for @pix_hub_code_read_title.
  ///
  /// In pt, this message translates to:
  /// **'Dados lidos do código'**
  String get pix_hub_code_read_title;

  /// No description provided for @pix_hub_code_local_check_warning.
  ///
  /// In pt, this message translates to:
  /// **'Os dados vêm do próprio código. A Mooze não consultou nenhuma instituição.'**
  String get pix_hub_code_local_check_warning;

  /// No description provided for @pix_hub_code_clipboard_empty.
  ///
  /// In pt, this message translates to:
  /// **'A área de transferência está vazia.'**
  String get pix_hub_code_clipboard_empty;

  /// No description provided for @pix_hub_code_copied.
  ///
  /// In pt, this message translates to:
  /// **'Código copiado.'**
  String get pix_hub_code_copied;

  /// No description provided for @pix_hub_code_error_empty.
  ///
  /// In pt, this message translates to:
  /// **'Informe o código Pix.'**
  String get pix_hub_code_error_empty;

  /// No description provided for @pix_hub_code_error_short.
  ///
  /// In pt, this message translates to:
  /// **'O código é curto demais.'**
  String get pix_hub_code_error_short;

  /// No description provided for @pix_hub_code_error_malformed.
  ///
  /// In pt, this message translates to:
  /// **'O código não segue o padrão Pix.'**
  String get pix_hub_code_error_malformed;

  /// No description provided for @pix_hub_code_error_not_pix.
  ///
  /// In pt, this message translates to:
  /// **'O código não é uma cobrança Pix.'**
  String get pix_hub_code_error_not_pix;

  /// No description provided for @pix_hub_code_error_checksum.
  ///
  /// In pt, this message translates to:
  /// **'O dígito de verificação do código não confere.'**
  String get pix_hub_code_error_checksum;

  /// No description provided for @pix_hub_scan_permission_title.
  ///
  /// In pt, this message translates to:
  /// **'Câmera bloqueada'**
  String get pix_hub_scan_permission_title;

  /// No description provided for @pix_hub_scan_permission_body.
  ///
  /// In pt, this message translates to:
  /// **'Libere o acesso à câmera para ler o QR Code.'**
  String get pix_hub_scan_permission_body;

  /// No description provided for @pix_hub_scan_open_settings.
  ///
  /// In pt, this message translates to:
  /// **'Abrir ajustes'**
  String get pix_hub_scan_open_settings;

  /// No description provided for @pix_hub_scan_unavailable_title.
  ///
  /// In pt, this message translates to:
  /// **'Câmera indisponível'**
  String get pix_hub_scan_unavailable_title;

  /// No description provided for @pix_hub_scan_unavailable_body.
  ///
  /// In pt, this message translates to:
  /// **'Use o Pix Copia e Cola.'**
  String get pix_hub_scan_unavailable_body;

  /// No description provided for @pix_hub_scan_demo_hint.
  ///
  /// In pt, this message translates to:
  /// **'Sem câmera disponível? Use o código de demonstração para testar o fluxo.'**
  String get pix_hub_scan_demo_hint;

  /// No description provided for @pix_hub_amount_title.
  ///
  /// In pt, this message translates to:
  /// **'Valor'**
  String get pix_hub_amount_title;

  /// No description provided for @pix_hub_amount_label.
  ///
  /// In pt, this message translates to:
  /// **'Valor do Pix'**
  String get pix_hub_amount_label;

  /// No description provided for @pix_hub_amount_error_empty.
  ///
  /// In pt, this message translates to:
  /// **'Informe um valor maior que zero.'**
  String get pix_hub_amount_error_empty;

  /// No description provided for @pix_hub_amount_error_max.
  ///
  /// In pt, this message translates to:
  /// **'O valor máximo é {amount}.'**
  String pix_hub_amount_error_max(String amount);

  /// No description provided for @pix_hub_amount_fixed_hint.
  ///
  /// In pt, this message translates to:
  /// **'O código já define o valor da cobrança.'**
  String get pix_hub_amount_fixed_hint;

  /// No description provided for @pix_hub_description_label.
  ///
  /// In pt, this message translates to:
  /// **'Descrição (opcional)'**
  String get pix_hub_description_label;

  /// No description provided for @pix_hub_description_hint.
  ///
  /// In pt, this message translates to:
  /// **'Mensagem para quem recebe'**
  String get pix_hub_description_hint;

  /// No description provided for @pix_hub_review_title.
  ///
  /// In pt, this message translates to:
  /// **'Revisar pagamento'**
  String get pix_hub_review_title;

  /// No description provided for @pix_hub_review_amount_label.
  ///
  /// In pt, this message translates to:
  /// **'Você vai enviar'**
  String get pix_hub_review_amount_label;

  /// No description provided for @pix_hub_review_confirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar e pagar'**
  String get pix_hub_review_confirm;

  /// No description provided for @pix_hub_review_disclaimer.
  ///
  /// In pt, this message translates to:
  /// **'Ao confirmar, sua carteira envia o valor em DePix ao provedor Pix. Não é possível desfazer esta transferência.'**
  String get pix_hub_review_disclaimer;

  /// No description provided for @pix_hub_result_title.
  ///
  /// In pt, this message translates to:
  /// **'Resultado'**
  String get pix_hub_result_title;

  /// No description provided for @pix_hub_result_success_title.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento enviado!'**
  String get pix_hub_result_success_title;

  /// No description provided for @pix_hub_result_success_body.
  ///
  /// In pt, this message translates to:
  /// **'O registro entrou no histórico de demonstração. Nenhum valor foi transferido.'**
  String get pix_hub_result_success_body;

  /// No description provided for @pix_hub_result_failure_title.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento simulado recusado'**
  String get pix_hub_result_failure_title;

  /// No description provided for @pix_hub_result_disclaimer.
  ///
  /// In pt, this message translates to:
  /// **'Esta tela é uma demonstração. Ela não comprova uma transação financeira.'**
  String get pix_hub_result_disclaimer;

  /// No description provided for @pix_hub_result_try_again.
  ///
  /// In pt, this message translates to:
  /// **'Tentar outro valor'**
  String get pix_hub_result_try_again;

  /// No description provided for @pix_hub_flow_expired.
  ///
  /// In pt, this message translates to:
  /// **'O fluxo foi reiniciado. Comece outra vez.'**
  String get pix_hub_flow_expired;

  /// No description provided for @pix_hub_back_to_hub.
  ///
  /// In pt, this message translates to:
  /// **'Voltar ao Pix'**
  String get pix_hub_back_to_hub;

  /// No description provided for @pix_hub_summary_recipient.
  ///
  /// In pt, this message translates to:
  /// **'Para'**
  String get pix_hub_summary_recipient;

  /// No description provided for @pix_hub_summary_payer.
  ///
  /// In pt, this message translates to:
  /// **'De'**
  String get pix_hub_summary_payer;

  /// No description provided for @pix_hub_summary_institution.
  ///
  /// In pt, this message translates to:
  /// **'Instituição'**
  String get pix_hub_summary_institution;

  /// No description provided for @pix_hub_summary_document.
  ///
  /// In pt, this message translates to:
  /// **'Documento'**
  String get pix_hub_summary_document;

  /// No description provided for @pix_hub_summary_method.
  ///
  /// In pt, this message translates to:
  /// **'Forma de envio'**
  String get pix_hub_summary_method;

  /// No description provided for @pix_hub_summary_description.
  ///
  /// In pt, this message translates to:
  /// **'Descrição'**
  String get pix_hub_summary_description;

  /// No description provided for @pix_hub_summary_amount.
  ///
  /// In pt, this message translates to:
  /// **'Valor'**
  String get pix_hub_summary_amount;

  /// No description provided for @pix_hub_summary_date.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get pix_hub_summary_date;

  /// No description provided for @pix_hub_summary_reference.
  ///
  /// In pt, this message translates to:
  /// **'Identificador'**
  String get pix_hub_summary_reference;

  /// No description provided for @pix_hub_summary_status.
  ///
  /// In pt, this message translates to:
  /// **'Status'**
  String get pix_hub_summary_status;

  /// No description provided for @pix_hub_summary_type.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get pix_hub_summary_type;

  /// No description provided for @pix_hub_summary_city.
  ///
  /// In pt, this message translates to:
  /// **'Cidade'**
  String get pix_hub_summary_city;

  /// No description provided for @pix_hub_summary_created_at.
  ///
  /// In pt, this message translates to:
  /// **'Criada em'**
  String get pix_hub_summary_created_at;

  /// No description provided for @pix_hub_summary_expires_at.
  ///
  /// In pt, this message translates to:
  /// **'Expira em'**
  String get pix_hub_summary_expires_at;

  /// No description provided for @pix_hub_method_key.
  ///
  /// In pt, this message translates to:
  /// **'Chave Pix'**
  String get pix_hub_method_key;

  /// No description provided for @pix_hub_method_qr.
  ///
  /// In pt, this message translates to:
  /// **'QR Code'**
  String get pix_hub_method_qr;

  /// No description provided for @pix_hub_method_copy_paste.
  ///
  /// In pt, this message translates to:
  /// **'Copia e Cola'**
  String get pix_hub_method_copy_paste;

  /// No description provided for @pix_hub_method_recent.
  ///
  /// In pt, this message translates to:
  /// **'Contato recente'**
  String get pix_hub_method_recent;

  /// No description provided for @pix_hub_receive_title.
  ///
  /// In pt, this message translates to:
  /// **'Receber Pix'**
  String get pix_hub_receive_title;

  /// No description provided for @pix_hub_receive_from_others.
  ///
  /// In pt, this message translates to:
  /// **'Receber de outra pessoa'**
  String get pix_hub_receive_from_others;

  /// No description provided for @pix_hub_receive_create_charge.
  ///
  /// In pt, this message translates to:
  /// **'Criar cobrança'**
  String get pix_hub_receive_create_charge;

  /// No description provided for @pix_hub_receive_create_charge_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Gere um QR Code e um código Copia e Cola.'**
  String get pix_hub_receive_create_charge_subtitle;

  /// No description provided for @pix_hub_receive_own_wallet.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar saldo na sua carteira'**
  String get pix_hub_receive_own_wallet;

  /// No description provided for @pix_hub_receive_deposit_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Pague um Pix e receba o valor na carteira Mooze.'**
  String get pix_hub_receive_deposit_subtitle;

  /// No description provided for @pix_hub_receive_deposit_note.
  ///
  /// In pt, this message translates to:
  /// **'O depósito usa o serviço real da Mooze e converte reais no ativo escolhido. Ele não é uma cobrança para outra pessoa.'**
  String get pix_hub_receive_deposit_note;

  /// No description provided for @pix_hub_my_keys.
  ///
  /// In pt, this message translates to:
  /// **'Minhas chaves Pix'**
  String get pix_hub_my_keys;

  /// No description provided for @pix_hub_keys_unavailable_title.
  ///
  /// In pt, this message translates to:
  /// **'Cadastro e exclusão indisponíveis'**
  String get pix_hub_keys_unavailable_title;

  /// No description provided for @pix_hub_keys_unavailable_body.
  ///
  /// In pt, this message translates to:
  /// **'A Mooze ainda não possui serviço para cadastrar ou excluir chaves Pix. As chaves acima são fictícias e servem para demonstrar a tela.'**
  String get pix_hub_keys_unavailable_body;

  /// No description provided for @pix_hub_key_copied.
  ///
  /// In pt, this message translates to:
  /// **'Chave copiada.'**
  String get pix_hub_key_copied;

  /// No description provided for @pix_hub_key_share_message.
  ///
  /// In pt, this message translates to:
  /// **'Minha chave Pix de demonstração: {key}'**
  String pix_hub_key_share_message(String key);

  /// No description provided for @pix_hub_copy.
  ///
  /// In pt, this message translates to:
  /// **'Copiar'**
  String get pix_hub_copy;

  /// No description provided for @pix_hub_share.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar'**
  String get pix_hub_share;

  /// No description provided for @pix_hub_value_unavailable.
  ///
  /// In pt, this message translates to:
  /// **'Não informado'**
  String get pix_hub_value_unavailable;

  /// No description provided for @pix_hub_charge_key_label.
  ///
  /// In pt, this message translates to:
  /// **'Chave que recebe'**
  String get pix_hub_charge_key_label;

  /// No description provided for @pix_hub_charge_open_amount.
  ///
  /// In pt, this message translates to:
  /// **'Quem paga escolhe o valor'**
  String get pix_hub_charge_open_amount;

  /// No description provided for @pix_hub_charge_open_amount_hint.
  ///
  /// In pt, this message translates to:
  /// **'A cobrança fica sem valor definido.'**
  String get pix_hub_charge_open_amount_hint;

  /// No description provided for @pix_hub_charge_create.
  ///
  /// In pt, this message translates to:
  /// **'Gerar cobrança'**
  String get pix_hub_charge_create;

  /// No description provided for @pix_hub_charge_error_min.
  ///
  /// In pt, this message translates to:
  /// **'O valor mínimo é {amount}.'**
  String pix_hub_charge_error_min(String amount);

  /// No description provided for @pix_hub_charge_detail_title.
  ///
  /// In pt, this message translates to:
  /// **'Cobrança'**
  String get pix_hub_charge_detail_title;

  /// No description provided for @pix_hub_charge_code_label.
  ///
  /// In pt, this message translates to:
  /// **'Código Copia e Cola'**
  String get pix_hub_charge_code_label;

  /// No description provided for @pix_hub_charge_share_message.
  ///
  /// In pt, this message translates to:
  /// **'Cobrança Pix de demonstração: {code}'**
  String pix_hub_charge_share_message(String code);

  /// No description provided for @pix_hub_charge_disclaimer.
  ///
  /// In pt, this message translates to:
  /// **'O QR Code e o código são de demonstração. Nenhuma cobrança foi registrada em uma instituição Pix.'**
  String get pix_hub_charge_disclaimer;

  /// No description provided for @pix_hub_charge_create_another.
  ///
  /// In pt, this message translates to:
  /// **'Criar outra cobrança'**
  String get pix_hub_charge_create_another;

  /// No description provided for @pix_hub_link_create.
  ///
  /// In pt, this message translates to:
  /// **'Criar link'**
  String get pix_hub_link_create;

  /// No description provided for @pix_hub_link_reference_label.
  ///
  /// In pt, this message translates to:
  /// **'Identificação'**
  String get pix_hub_link_reference_label;

  /// No description provided for @pix_hub_link_reference_hint.
  ///
  /// In pt, this message translates to:
  /// **'Mensalidade de março'**
  String get pix_hub_link_reference_hint;

  /// No description provided for @pix_hub_link_reference_error.
  ///
  /// In pt, this message translates to:
  /// **'Informe uma identificação.'**
  String get pix_hub_link_reference_error;

  /// No description provided for @pix_hub_link_amount_error.
  ///
  /// In pt, this message translates to:
  /// **'O valor deve ficar entre {min} e {max}.'**
  String pix_hub_link_amount_error(String min, String max);

  /// No description provided for @pix_hub_link_single_use.
  ///
  /// In pt, this message translates to:
  /// **'Uso único'**
  String get pix_hub_link_single_use;

  /// No description provided for @pix_hub_link_single_use_hint.
  ///
  /// In pt, this message translates to:
  /// **'O link aceita um pagamento e encerra.'**
  String get pix_hub_link_single_use_hint;

  /// No description provided for @pix_hub_link_reusable.
  ///
  /// In pt, this message translates to:
  /// **'Reutilizável'**
  String get pix_hub_link_reusable;

  /// No description provided for @pix_hub_link_usage_label.
  ///
  /// In pt, this message translates to:
  /// **'Uso'**
  String get pix_hub_link_usage_label;

  /// No description provided for @pix_hub_link_review.
  ///
  /// In pt, this message translates to:
  /// **'Revisar link'**
  String get pix_hub_link_review;

  /// No description provided for @pix_hub_link_confirm.
  ///
  /// In pt, this message translates to:
  /// **'Gerar link'**
  String get pix_hub_link_confirm;

  /// No description provided for @pix_hub_link_detail_title.
  ///
  /// In pt, this message translates to:
  /// **'Link de pagamento'**
  String get pix_hub_link_detail_title;

  /// No description provided for @pix_hub_link_url_label.
  ///
  /// In pt, this message translates to:
  /// **'Endereço do link'**
  String get pix_hub_link_url_label;

  /// No description provided for @pix_hub_link_copied.
  ///
  /// In pt, this message translates to:
  /// **'Link copiado.'**
  String get pix_hub_link_copied;

  /// No description provided for @pix_hub_link_share_message.
  ///
  /// In pt, this message translates to:
  /// **'Link de pagamento de demonstração: {url}'**
  String pix_hub_link_share_message(String url);

  /// No description provided for @pix_hub_link_paid_at.
  ///
  /// In pt, this message translates to:
  /// **'Pago em'**
  String get pix_hub_link_paid_at;

  /// No description provided for @pix_hub_link_open_amount.
  ///
  /// In pt, this message translates to:
  /// **'Valor livre'**
  String get pix_hub_link_open_amount;

  /// No description provided for @pix_hub_link_status_pending.
  ///
  /// In pt, this message translates to:
  /// **'Pendente'**
  String get pix_hub_link_status_pending;

  /// No description provided for @pix_hub_link_status_paid.
  ///
  /// In pt, this message translates to:
  /// **'Pago'**
  String get pix_hub_link_status_paid;

  /// No description provided for @pix_hub_link_status_expired.
  ///
  /// In pt, this message translates to:
  /// **'Expirado'**
  String get pix_hub_link_status_expired;

  /// No description provided for @pix_hub_link_disclaimer.
  ///
  /// In pt, this message translates to:
  /// **'O endereço é fictício e não abre uma página de pagamento real.'**
  String get pix_hub_link_disclaimer;

  /// No description provided for @pix_hub_history_filter_all.
  ///
  /// In pt, this message translates to:
  /// **'Tudo'**
  String get pix_hub_history_filter_all;

  /// No description provided for @pix_hub_history_filter_sent.
  ///
  /// In pt, this message translates to:
  /// **'Enviados'**
  String get pix_hub_history_filter_sent;

  /// No description provided for @pix_hub_history_filter_received.
  ///
  /// In pt, this message translates to:
  /// **'Recebidos'**
  String get pix_hub_history_filter_received;

  /// No description provided for @pix_hub_history_note.
  ///
  /// In pt, this message translates to:
  /// **'A lista mostra apenas movimentações Pix fictícias. As transações da carteira ficam no histórico da carteira.'**
  String get pix_hub_history_note;

  /// No description provided for @pix_hub_tx_kind_sent.
  ///
  /// In pt, this message translates to:
  /// **'Pix enviado'**
  String get pix_hub_tx_kind_sent;

  /// No description provided for @pix_hub_tx_kind_received.
  ///
  /// In pt, this message translates to:
  /// **'Pix recebido'**
  String get pix_hub_tx_kind_received;

  /// No description provided for @pix_hub_tx_kind_deposit.
  ///
  /// In pt, this message translates to:
  /// **'Depósito na carteira'**
  String get pix_hub_tx_kind_deposit;

  /// No description provided for @pix_hub_tx_kind_payment_link.
  ///
  /// In pt, this message translates to:
  /// **'Link de pagamento'**
  String get pix_hub_tx_kind_payment_link;

  /// No description provided for @pix_hub_tx_status_completed.
  ///
  /// In pt, this message translates to:
  /// **'Concluído'**
  String get pix_hub_tx_status_completed;

  /// No description provided for @pix_hub_tx_status_pending.
  ///
  /// In pt, this message translates to:
  /// **'Em processamento'**
  String get pix_hub_tx_status_pending;

  /// No description provided for @pix_hub_tx_status_failed.
  ///
  /// In pt, this message translates to:
  /// **'Falhou'**
  String get pix_hub_tx_status_failed;

  /// No description provided for @pix_hub_tx_detail_title.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes da movimentação'**
  String get pix_hub_tx_detail_title;

  /// No description provided for @pix_hub_tx_detail_disclaimer.
  ///
  /// In pt, this message translates to:
  /// **'Este registro é fictício. Ele não é um comprovante de pagamento.'**
  String get pix_hub_tx_detail_disclaimer;

  /// No description provided for @pix_hub_failure_load.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os dados.'**
  String get pix_hub_failure_load;

  /// No description provided for @pix_hub_failure_declined.
  ///
  /// In pt, this message translates to:
  /// **'A simulação recusou o pagamento. O saldo de demonstração é de R\$ 2.500,00.'**
  String get pix_hub_failure_declined;

  /// No description provided for @pix_hub_failure_recipient.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum recebedor corresponde a esses dados.'**
  String get pix_hub_failure_recipient;

  /// No description provided for @pix_hub_failure_amount.
  ///
  /// In pt, this message translates to:
  /// **'O valor está fora do limite aceito.'**
  String get pix_hub_failure_amount;

  /// No description provided for @pix_hub_failure_unknown.
  ///
  /// In pt, this message translates to:
  /// **'Algo deu errado. Tente novamente.'**
  String get pix_hub_failure_unknown;

  /// No description provided for @pix_hub_failure_network.
  ///
  /// In pt, this message translates to:
  /// **'Sem conexão com o servidor. Verifique a internet e tente novamente.'**
  String get pix_hub_failure_network;

  /// No description provided for @pix_hub_failure_session.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível validar sua sessão. Tente novamente.'**
  String get pix_hub_failure_session;

  /// No description provided for @pix_hub_failure_not_eligible.
  ///
  /// In pt, this message translates to:
  /// **'Sua conta ainda não pode criar links de pagamento. Suba de nível para liberar o recurso.'**
  String get pix_hub_failure_not_eligible;

  /// No description provided for @pix_hub_failure_rate_limited.
  ///
  /// In pt, this message translates to:
  /// **'Muitas tentativas seguidas. Aguarde um pouco e tente novamente.'**
  String get pix_hub_failure_rate_limited;

  /// No description provided for @pix_hub_failure_unavailable.
  ///
  /// In pt, this message translates to:
  /// **'O serviço está indisponível agora. Tente novamente mais tarde.'**
  String get pix_hub_failure_unavailable;

  /// No description provided for @pix_hub_failure_invalid_response.
  ///
  /// In pt, this message translates to:
  /// **'O servidor respondeu sem o link de pagamento. Tente novamente.'**
  String get pix_hub_failure_invalid_response;

  /// No description provided for @pix_hub_failure_wallet.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível obter um endereço da sua carteira. Tente novamente.'**
  String get pix_hub_failure_wallet;

  /// No description provided for @pix_hub_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Envie, receba e gerencie seus pagamentos pelo Pix.'**
  String get pix_hub_subtitle;

  /// No description provided for @pix_hub_other_operations.
  ///
  /// In pt, this message translates to:
  /// **'Outras operações'**
  String get pix_hub_other_operations;

  /// No description provided for @pix_hub_action_pending.
  ///
  /// In pt, this message translates to:
  /// **'Cobranças pendentes'**
  String get pix_hub_action_pending;

  /// No description provided for @pix_hub_action_pending_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Veja e remova cobranças em aberto.'**
  String get pix_hub_action_pending_subtitle;

  /// No description provided for @pix_hub_action_other_transactions.
  ///
  /// In pt, this message translates to:
  /// **'Outras transações'**
  String get pix_hub_action_other_transactions;

  /// No description provided for @pix_hub_action_other_transactions_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Históricos, links e taxas do Pix.'**
  String get pix_hub_action_other_transactions_subtitle;

  /// No description provided for @pix_hub_info_title.
  ///
  /// In pt, this message translates to:
  /// **'Como o Pix funciona'**
  String get pix_hub_info_title;

  /// No description provided for @pix_hub_info_send_title.
  ///
  /// In pt, this message translates to:
  /// **'Envio e recebimento'**
  String get pix_hub_info_send_title;

  /// No description provided for @pix_hub_info_send_body.
  ///
  /// In pt, this message translates to:
  /// **'O envio de Pix usa seu saldo de DePix. O provedor Pix paga o destinatário, e a taxa da rede Liquid é paga em L-BTC. Cobranças, chaves e links ainda usam dados fictícios.'**
  String get pix_hub_info_send_body;

  /// No description provided for @pix_hub_info_deposit_title.
  ///
  /// In pt, this message translates to:
  /// **'Depósito na carteira'**
  String get pix_hub_info_deposit_title;

  /// No description provided for @pix_hub_info_deposit_body.
  ///
  /// In pt, this message translates to:
  /// **'O depósito usa o serviço real da Mooze. O valor em reais vira o ativo que você escolher na carteira.'**
  String get pix_hub_info_deposit_body;

  /// No description provided for @pix_hub_send_method_question.
  ///
  /// In pt, this message translates to:
  /// **'Como você quer enviar?'**
  String get pix_hub_send_method_question;

  /// No description provided for @pix_hub_send_method_qr_description.
  ///
  /// In pt, this message translates to:
  /// **'Escaneie o código do recebedor.'**
  String get pix_hub_send_method_qr_description;

  /// No description provided for @pix_hub_send_method_code_description.
  ///
  /// In pt, this message translates to:
  /// **'Cole o código Pix.'**
  String get pix_hub_send_method_code_description;

  /// No description provided for @pix_hub_send_method_recent_description.
  ///
  /// In pt, this message translates to:
  /// **'Pessoas para quem você já enviou.'**
  String get pix_hub_send_method_recent_description;

  /// No description provided for @pix_hub_key_type_label.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de chave'**
  String get pix_hub_key_type_label;

  /// No description provided for @pix_hub_key_hint_cpf.
  ///
  /// In pt, this message translates to:
  /// **'000.000.000-00'**
  String get pix_hub_key_hint_cpf;

  /// No description provided for @pix_hub_key_hint_cnpj.
  ///
  /// In pt, this message translates to:
  /// **'00.000.000/0000-00'**
  String get pix_hub_key_hint_cnpj;

  /// No description provided for @pix_hub_key_hint_phone.
  ///
  /// In pt, this message translates to:
  /// **'ex: 11 98765-4321'**
  String get pix_hub_key_hint_phone;

  /// No description provided for @pix_hub_key_hint_email.
  ///
  /// In pt, this message translates to:
  /// **'nome@email.com'**
  String get pix_hub_key_hint_email;

  /// No description provided for @pix_hub_key_hint_random.
  ///
  /// In pt, this message translates to:
  /// **'00000000-0000-0000-0000-000000000000'**
  String get pix_hub_key_hint_random;

  /// No description provided for @pix_hub_summary_payment_method.
  ///
  /// In pt, this message translates to:
  /// **'Forma de pagamento'**
  String get pix_hub_summary_payment_method;

  /// No description provided for @pix_hub_review_edit.
  ///
  /// In pt, this message translates to:
  /// **'Alterar dados'**
  String get pix_hub_review_edit;

  /// No description provided for @pix_hub_review_key_chip.
  ///
  /// In pt, this message translates to:
  /// **'Chave Pix ({type})'**
  String pix_hub_review_key_chip(String type);

  /// No description provided for @pix_hub_result_to.
  ///
  /// In pt, this message translates to:
  /// **'Para {name}'**
  String pix_hub_result_to(String name);

  /// No description provided for @pix_hub_result_datetime.
  ///
  /// In pt, this message translates to:
  /// **'Data e hora'**
  String get pix_hub_result_datetime;

  /// No description provided for @pix_hub_result_details.
  ///
  /// In pt, this message translates to:
  /// **'Ver detalhes'**
  String get pix_hub_result_details;

  /// No description provided for @pix_hub_deposit_gate_title.
  ///
  /// In pt, this message translates to:
  /// **'Antes de depositar'**
  String get pix_hub_deposit_gate_title;

  /// No description provided for @pix_hub_deposit_gate_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Informe o CPF da conta bancária que vai pagar e confirme o aviso abaixo.'**
  String get pix_hub_deposit_gate_subtitle;

  /// No description provided for @pix_hub_deposit_cpf_hint.
  ///
  /// In pt, this message translates to:
  /// **'A Mooze confere o formato e os dígitos verificadores. O aplicativo não confirma quem é o titular da conta bancária.'**
  String get pix_hub_deposit_cpf_hint;

  /// No description provided for @pix_hub_deposit_notice_title.
  ///
  /// In pt, this message translates to:
  /// **'Importante'**
  String get pix_hub_deposit_notice_title;

  /// No description provided for @pix_hub_deposit_notice_body.
  ///
  /// In pt, this message translates to:
  /// **'Para fazer depósitos via Pix, você precisa usar uma conta bancária em seu próprio nome, registrada sob o mesmo CPF cadastrado na Mooze. Não use contas bancárias de terceiros.'**
  String get pix_hub_deposit_notice_body;

  /// No description provided for @pix_hub_deposit_notice_ack.
  ///
  /// In pt, this message translates to:
  /// **'Li e entendi o aviso.'**
  String get pix_hub_deposit_notice_ack;

  /// No description provided for @pix_hub_deposit_notice_screen_title.
  ///
  /// In pt, this message translates to:
  /// **'Aviso sobre depósitos'**
  String get pix_hub_deposit_notice_screen_title;

  /// No description provided for @pix_hub_deposit_cpf_stored_label.
  ///
  /// In pt, this message translates to:
  /// **'CPF informado'**
  String get pix_hub_deposit_cpf_stored_label;

  /// No description provided for @pix_hub_deposit_cpf_missing.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum CPF informado.'**
  String get pix_hub_deposit_cpf_missing;

  /// No description provided for @pix_hub_deposit_change_cpf.
  ///
  /// In pt, this message translates to:
  /// **'Alterar CPF'**
  String get pix_hub_deposit_change_cpf;

  /// No description provided for @pix_hub_pending_deposits.
  ///
  /// In pt, this message translates to:
  /// **'Depósitos em andamento'**
  String get pix_hub_pending_deposits;

  /// No description provided for @pix_hub_pending_deposits_empty_title.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum depósito em andamento'**
  String get pix_hub_pending_deposits_empty_title;

  /// No description provided for @pix_hub_pending_deposits_empty_body.
  ///
  /// In pt, this message translates to:
  /// **'Os depósitos que aguardam pagamento aparecem aqui.'**
  String get pix_hub_pending_deposits_empty_body;

  /// No description provided for @pix_hub_pending_deposits_note.
  ///
  /// In pt, this message translates to:
  /// **'A Mooze não cancela um depósito em andamento. A cobrança deixa de valer quando expira.'**
  String get pix_hub_pending_deposits_note;

  /// No description provided for @pix_hub_pending_links_section.
  ///
  /// In pt, this message translates to:
  /// **'Links de pagamento'**
  String get pix_hub_pending_links_section;

  /// No description provided for @pix_hub_pending_remove_title.
  ///
  /// In pt, this message translates to:
  /// **'Remover link?'**
  String get pix_hub_pending_remove_title;

  /// No description provided for @pix_hub_pending_remove_body.
  ///
  /// In pt, this message translates to:
  /// **'O link \"{reference}\" sai da lista de demonstração.'**
  String pix_hub_pending_remove_body(String reference);

  /// No description provided for @pix_hub_pending_remove_confirm.
  ///
  /// In pt, this message translates to:
  /// **'Remover'**
  String get pix_hub_pending_remove_confirm;

  /// No description provided for @pix_hub_pending_removed.
  ///
  /// In pt, this message translates to:
  /// **'Link removido.'**
  String get pix_hub_pending_removed;

  /// No description provided for @pix_hub_other_section_history.
  ///
  /// In pt, this message translates to:
  /// **'Históricos'**
  String get pix_hub_other_section_history;

  /// No description provided for @pix_hub_other_deposit_history.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de depósitos'**
  String get pix_hub_other_deposit_history;

  /// No description provided for @pix_hub_other_deposit_history_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Seus depósitos reais pelo Pix.'**
  String get pix_hub_other_deposit_history_subtitle;

  /// No description provided for @pix_hub_other_section_tools.
  ///
  /// In pt, this message translates to:
  /// **'Ferramentas'**
  String get pix_hub_other_section_tools;

  /// No description provided for @pix_hub_other_recipients_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Pessoas para quem você já enviou.'**
  String get pix_hub_other_recipients_subtitle;

  /// No description provided for @pix_hub_other_fees_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Veja as taxas aplicadas.'**
  String get pix_hub_other_fees_subtitle;

  /// No description provided for @pix_hub_preferences.
  ///
  /// In pt, this message translates to:
  /// **'Preferências'**
  String get pix_hub_preferences;

  /// No description provided for @pix_hub_preferences_limits.
  ///
  /// In pt, this message translates to:
  /// **'Meus limites'**
  String get pix_hub_preferences_limits;

  /// No description provided for @pix_hub_preferences_limits_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Veja os limites do Pix na sua conta.'**
  String get pix_hub_preferences_limits_subtitle;

  /// No description provided for @pix_hub_preferences_level.
  ///
  /// In pt, this message translates to:
  /// **'Meu nível'**
  String get pix_hub_preferences_level;

  /// No description provided for @pix_hub_preferences_level_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Veja o nível atual e como subir de nível.'**
  String get pix_hub_preferences_level_subtitle;

  /// No description provided for @pix_hub_limits_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Os valores abaixo vêm da sua conta Mooze.'**
  String get pix_hub_limits_subtitle;

  /// No description provided for @pix_hub_limits_how_it_works.
  ///
  /// In pt, this message translates to:
  /// **'Como os limites funcionam'**
  String get pix_hub_limits_how_it_works;

  /// No description provided for @pix_hub_shortcut_receive_description.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhe sua chave ou gere um QR Code'**
  String get pix_hub_shortcut_receive_description;

  /// No description provided for @pix_hub_failure_invalid_request.
  ///
  /// In pt, this message translates to:
  /// **'O servidor recusou os dados. Confira a chave, o CPF/CNPJ e o valor.'**
  String get pix_hub_failure_invalid_request;

  /// No description provided for @pix_hub_failure_limit_exceeded.
  ///
  /// In pt, this message translates to:
  /// **'O valor passa do seu limite atual, ou sua conta ainda não pode enviar Pix.'**
  String get pix_hub_failure_limit_exceeded;

  /// No description provided for @pix_hub_failure_provider_refused.
  ///
  /// In pt, this message translates to:
  /// **'O provedor Pix recusou o envio. Confira se a chave pertence ao CPF/CNPJ informado.'**
  String get pix_hub_failure_provider_refused;

  /// No description provided for @pix_hub_failure_outcome_unknown.
  ///
  /// In pt, this message translates to:
  /// **'O serviço não confirmou o pedido. Nenhum valor saiu da sua carteira. Tente de novo em alguns minutos.'**
  String get pix_hub_failure_outcome_unknown;

  /// No description provided for @pix_hub_failure_quote_mismatch.
  ///
  /// In pt, this message translates to:
  /// **'A cotação recebida não confere com o pedido. Nenhum valor foi enviado. Tente de novo.'**
  String get pix_hub_failure_quote_mismatch;

  /// No description provided for @pix_hub_failure_quote_expired.
  ///
  /// In pt, this message translates to:
  /// **'O prazo da cotação acabou. Peça uma nova cotação para continuar.'**
  String get pix_hub_failure_quote_expired;

  /// No description provided for @pix_hub_failure_insufficient_funds.
  ///
  /// In pt, this message translates to:
  /// **'Seu saldo de DePix não cobre este envio e a taxa.'**
  String get pix_hub_failure_insufficient_funds;

  /// No description provided for @pix_hub_failure_insufficient_fee_asset.
  ///
  /// In pt, this message translates to:
  /// **'Você precisa de L-BTC para pagar a taxa da rede Liquid.'**
  String get pix_hub_failure_insufficient_fee_asset;

  /// No description provided for @pix_hub_failure_funding_failed.
  ///
  /// In pt, this message translates to:
  /// **'A carteira não conseguiu montar a transferência de DePix. Nenhum valor saiu da sua carteira.'**
  String get pix_hub_failure_funding_failed;

  /// No description provided for @pix_hub_failure_unsupported_code.
  ///
  /// In pt, this message translates to:
  /// **'Este código não tem chave Pix. O Mooze paga apenas códigos com chave.'**
  String get pix_hub_failure_unsupported_code;

  /// No description provided for @pix_hub_tax_id_label.
  ///
  /// In pt, this message translates to:
  /// **'CPF ou CNPJ do dono da chave'**
  String get pix_hub_tax_id_label;

  /// No description provided for @pix_hub_tax_id_hint.
  ///
  /// In pt, this message translates to:
  /// **'000.000.000-00'**
  String get pix_hub_tax_id_hint;

  /// No description provided for @pix_hub_tax_id_help.
  ///
  /// In pt, this message translates to:
  /// **'O provedor Pix confere se a chave pertence a este documento. O Mooze não guarda o número.'**
  String get pix_hub_tax_id_help;

  /// No description provided for @pix_hub_tax_id_error_empty.
  ///
  /// In pt, this message translates to:
  /// **'Informe o CPF ou CNPJ.'**
  String get pix_hub_tax_id_error_empty;

  /// No description provided for @pix_hub_tax_id_error_invalid.
  ///
  /// In pt, this message translates to:
  /// **'CPF ou CNPJ inválido.'**
  String get pix_hub_tax_id_error_invalid;

  /// No description provided for @pix_hub_amount_error_min.
  ///
  /// In pt, this message translates to:
  /// **'O valor mínimo é {amount}.'**
  String pix_hub_amount_error_min(String amount);

  /// No description provided for @pix_hub_amount_error_balance.
  ///
  /// In pt, this message translates to:
  /// **'Seu saldo de DePix não cobre este valor.'**
  String get pix_hub_amount_error_balance;

  /// No description provided for @pix_hub_amount_balance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo disponível: {amount}'**
  String pix_hub_amount_balance(String amount);

  /// No description provided for @pix_hub_amount_fee_hint.
  ///
  /// In pt, this message translates to:
  /// **'A taxa do provedor Pix aparece na revisão e é somada ao valor em DePix.'**
  String get pix_hub_amount_fee_hint;

  /// No description provided for @pix_hub_summary_code_name.
  ///
  /// In pt, this message translates to:
  /// **'Nome no código'**
  String get pix_hub_summary_code_name;

  /// No description provided for @pix_hub_code_no_key.
  ///
  /// In pt, this message translates to:
  /// **'Sem chave Pix (código dinâmico)'**
  String get pix_hub_code_no_key;

  /// No description provided for @pix_hub_review_receives.
  ///
  /// In pt, this message translates to:
  /// **'O destinatário recebe'**
  String get pix_hub_review_receives;

  /// No description provided for @pix_hub_review_provider_fee.
  ///
  /// In pt, this message translates to:
  /// **'Taxa do provedor Pix'**
  String get pix_hub_review_provider_fee;

  /// No description provided for @pix_hub_review_depix_debit.
  ///
  /// In pt, this message translates to:
  /// **'Sai da sua carteira'**
  String get pix_hub_review_depix_debit;

  /// No description provided for @pix_hub_review_network_fee.
  ///
  /// In pt, this message translates to:
  /// **'Taxa da rede Liquid'**
  String get pix_hub_review_network_fee;

  /// No description provided for @pix_hub_review_network_fee_value.
  ///
  /// In pt, this message translates to:
  /// **'{amount} sats (L-BTC)'**
  String pix_hub_review_network_fee_value(String amount);

  /// No description provided for @pix_hub_review_owner_document.
  ///
  /// In pt, this message translates to:
  /// **'Documento do dono da chave'**
  String get pix_hub_review_owner_document;

  /// No description provided for @pix_hub_review_deadline.
  ///
  /// In pt, this message translates to:
  /// **'Pague até {time}'**
  String pix_hub_review_deadline(String time);

  /// No description provided for @pix_hub_review_time_left.
  ///
  /// In pt, this message translates to:
  /// **'Faltam {time}'**
  String pix_hub_review_time_left(String time);

  /// No description provided for @pix_hub_review_expired.
  ///
  /// In pt, this message translates to:
  /// **'O prazo desta cotação acabou.'**
  String get pix_hub_review_expired;

  /// No description provided for @pix_hub_review_new_quote.
  ///
  /// In pt, this message translates to:
  /// **'Pedir nova cotação'**
  String get pix_hub_review_new_quote;

  /// No description provided for @pix_hub_result_processing_title.
  ///
  /// In pt, this message translates to:
  /// **'Pix em processamento'**
  String get pix_hub_result_processing_title;

  /// No description provided for @pix_hub_result_processing_body.
  ///
  /// In pt, this message translates to:
  /// **'Seu DePix foi enviado. O provedor Pix está processando a transferência. Isso pode levar alguns minutos.'**
  String get pix_hub_result_processing_body;

  /// No description provided for @pix_hub_result_completed_title.
  ///
  /// In pt, this message translates to:
  /// **'Pix entregue'**
  String get pix_hub_result_completed_title;

  /// No description provided for @pix_hub_result_completed_body.
  ///
  /// In pt, this message translates to:
  /// **'O provedor Pix confirmou o pagamento ao destinatário.'**
  String get pix_hub_result_completed_body;

  /// No description provided for @pix_hub_result_failed_title.
  ///
  /// In pt, this message translates to:
  /// **'Pix não concluído'**
  String get pix_hub_result_failed_title;

  /// No description provided for @pix_hub_result_refunded_body.
  ///
  /// In pt, this message translates to:
  /// **'O provedor devolveu o depósito ao seu endereço de reembolso.'**
  String get pix_hub_result_refunded_body;

  /// No description provided for @pix_hub_result_failed_body.
  ///
  /// In pt, this message translates to:
  /// **'O provedor encerrou o pedido sem pagar o Pix. Se o DePix não voltar à sua carteira, fale com o suporte e informe o ID do pedido.'**
  String get pix_hub_result_failed_body;

  /// No description provided for @pix_hub_result_unknown_title.
  ///
  /// In pt, this message translates to:
  /// **'Resultado não confirmado'**
  String get pix_hub_result_unknown_title;

  /// No description provided for @pix_hub_result_unknown_body.
  ///
  /// In pt, this message translates to:
  /// **'Não conseguimos confirmar se a transferência de DePix chegou à rede. Não pague de novo. Acompanhe o status abaixo.'**
  String get pix_hub_result_unknown_body;

  /// No description provided for @pix_hub_result_polling_stopped.
  ///
  /// In pt, this message translates to:
  /// **'O status ainda não mudou. Atualize mais tarde.'**
  String get pix_hub_result_polling_stopped;

  /// No description provided for @pix_hub_result_status_error.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível atualizar o status.'**
  String get pix_hub_result_status_error;

  /// No description provided for @pix_hub_result_refresh.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar status'**
  String get pix_hub_result_refresh;

  /// No description provided for @pix_hub_result_receipt.
  ///
  /// In pt, this message translates to:
  /// **'Abrir comprovante'**
  String get pix_hub_result_receipt;

  /// No description provided for @pix_hub_result_copy_id.
  ///
  /// In pt, this message translates to:
  /// **'Copiar ID do pedido'**
  String get pix_hub_result_copy_id;

  /// No description provided for @pix_hub_result_id_copied.
  ///
  /// In pt, this message translates to:
  /// **'ID copiado.'**
  String get pix_hub_result_id_copied;

  /// No description provided for @pix_hub_summary_withdrawal_id.
  ///
  /// In pt, this message translates to:
  /// **'ID do pedido'**
  String get pix_hub_summary_withdrawal_id;

  /// No description provided for @pix_hub_summary_funding_txid.
  ///
  /// In pt, this message translates to:
  /// **'Transação Liquid'**
  String get pix_hub_summary_funding_txid;

  /// No description provided for @pix_hub_summary_end_to_end.
  ///
  /// In pt, this message translates to:
  /// **'ID fim a fim'**
  String get pix_hub_summary_end_to_end;

  /// No description provided for @pix_hub_summary_refund.
  ///
  /// In pt, this message translates to:
  /// **'Valor devolvido'**
  String get pix_hub_summary_refund;

  /// No description provided for @pix_hub_withdrawal_status_checking.
  ///
  /// In pt, this message translates to:
  /// **'Consultando…'**
  String get pix_hub_withdrawal_status_checking;

  /// No description provided for @pix_hub_withdrawal_status_creating.
  ///
  /// In pt, this message translates to:
  /// **'Criando'**
  String get pix_hub_withdrawal_status_creating;

  /// No description provided for @pix_hub_withdrawal_status_rejected.
  ///
  /// In pt, this message translates to:
  /// **'Recusado'**
  String get pix_hub_withdrawal_status_rejected;

  /// No description provided for @pix_hub_withdrawal_status_uncertain.
  ///
  /// In pt, this message translates to:
  /// **'Em verificação'**
  String get pix_hub_withdrawal_status_uncertain;

  /// No description provided for @pix_hub_withdrawal_status_unsent.
  ///
  /// In pt, this message translates to:
  /// **'Aguardando o depósito'**
  String get pix_hub_withdrawal_status_unsent;

  /// No description provided for @pix_hub_withdrawal_status_sending.
  ///
  /// In pt, this message translates to:
  /// **'Enviando o Pix'**
  String get pix_hub_withdrawal_status_sending;

  /// No description provided for @pix_hub_withdrawal_status_sent.
  ///
  /// In pt, this message translates to:
  /// **'Pix entregue'**
  String get pix_hub_withdrawal_status_sent;

  /// No description provided for @pix_hub_withdrawal_status_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro no provedor'**
  String get pix_hub_withdrawal_status_error;

  /// No description provided for @pix_hub_withdrawal_status_canceled.
  ///
  /// In pt, this message translates to:
  /// **'Cancelado'**
  String get pix_hub_withdrawal_status_canceled;

  /// No description provided for @pix_hub_withdrawal_status_refunded.
  ///
  /// In pt, this message translates to:
  /// **'Devolvido'**
  String get pix_hub_withdrawal_status_refunded;

  /// No description provided for @pix_hub_withdrawal_status_replaced.
  ///
  /// In pt, this message translates to:
  /// **'Substituído'**
  String get pix_hub_withdrawal_status_replaced;

  /// No description provided for @pix_hub_withdrawal_status_unknown.
  ///
  /// In pt, this message translates to:
  /// **'Desconhecido'**
  String get pix_hub_withdrawal_status_unknown;

  /// No description provided for @pix_hub_pending_withdrawals_title.
  ///
  /// In pt, this message translates to:
  /// **'Pix em andamento'**
  String get pix_hub_pending_withdrawals_title;

  /// No description provided for @pix_hub_pending_withdrawal_item.
  ///
  /// In pt, this message translates to:
  /// **'{amount} para {key}'**
  String pix_hub_pending_withdrawal_item(String amount, String key);

  /// No description provided for @pix_hub_pending_withdrawal_hint.
  ///
  /// In pt, this message translates to:
  /// **'Toque para ver o status.'**
  String get pix_hub_pending_withdrawal_hint;

  /// No description provided for @pix_hub_send_key_title.
  ///
  /// In pt, this message translates to:
  /// **'Para quem você quer transferir?'**
  String get pix_hub_send_key_title;

  /// No description provided for @pix_hub_send_key_label.
  ///
  /// In pt, this message translates to:
  /// **'Insira o dado de quem vai receber'**
  String get pix_hub_send_key_label;

  /// No description provided for @pix_hub_send_key_hint.
  ///
  /// In pt, this message translates to:
  /// **'CPF/CNPJ, celular, e-mail ou chave Pix'**
  String get pix_hub_send_key_hint;

  /// No description provided for @pix_hub_send_key_scan.
  ///
  /// In pt, this message translates to:
  /// **'Ler QR Code'**
  String get pix_hub_send_key_scan;

  /// No description provided for @pix_hub_send_key_clear.
  ///
  /// In pt, this message translates to:
  /// **'Limpar'**
  String get pix_hub_send_key_clear;

  /// No description provided for @pix_hub_send_key_code_detected.
  ///
  /// In pt, this message translates to:
  /// **'Código Pix Copia e Cola reconhecido.'**
  String get pix_hub_send_key_code_detected;

  /// No description provided for @pix_hub_send_key_ambiguous.
  ///
  /// In pt, this message translates to:
  /// **'Este número é um CPF ou um celular?'**
  String get pix_hub_send_key_ambiguous;

  /// No description provided for @pix_hub_amount_question.
  ///
  /// In pt, this message translates to:
  /// **'Quanto você quer transferir?'**
  String get pix_hub_amount_question;

  /// No description provided for @pix_hub_tax_id_valid.
  ///
  /// In pt, this message translates to:
  /// **'Documento válido'**
  String get pix_hub_tax_id_valid;
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
