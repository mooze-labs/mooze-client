// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get common_back => 'Back';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_confirm => 'Confirm';

  @override
  String get common_save => 'Save';

  @override
  String get common_close => 'Close';

  @override
  String get common_continue => 'Continue';

  @override
  String get common_next => 'Next';

  @override
  String get common_ok => 'OK';

  @override
  String get common_retry => 'Try again';

  @override
  String get common_loading => 'Loading...';

  @override
  String get common_processing => 'Processing...';

  @override
  String get common_sending => 'Sending...';

  @override
  String get common_confirming => 'Confirming...';

  @override
  String get common_verifying => 'Verifying...';

  @override
  String get common_understood => 'Got it';

  @override
  String get common_no_thanks => 'No thanks';

  @override
  String get common_max => 'MAX';

  @override
  String get common_yes => 'Yes';

  @override
  String get common_no => 'No';

  @override
  String get common_finish => 'Finish';

  @override
  String get common_redo => 'Redo';

  @override
  String get error_open_link => 'Could not open the link';

  @override
  String get error_opening_link => 'Error opening the link';

  @override
  String get error_open_browser => 'Could not open the browser.';

  @override
  String error_unexpected(String error) {
    return 'Unexpected error: $error';
  }

  @override
  String error_generic(String error) {
    return 'Error: $error';
  }

  @override
  String get error_load_data => 'Failed to load data. Please try again.';

  @override
  String get error_load_data_short => 'Failed to load data';

  @override
  String get error_load_data_title => 'Failed to Load Data';

  @override
  String get error_no_internet => 'No internet connection. Check your network.';

  @override
  String get error_server_unavailable =>
      'Server temporarily unavailable. Please try again.';

  @override
  String get error_server_communication =>
      'Server communication error. Please try again.';

  @override
  String get error_authentication_failed => 'Authentication failed.';

  @override
  String get error_access_denied => 'Access denied. Check your permissions.';

  @override
  String get error_service_not_found =>
      'Service not found. Please try again later.';

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_section_security => 'SECURITY';

  @override
  String get settings_section_appearance => 'APPEARANCE';

  @override
  String get settings_section_language => 'LANGUAGE';

  @override
  String get settings_section_currency => 'CURRENCY';

  @override
  String get settings_section_account => 'ACCOUNT & REWARDS';

  @override
  String get settings_section_legal => 'LEGAL';

  @override
  String get settings_section_developer => 'DEVELOPER';

  @override
  String get settings_section_help => 'HELP';

  @override
  String get settings_view_recovery_phrase => 'View recovery phrase';

  @override
  String get settings_change_pin => 'Change PIN';

  @override
  String get settings_biometric_auth => 'Biometric authentication';

  @override
  String get settings_delete_wallet => 'Delete wallet';

  @override
  String get settings_theme => 'Theme';

  @override
  String get settings_language => 'Language';

  @override
  String get settings_change_currency => 'Change currency';

  @override
  String get settings_referral_code => 'Referral code';

  @override
  String get settings_terms => 'Terms of use';

  @override
  String get settings_license => 'GPL license';

  @override
  String get settings_logs => 'Logs';

  @override
  String get settings_log_details => 'Log details';

  @override
  String get settings_contact_support => 'Contact support';

  @override
  String get settings_section_network => 'NETWORK';

  @override
  String get settings_node_config => 'Node configuration';

  @override
  String get node_config_title => 'Node configuration';

  @override
  String get node_config_section_mode => 'MODE';

  @override
  String get node_config_section_custom => 'ENDPOINTS';

  @override
  String get node_config_section_advanced => 'ADVANCED';

  @override
  String get node_config_mode_default_title => 'Default mode';

  @override
  String get node_config_mode_default_subtitle =>
      'Use the system\'s recommended servers with automatic fallback between Bitcoin, Liquid and Lightning.';

  @override
  String get node_config_mode_custom_title => 'Custom mode';

  @override
  String get node_config_mode_custom_subtitle =>
      'Advanced — connect to your own Electrum endpoints.';

  @override
  String get node_config_advanced_warning =>
      'Only set this if you know what you are doing. Invalid URLs may prevent the app from syncing.';

  @override
  String get node_config_bitcoin_label => 'Bitcoin Mainnet endpoint';

  @override
  String get node_config_bitcoin_hint => 'ssl://your-node.tld:50002';

  @override
  String get node_config_bitcoin_helper =>
      'Format: scheme://host:port. Use ssl:// for encrypted connections.';

  @override
  String get node_config_liquid_label => 'Liquid Network endpoint';

  @override
  String get node_config_liquid_hint => 'your-node.tld:50002';

  @override
  String get node_config_liquid_helper =>
      'Format: host:port. LWK negotiates TLS automatically.';

  @override
  String get node_config_lightning_note =>
      'The Lightning node is managed automatically by the Breez SDK and cannot be customized.';

  @override
  String get node_config_fallback_toggle_title => 'Allow automatic fallback';

  @override
  String get node_config_fallback_toggle_subtitle =>
      'If your node fails, the app will try the default servers automatically.';

  @override
  String get node_config_save => 'Save settings';

  @override
  String get node_config_url_required => 'Required in custom mode';

  @override
  String get node_config_url_invalid =>
      'Use the format host:port (or scheme://host:port)';

  @override
  String get node_config_unsaved_title => 'Unsaved changes';

  @override
  String get node_config_unsaved_message =>
      'You have unsaved changes. Do you want to save them before leaving?';

  @override
  String get node_config_unsaved_discard => 'Discard';

  @override
  String get node_config_save_success => 'Node settings saved';

  @override
  String node_config_save_error(String error) {
    return 'Failed to save: $error';
  }

  @override
  String get node_config_load_error => 'Failed to load node settings';

  @override
  String get support_telegram_open_error => 'Could not open Telegram';

  @override
  String get support_screen_title => 'Support Center';

  @override
  String get support_help_title => 'How can we help?';

  @override
  String get support_help_subtitle =>
      'For faster service, share the code below with our support team.';

  @override
  String get support_user_code_label => 'Your identification code';

  @override
  String get support_user_code_load_error_title => 'Could not load your code';

  @override
  String get support_user_code_load_error_msg =>
      'Something went wrong while loading your information';

  @override
  String get support_user_code_not_found =>
      'We couldn\'t find your information';

  @override
  String get support_contact_button => 'Contact support';

  @override
  String get biometric_auth_reason =>
      'Confirm your identity to enable biometric authentication';

  @override
  String get biometric_enabled_success => 'Biometric authentication enabled.';

  @override
  String get biometric_disabled_info => 'Biometric authentication disabled.';

  @override
  String get biometric_disable_error => 'Failed to disable biometrics.';

  @override
  String get biometric_save_error => 'Failed to save setting.';

  @override
  String biometric_auth_error(String error) {
    return 'Authentication error: $error';
  }

  @override
  String get biometric_setup_enable_q => 'Enable biometrics?';

  @override
  String get biometric_setup_explanation =>
      'Use Face ID, fingerprint, or your device password to access your wallet faster and more securely.';

  @override
  String get biometric_setup_enable => 'Enable biometrics';

  @override
  String seed_fetch_error(String error) {
    return 'Error: $error';
  }

  @override
  String get seed_not_found => 'No recovery phrase found.';

  @override
  String get seed_screen_title => 'Recovery Phrase';

  @override
  String get seed_words_of => 'Recovery ';

  @override
  String get seed_recovery_word => 'Words';

  @override
  String get seed_save_warning =>
      'Write these words down somewhere safe. They are the only way to recover your wallet.';

  @override
  String get seed_copy => 'Copy seed';

  @override
  String get seed_copied => 'Copied';

  @override
  String get seed_confirm_phrase => 'Confirm phrase';

  @override
  String seed_confirmed_words_count(int count) {
    return 'Confirmed words ($count)';
  }

  @override
  String get seed_remove_last => 'Remove last';

  @override
  String get pin_confirm_title => 'Confirm PIN';

  @override
  String get pin_confirm_yours => 'Confirm your ';

  @override
  String get pin_word => 'PIN';

  @override
  String get pin_confirm_instruction_1 => 'Enter the ';

  @override
  String get pin_confirm_instruction_2 => 'PIN ';

  @override
  String get pin_confirm_instruction_3 => 'you just created again.';

  @override
  String get pin_mismatch => 'PINs don\'t match';

  @override
  String get pin_validate_title => 'Verify PIN';

  @override
  String get pin_validate_security => 'Security check';

  @override
  String get pin_validate_action => 'Verify ';

  @override
  String get pin_validate_body => 'Enter your PIN to continue securely.';

  @override
  String get pin_incorrect => 'Incorrect PIN. Please try again.';

  @override
  String get pin_use_biometric => 'Use biometrics';

  @override
  String get pin_use_device_password => 'Use device password';

  @override
  String get pin_forgot => 'Forgot your PIN?';

  @override
  String get pin_biometric_unavailable =>
      'Biometrics or device password not available.';

  @override
  String get pin_biometric_access_reason =>
      'Use your biometrics to access your wallet';

  @override
  String get pin_reset_biometric_reason =>
      'Use your biometrics or device password to reset the PIN';

  @override
  String get theme_system => 'System';

  @override
  String get theme_light => 'Light';

  @override
  String get theme_dark => 'Dark';

  @override
  String get language_portuguese => 'Portuguese';

  @override
  String get language_english => 'English';

  @override
  String get language_spanish => 'Spanish';

  @override
  String get language_system => 'Device language';

  @override
  String get delete_wallet_title => 'Delete wallet';

  @override
  String get delete_wallet_warning_title => 'Be careful when deleting your ';

  @override
  String get delete_wallet_word => 'wallet';

  @override
  String get delete_wallet_warning_subtitle =>
      'If you delete it, you\'ll need to go through the TRUST verification again, and you\'ll lose access to your funds unless you have saved your recovery phrase.';

  @override
  String get delete_wallet_pix_limits_title => 'PIX limits';

  @override
  String get delete_wallet_pix_limits_desc =>
      'I understand that I\'ll need to go through TRUST again and that my PIX limits will be reset.';

  @override
  String get delete_wallet_funds_loss_title => 'Loss of funds';

  @override
  String get delete_wallet_funds_loss_desc =>
      'I understand that I\'ll lose access to my funds if I haven\'t saved my recovery phrase.';

  @override
  String get delete_wallet_button => 'Delete wallet';

  @override
  String get delete_wallet_error =>
      'Failed to delete wallet. Please try again.';

  @override
  String get referral_title => 'Referral Code';

  @override
  String get referral_applied_success => 'Code applied successfully!';

  @override
  String get referral_error_empty_code => 'Code cannot be empty.';

  @override
  String get referral_error_invalid_code =>
      'Invalid code. Please check and try again.';

  @override
  String get referral_error_apply_failed =>
      'Failed to apply code. Please try again.';

  @override
  String get referral_error_fetch_failed => 'Failed to fetch referral code.';

  @override
  String get referral_error_validate_failed => 'Failed to validate code.';

  @override
  String get license_title => 'GPL v3 License';

  @override
  String get license_subtitle => 'GNU General Public License';

  @override
  String get license_version_line =>
      'Version 3, June 29, 2007 • Free Software Foundation';

  @override
  String get license_copyleft_title => 'Copyleft License';

  @override
  String get license_copyleft_desc =>
      'This license guarantees that the software stays free. Any distribution must include the source code.';

  @override
  String get license_free_software_title => 'Free Software';

  @override
  String get license_free_software_subtitle => 'Freedom guaranteed';

  @override
  String get license_redistributable_title => 'Redistributable';

  @override
  String get license_redistributable_subtitle => 'With source code';

  @override
  String get license_copyleft_short_title => 'Copyleft';

  @override
  String get license_copyleft_short_subtitle => 'Free derivatives';

  @override
  String get license_copyright_line =>
      'Copyright © 2007 Free Software Foundation, Inc.';

  @override
  String get license_fsf_link => 'Free Software Foundation';

  @override
  String get license_full_link => 'Full License';

  @override
  String get license_section_preamble => 'Preamble';

  @override
  String get license_section_definitions => 'Definitions';

  @override
  String get license_section_source => 'Source Code';

  @override
  String get license_section_basic_perms => 'Basic Permissions';

  @override
  String get license_section_legal_rights => 'Protecting Users\' Legal Rights';

  @override
  String get license_section_verbatim => 'Conveying Verbatim Copies';

  @override
  String get license_section_modified => 'Conveying Modified Source Versions';

  @override
  String get license_section_non_source => 'Conveying Non-Source Forms';

  @override
  String get license_section_additional => 'Additional Terms';

  @override
  String get license_section_termination => 'Termination';

  @override
  String get license_section_acceptance =>
      'Acceptance Not Required for Having Copies';

  @override
  String get license_section_downstream =>
      'Automatic Licensing of Downstream Recipients';

  @override
  String get license_section_patents => 'Patents';

  @override
  String get license_section_no_surrender => 'No Surrender of Others\' Freedom';

  @override
  String get license_section_agpl =>
      'Use with the GNU Affero General Public License';

  @override
  String get license_section_revisions => 'Revised Versions of this License';

  @override
  String get license_section_warranty => 'Disclaimer of Warranty';

  @override
  String get license_section_liability => 'Limitation of Liability';

  @override
  String get license_section_interpretation =>
      'Interpretation of Sections 15 and 16';

  @override
  String get license_section_preamble_body =>
      'The GNU General Public License is a free, copyleft license for software and other kinds of works.\n\nThe licenses for most software and other practical works are designed to take away your freedom to share and change the works. By contrast, the GNU General Public License is intended to guarantee your freedom to share and change all versions of a program, to make sure it remains free software for all its users.\n\nWhen we speak of free software, we are referring to freedom, not price. Our General Public Licenses are designed to make sure that you have the freedom to distribute copies of free software, that you receive source code or can get it if you want it, that you can change the software or use pieces of it in new free programs, and that you know you can do these things.';

  @override
  String get license_section_definitions_body =>
      'This License refers to version 3 of the GNU General Public License.\n\nCopyright also means copyright-like laws that apply to other kinds of works, such as semiconductor masks.\n\nThe Program refers to any copyrightable work licensed under this License. Each licensee is addressed as you. Licensees and recipients may be individuals or organizations.\n\nTo modify a work means to copy from or adapt all or part of the work in a fashion requiring copyright permission, other than the making of an exact copy.';

  @override
  String get license_section_source_body =>
      'The source code for a work means the preferred form of the work for making modifications to it. Object code means any non-source form of a work.\n\nA Standard Interface means an interface that either is an official standard defined by a recognized standards body, or, in the case of interfaces specified for a particular programming language, one that is widely used among developers working in that language.';

  @override
  String get license_section_basic_perms_body =>
      'All rights granted under this License are granted for the term of copyright on the Program, and are irrevocable provided the stated conditions are met. This License explicitly affirms your unlimited permission to run the unmodified Program.\n\nYou may make, run and propagate covered works that you do not convey, without conditions so long as your license otherwise remains in force.';

  @override
  String get license_section_legal_rights_body =>
      'No covered work shall be deemed part of an effective technological measure under any applicable law fulfilling obligations under article 11 of the WIPO copyright treaty.\n\nWhen you convey a covered work, you waive any legal power to forbid circumvention of technological measures.';

  @override
  String get license_section_verbatim_body =>
      'You may convey verbatim copies of the Program source code as you receive it, in any medium, provided that you conspicuously and appropriately publish on each copy an appropriate copyright notice.\n\nYou may charge any price or no price for each copy that you convey, and you may offer support or warranty protection for a fee.';

  @override
  String get license_section_modified_body =>
      'You may convey a work based on the Program, or the modifications to produce it from the Program, in the form of source code under the terms of section 4, provided that you also meet all of these conditions:\n\na) The work must carry prominent notices stating that you modified it, and giving a relevant date.\nb) The work must carry prominent notices stating that it is released under this License.';

  @override
  String get license_section_non_source_body =>
      'You may convey a covered work in object code form under the terms of sections 4 and 5, provided that you also convey the machine-readable Corresponding Source under the terms of this License.\n\nThe Corresponding Source may be on a different server operated by you or a third party that supports equivalent copying facilities.';

  @override
  String get license_section_additional_body =>
      'Additional permissions are terms that supplement the terms of this License by making exceptions from one or more of its conditions. Additional permissions applicable to the entire Program shall be treated as though they were included in this License.\n\nYou may place additional permissions on material, added by you to a covered work, for which you have or can give appropriate copyright permission.';

  @override
  String get license_section_termination_body =>
      'You may not propagate or modify a covered work except as expressly provided under this License. Any attempt otherwise to propagate or modify it is void, and will automatically terminate your rights under this License.\n\nHowever, if you cease all violation of this License, then your license from a particular copyright holder is reinstated provisionally.';

  @override
  String get license_section_acceptance_body =>
      'You are not required to accept this License in order to receive or run a copy of the Program. Ancillary propagation of a covered work occurring solely as a consequence of using peer-to-peer transmission to receive a copy likewise does not require acceptance.';

  @override
  String get license_section_downstream_body =>
      'Each time you convey a covered work, the recipient automatically receives a license from the original licensors, to run, modify and propagate that work, subject to this License.\n\nYou may not impose any further restrictions on the exercise of the rights granted or affirmed under this License.';

  @override
  String get license_section_patents_body =>
      'A contributor is a copyright holder who authorizes use under this License of the Program or a work on which the Program is based.\n\nEach contributor grants you a non-exclusive, worldwide, royalty-free patent license under the essential patent claims of that contributor.';

  @override
  String get license_section_no_surrender_body =>
      'If conditions are imposed on you, whether by court order, agreement or otherwise, that contradict the conditions of this License, they do not excuse you from the conditions of this License.\n\nIf you cannot convey a covered work so as to satisfy simultaneously your obligations under this License and any other pertinent obligations, then you may not convey it at all.';

  @override
  String get license_section_agpl_body =>
      'Notwithstanding any other provision of this License, you have permission to link or combine any covered work with a work licensed under version 3 of the GNU Affero General Public License into a single combined work.';

  @override
  String get license_section_revisions_body =>
      'The Free Software Foundation may publish revised and/or new versions of the GNU General Public License from time to time. Such new versions will be similar in spirit to the present version, but may differ in detail to address new problems or concerns.\n\nEach version is given a distinguishing version number.';

  @override
  String get license_section_warranty_body =>
      'THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM AS IS WITHOUT WARRANTY OF ANY KIND.\n\nTHE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU. SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.';

  @override
  String get license_section_liability_body =>
      'IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS THE PROGRAM AS PERMITTED ABOVE, BE LIABLE FOR DAMAGES.\n\nTHIS INCLUDES ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE PROGRAM, EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.';

  @override
  String get license_section_interpretation_body =>
      'If the disclaimer of warranty and limitation of liability provided above cannot be given local legal effect according to their terms, reviewing courts shall apply local law that most closely approximates an absolute waiver of all civil liability in connection with the Program, unless a warranty or assumption of liability accompanies a copy of the Program in return for a fee.';

  @override
  String get license_end_terms => 'END OF TERMS AND CONDITIONS';

  @override
  String get terms_title => 'Terms of Use';

  @override
  String get terms_subtitle => 'Mooze Wallet';

  @override
  String get terms_intro =>
      'By using the Mooze app, you fully agree to these terms. Please read carefully before continuing.';

  @override
  String get terms_warning_title => 'Important Notice';

  @override
  String get terms_warning_message =>
      'You are solely responsible for keeping your recovery phrase secure. Losing this information results in irreversible loss of your digital assets.';

  @override
  String get terms_self_custody_title => 'Self-custody';

  @override
  String get terms_self_custody_subtitle => 'You control your funds';

  @override
  String get terms_privacy_title => 'Privacy';

  @override
  String get terms_privacy_subtitle => 'Data protected';

  @override
  String get terms_beta_title => 'Beta';

  @override
  String get terms_beta_subtitle => 'In development';

  @override
  String get terms_last_updated => 'Last updated: 03/23/2026';

  @override
  String get terms_privacy_policy_link => 'View Privacy Policy';

  @override
  String get terms_section_1 => '1. Acceptance of Terms';

  @override
  String get terms_section_2 => '2. Legal Nature and Classification of Mooze';

  @override
  String get terms_section_3 => '3. Definitions';

  @override
  String get terms_section_4 => '4. Description of Services';

  @override
  String get terms_section_5 => '5. Non-custodial Model and Self-Custody';

  @override
  String get terms_section_6 => '6. User Responsibilities';

  @override
  String get terms_section_7 => '7. Fees and Service Charges';

  @override
  String get terms_section_8 => '8. Monetary Reference and Price Information';

  @override
  String get terms_section_9 => '9. Limitation of Liability';

  @override
  String get terms_section_10 => '10. Anti-fraud Policy and Security';

  @override
  String get terms_section_11 =>
      '11. Monitoring, Fraud Prevention and Service Suspension';

  @override
  String get terms_section_12 => '12. User Legal Obligations';

  @override
  String get terms_section_13 => '13. Jurisdiction and Applicable Law';

  @override
  String get terms_section_14 => '14. Dispute Resolution';

  @override
  String get terms_section_15 => '15. Intellectual Property';

  @override
  String get terms_section_16 => '16. General Provisions';

  @override
  String get terms_section_17 => '17. Minimum Age';

  @override
  String get terms_section_18 => '18. Changes to Terms';

  @override
  String get terms_section_19 => '19. Contact';

  @override
  String get privacy_section_header => 'Privacy Policy — Mooze Wallet';

  @override
  String get privacy_section_1 => '1. Commitment to Privacy';

  @override
  String get privacy_section_2 => '2. Definitions';

  @override
  String get privacy_section_3 => '3. Data Collected and Not Collected';

  @override
  String get privacy_section_4 => '4. Data Processing in Fiat Operations';

  @override
  String get privacy_section_5 => '5. Data Sharing';

  @override
  String get privacy_section_6 => '6. Communication with Mooze';

  @override
  String get privacy_section_7 => '7. Security';

  @override
  String get privacy_section_8 => '8. Data Retention';

  @override
  String get privacy_section_9 => '9. User Rights (LGPD)';

  @override
  String get privacy_section_10 => '10. Data Jurisdiction';

  @override
  String get privacy_section_11 => '11. Changes';

  @override
  String get privacy_section_12 => '12. Contact';

  @override
  String get terms_section_1_body =>
      '1.1. By accessing, installing, or using the Mooze app, the User declares to have read, understood, and fully accepted these Terms of Use.\n\n1.2. Use of the App constitutes tacit and irrevocable acceptance of all provisions contained in this document.\n\n1.3. If the User disagrees with any provision of these Terms, they must immediately cease using the App and uninstall it from their devices.\n\n1.4. These Terms constitute a binding agreement between the User and Mooze Labs LLC, governed by the laws of the Republic of the Marshall Islands.';

  @override
  String get terms_section_2_body =>
      '2.1. Mooze Labs LLC is a limited liability company incorporated under the Associations Law of the Republic of the Marshall Islands.\n\n2.2. Mooze operates exclusively as a software service provider for managing self-custodial digital wallets on the Bitcoin network and Liquid Network.\n\n2.3. Mooze is NOT a broker, exchange, financial institution, exchange service provider, money transmitter, VASP, asset custodian, or investment advisor.\n\n2.4. Mooze does not at any point have custody, possession, discretionary control, or dominion over any digital assets of the User. Transient processing through Mooze\'s infrastructure is analogous to routing data packets through a network router.\n\n2.5. Mooze does not conduct foreign exchange or financial intermediation operations. All operations involving Brazilian reais are processed by partners regulated by the Central Bank of Brazil.\n\n2.6. Mooze operates exclusively as a non-custodial software provider, without access, control, or custody over Users\' digital assets.\n\n2.7. Mooze is an official member of the Liquid Federation (Blockstream), with an active PAK Entry.';

  @override
  String get terms_section_3_body =>
      '3.1. App or Mooze Wallet: self-custodial digital wallet software available for iOS and Android.\n\n3.2. User: any natural person who installs, accesses, or uses the App.\n\n3.3. Self-custody: model in which the User holds exclusive control over their private keys and seed phrases.\n\n3.4. Seed Phrase: sequence of 12 or 24 words (BIP39 standard), the sole wallet recovery mechanism.\n\n3.5. Liquid Network: federated sidechain of Bitcoin developed by Blockstream.\n\n3.6. DEPIX: digital token on the Liquid Network pegged to the Brazilian real (R\$ 1.00 = 1 DEPIX).\n\n3.7. L-BTC: Bitcoin representation on the Liquid Network.\n\n3.8. Atomic Swap: direct exchange between digital assets without a custodial intermediary.\n\n3.9. SideSwap: public protocol for atomic swaps on the Liquid Network.\n\n3.10. Confidential Transactions: Liquid Network technology that hides transaction values and asset types.\n\n3.11. APP ID: unique device-generated identifier used exclusively for fraud prevention.\n\n3.12. Regulated Partners: PLEBIT.COM.BR (CNPJ 43.375.652/0001-13), Fits Instituição de Pagamento (CNPJ 13.203.354/0001-85), Celcoin (CNPJ 13.935.893/0001-09), PLEBZ (CNPJ 45.808.899/0001-01).\n\n3.13. Eulen.app LLC: responsible for issuing the DEPIX token.\n\n3.14. PIX: instant payment system of the Central Bank of Brazil.\n\n3.15. Services: software functionalities made available by Mooze.';

  @override
  String get terms_section_4_body =>
      '4.1. SERVICE A — Software Orchestration for Digital Token Acquisition\nMooze provides a software interface that automatically orchestrates communication between the User\'s device, Regulated Partners, and Eulen.app LLC infrastructure. PIX payment is processed by Regulated Partners; Eulen.app LLC issues DEPIX tokens; Mooze\'s software routes tokens to the User\'s self-custodial address. Mooze acts exclusively as an automated orchestrator without acquiring ownership of assets.\n\n4.2. SERVICE B — Interface for Decentralized Digital Unit Conversion Protocol\nMooze provides an interface for the User to interact with the SideSwap protocol for atomic swaps on the Liquid Network. Mooze does not participate as a counterparty or custodian. Mooze\'s role is analogous to a browser providing access to websites. Mooze also provides access via Breez SDK for the Lightning Network.\n\n4.3. MERCHANT MODE\nFunctionality that allows receiving PIX payments into self-custodial wallets. The PIX QR code is generated by the User via the App. Mooze has no knowledge of the underlying commercial relationship. Users MUST NOT deliver products or services before final payment confirmation. Questions: suporte@mooze.app.';

  @override
  String get terms_section_5_body =>
      '5.1. The App operates under a full self-custody model. Private keys and seed phrases are generated and stored exclusively on the User\'s device and are inaccessible to Mooze.\n\n5.2. Mooze does not have at any time access, knowledge, possession, control, or copies of the User\'s private keys, seed phrases, or passwords.\n\n5.3. The User is solely responsible for safekeeping their private keys and seed phrases. Loss of these elements results in permanent and irreversible loss of access to digital assets.\n\n5.4. Mooze does not have the technical capability to recover, restore, access, or transfer the User\'s digital assets in case of loss of private keys or seed phrases.\n\n5.5. The User\'s wallet addresses are used by Mooze exclusively as automated routing parameters during Service execution.';

  @override
  String get terms_section_6_body =>
      '6.1. SAFEKEEPING OF PASSWORDS AND SEED PHRASES\nThe User is fully and exclusively responsible for creating, storing, and protecting their passwords, private keys, and seed phrases. Mooze will never request the User\'s private keys, seed phrases, or passwords through any communication channel.\n\n6.2. CONSEQUENCES OF LOSS OF ACCESS\nLoss of the seed phrase results in permanent and irreversible loss of access to all digital assets. Mooze cannot restore or recover wallet access in case of loss.\n\n6.3. DEVICE SECURITY\nThe User is responsible for device security, including updated OS, biometric authentication, and malware protection. Mooze is not responsible for losses resulting from device compromise.';

  @override
  String get terms_section_7_body =>
      '7.1. Mooze charges a Software Service Fee for the use of Services, calculated as a percentage of the transaction value and deducted from digital assets delivered to the User.\n\n7.2. The applicable percentage is displayed on the transaction confirmation screen before it is executed.\n\n7.3. Mooze reserves the right to change percentages at any time. Continued use after a change constitutes acceptance.\n\n7.4. Regulated Partners, SideSwap, Breez Technologies and partner fintechs may apply their own fees, independent from Mooze\'s fee.\n\n7.5. Mining costs (network fees) are the User\'s responsibility and independent of the Service Fee. Total values are displayed on the confirmation screen before execution.';

  @override
  String get terms_section_8_body =>
      '8.1. Reference values displayed in the App for digital assets are obtained from public market sources and serve exclusively as informational reference.\n\n8.2. Mooze does not guarantee the accuracy or real-time update of displayed prices. Price variation between display and execution is inherent to digital asset markets.\n\n8.3. Price display does not constitute an offer, investment recommendation, or value guarantee.\n\n8.4. The User acknowledges that digital assets are subject to high volatility and may suffer significant value losses.';

  @override
  String get terms_section_9_body =>
      '9.1. Mooze provides the App and Services as-is, without warranties of any kind.\n\n9.2. Mooze shall not be responsible for: asset losses due to loss of private keys; device compromise; blockchain network unavailability; failures of Regulated Partners, Eulen.app LLC, or SideSwap; third-party fraud; errors in wallet address entry; regulatory changes; digital asset price variations; User investment decisions; indirect or consequential damages.\n\n9.3. Mooze\'s total liability is limited to the Service fees effectively paid by the User in the last 12 months.\n\n9.4. The App is in BETA mode. The User accepts all associated risks.\n\n9.5. Seed phrases are compatible with BIP39 and the Liquid Network. In case of critical unavailability, the User can recover assets in any compatible wallet (e.g., Blockstream App).';

  @override
  String get terms_section_10_body =>
      '10.1. Mooze implements security mechanisms including:\n- APP ID binding to operations\n- Risk-level scoring system\n- Progressive limits per APP ID\n- Detection of anomalous patterns (smurfing, bursting, self-payments)\n\n10.2. Mooze\'s anti-fraud measures are exclusively technological in nature and do not replace the AML and KYC obligations of Regulated Partners.\n\n10.3. Regulated Partners are solely responsible for compliance with AML and KYC obligations before the Central Bank of Brazil.';

  @override
  String get terms_section_11_body =>
      '11.1. Mooze reserves the right to suspend, limit, or terminate an APP ID\'s access to Services without prior notice in case of: patterns indicative of fraud; compromised devices or emulators; attempts to circumvent security mechanisms; money laundering or terrorism financing patterns; request by competent authority.\n\n11.2. Suspension affects only new operations. Self-custody assets remain fully under the User\'s control, accessible via the seed phrase.\n\n11.3. Mooze will cooperate with competent authorities upon valid court order, subject to technical limitations of the self-custodial model.';

  @override
  String get terms_section_12_body =>
      '12.1. The User declares and warrants that:\n- Uses Services in compliance with the laws of their jurisdiction\n- Resources used for PIX payments are of lawful origin\n- Does not use Services for money laundering, terrorism financing, or tax evasion\n- Is exclusively responsible for declaring and paying taxes on digital assets\n- Is aware that Mooze does not qualify as a VASP under Law No. 14.478/2022\n\n12.2. Mooze does not provide tax, fiscal, or legal advisory services.\n\n12.3. Mooze does not file tax returns on behalf of the User.';

  @override
  String get terms_section_13_body =>
      '13.1. These Terms are governed by the laws of the Republic of the Marshall Islands.\n\n13.2. Mooze Labs LLC is incorporated in the Republic of the Marshall Islands and operates from that jurisdiction, without physical or legal presence in Brazil.\n\n13.3. The relationship between Mooze and Regulated Partners is governed by independent international contracts, without creating joint liability between the parties.';

  @override
  String get terms_section_14_body =>
      '14.1. Any dispute shall be resolved, at Mooze\'s sole discretion, by the courts of the Republic of the Marshall Islands or by international arbitration under UNCITRAL Rules.\n\n14.2. The User waives any forum other than those indicated, except where prohibited by mandatory law of their jurisdiction.\n\n14.3. Before formalizing any dispute, the User must notify Mooze in writing. The parties will make good-faith efforts for amicable resolution within 30 days.';

  @override
  String get terms_section_15_body =>
      '15.1. All software, source code, design, trademarks, logos, and App content are the exclusive property of Mooze Labs LLC or its licensors.\n\n15.2. Use of the App does not grant the User any intellectual property rights.\n\n15.3. Reproduction, modification, or reverse engineering of the App is prohibited without Mooze\'s express authorization.\n\n15.4. Source code is available at https://github.com/mooze-labs/mooze-client under the terms of the license indicated therein.';

  @override
  String get terms_section_16_body =>
      '16.1. ENTIRETY\nThese Terms and the Privacy Policy constitute the entire agreement between the parties, superseding any prior agreements.\n\n16.2. SEVERABILITY\nIf any provision is declared invalid, the remaining provisions shall remain in full force.\n\n16.3. WAIVER\nMooze\'s failure to enforce any provision does not constitute a waiver of the right to enforce it later.\n\n16.4. ASSIGNMENT\nThe User may not assign their rights without prior written authorization from Mooze.\n\n16.5. FORCE MAJEURE\nMooze shall not be responsible for delays caused by blockchain network failures, Partner unavailability, cyberattacks, government decisions, or natural disasters.\n\n16.6. INDEMNIFICATION\nThe User agrees to indemnify Mooze for claims arising from misuse of Services, violation of laws, or provision of false information.\n\n16.7. DISTRIBUTION\nDistribution on digital platforms is carried out by Mooze LLC (Delaware), as authorized distributor, without assuming development or operational responsibilities.';

  @override
  String get terms_section_17_body =>
      '17.1. The App and Services are intended exclusively for persons aged 18 or older.\n\n17.2. By using the App, the User declares being at least 18 years old and having full civil capacity.\n\n17.3. Mooze reserves the right to suspend access of any User found to be under 18 years of age.';

  @override
  String get terms_section_18_body =>
      '18.1. Mooze reserves the right to amend these Terms at any time by publishing the updated version in the App and at https://mooze.app/termosdeuso/.\n\n18.2. Significant changes will be communicated via the App, Telegram, or email.\n\n18.3. Continued use after publication of changes constitutes tacit acceptance of the updated Terms.\n\n18.4. Users who disagree with the changes must cease use. Self-custody assets remain accessible via the seed phrase.';

  @override
  String get terms_section_19_body =>
      '19.1. For questions, requests, or communications related to these Terms:\n\n(a) Email: suporte@mooze.app\n(b) Telegram: https://t.me/+zkNS6KIDsEcyZDkx\n(c) Automated FAQ via Telegram\n\n19.2. Mooze will make efforts to respond within 10 business days.';

  @override
  String get privacy_section_header_body =>
      'Last updated: 03/23/2026\n\nMooze Labs LLC, Republic of the Marshall Islands';

  @override
  String get privacy_section_1_body =>
      '1.1. Mooze Labs LLC is committed to protecting privacy and minimizing personal data in the use of the App.\n\n1.2. This Policy describes what information is collected, how it is used, with whom it is shared, and what rights the User has.\n\n1.3. Mooze adopts the principle of data minimization as a central pillar of its operation. The App is designed to function without collecting identifiable personal data.';

  @override
  String get privacy_section_2_body =>
      'All terms defined in the Terms of Use have the same meanings in this Policy. Additionally:\n\n(a) Personal Data: any information relating to an identified or identifiable natural person (LGPD).\n(b) Processing: any operation performed with Personal Data.\n(c) LGPD: Brazil\'s General Data Protection Law (Law No. 13.709/2018).';

  @override
  String get privacy_section_3_body =>
      'MOOZE DOES NOT STORE:\nCPF, RG, MAC addresses, phone numbers, residential addresses, dates of birth, personal biometrics, private keys, or seed phrases.\n\nMOOZE COLLECTS EXCLUSIVELY:\n(a) APP ID: cryptographic hash of the device, used only for fraud prevention.\n(b) Liquid Network wallet addresses: used as automated routing parameters.\n(c) Blinding keys: retained for transaction verification and reconciliation.\n(d) Transaction data: values, asset types, timestamps, and execution status.\n(e) Device technical data: OS version, device model, and App version — do not allow personal identification.';

  @override
  String get privacy_section_4_body =>
      '4.1. When the User performs operations via PIX (Service A), the data required for processing — including KYC and AML — is collected and processed exclusively by the Regulated Partners.\n\n4.2. Regulated Partners: PLEBIT.COM.BR (CNPJ 43.375.652/0001-13), Fits Instituição de Pagamento (CNPJ 13.203.354/0001-85), Celcoin (CNPJ 13.935.893/0001-09), PLEBZ (CNPJ 45.808.899/0001-01).\n\n4.3. Mooze does not receive, store, or have access to personal data collected by Regulated Partners.';

  @override
  String get privacy_section_5_body =>
      '5.1. Mooze shares data exclusively:\n(a) With Regulated Partners and Eulen.app LLC: wallet addresses, values, and APP ID when necessary for anti-fraud.\n(b) Upon valid court order.\n(c) For compliance with legal obligations in Marshall Islands jurisdiction.\n\n5.2. Mooze DOES NOT sell, rent, or share data with third parties for marketing or advertising purposes.\n\n5.3. Mooze DOES NOT use third-party trackers, tracking pixels, or analytics SDKs that collect personal data.';

  @override
  String get privacy_section_6_body =>
      '6.1. When the User contacts Mooze via email (suporte@mooze.app) or Telegram, voluntarily shared data will be used exclusively for attending to the request.\n\n6.2. Mooze does not associate communication data with APP IDs or wallet addresses, except when the User voluntarily provides such information.';

  @override
  String get privacy_section_7_body =>
      '7.1. Mooze adopts reasonable technical and organizational measures to protect data against unauthorized access, destruction, or improper disclosure.\n\n7.2. Collected data is stored in protected infrastructure with access controls and encryption.\n\n7.3. No method of electronic transmission or storage is entirely secure.';

  @override
  String get privacy_section_8_body =>
      'Data collected by Mooze is retained for the following periods:\n\n(a) APP ID: 5 years after the last operation.\n(b) Wallet addresses and blinding keys: 5 years for verification and legal obligation compliance.\n(c) Transaction data: 5 years from the transaction date.\n(d) Device technical data: deleted after 5 years of inactivity.\n\nPeriods may be extended for legal obligation compliance or defense in judicial proceedings.';

  @override
  String get privacy_section_9_body =>
      'In compliance with the LGPD (Law No. 13.709/2018), Mooze recognizes the following User rights:\n\n(a) Confirmation of data processing\n(b) Access to processed data\n(c) Correction of incomplete or inaccurate data\n(d) Deletion of consent-based data\n(e) Information about data sharing\n(f) Withdrawal of consent\n(g) Request for deletion of the APP ID associated with the device\n\nRequests via channels indicated in Section 12 of this Policy. Response time: 15 business days.';

  @override
  String get privacy_section_10_body =>
      '10.1. Data collected by Mooze is stored and processed in infrastructure outside Brazilian territory.\n\n10.2. The applicable data jurisdiction is the Republic of the Marshall Islands.\n\n10.3. Operational data transmitted to Regulated Partners during Service A is processed in Brazil, under the exclusive responsibility of Regulated Partners.';

  @override
  String get privacy_section_11_body =>
      '11.1. Mooze reserves the right to amend this Policy at any time by publishing the updated version in the App and at https://mooze.app/termosdeuso/.\n\n11.2. Continued use after publication constitutes tacit acceptance of the updated Policy.';

  @override
  String get privacy_section_12_body =>
      '12.1. To exercise rights, ask questions, or make requests:\n\n(a) Email: suporte@mooze.app\n(b) Telegram: https://t.me/+zkNS6KIDsEcyZDkx\n(c) Automated FAQ via Telegram\n\n12.2. Mooze will make efforts to respond within 15 business days.';

  @override
  String get developer_title => 'Developer Tools';

  @override
  String get developer_copy_debug_tooltip => 'Copy debug info';

  @override
  String get developer_debug_copied => 'Debug information copied!';

  @override
  String get developer_sync_light_success => 'Light sync completed!';

  @override
  String get developer_sync_full_success => 'Full sync completed!';

  @override
  String get developer_rescan_success =>
      'Onchain swaps rescanned successfully!';

  @override
  String get developer_refundables_title => 'Pending Refunds';

  @override
  String developer_refundables_message(int count) {
    return 'Found $count pending transaction(s) that can be refunded.\n\nWould you like to view them now?';
  }

  @override
  String get developer_later => 'Later';

  @override
  String get developer_view_now => 'View Now';

  @override
  String get developer_email_ready => 'Email ready to send!';

  @override
  String get developer_share_logs_success => 'Logs shared successfully!';

  @override
  String developer_sync_light_error(String error) {
    return 'Failed to light sync: $error';
  }

  @override
  String developer_sync_full_error(String error) {
    return 'Failed to full sync: $error';
  }

  @override
  String developer_rescan_error(String error) {
    return 'Failed to rescan swaps: $error';
  }

  @override
  String developer_export_error(String error) {
    return 'Failed to export logs: $error';
  }

  @override
  String developer_share_logs_error(String error) {
    return 'Error sharing logs: $error';
  }

  @override
  String developer_log_retention_days(int days) {
    return '$days days';
  }

  @override
  String get developer_clear_memory_success =>
      'Memory logs cleared successfully!';

  @override
  String get developer_clear_db_success =>
      'Database logs cleared successfully!';

  @override
  String get developer_clear_all_success => 'All logs cleared successfully!';

  @override
  String developer_clear_error(String error) {
    return 'Error clearing logs: $error';
  }

  @override
  String get developer_system_info => 'System Information';

  @override
  String get developer_app_version => 'App Version';

  @override
  String get developer_sdk_version => 'SDK Version';

  @override
  String get developer_balance => 'Balance';

  @override
  String get developer_pending_balance => 'Pending Balance';

  @override
  String get developer_logs_memory => 'Logs (Memory)';

  @override
  String get developer_logs_db => 'Logs (Database)';

  @override
  String get developer_log_retention_label => 'Log Retention';

  @override
  String get developer_tools_title => 'Tools';

  @override
  String get developer_tools_subtitle => 'Sync, logs and diagnostics';

  @override
  String get developer_action_light_sync => 'Light Sync';

  @override
  String get developer_action_light_sync_tooltip =>
      'Fast sync (transactions, balances, prices)';

  @override
  String get developer_action_full_sync => 'Full Sync';

  @override
  String get developer_action_full_sync_tooltip => 'Complete blockchain sync';

  @override
  String get developer_action_rescan => 'Rescan';

  @override
  String get developer_action_rescan_tooltip => 'Rescan onchain swaps';

  @override
  String get developer_action_refund => 'Refund';

  @override
  String get developer_action_refund_tooltip => 'Navigate to refund screen';

  @override
  String get developer_action_view_logs => 'View Logs';

  @override
  String get developer_action_view_logs_tooltip => 'View application logs';

  @override
  String get developer_action_export => 'Export';

  @override
  String get developer_action_export_tooltip => 'Export logs as ZIP';

  @override
  String get developer_action_clear_logs => 'Clear Logs';

  @override
  String get developer_action_clear_logs_tooltip => 'Clear all logs';

  @override
  String get export_logs_title => 'Export Logs';

  @override
  String get export_logs_description =>
      'App logs help our team resolve issues. How would you like to share them?';

  @override
  String get export_logs_by_email => 'Send by Email';

  @override
  String get export_logs_share => 'Save/Share';

  @override
  String get clear_logs_title => 'Clear Logs';

  @override
  String get clear_logs_description => 'Choose what to clear:';

  @override
  String get clear_logs_option_memory => 'Memory';

  @override
  String clear_logs_option_memory_desc(int count) {
    return 'Clear only memory logs ($count logs)';
  }

  @override
  String get clear_logs_option_db => 'Database';

  @override
  String clear_logs_option_db_desc(int count) {
    return 'Clear only database logs ($count logs)';
  }

  @override
  String get clear_logs_option_all => 'All';

  @override
  String get clear_logs_option_all_desc => 'Clear memory, files and database';

  @override
  String get clear_logs_cancel => 'Cancel';

  @override
  String get logs_viewer_title => 'Application Logs';

  @override
  String get logs_viewer_loading => 'Loading logs...';

  @override
  String get logs_viewer_empty => 'No logs found';

  @override
  String get logs_source_memory => 'Memory';

  @override
  String get logs_source_database => 'Database';

  @override
  String get logs_source_all => 'All';

  @override
  String get logs_filter_search_hint => 'Search logs...';

  @override
  String get logs_filter_all => 'All';

  @override
  String get logs_detail_level => 'Level';

  @override
  String get logs_detail_timestamp => 'Timestamp';

  @override
  String get logs_detail_message => 'Message:';

  @override
  String get logs_detail_error_label => 'Error:';

  @override
  String get logs_detail_stack_trace => 'Stack Trace:';

  @override
  String get logs_detail_copy => 'Copy Log';

  @override
  String get logs_detail_copied => 'Log copied!';

  @override
  String get receive_title => 'Receive Assets';

  @override
  String get receive_info_title => 'How to receive assets';

  @override
  String get receive_info_step1_title => 'Select asset';

  @override
  String get receive_info_step1_desc =>
      'Choose which cryptocurrency you want to receive';

  @override
  String get receive_info_step2_title => 'Choose network';

  @override
  String get receive_info_step2_desc =>
      'Bitcoin (on-chain), Lightning or Liquid';

  @override
  String get receive_info_step3_title => 'Generate QR code';

  @override
  String get receive_info_step3_desc =>
      'Share with whoever will send the payment';

  @override
  String get receive_info_close_hint => 'Tap outside this area to close';

  @override
  String get receive_qr_title => 'Receive Payment';

  @override
  String get receive_qr_amount_label => 'Amount:';

  @override
  String get receive_qr_description_label => 'Description:';

  @override
  String get receive_qr_lightning_invoice => 'Lightning Invoice';

  @override
  String get receive_qr_address_title => 'Receiving Address';

  @override
  String get receive_qr_copy_address => 'Copy Address';

  @override
  String get receive_qr_copied => 'Copied!';

  @override
  String receive_qr_error(String error) {
    return 'Error generating QR: $error';
  }

  @override
  String get receive_network_bitcoin_onchain => 'Bitcoin On-chain';

  @override
  String get receive_network_lightning_network => 'Lightning Network';

  @override
  String get receive_network_liquid_network => 'Liquid Network';

  @override
  String get receive_network_unknown => 'Unknown';

  @override
  String get receive_select_asset => 'Select an asset';

  @override
  String get receive_select_network => 'Select network';

  @override
  String get receive_asset_hint_btc =>
      'Bitcoin on-chain is the only available network for BTC';

  @override
  String get receive_asset_hint_lbtc =>
      'Bitcoin L2 supports Lightning and Liquid';

  @override
  String receive_asset_hint_liquid_only(String name) {
    return '$name supports Liquid network only';
  }

  @override
  String get receive_lightning_amount_required_hint =>
      'For Lightning, amount is required';

  @override
  String get receive_select_asset_first => 'Select an asset first';

  @override
  String get receive_network_label_bitcoin => 'Bitcoin';

  @override
  String get receive_network_label_lightning => 'Lightning';

  @override
  String get receive_network_label_liquid => 'Liquid';

  @override
  String get receive_network_subtitle_onchain => 'On-chain';

  @override
  String get receive_network_subtitle_instant => 'Instant';

  @override
  String get receive_network_subtitle_private => 'Private';

  @override
  String get receive_amount_label => 'Amount';

  @override
  String get receive_amount_hint_required => 'Enter amount (required)';

  @override
  String get receive_amount_hint_optional => 'Enter amount (optional)';

  @override
  String get receive_amount_helper_disabled =>
      'Select an asset and network first';

  @override
  String get receive_amount_helper_lightning => 'Amount required for Lightning';

  @override
  String get receive_amount_helper_optional =>
      'Amount optional for Bitcoin/Liquid';

  @override
  String get receive_amount_sats_label => 'Amount in Satoshis:';

  @override
  String get receive_lightning_limits_unavailable =>
      'Could not load Lightning limits';

  @override
  String receive_lightning_min_value(String amount) {
    return 'Minimum: $amount sats';
  }

  @override
  String receive_lightning_max_value(String amount) {
    return 'Maximum: $amount sats';
  }

  @override
  String get receive_lightning_valid => 'Valid amount for Lightning';

  @override
  String get receive_lightning_limits_loading => 'Loading Lightning limits...';

  @override
  String get receive_lightning_limits_error => 'Error loading Lightning limits';

  @override
  String get receive_bitcoin_valid => 'Valid amount for Bitcoin';

  @override
  String get receive_liquid_valid => 'Valid amount for Liquid';

  @override
  String get receive_description_label => 'Description (optional)';

  @override
  String get receive_description_hint => 'e.g. Lunch payment';

  @override
  String get receive_description_add => 'Add description';

  @override
  String get receive_generate_qr => 'Generate invoice';

  @override
  String get receive_select_asset_network => 'Select an asset and network';

  @override
  String get receive_conversion_loading => 'Loading conversions...';

  @override
  String get receive_conversion_equivalent => 'Equivalent conversions:';

  @override
  String get receive_satoshis_label => 'Satoshis:';

  @override
  String get wallet_title => 'My Wallet';

  @override
  String get wallet_assets_tab => 'Assets';

  @override
  String get wallet_balance_available => 'Available balance:';

  @override
  String get wallet_send => 'Send';

  @override
  String get wallet_receive => 'Receive';

  @override
  String get wallet_send_title => 'Review Transaction';

  @override
  String get wallet_send_all_title => 'Review Send All';

  @override
  String get wallet_send_calculating_total => 'Calculating send-all total...';

  @override
  String get wallet_send_preparing => 'Preparing transaction...';

  @override
  String get wallet_send_prepare_error => 'Failed to prepare the transaction';

  @override
  String get wallet_send_dust_warning =>
      'There are issues with this transaction. Please review the details.';

  @override
  String get wallet_send_all_info =>
      'Sending all available funds. Fees will be deducted automatically from the total.';

  @override
  String get wallet_send_destination_network => 'Destination Network';

  @override
  String get wallet_send_destination_address => 'Destination Address';

  @override
  String get wallet_send_fee_details => 'Fee Breakdown';

  @override
  String get wallet_send_network_fee => 'Network Fee';

  @override
  String get wallet_send_service_fee => 'Service Fee';

  @override
  String get wallet_send_total_fees => 'Total Fees';

  @override
  String get wallet_send_free => 'Free';

  @override
  String get wallet_send_loading_price => 'Loading price...';

  @override
  String get wallet_send_calc_value_error => 'Failed to calculate amount';

  @override
  String get wallet_send_calculating_value => 'Calculating amount...';

  @override
  String get wallet_send_tx_error_title => 'Transaction Error';

  @override
  String get wallet_send_tx_error_desc => 'The transaction could not be sent:';

  @override
  String get wallet_send_tx_error_check => 'Check the details and try again.';

  @override
  String wallet_send_wallet_error(String description) {
    return 'Wallet access error: $description';
  }

  @override
  String get wallet_send_send_all_label => 'Send All';

  @override
  String wallet_send_asset_label(String asset) {
    return 'Send $asset';
  }

  @override
  String get wallet_onchain_network => 'Bitcoin On-chain';

  @override
  String get wallet_amount => 'Amount';

  @override
  String get wallet_network_fee => 'Network fee';

  @override
  String get wallet_total => 'Total';

  @override
  String get wallet_destination => 'Destination';

  @override
  String get wallet_fee_calculated_note =>
      'The fee is based on the speed you selected.';

  @override
  String get wallet_slide_to_confirm => 'Slide to confirm';

  @override
  String get wallet_speed_economic => 'Economy';

  @override
  String get wallet_speed_economic_desc => 'Slower confirmation, lower fee';

  @override
  String get wallet_speed_normal => 'Normal';

  @override
  String get wallet_speed_normal_desc => 'Balance between speed and cost';

  @override
  String get wallet_speed_priority => 'Priority';

  @override
  String get wallet_speed_priority_desc => 'Fastest confirmation, higher fee';

  @override
  String wallet_speed_label(String speed) {
    return 'Speed: $speed';
  }

  @override
  String get wallet_tx_not_found => 'Transaction not found';

  @override
  String get wallet_tx_not_found_error => 'Error: transaction not found';

  @override
  String wallet_send_tx_error(String error) {
    return 'Failed to send transaction: $error';
  }

  @override
  String get wallet_fee_speed_title => 'Transaction speed';

  @override
  String get wallet_fee_economic => 'Economy';

  @override
  String get wallet_fee_economic_eta => '~60+ min';

  @override
  String get wallet_fee_normal => 'Normal';

  @override
  String get wallet_fee_normal_eta => '~30 min';

  @override
  String get wallet_fee_fast => 'Fast';

  @override
  String get wallet_fee_fast_eta => '~10 min';

  @override
  String get tx_confirmed_title => 'Transaction Confirmed!';

  @override
  String tx_received_asset(String ticker) {
    return 'You received $ticker';
  }

  @override
  String get tx_received => 'Received';

  @override
  String get tx_id => 'Transaction ID';

  @override
  String get tx_back_to_dashboard => 'Back to Dashboard';

  @override
  String get tx_history_title => 'Transaction history';

  @override
  String get tx_history_pix_title => 'PIX history';

  @override
  String get tx_detail_title => 'Transaction Details';

  @override
  String get tx_detail_swap_unfinished => 'Swap not completed';

  @override
  String get tx_detail_swap_refunded => 'Swap refunded';

  @override
  String get tx_detail_refund_available_msg =>
      'This transaction did not complete successfully. Your funds are safe and available for refund. Use the button below to request the refund.';

  @override
  String get tx_detail_refund_processed_msg =>
      'The refund for this transaction has already been processed or is being sent. Your funds have been or will be returned shortly.';

  @override
  String get tx_filter_title => 'Filters';

  @override
  String get tx_filter_sort_by => 'Sort by';

  @override
  String get tx_filter_type => 'Transaction type';

  @override
  String get tx_filter_status => 'Status';

  @override
  String get tx_filter_currency => 'Currency';

  @override
  String get tx_filter_period => 'Period';

  @override
  String get tx_filter_period_custom => 'Custom period';

  @override
  String get tx_filter_clear_period => 'Clear period';

  @override
  String get tx_filter_clear_filters => 'Clear filters';

  @override
  String get tx_filter_apply => 'Apply filters';

  @override
  String get tx_type_all => 'All';

  @override
  String get tx_type_send => 'Send';

  @override
  String get tx_type_receive => 'Receive';

  @override
  String get tx_type_swap => 'Swap';

  @override
  String get tx_status_all => 'All';

  @override
  String get tx_status_pending => 'Pending';

  @override
  String get tx_status_confirmed => 'Confirmed';

  @override
  String get tx_status_failed => 'Failed';

  @override
  String get tx_status_refundable => 'Refundable';

  @override
  String get wallet_errors_insufficient_funds =>
      'Insufficient funds in wallet.';

  @override
  String get wallet_errors_invalid_address => 'Invalid address.';

  @override
  String get wallet_errors_connection_failed => 'Connection failed.';

  @override
  String get wallet_errors_tx_cannot_finalize =>
      'Transaction cannot be finalized.';

  @override
  String get wallet_errors_invalid_asset => 'Invalid asset.';

  @override
  String get wallet_errors_invalid_amount => 'Invalid amount.';

  @override
  String get wallet_errors_connection => 'Connection error';

  @override
  String get wallet_errors_internal => 'Internal error';

  @override
  String get swap_title => 'Swap';

  @override
  String get swap_you_send => 'You send';

  @override
  String get swap_you_receive => 'You receive';

  @override
  String swap_rate_line(String from, String rate, String to) {
    return '1 $from = $rate $to';
  }

  @override
  String get swap_insufficient_balance =>
      'Insufficient balance to perform the swap';

  @override
  String get swap_updating_quote => 'Updating quote...';

  @override
  String swap_min_value_sats(String sats) {
    return 'Minimum value: $sats sats';
  }

  @override
  String swap_min_amount_sats(String sats) {
    return 'Minimum amount is $sats sats';
  }

  @override
  String get swap_no_liquidity_title => 'No Liquidity';

  @override
  String get swap_no_liquidity_body =>
      'There is no liquidity available on Sideswap for this operation right now.';

  @override
  String get swap_use_asset_value => 'Use asset amount';

  @override
  String swap_use_currency_value(String currency) {
    return 'Use $currency amount';
  }

  @override
  String swap_expires_in(int seconds) {
    return 'Expires in ${seconds}s';
  }

  @override
  String get swap_quote_refreshing => 'Refreshing quote...';

  @override
  String get swap_quote_outdated_title => 'Quote outdated';

  @override
  String get swap_quote_outdated_body =>
      'Tap refresh to get the latest market rate.';

  @override
  String get swap_refresh_action => 'Refresh';

  @override
  String get swap_rate_label => 'Rate';

  @override
  String get swap_confirm_title => 'Confirm Swap';

  @override
  String get swap_confirm_estimate => 'Estimate';

  @override
  String get swap_confirm_sending => 'Sending:';

  @override
  String get swap_confirm_boltz_fee => 'Boltz service fee:';

  @override
  String get swap_confirm_tx_fee => 'Transaction fee:';

  @override
  String get swap_confirm_total_fees => 'Total fees:';

  @override
  String get swap_confirm_receiving => 'Receiving:';

  @override
  String get swap_confirm_server_fee => 'Server fee';

  @override
  String get swap_confirm_fixed_fee => 'Fixed fee';

  @override
  String get swap_confirm_total_fees_short => 'Total fees';

  @override
  String swap_confirm_error(String error) {
    return 'Confirmation error: $error';
  }

  @override
  String get pix_confirm_title => 'Confirm transaction';

  @override
  String get pix_generating_qr => 'Generating QR Code...';

  @override
  String get pix_processing_unavailable =>
      'PIX transactions can\'t be processed right now. Please try again later.';

  @override
  String get pix_select_asset => 'Select an asset';

  @override
  String get pix_floating_rate_title => 'Floating Exchange Rate';

  @override
  String get pix_floating_rate_body =>
      'Heads up: LBTC fluctuates in price.\nThe BRL amount you receive may differ from what you expected.\nThe conversion to BRL uses the exchange rate at settlement time.';

  @override
  String get pix_dont_show_again => 'Don\'t show again';

  @override
  String get pix_disclaimer_header => 'For a smoother PIX experience:';

  @override
  String get pix_disclaimer_max_consecutive =>
      'Max 3 consecutive PIX from the same holder within 30 min.';

  @override
  String get pix_disclaimer_daily_limit =>
      'Limit R\$ 5,000/day per holder (banking-tier).';

  @override
  String get pix_disclaimer_outside_rules =>
      'Transfers outside these rules are returned to the sender.';

  @override
  String get pix_disclaimer_analyzed =>
      '100% of PIX transfers are analyzed by joint infrastructure — automatic refund if automation is suspected.';

  @override
  String get pix_disclaimer_avg_time =>
      'Avg. time: 5 to 25 min. PIX with banking risk signals: 3–7 business days (refundable).';

  @override
  String get pix_deposit_title => 'PIX Deposit Details';

  @override
  String get pix_deposit_label => 'PIX Deposit';

  @override
  String get pix_deposit_date => 'Date';

  @override
  String get pix_deposit_target_asset => 'Target asset';

  @override
  String get pix_deposit_value => 'Amount';

  @override
  String get pix_deposit_pix_key => 'PIX key';

  @override
  String get pix_deposit_id => 'Deposit ID';

  @override
  String get pix_deposit_received_value => 'Amount received';

  @override
  String get pix_deposit_tx_id => 'TX ID';

  @override
  String get pix_deposit_expired => 'Expired';

  @override
  String get pix_deposit_time_remaining => 'Time remaining to pay';

  @override
  String get pix_deposit_invalid => 'This PIX is no longer valid';

  @override
  String get pix_deposit_info => 'Information';

  @override
  String get pix_deposit_view_explorer => 'View on Explorer';

  @override
  String get pix_deposit_view_chain => 'View on the blockchain';

  @override
  String get human_verif_title => 'Humanity Verification';

  @override
  String get human_verif_intro_title => 'Verify you\'re human';

  @override
  String get human_verif_intro_body =>
      'To keep the platform safe, we need to verify that you\'re a real person.';

  @override
  String get human_verif_step1_title => 'Symbolic payment';

  @override
  String get human_verif_step1_desc =>
      'You\'ll send a R\$ 1.00 PIX to our key. The amount will be returned right after the payment.';

  @override
  String get human_verif_step2_title => 'Get your code';

  @override
  String get human_verif_step2_desc =>
      'You\'ll receive the amount back along with a unique code in the message.';

  @override
  String get human_verif_step3_title => 'Verify your identity';

  @override
  String get human_verif_step3_desc =>
      'Enter the code you received to confirm you\'re human.';

  @override
  String get human_verif_payment_title => 'Verification Payment';

  @override
  String get human_verif_time_remaining_prefix => 'You have ';

  @override
  String get human_verif_minutes_and => 'minutes and ';

  @override
  String get human_verif_seconds => 'seconds ';

  @override
  String get human_verif_to_pay => 'to complete the payment.';

  @override
  String get human_verif_pix_key => 'PIX key';

  @override
  String get human_verif_time_expired_title => 'Time\'s Up';

  @override
  String get human_verif_time_expired_body =>
      'The payment window has expired. Please try again.';

  @override
  String get human_verif_after_payment =>
      'After paying, you\'ll receive a code in the return PIX message.';

  @override
  String get human_verif_already_paid => 'I\'ve already paid';

  @override
  String get human_verif_code_title => 'Validate Code';

  @override
  String get human_verif_code_prompt_prefix => 'Enter the ';

  @override
  String get human_verif_code_word => 'code';

  @override
  String get human_verif_code_body =>
      'Enter the 6-digit code you received in the return PIX message.';

  @override
  String get human_verif_code_invalid => 'Invalid code. Please try again.';

  @override
  String get human_verif_code_help =>
      'Check the message field of the PIX you received back.';

  @override
  String get human_verif_back_to_payment => 'Back to payment';

  @override
  String get phone_verif_title => 'Verification';

  @override
  String get phone_verif_humanity_title => 'Humanity Verification';

  @override
  String get phone_verif_humanity_body =>
      'To keep things safe, we need to confirm that you\'re a real person. Your phone number will only be used to send a verification code. No data will be stored or linked to your wallet.';

  @override
  String get phone_verif_method_title => 'Choose Method';

  @override
  String get phone_verif_inform_prefix => 'Enter your ';

  @override
  String get phone_verif_phone_number => 'phone number';

  @override
  String get phone_verif_method_subtitle =>
      'Choose how you\'d like to receive the verification code';

  @override
  String get phone_verif_number_label => 'Number';

  @override
  String get phone_verif_number_hint => 'Enter your number';

  @override
  String get phone_verif_send_code => 'Send code';

  @override
  String get phone_verif_code_title => 'Confirm Code';

  @override
  String get phone_verif_code_prompt_prefix => 'Enter the ';

  @override
  String get phone_verif_code_word => 'code received';

  @override
  String phone_verif_code_body(String phone) {
    return 'We sent a 6-digit code to $phone via Telegram.';
  }

  @override
  String get phone_verif_verify => 'Verify';

  @override
  String phone_verif_resend_in(String seconds) {
    return 'Resend in 00:$seconds';
  }

  @override
  String get phone_verif_resend_code => 'Resend code';

  @override
  String get refund_screen_title => 'Transaction Refund';

  @override
  String get refund_available_title => 'Available Refunds';

  @override
  String refund_retry_progress(int current, int max) {
    return 'Attempt $current of $max';
  }

  @override
  String get refund_loading_long => 'Please wait, this may take a moment...';

  @override
  String get refund_empty_title => 'No Refunds Available';

  @override
  String get refund_empty_body => 'You have no transactions pending refund.';

  @override
  String get refund_pull_to_refresh => 'Pull down to refresh';

  @override
  String get refund_speed_title => 'Transaction Speed';

  @override
  String get refund_insufficient_for_fee =>
      'Insufficient funds to cover the transaction fee';

  @override
  String refund_fee_load_error(String error) {
    return 'Failed to fetch fees: $error';
  }

  @override
  String get refund_calculating_fees => 'Calculating fees...';

  @override
  String get refund_amount_too_small =>
      'Amount too small to cover the transaction fees';

  @override
  String get refund_confirm_button => 'Confirm Refund';

  @override
  String refund_process_error(String error) {
    return 'Failed to process refund: $error';
  }

  @override
  String get refund_none_found => 'No refundable swaps found';

  @override
  String get refund_details_title => 'Refund Details';

  @override
  String get refund_auto_send_info =>
      'Don\'t worry, the Bitcoin refund will be sent automatically to the address from your wallet.';

  @override
  String get refund_info_title => 'Refund Information';

  @override
  String get refund_label_amount => 'Amount';

  @override
  String get refund_label_transaction => 'Transaction';

  @override
  String get refund_label_date => 'Date';

  @override
  String get refund_label_refund_amount => 'Refund Amount';

  @override
  String get refund_address_label => 'Bitcoin Address';

  @override
  String get refund_address_hint => 'Enter the Bitcoin address';

  @override
  String get refund_address_required => 'Please enter a Bitcoin address';

  @override
  String get refund_address_invalid => 'Invalid Bitcoin address';

  @override
  String get refund_address_invalid_long =>
      'Invalid Bitcoin address. Use a valid address (e.g., 1..., 3..., bc1...)';

  @override
  String get refund_status_pending => 'Pending';

  @override
  String get refund_status_available => 'Available';

  @override
  String get refund_action_retransmit => 'Resubmit';

  @override
  String get refund_speed_select_title => 'Select the transaction speed';

  @override
  String get refund_amount_too_small_short =>
      'Amount too small to cover the fees';

  @override
  String get refund_fee_label_economy => 'Economy';

  @override
  String get refund_fee_label_standard => 'Standard';

  @override
  String get refund_fee_label_fast => 'Fast';

  @override
  String get refund_fee_label_urgent => 'Urgent';

  @override
  String get refund_fee_time_24h => '~24 hours';

  @override
  String get refund_fee_time_1h => '~1 hour';

  @override
  String get refund_fee_time_30m => '~30 minutes';

  @override
  String get refund_fee_time_10m => '~10 minutes';

  @override
  String refund_fee_rate(int rate) {
    return 'Fee: $rate sat/vB';
  }

  @override
  String refund_fee_total(String amount) {
    return 'Total: $amount sats';
  }

  @override
  String get refund_success_title => 'Refund Started!';

  @override
  String get refund_success_body =>
      'Your refund has been processed successfully. The funds will soon be available at the address provided.';

  @override
  String get refund_success_amount_label => 'Refunded Amount';

  @override
  String get refund_success_txid_label => 'Transaction ID';

  @override
  String get refund_success_back_dashboard => 'Back to Dashboard';

  @override
  String get refund_test_title => '🧪 Refund Test';

  @override
  String get refund_test_heading => 'Test Mode - Refund';

  @override
  String get refund_test_description =>
      'Use this screen to test the full refund flow with simulated data, without needing real transactions.';

  @override
  String get refund_test_button_mock => 'Test with Mock Data';

  @override
  String get refund_test_button_real_sdk => 'Test with Real SDK';

  @override
  String get refund_test_mock_data_title => 'Included Mock Data';

  @override
  String get refund_test_mock_item_swaps => '• 3 refundable swaps';

  @override
  String get refund_test_mock_item_amounts =>
      '• Amounts: 0.001, 0.0025, 0.0005 BTC';

  @override
  String get refund_test_mock_item_fees => '• 4 different fee options';

  @override
  String get refund_test_mock_item_address => '• Pre-filled Bitcoin address';

  @override
  String get refund_test_mock_item_success =>
      '• Simulates success in 90% of cases';

  @override
  String get refund_test_advanced_title => '🧪 Advanced Refund Test';

  @override
  String get refund_test_clear_tooltip => 'Clear mock transactions';

  @override
  String get refund_test_cleared_snack => 'Mock transactions removed';

  @override
  String get refund_test_advanced_heading =>
      'Refund Test with\nReal Transactions';

  @override
  String get refund_test_advanced_description =>
      'Simulate refundable Peg In transactions based on\nreal data to test the full refund flow.';

  @override
  String get refund_test_load_mock_button => 'Load Mock Transactions';

  @override
  String refund_test_loaded_snack(int count) {
    return '$count mock transactions loaded';
  }

  @override
  String refund_test_mock_list_title(int count) {
    return 'Mock Transactions ($count)';
  }

  @override
  String get refund_test_flow_button => 'Test Refund Flow (Mock SDK)';

  @override
  String get refund_test_real_tx_title => 'About the Real Transaction';

  @override
  String get refund_test_real_tx_type => '🔹 Type: Peg In (BTC → LBTC)';

  @override
  String get refund_test_real_tx_id => '🔹 TX ID: 5e2159e9b5fbf7023b2800...';

  @override
  String get refund_test_real_tx_sent =>
      '🔹 Sent amount: 52574 sats (402 sats fee)';

  @override
  String get refund_test_real_tx_expected =>
      '🔹 Expected amount: 52172 sats (LBTC)';

  @override
  String get refund_test_real_tx_date => '🔹 Date: 02/04/2026 at 00:17:10';

  @override
  String get refund_test_real_tx_lockup =>
      '🔹 Lockup TX: 2622dd4f5a1c69f7cea5...';

  @override
  String get refund_test_real_tx_address =>
      '🔹 Address: bc1p62e2r4jnr3v985uqk...';

  @override
  String get refund_test_real_tx_warning =>
      'Status: REFUNDABLE\nThis transaction failed and the funds can be refunded to the original Bitcoin address.';

  @override
  String get refund_test_badge_refundable => 'REFUNDABLE';

  @override
  String get refund_test_badge_confirmed => 'CONFIRMED';

  @override
  String refund_test_card_amount(String amount) {
    return 'Amount: $amount sats';
  }

  @override
  String refund_test_card_id(String id) {
    return 'ID: $id';
  }

  @override
  String refund_test_card_to(String address) {
    return 'To: $address';
  }

  @override
  String get qr_scanner_searching => 'Searching for QR Code...';

  @override
  String get qr_scanner_found => 'QR Code found!';

  @override
  String get qr_scanner_position_hint =>
      'Position the QR code inside the highlighted area';

  @override
  String get qr_scanner_supported_networks => 'Bitcoin • Lightning • Liquid';

  @override
  String get qr_scanner_flash_label => 'Flash';

  @override
  String get qr_scanner_camera_label => 'Camera';

  @override
  String get qr_validation_empty => 'Empty QR code';

  @override
  String get qr_validation_unrecognized => 'Unrecognized QR code format';

  @override
  String get qr_validation_lightning_unsupported_symbols =>
      'Lightning with special symbols (₿, #, \$) is not supported';

  @override
  String get qr_validation_lnurl_bip353_unsupported =>
      'LNURL BIP 353 format is not supported at the moment. Use a valid Lightning address or LNURL from walletofsatoshi.com';

  @override
  String get qr_validation_boltz_invalid => 'Invalid BOLTZ invoice';

  @override
  String get qr_validation_boltz_no_amount =>
      'BOLTZ invoice without amount is not supported. Please generate an invoice with a defined amount';

  @override
  String get qr_validation_liquid_invalid =>
      'Invalid Liquid address in QR code';

  @override
  String get qr_validation_liquid_format_error =>
      'Error processing Liquid QR: invalid format';

  @override
  String get qr_validation_bitcoin_invalid =>
      'Invalid Bitcoin address in QR code';

  @override
  String get qr_validation_bitcoin_format_error =>
      'Error processing Bitcoin QR: invalid format';

  @override
  String get qr_validation_lightning_too_short => 'Lightning invoice too short';

  @override
  String get qr_validation_lnurl_unsupported =>
      'LNURL not supported. Use walletofsatoshi.com or another compatible provider';

  @override
  String get qr_validation_invalid_default => 'Invalid QR code';

  @override
  String get tx_sent_title => 'Transaction Sent!';

  @override
  String tx_sent_subtitle(String ticker) {
    return 'Your $ticker was sent successfully';
  }

  @override
  String get tx_sent_status_label => 'Sent';

  @override
  String get tx_sent_track_history =>
      'You can track the status in the history section.';

  @override
  String get setup_first_access_title => 'How do you want to start?';

  @override
  String get setup_first_access_subtitle =>
      'You can create a new wallet protected by you, or import an existing one with your key.';

  @override
  String get setup_create_wallet_appbar => 'Create wallet';

  @override
  String get setup_seed_length_title => 'Select the length of the ';

  @override
  String get setup_seed_length_highlight => 'seed phrase';

  @override
  String get setup_seed_length_subtitle =>
      'You can create your wallet with 12 or 24 words. Both are secure, but each option has its own balance of practicality and protection.';

  @override
  String get setup_seed_12_title => '12 Words';

  @override
  String get setup_seed_12_desc =>
      'More practical and quick to set up. Recommended\nfor beginners or those who prefer simplicity without\ngiving up security.';

  @override
  String get setup_seed_24_title => '24 Words (recommended)';

  @override
  String get setup_seed_24_desc =>
      'Provides more security. Recommended for\nthose who want to protect larger amounts or seek\nmaximum security.';

  @override
  String get setup_generate_seed_button => 'Generate recovery phrase';

  @override
  String get setup_confirm_seed_appbar => 'Confirm your phrase';

  @override
  String get setup_confirm_seed_title => 'Security ';

  @override
  String get setup_confirm_seed_highlight => 'Confirmation';

  @override
  String get setup_confirm_seed_subtitle =>
      'Select the words in the correct order to confirm your recovery phrase.';

  @override
  String get setup_confirm_seed_error =>
      'One or more words are incorrect. Try again.';

  @override
  String setup_seed_word_label(int position) {
    return 'Word #$position: ';
  }

  @override
  String get setup_import_appbar => 'Import Wallet';

  @override
  String get setup_import_restart_tooltip => 'Restart';

  @override
  String get setup_import_instruction_title => 'Enter your recovery phrase';

  @override
  String get setup_import_instruction_body =>
      'Enter each word of your seed phrase (12 or 24 words). The system will offer BIP39 suggestions as you type. Press space or tap to confirm each word.';

  @override
  String get setup_import_seed_valid => 'Seed phrase valid! Ready to import.';

  @override
  String get setup_import_checksum_invalid =>
      'Invalid checksum. Check the words.';

  @override
  String get setup_import_tip =>
      'Tip: Press space to quickly confirm the first suggestion';

  @override
  String get setup_import_button => 'Import Wallet';

  @override
  String get setup_import_cleanup_warning =>
      'Warning: Some old files could not be removed. The app may need to be restarted.';

  @override
  String get setup_clipboard_detected_title => 'Seed phrase detected';

  @override
  String get setup_clipboard_detected_body =>
      'We detected a phrase in your clipboard';

  @override
  String get setup_clipboard_paste_button => 'Paste';

  @override
  String get setup_clipboard_ignore_button => 'Dismiss';

  @override
  String setup_input_hint_press_space(String word) {
    return 'Press space to confirm \"$word\"';
  }

  @override
  String get setup_input_hint_default => 'Type a BIP39 word...';

  @override
  String get setup_progress_label => 'Progress';

  @override
  String setup_progress_count(int count, int target) {
    return '$count/$target words';
  }

  @override
  String setup_seed_invalid_word(String word) {
    return 'Invalid word: $word';
  }

  @override
  String setup_seed_wrong_count(int count) {
    return 'Phrase must have 12, 15, 18, 21 or 24 words. Found: $count';
  }

  @override
  String setup_seed_invalid_words_list(String list) {
    return 'Invalid words: $list';
  }

  @override
  String get setup_seed_invalid_checksum =>
      'Invalid phrase. Check the checksum.';

  @override
  String get wallet_import_msg_processing => 'Processing...';

  @override
  String get wallet_import_msg_verifying => 'Verifying data...';

  @override
  String get wallet_import_msg_initializing => 'Initializing wallet...';

  @override
  String get wallet_import_phase_platform => 'Initializing platform...';

  @override
  String get wallet_import_phase_database => 'Preparing database...';

  @override
  String get wallet_import_phase_credentials => 'Loading credentials...';

  @override
  String get wallet_import_phase_connecting => 'Connecting to networks...';

  @override
  String get wallet_import_phase_authenticating => 'Authenticating session...';

  @override
  String get wallet_import_phase_finalizing => 'Finalizing wallet...';

  @override
  String get wallet_import_msg_loading_balances => 'Loading balances...';

  @override
  String get wallet_import_msg_loading_transactions =>
      'Loading transactions...';

  @override
  String get wallet_import_msg_completed => 'Import completed ✓';

  @override
  String wallet_import_msg_synced(String name) {
    return '$name synced ✓';
  }

  @override
  String wallet_import_msg_resynced(String name) {
    return '$name - resyncing...';
  }

  @override
  String get wallet_import_datasource_liquid => 'Liquid Network';

  @override
  String get wallet_import_datasource_bitcoin => 'Bitcoin';

  @override
  String get wallet_import_datasource_lightning => 'Lightning';

  @override
  String get wallet_import_error_reconnecting => 'Trying to reconnect...';

  @override
  String get wallet_import_error_load_data => 'Error loading data';

  @override
  String get wallet_import_error_connection => 'Connection error';

  @override
  String get wallet_import_error_servers => 'Error connecting to servers';

  @override
  String get wallet_import_error_servers_unavailable => 'Servers unavailable';

  @override
  String get wallet_import_error_generic => 'Error during import';

  @override
  String get wallet_import_error_occurred => 'An error occurred';

  @override
  String wallet_import_error_reconnecting_count(String current, String max) {
    return 'Reconnecting ($current/$max)';
  }

  @override
  String get wallet_import_error_reconnecting_servers =>
      'Trying to reconnect to servers...';

  @override
  String get wallet_import_error_no_connection =>
      'Could not connect to servers.\nCheck your connection and try again.';

  @override
  String get wallet_import_error_servers_long =>
      'Error connecting to servers.\nTry again.';

  @override
  String get wallet_import_error_internet =>
      'Connection error.\nCheck your internet.';

  @override
  String get wallet_import_error_wallet_data => 'Error loading wallet data.';

  @override
  String get wallet_import_error_unknown => 'Unknown error';

  @override
  String get send_pix_appbar => 'Send PIX';

  @override
  String get send_pix_qr_title => 'Scan PIX QR Code';

  @override
  String get send_pix_empty_key_error => 'Type or scan a PIX key';

  @override
  String get send_pix_insert_key => 'Enter the PIX key';

  @override
  String get send_pix_paste_or_scan => 'Paste the key or scan the QR Code';

  @override
  String get send_pix_key_label => 'PIX Key';

  @override
  String get send_pix_key_hint => 'example@email.com or random key';

  @override
  String get send_pix_accepted_types => 'Accepted key types:';

  @override
  String get send_pix_type_email => 'Email';

  @override
  String get send_pix_type_phone => 'Phone';

  @override
  String get send_pix_type_cpf_cnpj => 'CPF/CNPJ';

  @override
  String get send_pix_type_random => 'Random key';

  @override
  String get send_pix_lightning_info =>
      'Instant payment using Lightning Network';

  @override
  String get swap_success_title => 'Swap Completed!';

  @override
  String get swap_success_body =>
      'Your transaction has been processed successfully. The balance will be available in your wallet shortly.';

  @override
  String get swap_success_dialog_txid_copied => 'TX ID copied!';

  @override
  String get send_pix_success_title => 'PIX Sent!';

  @override
  String get send_pix_success_body =>
      'Your PIX payment was completed successfully!';

  @override
  String get send_pix_success_value_sent => 'Amount sent';

  @override
  String get send_pix_success_recipient_info =>
      'The recipient can already verify the PIX has been received.';

  @override
  String get pix_deposit_status_pending_label => 'Pending Payment';

  @override
  String get pix_deposit_status_under_review_label => 'Bank review';

  @override
  String get pix_deposit_status_processing_1_2_label => 'Processing 1/2';

  @override
  String get pix_deposit_status_under_analysis_label => 'Under analysis';

  @override
  String get pix_deposit_status_processing_2_2_label => 'Processing 2/2';

  @override
  String get pix_deposit_status_finished_label => 'Sent';

  @override
  String get pix_deposit_status_expired_label => 'Expired';

  @override
  String get pix_deposit_status_refunded_label => 'Payment refunded';

  @override
  String get pix_deposit_status_med_label => 'Disputed - MED';

  @override
  String get pix_deposit_status_processing_refund_1_2_label => 'Refunding 1/2';

  @override
  String get pix_deposit_status_processing_refund_2_2_label => 'Refunding 2/2';

  @override
  String get pix_deposit_status_completed_label => 'Completed';

  @override
  String get pix_deposit_status_unknown_label => 'Manual review';

  @override
  String get pix_deposit_status_pending_plural => 'Pending Payments';

  @override
  String get pix_deposit_status_under_review_plural => 'Under Analysis';

  @override
  String get pix_deposit_status_processing_plural => 'Processing';

  @override
  String get pix_deposit_status_in_transit_plural => 'On the way';

  @override
  String get pix_deposit_status_under_analysis_plural => 'Under analysis';

  @override
  String get pix_deposit_status_finished_plural => 'Sent';

  @override
  String get pix_deposit_status_expired_plural => 'Expired';

  @override
  String get pix_deposit_status_refunded_plural => 'Refunded payments';

  @override
  String get pix_deposit_status_processing_refunds_plural =>
      'Processing refunds';

  @override
  String get pix_deposit_status_completed_plural => 'Completed';

  @override
  String get swap_error_processing =>
      'Wait a moment before making another swap. Your previous transaction is still being processed.';

  @override
  String swap_error_insufficient_balance_detailed(int available, int required) {
    return 'Insufficient balance for this swap. Available: $available sats. Required (sent + fees): $required sats.';
  }

  @override
  String get swap_error_no_active_quote => 'No active quote';

  @override
  String get swap_error_timeout =>
      'Timeout: The operation took too long. Try again.';

  @override
  String swap_error_unexpected(String error) {
    return 'Unexpected error: $error';
  }

  @override
  String get tx_refund_failed_title => 'Transaction Failed';

  @override
  String get tx_refund_failed_body =>
      'Your peg-in transaction could not be completed. By clicking OK, your bitcoins will be returned to your onchain wallet.';

  @override
  String get tx_refund_status_label => 'Status';

  @override
  String get tx_refund_status_failed => 'Failed';

  @override
  String get tx_refund_address_label => 'Bitcoin Address for Refund';

  @override
  String get tx_refund_address_hint => 'Enter the Bitcoin address';

  @override
  String get tx_refund_address_auto =>
      'Address generated automatically from your wallet';

  @override
  String get tx_refund_fees_fallback_warning =>
      'Using estimated fees (API temporarily unavailable)';

  @override
  String get tx_refund_screen_deprecated =>
      'This screen is deprecated. Please use the new refund flow.';

  @override
  String get tx_refund_dialog_title => 'Refund Started';

  @override
  String get tx_refund_dialog_body => 'Your refund was processed successfully!';

  @override
  String get tx_refund_dialog_txid_label => 'TX ID:';

  @override
  String get human_verif_success_title => 'Humanity Confirmed!';

  @override
  String get human_verif_success_body =>
      'Your identity was verified successfully. You can now use all the platform features.';

  @override
  String get human_verif_success_card_title => 'Verification complete';

  @override
  String get human_verif_success_card_body => 'You are a real person';

  @override
  String get human_verif_success_refund_info =>
      'Your PIX of R\$ 1.00 was refunded successfully.';

  @override
  String get pix_received_title => 'PIX Received!';

  @override
  String get pix_received_body => 'Your deposit is being processed';

  @override
  String get pix_deposit_id_label => 'Deposit ID';

  @override
  String get pix_main_tab_receive => 'Receive';

  @override
  String get pix_main_tab_send => 'Send';

  @override
  String get pix_info_title => 'About PIX';

  @override
  String get pix_info_processing_title => 'Processing time';

  @override
  String get pix_info_processing_body =>
      'PIX payments may be processed within up to 72 business hours after confirmation.';

  @override
  String get pix_info_lbtc_variation_title => 'Exchange variation (LBTC)';

  @override
  String get pix_info_lbtc_variation_body =>
      'When choosing to receive in LBTC, the final value may vary due to the exchange rate at the time of conversion. You may receive more or less than estimated.';

  @override
  String get pix_info_fees_title => 'About the fees';

  @override
  String get pix_info_fees_body =>
      'Fees vary according to the transaction amount. Smaller amounts have fixed fees, larger amounts have decreasing percentage fees.';

  @override
  String get pix_info_fees_button => 'See fee details';

  @override
  String get pix_limits_title => 'Payment Limits';

  @override
  String get pix_limits_intro => 'Understand how PIX payments work:';

  @override
  String get pix_limits_initial_label => 'Initial Limit';

  @override
  String get pix_limits_initial_value => 'R\$ 20.00';

  @override
  String get pix_limits_max_label => 'Maximum Limit';

  @override
  String get pix_limits_max_value => 'R\$ 3,000.00';

  @override
  String get pix_limits_explanation =>
      'As payments are made, your transaction limits may evolve up to the maximum limit of R\$ 3,000.00 per transaction, according to your trust score within the Mooze app.';

  @override
  String get pix_limits_trust_info =>
      'Check your trust levels in the menu, under \"Wallet level\".';

  @override
  String get pix_limits_increase_info =>
      'To increase your limits, frequent payment usage will gradually raise them.';

  @override
  String pix_limits_button_understood_countdown(int seconds) {
    return 'Got it ($seconds)';
  }

  @override
  String get swap_pending_dialog_title => 'Pending Transaction';

  @override
  String get refund_mock_simulation_error =>
      'Simulated error: Transaction broadcast failed';

  @override
  String get merchant_welcome_title => 'Welcome to Merchant Mode!';

  @override
  String get merchant_welcome_body =>
      'Here\'s your mini point-of-sale: register items, total amounts, and quickly charge your customers.';

  @override
  String get merchant_step_enter_value_title => 'Enter the desired amount';

  @override
  String get merchant_step_enter_value_body =>
      'Let\'s start by entering R\$ 20.00 using the keypad below.';

  @override
  String get merchant_step_add_value_title => 'Add amount';

  @override
  String get merchant_step_add_value_body =>
      'Now tap the green \'+\' button to add the amount to the items list.';

  @override
  String get merchant_step_items_tab_title => 'Items Tab';

  @override
  String get merchant_step_items_tab_body =>
      'Tap here to see your registered products and create new items.';

  @override
  String get merchant_step_create_product_title => 'Create product';

  @override
  String get merchant_step_create_product_body =>
      'Tap the \'+\' button to automatically create \'Produto 01\' priced at R\$ 21.00.';

  @override
  String get merchant_step_edit_delete_title => 'Edit and Delete products';

  @override
  String get merchant_step_edit_delete_body =>
      'Swipe this product from right to left to see the edit and delete options.';

  @override
  String get merchant_step_finalize_title => 'Finalize sale';

  @override
  String get merchant_step_finalize_body =>
      'Once you have items in the cart (minimum R\$ 20.00), tap here to finalize the sale.';

  @override
  String get merchant_step_clear_cart_title => 'Clear cart';

  @override
  String get merchant_step_clear_cart_body =>
      'If you\'d like to start over, tap here to clear all items from the cart.';

  @override
  String get merchant_tutorial_done_title => 'Tutorial Complete!';

  @override
  String get merchant_tutorial_done_body =>
      'You now know all the features of Merchant Mode. Ready to start?';

  @override
  String get merchant_default_product_name => 'Product 01';

  @override
  String get merchant_loose_value => 'Loose Amount';

  @override
  String get merchant_add_item_first =>
      'Add items to the cart before finalizing the sale';

  @override
  String get merchant_min_sale_value => 'Minimum sale value is R\$ 20.00';

  @override
  String merchant_add_product_error(String error) {
    return 'Failed to add product: $error';
  }

  @override
  String merchant_update_product_error(String error) {
    return 'Failed to update product: $error';
  }

  @override
  String merchant_remove_product_error(String error) {
    return 'Failed to remove product: $error';
  }

  @override
  String get merchant_tab_keypad => 'Keypad';

  @override
  String get merchant_tab_items => 'Items';

  @override
  String get merchant_load_products_error => 'Failed to load products';

  @override
  String get merchant_mode_header => 'Merchant Mode';

  @override
  String get merchant_clear_cart => 'Clear';

  @override
  String get merchant_no_products_title => 'No products yet';

  @override
  String get merchant_no_products_body =>
      'Add your first product\nby tapping the + button below';

  @override
  String get merchant_delete_item_title => 'Delete item';

  @override
  String merchant_delete_item_confirm(String name) {
    return 'Really delete \"$name\"?';
  }

  @override
  String get merchant_delete_action => 'Delete';

  @override
  String get merchant_add_product_title => 'Add Product';

  @override
  String get merchant_edit_product_title => 'Edit Product';

  @override
  String get merchant_product_name_label => 'Product name';

  @override
  String get merchant_product_name_hint => 'Enter the product name';

  @override
  String get merchant_price_label => 'Price';

  @override
  String get merchant_add_action => 'Add';

  @override
  String get merchant_min_sale_short => 'Min R\$ 20.00';

  @override
  String get merchant_finalize_sale_button => 'Complete Sale';

  @override
  String get merchant_charge_receive_title => 'Receive';

  @override
  String get merchant_charge_instruction_prefix =>
      'Choose the asset you want to receive on ';

  @override
  String get merchant_limit_daily => 'Daily limit';

  @override
  String get merchant_limit_per_transaction => 'Per transaction';

  @override
  String get merchant_limit_min => 'Minimum amount';

  @override
  String get merchant_limits_load_error => 'Failed to load limits';

  @override
  String get merchant_generate_qr => 'Generate QR Code';

  @override
  String merchant_validation_min_amount(String amount) {
    return 'Minimum amount: R\$ $amount';
  }

  @override
  String merchant_validation_max_per_tx(String amount) {
    return 'Per-transaction limit: R\$ $amount';
  }

  @override
  String get merchant_exit_ready => 'Ready to sell?';

  @override
  String get merchant_exit_new_payment => 'Receive new payment';

  @override
  String get merchant_exit_back_to_wallet => 'Want to access the wallet?';

  @override
  String get merchant_items_section => 'Items';

  @override
  String merchant_qty_prefix(int qty) {
    return 'x$qty';
  }

  @override
  String get common_error => 'Error';

  @override
  String get error_open_browser_link_copied =>
      'Couldn\'t open the browser. Link copied to clipboard.';

  @override
  String get pix_you_will_receive => 'You will receive';

  @override
  String pix_of_amount(String amount) {
    return 'of R\$ $amount';
  }

  @override
  String get pix_fees_applied => 'Fees applied';

  @override
  String get pix_fee_fixed_label => 'Fixed fee';

  @override
  String get pix_fee_fixed_mooze => 'Fixed fee (Mooze)';

  @override
  String get pix_fee_fixed_for_small_subtitle => 'For amounts up to R\$ 55';

  @override
  String get pix_fee_mooze => 'Mooze fee';

  @override
  String get pix_fee_processor => 'Processor fee';

  @override
  String get pix_fee_referral_discount => '15% discount already applied';

  @override
  String pix_fee_savings(String amount) {
    return 'You saved R\$ $amount with the referral code!';
  }

  @override
  String get pix_waiting_amount_title => 'Waiting for amount';

  @override
  String get pix_waiting_amount_body =>
      'Enter a valid amount to see\nthe transaction summary';

  @override
  String get pix_payment_screen_title => 'PIX Payment';

  @override
  String pix_qr_generation_error(String error) {
    return 'Failed to generate QR code: $error';
  }

  @override
  String get pix_payment_expired_body =>
      'The payment window has expired. Please generate a new PIX.';

  @override
  String get pix_fees_screen_header_title => 'Transparent Fees';

  @override
  String get pix_fees_screen_header_subtitle =>
      'Learn about our PIX deposit fees';

  @override
  String get pix_fees_screen_fixed_fee_title => 'Fixed Fee';

  @override
  String get pix_fees_screen_fixed_fee_subtitle =>
      'For deposits up to R\$ 55.00';

  @override
  String get pix_fees_screen_fixed_fee_breakdown =>
      'R\$ 1.00 Mooze + R\$ 1.00 Processor';

  @override
  String get pix_fees_screen_percentage_title => 'Percentage Fees';

  @override
  String get pix_fees_screen_percentage_subtitle =>
      'For deposits above R\$ 55.00';

  @override
  String get pix_fees_screen_tab_no_discount => 'No Discount';

  @override
  String get pix_fees_screen_tab_with_discount => 'With Discount';

  @override
  String pix_fees_screen_fee_range_before(String percentage) {
    return 'before $percentage%';
  }

  @override
  String pix_fees_screen_fee_range_label(String min, String max) {
    return 'R\$ $min to R\$ $max';
  }

  @override
  String get pix_fees_screen_referral_title => 'Referral Bonus';

  @override
  String get pix_fees_screen_referral_subtitle => 'Use a referral code';

  @override
  String get pix_fees_screen_referral_discount => '15% discount';

  @override
  String get pix_fees_screen_referral_disclaimer =>
      'All percentage fees are multiplied by 0.85';

  @override
  String get pix_fees_screen_examples_title => 'Practical Examples';

  @override
  String get pix_fees_screen_example_deposit => 'Deposit';

  @override
  String get pix_fees_screen_example_receive => 'You receive';

  @override
  String get pix_fees_screen_example_with_referral => 'With referral';

  @override
  String get pix_fees_screen_example_fee_label => 'Fee';

  @override
  String pix_fees_screen_fee_calculation_of(String percentage, String amount) {
    return '$percentage% of R\$ $amount';
  }

  @override
  String get pix_fees_screen_footer_title => 'Important Information';

  @override
  String get pix_fees_screen_footer_info_1 =>
      'The fixed fee of R\$ 2.00 applies only to deposits up to R\$ 55.00';

  @override
  String get pix_fees_screen_footer_info_2 =>
      'For amounts above R\$ 55.00, percentage fees apply';

  @override
  String get pix_fees_screen_footer_info_3 =>
      'The 15% referral discount applies only to percentage fees';

  @override
  String get pix_fees_screen_footer_info_4 =>
      'Fees are automatically deducted from the deposited amount';

  @override
  String get tx_detail_blockchain => 'Blockchain';

  @override
  String get tx_detail_swap_label => 'Asset swap';

  @override
  String get tx_detail_sent => 'Sent';

  @override
  String get tx_detail_expected => 'Expected';

  @override
  String get tx_type_redeposit => 'Auto-redeposit';

  @override
  String get tx_type_unknown => 'Unknown';

  @override
  String get tx_status_failed_processed => 'Refund Processed';

  @override
  String get tx_status_refundable_pending => 'Awaiting Refund';

  @override
  String get tx_status_confirmed_fem => 'Confirmed';

  @override
  String get tx_detail_confirmations => 'Confirmations';

  @override
  String get tx_detail_confirmations_full => '6+ confirmations';

  @override
  String tx_detail_confirmations_progress(int count) {
    return '$count/6 confirmations';
  }

  @override
  String get tx_detail_preimage_label => 'Preimage';

  @override
  String get tx_detail_preimage_pending =>
      'Preimage pending: once your transaction is confirmed, the preimage will appear here';

  @override
  String tx_detail_submarine_btc_to_lbtc(String from, String to) {
    return 'Network swap: You sent $from and will receive $to. Once the on-chain transaction is confirmed, funds will appear automatically on Liquid Network.';
  }

  @override
  String tx_detail_submarine_lbtc_to_btc(String from, String to) {
    return 'Network swap: You sent $from and will receive $to. Once processed, the transaction will be sent to the Bitcoin blockchain.';
  }

  @override
  String get tx_detail_submarine_generic =>
      'Network swap: cross-network transaction. Please wait for confirmation.';

  @override
  String get tx_detail_submarine_default =>
      'This transaction represents a network swap. Once confirmed, you\'ll receive the funds on the destination network.';

  @override
  String get tx_detail_request_refund => 'Request Refund';

  @override
  String get tx_detail_request_refund_subtitle => 'Recover your funds now';

  @override
  String get tx_detail_view_send => 'View Send';

  @override
  String get tx_detail_view_receive => 'View Receive';

  @override
  String get tx_detail_validate_payment => 'Validate Payment';

  @override
  String get tx_detail_verify_preimage => 'Verify preimage';

  @override
  String tx_detail_send_id_label(String chain) {
    return 'Send ID ($chain)';
  }

  @override
  String tx_detail_receive_id_label(String chain) {
    return 'Receive ID ($chain)';
  }

  @override
  String get main_settings_title => 'Menu';

  @override
  String get main_settings_section_merchant => 'MERCHANT';

  @override
  String get main_settings_section_transactions => 'TRANSACTIONS';

  @override
  String get main_settings_section_settings => 'SETTINGS';

  @override
  String get main_settings_section_wallet => 'WALLET';

  @override
  String get main_settings_section_external_links => 'EXTERNAL LINKS';

  @override
  String get main_settings_section_fees => 'FEES';

  @override
  String get main_settings_section_version => 'VERSION';

  @override
  String get main_settings_settings_label => 'Settings';

  @override
  String get main_settings_wallet_level => 'Wallet level';

  @override
  String get main_settings_pix_fees => 'PIX fees';

  @override
  String get main_settings_btc_services => 'Bitcoin services';

  @override
  String get main_settings_support => 'Support';

  @override
  String get onboarding_1_title => 'Your money, in your control';

  @override
  String get onboarding_1_body =>
      'Receive, send and manage Bitcoin with real privacy. A wallet built for people who value freedom.';

  @override
  String get onboarding_2_title => 'Security first';

  @override
  String get onboarding_2_body =>
      'Your key, your responsibility. Protect your wealth with strong encryption and local backups.';

  @override
  String get onboarding_3_title => 'Ready to get started?';

  @override
  String get onboarding_3_body =>
      'Create or import your wallet in seconds and take control of your Bitcoin.';

  @override
  String get first_access_create_wallet => 'Create Wallet';

  @override
  String get first_access_import_wallet => 'Import wallet';

  @override
  String get first_access_terms_prefix => 'I have read and agree to the ';

  @override
  String get first_access_terms_link => 'Terms and Conditions';

  @override
  String get level_my_levels => 'My Levels';

  @override
  String level_label(int n) {
    return 'Level $n';
  }

  @override
  String get level_current => 'Current level: ';

  @override
  String level_progress(int percent) {
    return 'Progress: $percent%';
  }

  @override
  String level_next(String name) {
    return 'Next: $name';
  }

  @override
  String get level_load_error => 'Failed to load level';

  @override
  String get level_load_retry => 'Please try again later.';

  @override
  String get level_user_label => 'User level';

  @override
  String get level_desc_bronze =>
      'Start by moving small amounts and unlock your first benefits.';

  @override
  String get level_desc_silver =>
      'The more you spend, the higher you go. Reach the Silver level.';

  @override
  String get level_desc_gold =>
      'Gold level with higher limits for bigger transactions.';

  @override
  String get level_desc_max =>
      'Max level with the highest limits and exclusive benefits.';

  @override
  String get wallet_levels_title => 'Wallet Levels';

  @override
  String get wallet_levels_api_down_title => 'API Unavailable';

  @override
  String get wallet_levels_api_down_body =>
      'Data may be out of date. Some features are temporarily unavailable.';

  @override
  String get wallet_levels_load_error_title => 'Failed to load wallet levels';

  @override
  String get wallet_levels_load_error_body =>
      'Check your internet connection and try again';

  @override
  String get wallet_levels_header_title => 'Grow with Mooze';

  @override
  String get wallet_levels_header_subtitle =>
      'The more you move, the more benefits and limits you unlock.';

  @override
  String get wallet_levels_quick_unlock_title => 'Unlock';

  @override
  String get wallet_levels_quick_unlock_subtitle => 'Increase limits';

  @override
  String get wallet_levels_quick_earn_title => 'Earn';

  @override
  String get wallet_levels_quick_earn_subtitle => 'Extra benefits';

  @override
  String get wallet_levels_quick_status_title => 'Status';

  @override
  String get wallet_levels_quick_status_subtitle => 'VIP recognition';

  @override
  String get wallet_levels_current_limits_title => 'Your Current Limits';

  @override
  String wallet_levels_current_level(String levelName) {
    return 'Level: $levelName';
  }

  @override
  String get wallet_levels_limit_per_transaction => 'Per transaction';

  @override
  String get wallet_levels_limit_daily => 'Daily limit';

  @override
  String get wallet_levels_limit_minimum => 'Minimum';

  @override
  String get wallet_levels_next_level_hint =>
      'Keep using to unlock the next level!';

  @override
  String wallet_levels_next_level_hint_named(String nextLevelName) {
    return 'Keep using to unlock the next level $nextLevelName!';
  }

  @override
  String get wallet_levels_load_limits_error_title => 'Failed to load limits';

  @override
  String get wallet_levels_load_limits_error_body =>
      'Try again later or contact support.';

  @override
  String get update_available_short => 'New update available';

  @override
  String get update_available_body => 'Update for improvements and fixes';

  @override
  String get update_available_button => 'UPDATE';

  @override
  String get update_dialog_title => 'Update Available';

  @override
  String get update_dialog_body => 'A new version of the app is available.';

  @override
  String get update_current_version => 'Current version:';

  @override
  String get update_new_version => 'New version:';

  @override
  String get update_dialog_recommend =>
      'We recommend updating to get the latest improvements and bug fixes.';

  @override
  String get update_later => 'LATER';

  @override
  String get info_overlay_dismiss_hint => 'Tap outside this area to close';

  @override
  String get auth_syncing => 'Syncing...';

  @override
  String get api_down_dialog_title => 'API Unavailable';

  @override
  String get api_down_dialog_body =>
      'The Mooze API is temporarily unavailable.';

  @override
  String get api_down_maintenance_title =>
      'The server may be under maintenance';

  @override
  String get api_down_warning_list =>
      '• PIX unavailable\n• Sync paused\n• Cached data in use';

  @override
  String get api_down_dialog_footer => 'Please try again in a few minutes.';

  @override
  String get api_down_indicator => 'API Unavailable';

  @override
  String get sync_error_indicator => 'Sync Error';

  @override
  String get sync_error_dialog_title => 'Synchronization Error';

  @override
  String get sync_error_dialog_body => 'Unable to synchronize Mooze services.';

  @override
  String get sync_error_warning => 'Operation not authorized';

  @override
  String get pin_create_title => 'Create PIN';

  @override
  String get pin_create_min_length => 'PIN must be at least 6 characters';

  @override
  String get pin_create_yours => 'Create your ';

  @override
  String get pin_create_intro_prefix => 'The ';

  @override
  String get pin_create_intro_suffix =>
      'will be used to authorize transactions and access your wallet.';

  @override
  String get currency_select_title => 'Select Currency';

  @override
  String get currency_display_label => 'Display currency';

  @override
  String get currency_display_description =>
      'Choose the currency used to display prices and values throughout the app.';

  @override
  String get currency_brl_name => 'Brazil (Brazilian Real)';

  @override
  String get currency_usd_name => 'United States (Dollar)';

  @override
  String get referral_save_title => 'Save with referrals!';

  @override
  String get referral_discount_badge => 'UP TO 15% OFF';

  @override
  String get referral_save_description =>
      'Enter your referral code and enjoy exclusive discounts on all platform fees.';

  @override
  String get referral_active_title => 'Active Discount';

  @override
  String referral_code_with_value(String code) {
    return 'Code: $code';
  }

  @override
  String get referral_savings_message => 'You\'re saving on every transaction!';

  @override
  String get referral_apply_code => 'Apply Code';

  @override
  String get referral_validating => 'Validating...';

  @override
  String get referral_api_down_warning =>
      'The API is unavailable. Referral codes cannot be applied at the moment.';

  @override
  String get referral_input_unavailable => 'Unavailable';

  @override
  String get referral_input_hint => 'E.g.: MOOZE123';

  @override
  String get referral_input_label => 'Referral Code';

  @override
  String get pix_fee_conversion_title => 'Conversion fees';

  @override
  String get pix_fee_discount_active_short => 'Discount active';

  @override
  String get pix_fee_tier1_range => 'R\$ 20 to R\$ 55';

  @override
  String get pix_fee_tier1_value => 'R\$ 2.00 flat *';

  @override
  String get pix_fee_tier2_range => 'R\$ 55 to R\$ 499';

  @override
  String get pix_fee_tier2_value => '3.5%';

  @override
  String get pix_fee_tier3_range => 'R\$ 500 to R\$ 3,000';

  @override
  String get pix_fee_tier3_value => '3% *';

  @override
  String get pix_fee_footnote_discount =>
      '* 15% off for users with a referral code.';

  @override
  String get pix_fee_footnote_network =>
      '* Network fees/variable spread paid by the user.';

  @override
  String get pix_fee_discount_chip_15 => '−15%';

  @override
  String get support_user_code_load_error_inline => 'Failed to load code';

  @override
  String get support_user_code_unique => 'Unique code';

  @override
  String get wallet_send_appbar_title => 'Send assets';

  @override
  String get wallet_send_instruction_prefix =>
      'Choose the asset you want to send on ';

  @override
  String get wallet_send_address_label => 'Destination address';

  @override
  String get wallet_send_address_hint => 'Type or paste the address';

  @override
  String get wallet_send_address_scan_qr => 'Scan QR Code';

  @override
  String get wallet_send_address_paste => 'Paste';

  @override
  String get wallet_send_address_clear => 'Clear';

  @override
  String get wallet_send_address_paste_empty => 'Clipboard is empty';

  @override
  String get wallet_send_select_asset => 'Select an asset';

  @override
  String get wallet_send_available_balance => 'Available balance';

  @override
  String get wallet_send_balance_unavailable => 'Unavailable';

  @override
  String get wallet_send_balance_load_error => 'Failed to load';

  @override
  String get wallet_send_amount_label => 'Amount';

  @override
  String get wallet_send_amount_hint => 'Enter the amount';

  @override
  String get wallet_send_amount_in_sats => 'Amount in Satoshis:';

  @override
  String get wallet_send_amount_valid => 'Valid amount!';

  @override
  String get wallet_send_conversion_asset => 'Asset';

  @override
  String get wallet_send_conversion_sats => 'Satoshis';

  @override
  String get wallet_send_conversion_fiat => 'Fiat';

  @override
  String get wallet_send_drain_title => 'Total Funds Sending';

  @override
  String wallet_send_drain_body(String asset) {
    return 'You selected to send all funds of asset $asset.';
  }

  @override
  String get wallet_send_drain_ready =>
      'Ready to review — fees will be deducted from the total amount';

  @override
  String get wallet_send_fee_estimated => 'Estimated fee';

  @override
  String get wallet_send_fee_calculating => 'Calculating fee...';

  @override
  String get wallet_send_fee_calc_error => 'Failed to calculate fee';

  @override
  String get wallet_send_fee_free => 'Free';

  @override
  String get wallet_send_lbtc_disclaimer_title => 'How sending assets works';

  @override
  String get wallet_send_lbtc_disclaimer_body =>
      'To send assets (Bitcoin L2, DePIX, or USDT), you need to keep a Bitcoin L2 balance in your wallet.';

  @override
  String get wallet_send_lbtc_network_fees_title => 'Network fees';

  @override
  String get wallet_send_lbtc_network_fees_desc =>
      'The Bitcoin L2 balance is used to pay Liquid network miners\' fees.';

  @override
  String get wallet_send_lbtc_obtain_title => 'How to get Bitcoin L2';

  @override
  String get wallet_send_lbtc_obtain_desc_disclaimer =>
      'Use the SWAP feature or receive Bitcoin via Lightning or Liquid.';

  @override
  String get wallet_send_lbtc_obtain_desc_info =>
      'Use the SWAP feature to convert Bitcoin (Lightning or on-chain) into Bitcoin L2 directly in the app.';

  @override
  String get wallet_send_lbtc_disclaimer_tip =>
      'Keep a small Bitcoin L2 balance to ensure your transactions are processed.';

  @override
  String wallet_send_lbtc_disclaimer_understood_countdown(int seconds) {
    return 'Got it ($seconds)';
  }

  @override
  String get wallet_send_lbtc_info_title => 'Fee information';

  @override
  String get wallet_send_lbtc_info_step1_title => 'Bitcoin L2 for network fees';

  @override
  String get wallet_send_lbtc_info_step1_desc =>
      'To send DePIX, USDT or any Liquid network asset, you need Bitcoin L2 (Liquid Bitcoin) in your wallet. It is used to pay network miners.';

  @override
  String get wallet_send_lbtc_info_step3_title =>
      'Receive via Lightning or Liquid';

  @override
  String get wallet_send_lbtc_info_step3_desc =>
      'Receive Bitcoin via the Lightning Network or Liquid to get Bitcoin L2 in your wallet without using SWAP.';

  @override
  String get wallet_send_lbtc_go_swap => 'Go to SWAP';

  @override
  String get wallet_send_lbtc_insufficient_title => 'Insufficient Bitcoin L2';

  @override
  String wallet_send_lbtc_insufficient_body(String asset) {
    return 'You need Bitcoin L2 to pay miner fees when sending $asset:';
  }

  @override
  String get wallet_send_lbtc_insufficient_swap_prefix => 'Use the ';

  @override
  String get wallet_send_lbtc_insufficient_swap_suffix =>
      ' feature to get Bitcoin L2';

  @override
  String get wallet_send_lbtc_insufficient_lightning =>
      'Receive Bitcoin via Lightning or Liquid to get Bitcoin L2';

  @override
  String get wallet_send_lbtc_banner_title => 'Bitcoin L2 required for fees';

  @override
  String get wallet_send_lbtc_banner_body =>
      'To send DePIX or USDT, you need Bitcoin L2 in your wallet to pay network fees.';

  @override
  String get wallet_send_lbtc_banner_action => 'Get via SWAP';

  @override
  String get wallet_send_network_unidentified => 'Network not identified';

  @override
  String get wallet_send_network_bitcoin => 'Bitcoin On-chain';

  @override
  String get wallet_send_network_lightning => 'Lightning Network';

  @override
  String get wallet_send_network_liquid => 'Liquid Network';

  @override
  String get wallet_send_network_unknown => 'Unknown network';

  @override
  String get wallet_send_predefined_label => 'Predefined amount';

  @override
  String get wallet_send_predefined_body =>
      'This invoice/address has a predefined amount. The amount field has been automatically filled.';

  @override
  String wallet_send_predefined_label_value(String label) {
    return 'Label: $label';
  }

  @override
  String wallet_send_predefined_message_value(String message) {
    return 'Message: $message';
  }

  @override
  String get wallet_send_review_preparing => 'Preparing...';

  @override
  String get wallet_send_review_drain => 'Review Total Send';

  @override
  String get wallet_send_review_transaction => 'Review Transaction';

  @override
  String wallet_send_review_lbtc_insufficient_error(String asset) {
    return 'Insufficient Bitcoin L2 balance for fees.\n\nTo send $asset, you need Bitcoin L2 to pay network miners. Use the SWAP feature or receive Bitcoin via Lightning or Liquid.';
  }

  @override
  String get wallet_send_review_insufficient_error =>
      'Insufficient balance to send.\n\nMake sure you have enough to cover the amount and network fees.';

  @override
  String get wallet_send_review_prepare_error =>
      'Could not prepare the transaction. Please try again.';

  @override
  String get wallet_send_loading_conversions => 'Loading conversions...';

  @override
  String get wallet_send_equivalent_conversions => 'Equivalent conversions:';

  @override
  String get wallet_send_satoshis_label => 'Satoshis:';

  @override
  String get wallet_send_validation_attention => 'Attention';

  @override
  String get wallet_send_validation_help =>
      'Validations are checked automatically as you type.';

  @override
  String get wallet_send_error_address_required => 'Address is required';

  @override
  String get wallet_send_error_address_invalid =>
      'Invalid or unsupported address';

  @override
  String wallet_send_error_asset_liquid_only(String asset) {
    return '$asset can only be sent over the Liquid or Lightning network';
  }

  @override
  String get wallet_send_error_liquid_only =>
      'To send Liquid assets use Bitcoin L2, Depix or USDT';

  @override
  String get wallet_send_error_amount_positive =>
      'Amount must be greater than zero';

  @override
  String get wallet_send_error_balance_check =>
      'Failed to check available balance';

  @override
  String get wallet_send_error_insufficient_balance => 'Insufficient balance';

  @override
  String get wallet_send_error_address_unrecognized =>
      'Invalid or unrecognized address';

  @override
  String get wallet_send_error_pending_payments =>
      'You can\'t send the full balance while there are pending payments. Wait for the payments to complete and try again.';

  @override
  String wallet_send_error_validation_failed(String error) {
    return 'Could not validate the transaction: $error';
  }

  @override
  String get wallet_send_error_amount_exceeds_balance =>
      'The amount entered is greater than the available balance';

  @override
  String wallet_send_error_insufficient_with_fees(
    String total,
    String amount,
    String fee,
    String satText,
    String balance,
  ) {
    return 'Insufficient balance. You need $total sats ($amount + $fee $satText fee), but only $balance sats are available';
  }

  @override
  String wallet_send_error_fee_calc_failed(String error) {
    return 'Could not calculate fees: $error';
  }

  @override
  String wallet_send_error_validate_balance_fees(String error) {
    return 'Error validating balance and fees: $error';
  }

  @override
  String wallet_send_error_min_lightning(int amount) {
    return 'Minimum Lightning amount is $amount sats';
  }

  @override
  String wallet_send_error_max_lightning(int amount) {
    return 'Maximum Lightning amount is $amount sats';
  }

  @override
  String get wallet_send_error_min_usdt => 'Minimum USDT amount is 0.5 USDT';

  @override
  String get wallet_send_error_min_depix => 'Minimum Depix amount is 1.0 Depix';

  @override
  String wallet_send_error_validate_limits(String error) {
    return 'Error validating send limits: $error';
  }

  @override
  String get wallet_action_receive => 'RECEIVE';

  @override
  String get wallet_action_send => 'SEND';

  @override
  String get wallet_assets_section_title => 'Assets';

  @override
  String get wallet_transactions_section_title => 'Transactions';

  @override
  String get wallet_section_see_more => 'See more';

  @override
  String wallet_tx_sent(String ticker) {
    return 'Sent $ticker';
  }

  @override
  String wallet_tx_received(String ticker) {
    return 'Received $ticker';
  }

  @override
  String wallet_tx_swap_pair(String from, String to) {
    return 'Swap: $from to $to';
  }

  @override
  String wallet_tx_redeposit(String ticker) {
    return 'Self-deposited $ticker';
  }

  @override
  String get wallet_tx_unknown => 'Unknown transaction type';

  @override
  String get wallet_tx_load_error_title => 'Unable to load transactions';

  @override
  String get wallet_tx_load_error_retry => 'Please try again later';

  @override
  String get wallet_tx_empty_title => 'No transactions found';

  @override
  String get wallet_tx_empty_body =>
      'Your transaction history will appear here as soon as you make a transfer.';

  @override
  String get wallet_all_assets_title => 'All Assets';

  @override
  String get wallet_all_assets_subtitle =>
      'Track quotes for all available assets';

  @override
  String get wallet_all_assets_favorite_hint => 'Tap the icon to favorite — ';

  @override
  String wallet_all_assets_favorite_count(int count) {
    return '$count/2 selected';
  }

  @override
  String wallet_asset_chart_title(String period) {
    return 'Chart - $period';
  }

  @override
  String get wallet_asset_chart_unavailable => 'Chart Unavailable';

  @override
  String get wallet_asset_chart_load_error => 'Could not load the chart';

  @override
  String get wallet_asset_stats_high => 'High';

  @override
  String get wallet_asset_stats_low => 'Low';

  @override
  String get wallet_asset_stats_current => 'Current';

  @override
  String get wallet_holding_appbar_title => 'Assets';

  @override
  String get wallet_holding_action_send => 'Send';

  @override
  String get wallet_holding_action_receive => 'Receive';

  @override
  String get wallet_holding_action_swap => 'Swap';

  @override
  String wallet_holding_unexpected_error(String error) {
    return 'Unexpected error: $error';
  }

  @override
  String get wallet_holding_empty => 'No assets found';

  @override
  String get wallet_holding_no_balance => 'No balance';

  @override
  String get wallet_holding_load_error_title => 'Failed to load assets';

  @override
  String get wallet_holding_pending_payments_title => 'Payments under review';

  @override
  String wallet_holding_pending_payments_total(String currency, String value) {
    return 'Total: $currency $value';
  }

  @override
  String get wallet_holding_calculating => 'Calculating...';

  @override
  String get pix_receive_appbar_title => 'Receive PIX';

  @override
  String get pix_receive_api_unavailable =>
      'PIX transactions can\'t be processed right now. Please try again later.';

  @override
  String get pix_receive_info_title => 'PIX Information';

  @override
  String get pix_receive_info_step1_title => 'Processing time';

  @override
  String get pix_receive_info_step1_desc =>
      'PIX payments may take up to 72 business hours to process after confirmation.';

  @override
  String get pix_receive_info_step2_title => 'Exchange variation (LBTC)';

  @override
  String get pix_receive_info_step2_desc =>
      'When you choose to receive in LBTC, the final amount may vary due to the conversion rate at the time. You may receive more or less than the calculated amount.';

  @override
  String get pix_receive_info_step3_title => 'About fees';

  @override
  String get pix_receive_info_step3_desc =>
      'Fees vary based on the transaction amount. Smaller amounts have flat fees, larger amounts have decreasing percentage fees.';

  @override
  String get pix_receive_info_see_fees => 'See fee details';

  @override
  String get pix_receive_instruction_prefix =>
      'Choose the asset you want to receive on ';

  @override
  String get pix_receive_tip_more_payments =>
      'Make more payments to unlock new limits';

  @override
  String get pix_receive_advance => 'Continue';

  @override
  String get pix_receive_my_level => 'My Level';

  @override
  String get pix_receive_you_add => 'You add';

  @override
  String get pix_receive_my_limits => 'My limits';

  @override
  String get pix_receive_see_levels => 'View levels';

  @override
  String get pix_receive_daily_limit => 'Daily limit';

  @override
  String get pix_receive_per_transaction => 'Per transaction';

  @override
  String get pix_receive_min => 'Min.';

  @override
  String get pix_receive_limits_error => 'Failed to load limits';

  @override
  String pix_receive_details(String detail) {
    return 'Details: $detail';
  }

  @override
  String get pix_receive_validation_invalid_amount => 'Enter a valid amount';

  @override
  String pix_receive_validation_below_min(String amount) {
    return 'Minimum amount: R\$ $amount';
  }

  @override
  String pix_receive_validation_above_transaction(String amount) {
    return 'Per-transaction limit: R\$ $amount';
  }

  @override
  String get pix_tip_consecutive_daily =>
      'Max 3 consecutive PIX from the same holder in 30 min · Limit of R\$ 5,000/day per holder.';

  @override
  String get pix_tip_outside_rules_returned =>
      'Payments outside the rules are automatically returned to the sender.';

  @override
  String get pix_tip_processing_avg_time =>
      'Processed in 5–25 min. PIX with banking risk signals may take 3–7 days (refundable).';

  @override
  String get pix_payment_appbar_title => 'PIX Payment';

  @override
  String pix_payment_qr_error(String error) {
    return 'Failed to generate QR code: $error';
  }

  @override
  String get pix_payment_time_expired_body =>
      'The payment window has expired. Please generate a new PIX.';

  @override
  String get tx_filter_pix_title => 'PIX Filters';

  @override
  String get tx_filter_deposit_status => 'Deposit status';

  @override
  String get tx_filter_most_recent => 'Most Recent';

  @override
  String get tx_filter_oldest => 'Oldest';

  @override
  String get tx_filter_select_period => 'Select Period';

  @override
  String get tx_filter_select => 'Select';

  @override
  String get tx_filter_to => 'to';

  @override
  String get tx_filter_start_after_end_error =>
      'The start date cannot be after the end date.';

  @override
  String get tx_history_refresh_debug => 'Refresh (Debug)';

  @override
  String tx_history_filters_active(String description) {
    return 'Active filters - $description';
  }

  @override
  String get tx_history_clear => 'Clear';

  @override
  String tx_history_filter_count(int filtered, int total, String description) {
    return '$filtered of $total transactions - $description';
  }

  @override
  String get tx_history_filter_refunds => 'Refunds';

  @override
  String tx_history_filter_from(String date) {
    return 'From $date';
  }

  @override
  String tx_history_filter_until(String date) {
    return 'Until $date';
  }

  @override
  String get tx_history_filter_oldest_first => 'Oldest first';

  @override
  String get tx_history_filter_default => 'All';

  @override
  String get pix_filter_status_pending => 'Pending Payment';

  @override
  String get pix_filter_status_processing => 'Processing 1/2';

  @override
  String get pix_filter_status_finished => 'Sent';

  @override
  String get pix_filter_status_expired => 'Expired';

  @override
  String get address_explorer_title => 'Addresses & UTXOs';

  @override
  String get address_explorer_search_hint => 'Search address…';

  @override
  String get address_explorer_search_match_onchain =>
      'Address found in On-chain.';

  @override
  String get address_explorer_search_match_liquid => 'Address found in Liquid.';

  @override
  String address_explorer_search_match_at_index(String chain, int index) {
    return '$chain · index $index';
  }

  @override
  String get address_explorer_search_no_match =>
      'Address does not belong to your wallet.';

  @override
  String get address_explorer_tab_onchain => 'On-chain';

  @override
  String get address_explorer_tab_liquid => 'Liquid';

  @override
  String address_explorer_load_more(int count) {
    return 'Load $count more addresses';
  }

  @override
  String get address_explorer_loading_more => 'Loading…';

  @override
  String get address_explorer_loading => 'Loading addresses…';

  @override
  String get address_explorer_empty => 'No addresses found.';

  @override
  String address_explorer_load_error(String error) {
    return 'Failed to load addresses: $error';
  }

  @override
  String get address_explorer_address_copied => 'Address copied';

  @override
  String get address_explorer_status_used => 'USED';

  @override
  String get address_explorer_status_unused => 'UNUSED';

  @override
  String address_explorer_utxo_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count UTXOs',
      one: '1 UTXO',
      zero: 'no UTXOs',
    );
    return '$_temp0';
  }

  @override
  String get address_explorer_utxos_section => 'UTXOs';

  @override
  String get address_explorer_utxos_tap_to_expand => 'tap to expand';

  @override
  String get address_explorer_utxos_tap_to_collapse => 'tap to collapse';

  @override
  String address_explorer_summary(int total, int used, int utxos) {
    return '$total addresses · $used used · $utxos UTXOs';
  }

  @override
  String address_explorer_summary_addresses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count addresses',
      one: '1 address',
    );
    return '$_temp0';
  }

  @override
  String address_explorer_summary_status(int used, int unused) {
    return '$used used • $unused unused';
  }

  @override
  String address_explorer_summary_utxos_total(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count UTXOs',
      one: '1 UTXO',
      zero: 'no UTXOs',
    );
    return '$_temp0';
  }

  @override
  String address_explorer_total_received(String amount) {
    return 'Received: $amount';
  }

  @override
  String get address_explorer_filter_all => 'All';

  @override
  String get address_explorer_filter_used => 'Used';

  @override
  String get address_explorer_filter_unused => 'Unused';

  @override
  String get address_explorer_filter_with_utxos => 'Has UTXOs';

  @override
  String get address_explorer_filter_empty =>
      'No addresses match the current filter.';

  @override
  String get address_explorer_full_address_title => 'Address';

  @override
  String get address_explorer_full_address_copy => 'Copy address';

  @override
  String get address_explorer_close => 'Close';

  @override
  String get address_ownership_title => 'Verify address';

  @override
  String get address_ownership_description =>
      'Paste an address to verify ownership';

  @override
  String get address_ownership_subtitle => 'Supports Bitcoin and Liquid';

  @override
  String get address_ownership_input_hint => 'bc1q… / lq1… / 1A1z…';

  @override
  String get address_ownership_paste_tooltip => 'Paste';

  @override
  String get address_ownership_clear_tooltip => 'Clear';

  @override
  String get address_ownership_verify => 'Verify';

  @override
  String get address_ownership_verifying => 'Verifying…';

  @override
  String get address_ownership_clear => 'Clear';

  @override
  String get address_ownership_paste_feedback => 'Pasted from clipboard';

  @override
  String get address_ownership_clear_feedback => 'Cleared';

  @override
  String address_ownership_detected(String chain) {
    return 'Detected: $chain';
  }

  @override
  String get address_ownership_invalid_format => 'Invalid address format';

  @override
  String get address_ownership_owned_title => 'Your address';

  @override
  String get address_ownership_not_owned_title => 'Not your address';

  @override
  String get address_ownership_field_type => 'Type';

  @override
  String get address_ownership_field_utxos => 'UTXOs';

  @override
  String get address_ownership_field_used => 'Used';

  @override
  String get address_ownership_yes => 'Yes';

  @override
  String get address_ownership_no => 'No';

  @override
  String get address_ownership_chain_bitcoin => 'Bitcoin';

  @override
  String get address_ownership_chain_liquid => 'Liquid';

  @override
  String address_ownership_index_label(int index) {
    return 'index $index';
  }

  @override
  String get address_ownership_status_used => 'used';

  @override
  String get address_ownership_status_unused => 'unused';

  @override
  String get settings_section_addresses => 'ADDRESSES';

  @override
  String get settings_verify_address => 'Verify address';

  @override
  String get settings_address_explorer => 'Addresses & UTXOs';
}
