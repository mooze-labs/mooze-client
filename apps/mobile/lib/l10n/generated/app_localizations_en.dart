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
  String get nav_home => 'Home';

  @override
  String get nav_menu => 'Menu';

  @override
  String get nav_pix => 'Pix';

  @override
  String get onboarding_get_started => 'Get started';

  @override
  String get pix_send_confirm_title => 'Confirm payment';

  @override
  String get pix_send_error_title => 'Payment error';

  @override
  String get pix_send_processing_payment => 'Processing payment...';

  @override
  String get common_taking_longer =>
      'This is taking longer than usual. Check your connection.';

  @override
  String get error_something_went_wrong => 'Something went wrong. Try again.';

  @override
  String get send_clipboard_address_found => 'Copied address detected';

  @override
  String get send_clipboard_use => 'Use';

  @override
  String get pix_clipboard_key_found => 'Copied PIX key detected';

  @override
  String get deeplink_invalid_payment => 'Invalid payment link';

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
  String get settings_security => 'Security';

  @override
  String get security_session_lock_title => 'Use Biometric/PIN Lock';

  @override
  String get security_session_lock_subtitle =>
      'Require authentication after a period of inactivity';

  @override
  String get security_privacy_shield_title => 'Protect App Switcher';

  @override
  String get security_privacy_shield_subtitle =>
      'Hide wallet content in the app switcher';

  @override
  String get security_lock_after => 'Lock After';

  @override
  String get security_timeout_immediate => 'Immediately';

  @override
  String get security_timeout_15s => '15 seconds';

  @override
  String get security_timeout_30s => '30 seconds';

  @override
  String get security_timeout_1m => '1 minute';

  @override
  String get security_timeout_5m => '5 minutes';

  @override
  String get privacy_shield_locked_title => 'Application Locked';

  @override
  String get privacy_shield_locked_subtitle => 'Authenticate to continue';

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
      'Format: scheme://host:port. Use ssl:// for encrypted connections. Leave empty to use the default node.';

  @override
  String get node_config_liquid_label => 'Liquid Network endpoint';

  @override
  String get node_config_liquid_hint => 'your-node.tld:50002';

  @override
  String get node_config_liquid_helper =>
      'Format: host:port. LWK negotiates TLS automatically. Leave empty to use the default node.';

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
  String get node_config_at_least_one =>
      'Set at least one endpoint, or switch to default mode.';

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
    return '$error';
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
  String get screenshot_blocked_title => 'Screenshot Blocked';

  @override
  String get screenshot_blocked_message =>
      'This screen contains sensitive wallet information and cannot be captured.';

  @override
  String get screenshot_blocked_warning =>
      'For your security, never take screenshots of your recovery phrase (seed phrase). Anyone with access to your recovery phrase can gain full control of your wallet.';

  @override
  String get screenshot_blocked_acknowledge => 'I understand';

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
  String get pin_use_pin => 'Use PIN';

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
  String get terms_last_updated => 'Last updated: 04/18/2026';

  @override
  String get terms_privacy_policy_link => 'View Privacy Policy';

  @override
  String get terms_preamble => 'Preamble — Passive Offer and Self-Access';

  @override
  String get terms_preamble_body =>
      'These Terms of Use govern the relationship between Mooze Labs LLC and the User who, on the User\'s own and sole initiative, obtains, installs and uses the Mooze Wallet application.\n\nMaking the App available on global distribution platforms (Google Play Store, Apple App Store, similar stores or a public APK repository) constitutes the mere passive placement of software. Any use of the App results from the User\'s active search and voluntary interest, and the User represents that the User accesses Mooze by personal decision.';

  @override
  String get terms_section_1 => '1. Acceptance of Terms';

  @override
  String get terms_section_2 => '2. Legal Nature of Mooze';

  @override
  String get terms_section_3 => '3. Definitions';

  @override
  String get terms_section_4 => '4. Description of the Services';

  @override
  String get terms_section_5 => '5. Non-Custodial Model and Self-Custody';

  @override
  String get terms_section_6 => '6. User Responsibilities';

  @override
  String get terms_section_7 => '7. Fees and Service Charges';

  @override
  String get terms_section_8 =>
      '8. Price References and No Investment Recommendation';

  @override
  String get terms_section_9 => '9. Limitation of Liability';

  @override
  String get terms_section_10 => '10. Anti-Fraud and Security Policy';

  @override
  String get terms_section_11 =>
      '11. Monitoring, Fraud Prevention and Suspension of Services';

  @override
  String get terms_section_12 =>
      '12. Legal Obligations of the User and Jurisdictional Restrictions';

  @override
  String get terms_section_13 => '13. Jurisdiction and Governing Law';

  @override
  String get terms_section_14 => '14. Dispute Resolution';

  @override
  String get terms_section_15 => '15. Intellectual Property';

  @override
  String get terms_section_16 => '16. General Provisions';

  @override
  String get terms_section_17 => '17. Minimum Age';

  @override
  String get terms_section_18 => '18. Changes to the Terms';

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
  String get privacy_section_4 =>
      '4. Data Processing in Operations with a Fiat Reference';

  @override
  String get privacy_section_5 => '5. Data Sharing';

  @override
  String get privacy_section_6 => '6. Communication with Mooze';

  @override
  String get privacy_section_7 => '7. Security';

  @override
  String get privacy_section_8 => '8. Data Retention';

  @override
  String get privacy_section_9 =>
      '9. User Rights (LGPD and Equivalent Jurisdictions)';

  @override
  String get privacy_section_10 =>
      '10. Data Jurisdiction and International Transfers';

  @override
  String get privacy_section_11 => '11. Changes';

  @override
  String get privacy_section_12 => '12. Contact';

  @override
  String get terms_section_1_body =>
      '1.1. By accessing, installing or using the Mooze Wallet application (the \"App\"), the User represents that the User has read, understood and fully accepted these Terms of Use (the \"Terms\") and the accompanying Privacy Policy.\n\n1.2. Use of the App constitutes express, informed, conscious and irrevocable acceptance of all provisions contained in this document.\n\n1.3. If the User does not agree with any provision of these Terms, the User must immediately cease using the App, uninstall it from the User\'s devices and refrain from any interaction with the Services. Continued use of the App after the publication of these Terms or of subsequently updated versions constitutes full agreement with the terms then in effect.\n\n1.4. These Terms constitute a binding international contract between the User and Mooze Labs LLC, governed exclusively by the laws of the Republic of the Marshall Islands (\"RMI\"), within the limits set forth in Section 13.\n\n1.5. The User acknowledges that the User obtained the App through freely available and known information, by the User\'s own final decision, and is the sole capable responsible party.';

  @override
  String get terms_section_2_body =>
      '2.1. Mooze Labs LLC (\"Mooze\") is a limited liability company duly organized under the Associations Law of the Republic of the Marshall Islands (Title 52, Marshall Islands Revised Code), RMI.\n\n2.2. Mooze acts exclusively as a provider of software services (Software-as-a-Service). Its activity consists of the development, maintenance and provision of technology infrastructure for the operation of self-custodial digital wallets on the Bitcoin, Liquid Network and Lightning Network networks, as well as the programmatic orchestration of software calls (API calls) between the User\'s device and third-party infrastructures.\n\n2.3. Mooze IS NOT, does not operate as, does not hold itself out as, and shall not be construed as:\n(a) a brokerage, exchange, trading venue, trading platform, market maker or liquidity platform for digital assets;\n(b) a financial institution, payment institution, credit company, credit cooperative or equivalent entity;\n(c) a foreign exchange service provider, foreign exchange house or foreign exchange operator;\n(d) a money transmitter or money services business (MSB);\n(e) a Virtual Asset Service Provider (VASP) within the meaning of the Banking (Amendment) Act, 2020 — P.L. 2020-61, Section 102(ii), of the Republic of the Marshall Islands;\n(f) a virtual asset service provider within the meaning of Law No. 14,478/2022 (Brazilian Legal Framework for Crypto-assets) or CVM Resolution No. 175;\n(g) an entity subject to the obligations of FATF Recommendation 15 as a VASP;\n(h) a custodian, depositary, bailee or administrator of digital assets or of third-party financial resources;\n(i) an investment adviser, provider of financial advice or securities analyst.\n\n2.4. Mooze does not exercise custody, possession, discretionary control over balances on behalf of users, ownership, dominion, or the right to use, enjoy or dispose of any digital assets or monetary amounts belonging to the user. The transitory, programmatic and automated processing of digital assets by Mooze\'s infrastructure during the performance of the Services constitutes technical routing, analogous to the processing of data packets by network equipment (a router), without Mooze acquiring, at any time or in any form, any right, interest or beneficial ownership.\n\n2.5. Mooze does not, under any circumstances, carry out: (i) exchange operations; (ii) conversion between fiat currencies; (iii) conversion between fiat currency and a digital asset, or between digital assets, executed on behalf of the User and in the User\'s ownership; (iv) financial intermediation; (v) transmission of value on behalf of third parties. Any and all operations involving fiat currency (Brazilian reais) are processed entirely by partners regulated by the Central Bank of Brazil, as described in Section 4. Any and all conversions between digital assets are executed directly by the User, through decentralized peer-to-peer protocols (atomic swap), without Mooze acting as a counterparty.\n\n2.6. Under the Banking (Amendment) Act, 2020 (P.L. 2020-61) of the Republic of the Marshall Islands, Chapter 1, Section 102(ii), the definition of VASP (Virtual Asset Service Provider) covers exclusively natural or legal persons that, as a business, conduct one or more of the following activities \"for or on behalf of another natural or legal person\": (i) exchange between virtual assets and fiat currencies; (ii) exchange between one or more forms of virtual assets; (iii) transfer of virtual assets; (iv) safekeeping and/or administration of virtual assets or of instruments enabling control over virtual assets; (v) participation in and provision of financial services related to an issuer\'s offer and/or sale of a virtual asset. Mooze does not conduct any of activities (i) through (v) \"for or on behalf of\" third parties, because: (a) it operates exclusively as a non-custodial software provider; (b) it does not hold, and has no technical capacity to hold, the User\'s private keys; (c) it does not execute conversions on behalf of the User, and limits itself to orchestrating programmatic calls between the User and third-party providers; (d) it does not participate as a counterparty in any transfer or atomic swap.\n\n2.7. Mooze is not subject to the AML Regulations 2002 of the Republic of the Marshall Islands (as amended) as a VASP, because it does not meet the legal criterion of providing services \"for or on behalf of\" third parties. Compliance with anti-money laundering (AML), know-your-customer (KYC) and \"Travel Rule\" obligations relating to transfers above USD 1,000.00 rests exclusively with the Regulated Partners and the other VASPs involved in the operational flow described in Section 4.\n\n2.8. Mooze is an official member of the Liquid Federation (Blockstream), with an active PAK Entry, attesting to its participation in the Liquid Network ecosystem as a technology entity. Participation in the Liquid Federation constitutes a technical and operational relationship, and not a corporate, agency or joint and several liability relationship with Blockstream or with the other members of the federation.';

  @override
  String get terms_section_3_body =>
      'For purposes of these Terms, the following terms have the meanings indicated:\n\n3.1. \"App\" or \"Mooze Wallet\": self-custodial digital wallet software developed by Mooze, made available for iOS and Android mobile devices (through stores such as Google Play Store, Apple App Store and similar stores, and also through an APK file for direct distribution).\n\n3.2. \"User\": a natural person over 18 (eighteen) years of age with full legal capacity who installs, accesses or uses the App on the User\'s own initiative.\n\n3.3. \"Self-Custody\": a model in which the User holds exclusive technical control over the User\'s private keys and seed phrases, without Mooze or any third party having access to, a copy of, knowledge of or the technical capacity to reconstruct such information.\n\n3.4. \"Seed Phrase\": a sequence of 12 (twelve) or 24 (twenty-four) words, generated locally on the User\'s device in accordance with the open BIP39 standard, which constitutes the sole mechanism for recovering the User\'s digital wallet.\n\n3.5. \"Liquid Network\": a federated Bitcoin sidechain, developed and maintained by Blockstream and the Liquid Federation, that enables the issuance and transfer of digital assets with Confidential Transactions technology.\n\n3.6. \"DEPIX\": a digital token issued on the Liquid Network by Eulen.app LLC (an entity organized in Saint Kitts and Nevis) in cooperation with the depix.info project, whose value is pegged to the Brazilian real (BRL) at a ratio of 1 (one) DEPIX to R\$ 1.00 (one real). As described in the public whitepaper available at depix.info, DEPIX is collateralized partially in fiat currencies and mostly in Bitcoin, through NITI (Non-custodial Interlinked Tokenization Infrastructure) protocols on on-chain networks and on the Liquid Network. Mooze IS NOT the issuer, administrator or guarantor of DEPIX, nor is it responsible for the peg, backing or liquidity of DEPIX.\n\n3.7. \"L-BTC\": the technical representation of Bitcoin on the Liquid Network, issued 1:1 against Bitcoin deposited in the federated peg-in, used for transactions within that network.\n\n3.8. \"Atomic Swap\": a cryptographic mechanism for the direct exchange between two digital assets, executed directly on the blockchain or sidechain, without a custodial intermediary, in which both legs of the transaction are completed simultaneously or neither of them takes effect (all-or-nothing).\n\n3.9. \"SideSwap\": a public, open-source protocol for executing atomic swaps on the Liquid Network.\n\n3.10. \"Confidential Transactions\": a native Liquid Network technology that conceals amounts and asset types in transactions, which are visible only to the parties involved by means of the respective blinding keys.\n\n3.11. \"APP ID\": a technical identifier generated from cryptographic features of the User\'s device (MediaDRM on Android, DeviceCheck on iOS), resulting in a one-way hash. The APP ID is used exclusively for fraud prevention and control of operational limits, does not allow personal identification of the User and does not constitute personally identifiable data under the LGPD or equivalent legislation.\n\n3.12. \"Regulated Partners\": Brazilian financial and payment institutions, duly authorized and regulated by the Central Bank of Brazil, that participate in the processing of operations involving fiat currency (PIX). These include, without limitation to those listed:\n(a) PLEBIT.COM.BR Soluções em Tecnologia Ltda — CNPJ 43.375.652/0001-13;\n(b) Fits Instituição de Pagamento — CNPJ 13.203.354/0001-85;\n(c) Celcoin — CNPJ 13.935.893/0001-09;\n(d) PLEBZ INTERMEDIACAO DE PAGAMENTOS LTDA — CNPJ 45.808.899/0001-01.\n\n3.13. \"Eulen.app LLC\": a company organized in Saint Kitts and Nevis, issuer of the DEPIX token and responsible for the tokenization technology infrastructure described in its public whitepaper.\n\n3.14. \"PIX\": the instant payment system established, regulated and operated by the Central Bank of Brazil.\n\n3.15. \"Services\": the set of software features made available by Mooze to the User through the App, as described in Section 4.\n\n3.16. \"NITI Protocol\": a decentralized protocol used for the verification and routing of transactions on the Liquid Network.\n\n3.17. \"Blinding Key\": a cryptographic key associated with a Confidential Transaction on the Liquid Network, which allows its holder to view the amounts and asset types transacted in that specific transaction.\n\n3.18. \"MED\" (\"Mecanismo Especial de Devolução\", Special Refund Mechanism): a mechanism established by the Central Bank of Brazil for the refund of amounts in PIX transactions, applicable in cases of fraud or operational failure, governed by the applicable BCB Resolution and operated exclusively by the institutions participating in the PIX arrangement.\n\n3.19. \"Breez\" or \"Breez SDK\": a third-party software development kit (SDK) used by Mooze for technical integration with the Lightning Network.\n\n3.20. \"Hodle\": a third-party service used for complementary features involving the PIX system.\n\n3.21. \"Partner Infratechs\": third-party companies that provide financial technology infrastructure services used by Mooze in the orchestration of its software Services, without providing services directly to the end Users of the App and without any direct contractual relationship with the User.\n\n3.22. \"FATF\": Financial Action Task Force (Grupo de Ação Financeira Internacional), an intergovernmental body referenced in these Terms for purposes of the definition of VASP and the application of Recommendation 15.\n\n3.23. \"Passive Offer\" or \"Reverse Solicitation\": a form of making a service available in which the customer seeks out the provider by the customer\'s own decision and initiative.';

  @override
  String get terms_section_4_body =>
      'Mooze makes available to the User, through the App, software services organized into modalities that are independent of one another. Each modality constitutes an autonomous technology service, with a distinct purpose, operation and contractual basis. Use of one modality neither requires nor is a condition for use of the others.\n\n4.1. SERVICE A — SOFTWARE ORCHESTRATION FOR THE ACQUISITION OF DIGITAL TOKENS\n\n4.1.1. Service A consists of Mooze making available a software interface that programmatically orchestrates communication between the User\'s device, the Regulated Partners and the digital token issuance infrastructure operated by Eulen.app LLC and other Partner Infratechs.\n\n4.1.2. The operational flow of Service A takes place as described below:\n(a) The User, through the App, enters the amount in reais (BRL) that the User wishes to use to acquire DEPIX and generates a PIX QR code, in which, via the User\'s platform for initiating the operation, the User provides all data necessary for the transaction, which may include public keys, wallet addresses, amounts and general device information;\n(b) The PIX payment is received, processed and settled entirely by one of the Regulated Partners (PLEBIT.COM.BR, Fits Instituição de Pagamento, Celcoin or PLEBZ), which are the only entities authorized to receive and process fiat currency funds in both directions of FIAT transaction flows;\n(c) The Regulated Partner communicates the PIX settlement data to Eulen.app LLC;\n(d) Eulen.app LLC issues the corresponding quantity of DEPIX tokens on the Liquid Network;\n(e) Mooze\'s software captures the User\'s wallet address — a public address mathematically derived from the private keys under the User\'s exclusive control — and transmits that address to the Eulen.app LLC infrastructure so that the DEPIX tokens are delivered directly to the User\'s Self-Custody address;\n(f) The DEPIX tokens are delivered, through the joint processing system initiated via software with Eulen.app LLC, directly via programmatic routing directed to the User\'s Self-Custody address on the Liquid Network.\n\n4.1.3. Service A constitutes the provision of software technology services, performed through infrastructure integrated among Mooze, specialized partners and service providers in the ecosystem. Mooze coordinates API (application programming interface) calls between the User\'s device, the Regulated Partners, Eulen.app LLC and the Partner Infratechs, including the automated verification system described in clause 4.1.4, without acquiring ownership, beneficial possession or control over the routed assets outside predefined programmatic scopes.\n\n4.1.4. The processing of digital assets under Service A involves multiple layers of technical and operational verification performed by integrated systems of specialized partners and service providers. Completion of processing may result from joint review procedures that, depending on the nature and characteristics of the operation, are governed by the following characteristics:\n(a) Processing is governed by integrated automated systems, whose criteria are determined by participants in the technology ecosystem; the possible outcomes are: (i) completion of the operation, with delivery of the assets to the User\'s Self-Custody address; or (ii) reversal of the operation, with return of the assets to Eulen.app LLC and notice of the PIX payment chargeback to the Regulated Partners;\n(b) there are no alternative technical destinations for the assets other than those described in (a)(i) and (a)(ii) — the structure of the system does not allow for deviations;\n(c) the integrated automated systems do not allow for discretionary intervention in individual operations;\n(d) Mooze does not acquire, at any time, beneficial ownership, any property right, or any right to use, enjoy or dispose of the tokens in transit;\n(e) the tokens in transit are not commingled with Mooze\'s assets, nor used as backing, collateral or reserve for any obligation of Mooze;\n(f) the delivery operation constitutes an atomic handoff: until the moment immediately prior to release to the User, the tokens remain under programmatic technical control with a destination predefined for the operation itself;\n(g) technical maintenance of the anti-fraud system (correction of defects, updating of programmatic rules, calibration of thresholds) constitutes software development and does not amount to discretionary intervention in individual operations.\n\n4.1.5. Operations under Service A may be subject to verification procedures performed by integrated automated systems of partners in the technology ecosystem. The duration and methodology of the verification procedures are determined by these automated systems, and may result in immediate processing or in additional review for a variable period depending on the nature and characteristics of the operation. During processing:\n(a) the assets remain in automated transit, without commingling with assets of other operations and without fungibility with Mooze\'s assets;\n(b) Mooze does not, and cannot, exercise any use, enjoyment, lending, investment, rehypothecation or any form of economic exploitation of the tokens in transition;\n(c) once the verification period expires without any inconsistency being flagged, the assets are automatically released to the User\'s Self-Custody address;\n(d) the transitory processing does not constitute custody, safekeeping, deposit or administration of assets on behalf of the User, because (i) it does not arise from a safekeeping or deposit agreement with the User, but from a technical procedure of the ecosystem applied via the processing route for delivery, and (ii) at no time does Mooze acquire beneficial ownership of or discretionary power over the assets.\n\n4.1.6. Operations may be reversed when integrated automated systems or Regulated Partners detect risk flags, technical inconsistencies or applicable regulatory requirements (including MED). In that case, the digital assets are reversed to Eulen.app LLC via blockchain within the processing time of the respective networks used. Processing of the chargeback of the PIX payment in fiat currency is the exclusive responsibility of the Regulated Partners, under the jurisdiction and regulation of the Central Bank of Brazil, and may take up to 7 (seven) calendar days counted on average from the start of the operation. The additional period between the reversal of the tokens to Eulen.app LLC and the completion of the PIX chargeback refers exclusively to the processing time of the Brazilian banking system by the Regulated Partners, during which period Mooze does not hold any tokens or financial resources related to the operation.\n\n4.1.7. Processing of the PIX payment, including verification of the payer\'s identity (KYC), anti-money laundering (AML), compliance with the \"Travel Rule\" in cross-border transfers of virtual assets upon events triggered by regulated amount thresholds, and other regulatory obligations before the Central Bank of Brazil, the Council for Financial Activities Control (COAF) and the Brazilian Federal Revenue Service, is the exclusive responsibility of the Regulated Partners and the other VASPs involved, within the limits of their respective activities.\n\n4.1.8. The issuance of DEPIX tokens is the exclusive responsibility of Eulen.app LLC and the depix.info project, which operate independently of Mooze. Mooze does not guarantee the peg, liquidity, backing, solvency or continuity of operation of DEPIX, nor does Mooze represent or answer for operations related to DEPIX, Eulen.app LLC and its contractual partnerships.\n\n4.1.9. Service A constitutes the provision of a software service (SaaS) and does not amount to: (a) a financial service; (b) an exchange operation; (c) financial intermediation; (d) transmission of value; (e) the provision of virtual asset services (VASP) within the meaning of the Banking (Amendment) Act, 2020 (RMI) or of regulatory laws of Brazilian territory; (f) any activity subject to financial, banking or insurance regulation.\n\n4.2. SERVICE B — INTERFACE FOR A DECENTRALIZED PROTOCOL FOR CONVERSION BETWEEN DIGITAL UNITS\n\n4.2.1. Service B consists of Mooze making available a software interface that allows the User to interact with the SideSwap protocol to execute atomic swaps between digital assets on the Liquid Network, as well as, where applicable, with the Breez SDK for access to the Lightning Network.\n\n4.2.2. Service B is entirely independent of Service A. Use of one Service neither implies nor requires use of the other.\n\n4.2.3. The operational flow of Service B takes place as described below:\n(a) The User, from the User\'s self-custodial wallet in the App, voluntarily initiates a request for conversion between digital assets (for example, DEPIX to L-BTC);\n(b) Mooze\'s software presents the User with a graphical interface for interacting with the SideSwap protocol (or the Breez SDK, where applicable);\n(c) The atomic swap is executed directly on the Liquid Network (or on the Lightning Network, where applicable), through the corresponding protocol, between the User and the liquidity available in the protocol;\n(d) Mooze does not participate as a counterparty, custodian, market maker or liquidity provider at any stage of the atomic swap;\n(e) The conversion takes place peer-to-peer, directly on the blockchain or sidechain, cryptographically guaranteed by the atomic swap mechanism — at no time is there an intermediary holding both sides of the operation.\n\n4.2.4. Mooze\'s role in Service B is analogous to that of a web browser that provides access to a website: Mooze provides the software interface for the User to interact with a decentralized protocol, without participating in the execution of the protocol itself.\n\n4.2.5. The SideSwap protocol is public, open source and operates in a decentralized manner on the Liquid Network. The Breez SDK is public third-party software used for access to the Lightning Network. Mooze does not control, operate, administer, govern or maintain any of these protocols or SDKs.\n\n4.2.6. Service B does not constitute brokerage, exchange, financial intermediation, foreign exchange, trading, market making or asset settlement activity. It constitutes exclusively the provision of a software interface for access to decentralized protocols.\n\n4.2.7. Mooze does not guarantee: (a) the availability of liquidity in the protocols used; (b) the successful execution of atomic swaps; (c) the conversion rates charged by the protocols; (d) the operational continuity of third-party protocols or SDKs.\n\n4.2.8. For access to the Lightning Network, Mooze makes available the technical integration with the public Breez SDK, subject to the same terms described herein for SideSwap.\n\n4.2.9. When the User selects, by the User\'s own voluntary decision, a final digital asset other than DEPIX (for example, L-BTC), Mooze\'s software sequentially orchestrates the execution of Service A (acquisition of DEPIX) followed by Service B (conversion of DEPIX into the selected asset via the decentralized Sideswap protocol). The conversion is executed entirely by the decentralized protocol. Mooze limits itself to orchestrating the software calls necessary for the final asset to be available via the User\'s Self-Custody address. The User acknowledges that this sequential orchestration constitutes the provision of an automated software service (SaaS) and does not amount to foreign exchange activity for which Mooze is responsible, brokerage, financial intermediation or VASP activity, because it is executed exclusively via the Sideswap protocol.\n\n4.3. MERCHANT MODE\n\n4.3.1. The App provides a feature called \"Merchant Mode\", which allows the User to receive payments via PIX directly into the User\'s self-custodial wallet in the App, both from third-party payers and in the form of self-payments.\n\n4.3.2. Merchant Mode uses the same technology infrastructure described in Service A (clause 4.1), and the same provisions regarding the nature of the service, the responsibilities of the Regulated Partners and the absence of custody by Mooze apply in full.\n\n4.3.3. Merchant Mode constitutes a software feature and does not amount to an acquiring, sub-acquiring or merchant accreditation service, a payment arrangement, a payment gateway or any regulated financial service. The PIX payment QR code is generated by the Merchant-User itself through the App, using the infrastructure of the Regulated Partners. Mooze does not participate in, intermediate, know of, validate or endorse the underlying commercial relationship between the Merchant-User and the payer. The payer makes a conventional PIX payment to the Regulated Partner, without any interaction, contractual relationship or direct communication with Mooze.\n\n4.3.4. Payments received through Merchant Mode are subject to verification procedures performed by integrated systems of partners and service providers. Completion of processing may take variable periods, from minutes to several days, according to the applicable procedures determined by each participant in the processing chain.\n\n4.3.5. Payments may be reversed when integrated review systems detect technical inconsistencies, regulatory requirements or other conditions that result in non-completion of the operation. The reversal will be processed by the service providers responsible for the original flow. A User who uses Merchant Mode MUST NOT deliver a product or service to the payer before final confirmation of the payment through the tracking features available in the App.\n\n4.3.6. Any losses, damages or disputes arising from the delivery of a product or service before final confirmation of the processing of the payment are the exclusive responsibility of the Merchant-User, and no liability falls on Mooze, the Regulated Partners or the Partner Infratechs.\n\n4.3.7. A User who uses Merchant Mode assumes full civil, tax and criminal responsibility for the operations carried out through the App, including operations carried out by third parties who use the device under the User\'s physical custody.\n\n4.3.8. Operational questions about payments should be directed to Mooze support at suporte@mooze.app.\n\n4.4. NATURE OF THE INTEGRATED TECHNOLOGY ECOSYSTEM\n\n4.4.1. The Services made available by Mooze operate in a complex technology ecosystem involving multiple service providers, third-party infrastructures, decentralized protocols and integrated systems.\n\n4.4.2. The execution of operations under the Services involves, on a non-exhaustive basis: (a) software infrastructure developed by Mooze; (b) systems of specialized partners and providers; (c) infrastructures of the Regulated Partners; (d) public blockchain protocols; (e) review and verification systems operated jointly by participants in the ecosystem.\n\n4.4.3. Mooze does not have exclusive control over all of the components, systems and processes involved in the execution of the Services. Decisions on the processing, approval, timing, reversal or non-performance of operations may result from automated systems, third-party procedures, regulatory requirements or technical conditions applied by any participant in the ecosystem.\n\n4.4.4. The User acknowledges that the provision of the Services constitutes technological coordination among multiple agents, and does not amount to a unilateral relationship or a service provided exclusively by Mooze. Mooze acts as a provider of software integration components within a broader ecosystem.';

  @override
  String get terms_section_5_body =>
      '5.1. The App operates under a full Self-Custody model. Private keys and seed phrases are generated and stored exclusively on the User\'s device and are technically inaccessible to Mooze.\n\n5.2. Mooze does not have, at any time and under any circumstances, access to, knowledge of, possession of, control over, a copy or backup of, custody of, or the technical capacity to reconstruct the User\'s private keys, seed phrases or passwords.\n\n5.3. The User is solely and exclusively responsible for the safekeeping, security and integrity of the User\'s private keys, seed phrases and passwords. Loss of these elements results in the permanent and irreversible loss of access to the digital assets stored in the wallet.\n\n5.4. Mooze does not have the technical capacity to recover, restore, access, transfer or recreate the User\'s digital assets in the event of loss of the private keys or seed phrases. Requests to that effect are technically impossible to fulfill.\n\n5.5. The User\'s wallet addresses and public keys are mathematically derived from the User\'s private keys by means of a deterministic cryptographic algorithm. Mooze uses this data exclusively as a technical parameter for automated routing during the performance of the Services, transmitting it via infrastructure for the direct delivery of the assets to the User.\n\n5.6. The User acknowledges that Self-Custody is the structural pillar of Mooze\'s model and a determining element of its legal classification as a non-VASP. Any attempt to circumvent the Self-Custody model (for example, demanding that Mooze safekeep keys, hold assets in custody or carry out the discretionary recovery of seed phrases) is incompatible with the nature of the Service, will not be fulfilled.';

  @override
  String get terms_section_6_body =>
      '6.1. SAFEKEEPING OF PASSWORDS AND SEED PHRASES\n\n6.1.1. The User is fully and exclusively responsible for the creation, storage and protection of the User\'s passwords, private keys and seed phrases.\n\n6.1.2. The User must store the User\'s seed phrase in a secure location, preferably offline (on a physical medium such as paper, engraved steel or a dedicated device), and never share it with third parties, including Mooze or any person who claims to be a representative of Mooze.\n\n6.1.3. Mooze NEVER asks the User, through any means of communication (e-mail, Telegram, telephone, social media, advertisements, in-app chat), for the User\'s private keys, seed phrases or passwords. Any request to that effect must be considered a fraud attempt and reported to official support at suporte@mooze.app.\n\n6.1.4. The user is solely responsible for verifying legitimacy in cases of communications or phishing attempts, or communications via homograph channels impersonating Mooze; with this knowledge provided through these terms, it is advised that, for communications from a homograph or suspicious domain similar to that of Mooze, the user should make contact by forwarding the suspicious contacts or messages (see section 6.1.3.) to suporte@mooze.app for assistance and verification; Mooze communicates with customers exclusively via the mooze.app domain.\n\n6.2. CONSEQUENCES OF LOSS OF ACCESS\n\n6.2.1. Loss of the seed phrase results in the permanent and irreversible loss of access to all digital assets stored in the associated wallet.\n\n6.2.2. Mooze cannot restore, recover or recreate access to the User\'s wallet in the event of loss of the seed phrase.\n\n6.2.3. The User acknowledges and accepts that Self-Custody entails full and exclusive responsibility for the User\'s digital assets, including the risk of total and definitive loss due to the User\'s own act or omission and lack of skill with respect to Blockchain and cryptocurrency technologies.\n\n6.2.4. The user, upon uninstalling the Mooze application, rotating data via platforms for access to the services via Mooze, or rotating wallets or seed phrases on the same device or on different devices, is aware of the possibility of data loss, such as storage of blockchain histories, histories of payments via partner processors, possible loss of standing in internal user reputation scores via Mooze systems and services (score and transaction limit related to banking transactions via regulated partners), and any data, not limited to these, that is saved locally for privacy and security; these actions may result in these consequences, and the user hereby declares that the user is fully aware of the consequences of these actions.\n\n6.3. DEVICE SECURITY AND SOURCE FROM WHICH THE SERVICES ARE OBTAINED\n\n6.3.1. The User is responsible for the security of the mobile device used to access the App, including: (a) keeping the operating system up to date; (b) using biometric authentication or a strong device password; (c) protection against malware and applications from untrusted sources; (d) refraining from rooting, jailbreaking or using emulators; the user may download the application via official authorized stores under Mooze\'s identification or through sources such as its official Github (github.com/mooze-labs), both of which sources offer ways to verify the authenticity of the source of services and applications, such as verification of the authenticity of the application and its integrity via hash ID checks in the public repositories; Mooze is not responsible for any problem arising from users who use tampered and/or fraudulent application download sources or service sources, nor for losses arising from failure to verify the source of services or of the applications obtained; the user hereby consents that the user may use verification via Mooze\'s official Github and the secure security methods of the available official stores.\n\n6.3.2. Mooze is not responsible for losses arising from compromise of the User\'s device, including malware infection, unauthorized access to the device, interception of data by third parties or use of modified devices.';

  @override
  String get terms_section_7_body =>
      '7.1. Use of the Services is subject to processing and technology fees (the \"Service Fee\" or \"Software Service Fee\") charged by reason of the operation of the technology ecosystem described in Section 4.\n\n7.2. The Service Fees compensate the technology infrastructure providers involved in the operation, including but not limited to: software development and maintenance, systems integration, processing of operations, network infrastructure, security and other technical services necessary for the functioning of the ecosystem.\n\n7.3. The Software Service Fee is calculated as a percentage of the amount of the operation and deducted from the amount of digital assets delivered to the User. The current percentage is displayed to the User on the operation confirmation screen, before the operation is carried out, and is also disclosed in the informational menus of the App.\n\n7.4. Mooze reserves the right to change the Software Service Fee percentages at any time, by means of an update in the App or due to needs for reference pegging to Bitcoin quotes (example: Bitcoin Liquid network fees and similar Bitcoin-denominated references may be adjusted due to fluctuating quotes). Continued use of the App after the change constitutes acceptance of the new percentages or of the needs for non-fixed reference amounts.\n\n7.5. The Software Service Fee constitutes compensation for a software service (SaaS), analogous in nature to the fees charged by technology platforms for the use of their services. It does not constitute a financial fee, brokerage commission, foreign exchange fee, foreign exchange spread or financial charge of any kind.\n\n7.6. The Regulated Partners, the decentralized protocols (SideSwap, Breez, Lightning) and the Partner Infratechs may apply their own fees, spreads, charges or network costs, independent of Mooze\'s Software Service Fee, over which Mooze exercises no control and bears no responsibility. Mooze informs the User of these pass-through charges on the operation confirmation screen, on a fixed or floating basis, on the platform used.\n\n7.7. Mining costs and network fees relating to transactions on the Bitcoin, Liquid Network or Lightning Network networks are the responsibility of the User and are independent of the Software Service Fee. Network fees incurred during the performance of the Services by the Regulated Partners, Partner Infratechs or protocols used may be passed on to the User, in addition to the Software Service Fee, as displayed on the confirmation screen before the operation is carried out.';

  @override
  String get terms_section_8_body =>
      '8.1. The reference values displayed in the App for digital assets (Bitcoin, L-BTC, DEPIX, L-USDT and others) are obtained from public market sources and serve exclusively as an informational reference.\n\n8.2. Mooze does not guarantee the accuracy, precision or real-time updating of the prices displayed. Price variation between the time of display and the time an operation is carried out is inherent to the functioning of digital asset markets.\n\n8.3. The display of prices in the App: (a) does not constitute an offer, public offering, recommendation, investment advice, securities analysis or guarantee of value; (b) does not amount to a public offering of securities within the meaning of Law No. 6,385/76 or equivalent legislation; (c) does not qualify as \"investment advice\" or \"solicitation\" within the meaning of the regulations of the United States, the European Union, the United Kingdom or any other jurisdiction.\n\n8.4. The User acknowledges that digital assets are subject to high volatility and that the User may suffer significant losses in value. Mooze is not responsible for losses arising from price variation.';

  @override
  String get terms_section_9_body =>
      '9.1. Mooze provides the App and the Services \"as is\" and \"as available\", without warranties of any kind, express or implied, including, without limitation, warranties of merchantability, fitness for a particular purpose or non-infringement.\n\n9.2. Mooze shall not be liable for:\n(a) losses of digital assets arising from the loss, compromise or misuse of private keys, seed phrases or passwords by the User;\n(b) losses arising from compromise of the User\'s device and use of a fake Platform (homograph / fake domain) or of an application that is tampered with or downloaded from an unofficial source;\n(c) unavailability, failures, delays, forks, reorganizations or interruptions on the Liquid Network, the Bitcoin network, the Lightning Network or any other blockchain or sidechain network;\n(d) failures, unavailability or delays in the services provided by the Regulated Partners, Eulen.app LLC, the depix.info project, the SideSwap protocol, the Breez SDK or any third-party infrastructure providers;\n(e) acts of fraud, phishing, social engineering, SIM swap or any form of attack directed at the User by third parties (including obtaining a fraudulent application or software service that the user consented to use without verifying the source, as discussed in item 6.3), including through deceptive communications, use of homograph e-mail contacts, domains similar to Mooze\'s official domain, tampered applications, fake profiles on social media or messaging apps, and any other forms of attack directed at the User, the prevention of which is not under Mooze\'s control;\n(f) errors in the entry of wallet addresses by the User, resulting in digital assets being sent to incorrect addresses; failures in sending or receiving assets on third-party platforms and services; refusal of assets by third-party services; failures of smart contracts on any blockchain networks initiated directly or indirectly by the User through the User\'s Self-Custody; use of insufficient network fees that result in the transaction not being mined or being delayed; use of the Services via PIX, by third parties, for willful or unlawful activities, notwithstanding the existence of joint anti-fraud systems — cases in which Mooze is not responsible, because it does not intermediate, endorse or validate the underlying relationship between the Merchant-User and the payer;\n(g) regulatory changes that affect the availability of the Services in a given jurisdiction, including total interruption or discontinuation in response to supervening legal requirements;\n(h) variation in the value of digital assets;\n(i) investment decisions made by the User based on information displayed in the App or in any other Mooze material;\n(j) indirect, incidental, consequential or punitive damages, lost profits, loss of opportunity, loss of data or reputational loss.\n\n9.2.1. Mooze is not responsible for: (i) decisions made by automated programmatic systems participating in the ecosystem; (ii) processing times determined by third-party infrastructures or Regulated Partners; (iii) review criteria applied by specialized service providers; (iv) reversals requested by financial institutions, Regulated Partners or regulatory authorities.\n\n9.3. Mooze is not responsible for any tax, fiscal, regulatory, labor or legal obligations of the User arising from the holding, use, conversion, disposal, receipt or movement of digital assets. Responsibility for compliance with tax obligations — including, where applicable, any normative instructions or ancillary obligations related to crypto-assets and/or income tax returns under the laws of the User\'s tax residence — rests entirely with the User, including the responsibility to monitor the User\'s own onchain transactions in order to comply with obligations of a personal and individual nature.\n\n9.4. The App may operate in a BETA version, which may coexist with stable release versions for a fixed period. The User agrees that, during the BETA period, defects, instabilities or interruptions may occur, and accepts all resulting risks.\n\n9.5. The seed phrases generated in the App are compatible with the open BIP39 standard and with the Liquid Network. In the event of critical unavailability of the App, discontinuation of the Services or the winding up of Mooze\'s activities, the User may recover access to the User\'s digital assets by importing the User\'s seed phrases into any wallet software compatible with the corresponding network (for example, the Blockstream App for the Liquid Network and the onchain Bitcoin network, which automatically derives all balances held by the user and their blockchain histories). This provision constitutes a structural guarantee of Self-Custody and an integral element of Mooze\'s non-custodial model.';

  @override
  String get terms_section_10_body =>
      '10.1. Mooze implements software-level security mechanisms for fraud prevention, including:\n(a) linking of the APP ID (technical device identifier) to the operations carried out;\n(b) a scoring system by risk levels;\n(c) progressive limits per operation according to the history of the APP ID;\n(d) detection of anomalous patterns (smurfing, bursting, coordinated self-payments, use of multiple devices for the same operation, use of emulators, use of modified devices).\n\n10.2. Mooze\'s anti-fraud measures are exclusively technological in nature, applied to the software flow, and do not replace the anti-money laundering (AML), customer identification (KYC) and \"Travel Rule\" obligations of the Regulated Partners and the other VASPs involved.\n\n10.3. The Regulated Partners are solely responsible for compliance with AML and KYC obligations before the Central Bank of Brazil, COAF and other competent authorities, under Law No. 9,613/1998, Law No. 14,478/2022 and applicable regulations or other future laws that may become ancillary.';

  @override
  String get terms_section_11_body =>
      '11.1. Mooze reserves the right to suspend, limit or terminate an APP ID\'s access to the Services, with or without prior notice, in the following cases:\n(a) detection of a pattern indicative of fraud, unlawful activity or attempted abuse of the Services;\n(b) use of compromised, rooted or jailbroken devices, emulators or manipulation tools;\n(c) attempts to circumvent the security mechanisms, anti-fraud mechanisms or operational limits of the App, attempted sabotage or attacks on Mooze infrastructure;\n(d) patterns indicative of use of the Services for money laundering, terrorist financing, sanctions evasion or any unlawful purpose;\n(e) a substantiated request from a competent authority or a valid court order;\n(f) use from a restricted jurisdiction under clause 12.1(a).\n\n11.2. Suspension of access affects exclusively the ability of the APP ID to initiate new operations that use connections to the PIX system of the regulated partners through the App. The digital assets in the User\'s Self-Custody remain entirely under the User\'s control, because they are stored in the User\'s own wallet and are accessible by means of the User\'s seed phrase in any wallet software compatible with the corresponding network.\n\n11.3. Mooze will cooperate with competent authorities upon a valid court order, subject to the technical limitations inherent to the self-custodial model (Mooze has no access to the User\'s private keys, seed phrases or digital assets). Mooze\'s cooperation is limited to providing the data actually in its technical possession (APP ID, public addresses, transaction data, blinding keys), under Section 5 of the Privacy Policy.\n\n11.4. MED procedures are processed by the Regulated Partners, which are entities participating in the PIX system. Mooze collaborates technologically with the Regulated Partners, providing APP ID information and transaction data when requested, but does not operate as a participant in the PIX system.';

  @override
  String get terms_section_12_body =>
      '12.1. The User expressly and knowingly represents, warrants and undertakes that:\n(a) the User uses the Services in compliance with the legislation applicable in the User\'s jurisdiction of domicile and residence. The User represents that the User is not a resident, domiciliary, citizen or national of, or a \"US Person\" within the meaning of Regulation S (SEC), nor a resident, national or citizen of: (i) the United States of America and its territories; (ii) the United Kingdom; (iii) the Member States of the European Union and of the European Economic Area; (iv) jurisdictions included in the sanctions lists of OFAC (U.S. Office of Foreign Assets Control), the sanctions of the United Nations Security Council, or the sanctions of the European Union or the United Kingdom; (v) jurisdictions classified by the FATF as High-Risk Jurisdictions Subject to a Call for Action; Mooze may use means of regional verification to carry out such checks, of which the user is aware and to which the user agrees. If it is found, at any time, that the User is a resident, national or citizen of a restricted jurisdiction, the APP ID\'s access to the Services may be immediately suspended or terminated. This clause does not, under any circumstances, extend regulatory jurisdiction over Mooze Labs LLC with respect to such jurisdictions, and has effect solely as a contractual filter;\n(b) the funds used in operations via PIX are of lawful and provable origin, arising from lawfully conducted activities;\n(c) the User does not use the Services for money laundering, terrorist financing, tax evasion, sanctions evasion, human trafficking, drug trafficking, corruption or any unlawful purpose;\n(d) the User is solely responsible for reporting and paying taxes levied on the holding, use, receipt, conversion or disposal of digital assets in the User\'s jurisdiction, including, where applicable, compliance with the national Normative Instructions relating to the User\'s current tax residence or citizenship.\n(e) the User must use the Services only with knowledge of the crypto-asset regulatory obligations of the User\'s tax residence or nationality, and acknowledges that Mooze does not qualify as a virtual asset service provider (PSAV, virtual asset service provider) within the meaning of the aforementioned law, because (i) it does not carry out custody, intermediation, administration, trading or brokerage of virtual assets in the name or on behalf of third parties, (ii) it operates exclusively as a non-custodial software provider, (iii) it is headquartered outside Brazilian territory, in a foreign jurisdiction;\n(f) the User understands and accepts that the User obtained access to the Services through the User\'s own active and voluntary search (reverse solicitation), without having been the object of coercion or linguistic persuasion of any kind initiated by Mooze;\n(g) the User understands and accepts the risks inherent to blockchain technology, including volatility, regulatory risk, fork risk, technological risk and risk of total loss.\n\n12.2. Mooze does not provide tax, fiscal or legal advisory services. The User must seek independent professional advice for compliance with the User\'s legal obligations.\n\n12.3. Mooze does not file, on behalf of the User, tax returns, operation reports, income statements or communications to any tax authority. The User is solely responsible for such obligations.\n\n12.4. Mooze does not provide Services to politically exposed persons (PEPs) subject to specific restrictions of sanctioning jurisdictions, and the User must properly declare the User\'s status and refrain from using the Services in violation of such restrictions.';

  @override
  String get terms_section_13_body =>
      '13.1. These Terms are governed exclusively by the laws of the Republic of the Marshall Islands, including, in particular, the Associations Law (Title 52, MIRC) and the Banking (Amendment) Act, 2020 (P.L. 2020-61).\n\n13.2. Mooze Labs LLC is an entity duly organized in the Republic of the Marshall Islands and operates from that jurisdiction. Mooze DOES NOT have a permanent establishment, subsidiary, branch, representative office, agency, agent or any form of physical, operational or legal presence in Brazil or in any other jurisdiction, other than the jurisdiction of organization.\n\n13.3. The relationship between Mooze and the Regulated Partners is governed by independent international contracts, which do not create any corporate relationship, representation, agency, mandate, appointment of an agent, consortium or joint and several liability between Mooze and such partners.\n\n13.4. Any use of the Services by a User domiciled in Brazil does not, by itself, imply submission of Mooze to Brazilian jurisdiction, by reason of the Passive Offer nature and the absence of an establishment in the country, subject to the limits of applicable mandatory laws.';

  @override
  String get terms_section_14_body =>
      '14.1. Any dispute, controversy or claim arising out of or relating to these Terms shall be resolved, at Mooze\'s sole discretion:\n(a) by the competent courts of the Republic of the Marshall Islands; or\n(b) by international arbitration conducted under the UNCITRAL Arbitration Rules (United Nations Commission on International Trade Law), by a sole arbitrator, in the English language, with the seat of arbitration to be determined by Mooze.\n\n14.2. The User waives any forum other than those indicated in clause 14.1, except where such waiver is prohibited by the mandatory law of the User\'s jurisdiction of domicile.\n\n14.3. Before initiating any formal proceeding, the User must send a written notice to Mooze containing the complete data obtained from the Mooze application or Platform, through the channel indicated in Section 19, describing the matter in detail. The parties will use good-faith efforts to reach an amicable resolution within 30 (thirty) calendar days from receipt of the notice.\n\n14.4. In the event of arbitration, each party will bear its own costs and fees, and the administrative costs of the arbitration will be borne by the losing party, to the extent permitted by the UNCITRAL Rules.';

  @override
  String get terms_section_15_body =>
      '15.1. All software, source code, design, graphical interface, trademarks, logos, trade names, editorial content and documentation of the App are the exclusive property of Mooze Labs LLC or its licensors, except where expressly made available as open source in an official Mooze repository on GitHub. Whatever is not expressly made available as open source remains protected by applicable intellectual property law.\n\n15.2. Use of the App does not confer on the User any intellectual property right in the App or its components, except for the limited personal use rights arising from these Terms.\n\n15.3. Reproduction, modification, distribution, reverse engineering, decompilation, disassembly or creation of derivative works of the App is prohibited without the express written authorization of Mooze, except for what is expressly made available as open source in Mooze\'s official repository and used under the terms of the license indicated there.\n\n15.4. The source code of the App is publicly available at https://github.com/mooze-labs/mooze-client under the terms of the license indicated there. Use of the source code is subject exclusively to the terms of that license, independently of these Terms.';

  @override
  String get terms_section_16_body =>
      '16.1. ENTIRE AGREEMENT\nThese Terms, together with the accompanying Privacy Policy, constitute the entire agreement between Mooze and the User with respect to the subject matter hereof, superseding any prior agreements, understandings, memoranda or communications, whether oral or written.\n\n16.2. SEVERABILITY\nIf any provision of these Terms is declared invalid, void, unlawful or unenforceable by a competent court or arbitrator, the remaining provisions will remain in full force and effect. The invalid provision will be interpreted and, where possible, replaced by a valid provision that most closely approximates the original intention of the parties and the economic and legal balance of the contract.\n\n16.3. WAIVER\nMooze\'s failure or forbearance to require compliance with any provision of these Terms, on one or more occasions, will not constitute a waiver of the right to require it subsequently.\n\n16.4. ASSIGNMENT\nThe User may not assign, transfer, sublicense or encumber the User\'s rights or obligations under these Terms without the prior written authorization of Mooze. Mooze may freely assign its rights and obligations under these Terms to any affiliate, successor, acquirer or assignee, upon notice to the User through the official channels.\n\n16.5. FORCE MAJEURE AND SUPERVENING ILLEGALITY\nMooze will not be liable for any delay or impossibility in the performance of its obligations arising from events beyond its reasonable control, including, without limitation:\n(a) failures or interruptions on the Liquid Network, the Bitcoin network, the Lightning Network or any blockchain network;\n(b) unavailability of the services of the Regulated Partners or of third-party infrastructure providers;\n(c) cyberattacks, or failures of internet or telecommunications infrastructure;\n(d) governmental, regulatory or judicial decisions, in any jurisdiction, that restrict the operation or render it unfeasible;\n(e) natural disasters, pandemics, wars, strikes, civil unrest or states of emergency;\n(f) legislative or regulatory changes that make the provision of the Services unlawful or unfeasible in a given jurisdiction, in which case Mooze may suspend or terminate the Services in the respective jurisdiction without additional liability, subject to the Self-Custody of the User\'s assets.\n\n16.6. INDEMNIFICATION\nThe User agrees to indemnify, defend and hold harmless Mooze, its affiliates, directors, members, employees, contractors, agents and licensors from and against any claims, damages, losses, costs (including reasonable attorneys\' fees) and liabilities arising from:\n(a) use of the Services by the User in breach of these Terms;\n(b) violation of any applicable law or regulation by the User;\n(c) third-party claims related to acts or omissions of the User;\n(d) provision of false, inaccurate or incomplete information by the User, including false representations regarding non-residence in restricted jurisdictions and regarding the lawful origin of funds.\n\n16.7. DISTRIBUTION OF THE APP\nDistribution of the App on digital platforms, including Google Play Store, Apple App Store and other channels, is carried out jointly by Mooze LLC, a limited liability company organized in the State of Delaware, United States, in its capacity as authorized distributor of Mooze Labs LLC, under an independent distribution agreement entered into between the parties. Mooze LLC (Delaware) acts exclusively as distributor and representative for purposes of publication on digital platforms, without assuming any responsibilities for development, operation, user support, regulatory compliance or custody of assets. Ownership, development, operation and all legal, regulatory and contractual responsibilities relating to the App and the Services remain exclusively with Mooze Labs LLC (Republic of the Marshall Islands). The relationship between Mooze Labs LLC and Mooze LLC (Delaware) does not change the legal nature, regulatory classification, applicable jurisdiction or any provisions of these Terms. Compliance with the distribution policies of the app stores (including, without limitation, the Cryptocurrency Exchanges and Software Wallets policy — Google Play and App Store Review Guidelines 3.1.5 — Apple) is achieved by means of a declaration that Mooze Wallet is an exclusively non-custodial wallet, outside the scope that requires a VASP license for publication.\n\n16.8. LANGUAGE\nThese Terms are originally drafted in Brazilian Portuguese. In the event of translations into other languages, the Portuguese version prevails in case of any divergence of interpretation; all of the terms drafted and presented herein, mainly in Brazilian Portuguese, exist for the sole and exclusive purpose of providing clarification to the regional LATAM public, the main region where Brazil\'s PIX services have the greatest reach, and this communication fact shall not be interpreted as an intention to establish a seat in and/or perform software services in territories beyond the place of organization of Mooze Labs LLC.';

  @override
  String get terms_section_17_body =>
      '17.1. The App and the Services are intended exclusively for natural persons aged 18 (eighteen) years or older.\n\n17.2. By using the App, the User represents that the User is at least 18 (eighteen) years of age and has full legal capacity to enter into binding contracts.\n\n17.3. Mooze reserves the right to suspend or terminate the access of any User who is found to be an unemancipated minor under 18 (eighteen) years of age.\n\n17.4. The App constitutes exclusively software for the management of a self-custodial digital wallet and the instrumentation of financial operations with digital assets, and does not amount to a social network, social media platform, messaging service, streaming platform, entertainment service, electronic game application or any form of digital platform with features for engagement or social interaction among users.\n\nBy reason of this nature, Mooze does not fall within the scope of application of Law No. 15,211/2025 (Law for the Protection of Children and Adolescents in the Digital Environment — \"ECA Digital\"), whose obligations are directed at social networks, entertainment platforms, electronic games and services with addictive or behavioral engagement features. Mooze does not make available, and does not have the technical capacity to make available:\n\n(a) features for creating, publishing or sharing content among users;\n(b) social interaction mechanisms (likes, comments, reactions, shares);\n(c) networks of contacts, followers, friendships or connections among users;\n(d) content recommendation algorithms, personalized feeds or infinite scroll;\n(e) chat, messaging, or direct or indirect communication among users of the App;\n(f) public user profiles, timelines or spaces for user-generated content;\n(g) gamification mechanisms, engagement rewards, behavioral notifications or features designed to maximize usage time.\n\nUse of the Services by Brazilians presupposes, structurally and unavoidably, the User\'s full legal capacity, under articles 3, 4 and 5 of Law No. 10,406/2002 (Brazilian Civil Code), because the Services involve entering into binding contracts and disposing of financial assets — legal acts that unemancipated minors are legally unable to perform on their own. This structural requirement constitutes, by itself, a legal mechanism for excluding children and adolescents that is incompatible with any classification as a digital platform subject to the obligations of Law No. 15,211/2025 or to the provisions of the Statute of Children and Adolescents (Law No. 8,069/1990) applicable to entertainment and content services.';

  @override
  String get terms_section_18_body =>
      '18.1. Mooze reserves the right to change these Terms at any time by publishing the updated version in the App and at https://mooze.app/termosdeuso/, with an indication of the date of the new version.\n\n18.2. Material changes will be communicated to the User through the App, the Telegram support channel or by e-mail, when available.\n\n18.3. Continued use of the App after the publication of changes constitutes tacit acceptance of the updated Terms.\n\n18.4. A User who does not agree with the changes must cease using the App. The digital assets in the User\'s Self-Custody remain under the User\'s exclusive control and are accessible by means of the User\'s seed phrase in any compatible wallet software.';

  @override
  String get terms_section_19_body =>
      '19.1. For questions, requests or communications related to these Terms, the User may contact Mooze through the following official channels:\n(a) Support e-mail: suporte@mooze.app\n(b) Telegram support channel: https://t.me/+zkNS6KIDsEcyZDkx (also accessible via https://moozeapp.keepo.bio)\n(c) Automated FAQ via Telegram\n\n19.2. Formal notices of a legal nature (including dispute notices under clause 14.3, subpoenas, service of process or court orders) must be addressed in writing to Mooze Labs LLC, Trust Company Complex, Ajeltake Island, Ajeltake Road, Majuro, Marshall Islands MH96960, Republic of the Marshall Islands, with a copy to the e-mail suporte@mooze.app; delivery through any other channels or jurisdictions does not constitute valid service of process.\n\n19.3. Mooze will use efforts to respond to support communications within 2 (two) to 10 (ten) business days. Formal notices will be answered within the time limits applicable under RMI law or UNCITRAL arbitration, as the case may be.';

  @override
  String get privacy_section_header_body =>
      'Last updated: 04/18/2026\n\nMooze Labs LLC\nRepublic of the Marshall Islands\nhttps://mooze.app';

  @override
  String get privacy_section_1_body =>
      '1.1. Mooze Labs LLC (\"Mooze\"), a company duly organized in the Republic of the Marshall Islands, is committed to protecting privacy and to minimizing personal data in the use of the Mooze Wallet application (the \"App\").\n\n1.2. This Privacy Policy (the \"Policy\") describes what information is collected, how it is used, with whom it is shared and what rights the User has with respect to the User\'s data.\n\n1.3. Mooze adopts the principle of data minimization as a central pillar of its operation. The App was designed to function without the collection of personally identifiable data by Mooze.\n\n1.4. This Policy must be read together with the Terms of Use of the App.';

  @override
  String get privacy_section_2_body =>
      '2.1. All terms defined in the Terms of Use and used in this Policy have the same meanings assigned in Section 3 of the Terms of Use, unless expressly provided otherwise in this document.\n\n2.2. For purposes of this Policy, the following definitions also apply:\n(a) \"Personal Data\": any information relating to an identified or identifiable natural person, within the meaning of the General Data Protection Law (Law No. 13,709/2018 — LGPD) or equivalent legislation.\n(b) \"Processing\": any operation performed with Personal Data, including collection, storage, use, sharing and deletion.\n(c) \"LGPD\": the Brazilian General Data Protection Law (Law No. 13,709/2018).\n(d) \"Controller\" and \"Processor\": the roles defined in the LGPD, applicable, where appropriate, to the relationships among Mooze, the User and the Regulated Partners.';

  @override
  String get privacy_section_3_body =>
      '3.1. DATA THAT MOOZE DOES NOT COLLECT OR STORE\nMooze DOES NOT collect in its systems or servers, with respect to Users of the App:\n(a) CPF, RG, passport or any civil identification document;\n(b) full legal name;\n(c) telephone number;\n(d) residential or mailing address;\n(e) date of birth;\n(f) biometric data (the device identification used is a one-way cryptographic hash and does not constitute personal biometrics);\n(g) the User\'s private keys, seed phrases or passwords;\n(h) images, photographs or videos: the device camera is accessed exclusively for reading QR codes (addresses and payment invoices), with processing performed locally on the device itself; no image or capture is collected, stored or transmitted to Mooze or to third parties.\n\n3.2. DATA THAT MOOZE COLLECTS\nMooze collects exclusively the following data:\n(a) APP ID: a technical device identifier, generated from operating system features (MediaDRM on Android devices, DeviceCheck on iOS devices). The APP ID is a one-way cryptographic hash that, on its own, does not allow personal identification of the User. It is used exclusively for fraud prevention and control of operational limits.\n(b) Wallet data: descriptors, addresses and public keys mathematically derived from the User\'s keys, used as a technical parameter for automated routing for the delivery of digital assets to the User during the performance of the Services; none of this data allows Mooze to move or access users\' funds.\n(c) Blinding keys: cryptographic keys associated with Confidential Transactions on the Liquid Network, retained by Mooze exclusively for verification and reconciliation of transactions processed through the App in the functions involving Partner Infratechs via PIX.\n(d) Transaction data: records of the operations carried out through the App, including amounts, asset types, timestamps, transaction hashes and execution status. This data is retained for purposes of providing the Service, User support, reconciliation with partners and compliance with any legal obligations applicable to Mooze as a non-VASP entity.\n(e) Technical device data: generic information about the functioning of the App, such as operating system version, device model, installed App version and internal logs essential for support resolution and technical debugging. This data does not allow personal identification of the User.\n(f) Notification (push) token: a technical identifier generated by the Firebase Cloud Messaging service (Google LLC), used exclusively for sending operational notifications, such as transaction alerts, to the User\'s device. The token does not contain personally identifiable data, is not used for advertising, and its generation depends on notification permission granted by the User on the device.\n\n3.3. DEVICE PERMISSIONS\nThe App requests the following device permissions, always subject to the User\'s authorization in the operating system and for the purposes indicated below:\n(a) Camera: exclusively for reading QR codes (addresses and payment invoices), with local processing; images are not collected, stored or transmitted;\n(b) Notifications: exclusively for sending operational transaction alerts, through the Firebase Cloud Messaging service (Google LLC);\n(c) Biometric authentication or device credential: exclusively for locking local access to the App, processed by the device\'s own operating system; Mooze does not collect, access or store biometric data;\n(d) Network and internet access: for communication with the Bitcoin, Liquid Network and Lightning Network networks and with the infrastructure providers described in this Policy.';

  @override
  String get privacy_section_4_body =>
      '4.1. When the User carries out operations involving payment via PIX (Service A under the terms of use), the data necessary for processing the payment — including the payer\'s legal name, the payer\'s CPF, PIX key, bank details and other data necessary for compliance with KYC, AML and Travel Rule obligations — is collected and processed exclusively by the Regulated Partners in Brazil via indirect or direct services with our technology partners, within the limits of their respective activities via automations in systems linked to the Brazilian financial system.\n\n4.2. The Regulated Partners are:\n\n(a) PLEBIT.COM.BR Soluções em Tecnologia Ltda — CNPJ 43.375.652/0001-13;\n(b) Fits Instituição de Pagamento — CNPJ 13.203.354/0001-85;\n(c) Celcoin — CNPJ 13.935.893/0001-09;\n(d) PLEBZ INTERMEDIACAO DE PAGAMENTOS LTDA — CNPJ 45.808.899/0001-01.\n\nThis list of partners may be reduced or expanded, according to contractual modifications or changes and their availability.\n\n4.3. The collection, storage and processing of personal data by the Regulated Partners are governed by the respective privacy policies of those entities, in compliance with the LGPD and with the regulations of the Central Bank of Brazil. Each Regulated Partner acts as an autonomous Controller of the personal data it processes.\n\n4.4. Communication between Mooze\'s software and the Regulated Partners is limited to data strictly necessary for the automated routing of the operation (amount, public keys, destination wallet address, operation identifier, irreversible cryptographic identifiers derived from the payer\'s data and, when necessary, APP ID for anti-fraud purposes).\n\n4.5. Eulen.app LLC, as a technology infrastructure provider and issuer of the DEPIX token, and other partner infratechs may collect and process operational data necessary for the issuance of the tokens and related activities, in accordance with their own privacy policies, without Mooze acting as Controller of such data.';

  @override
  String get privacy_section_5_body =>
      '5.1. Mooze shares data exclusively in the following cases:\n(a) With the Regulated Partners and with Eulen.app LLC: data strictly necessary for the automated routing of operations (wallet addresses, amounts, operation identifiers and APP ID when necessary for anti-fraud purposes).\n(b) Upon a court order: Mooze may provide the data in its possession (APP ID, wallet addresses, blinding keys and related data collected) upon a valid court order issued by a competent court, subject to the rules on international recognition of judicial decisions applicable to entities headquartered in the Republic of the Marshall Islands.\n(c) For compliance with a legal obligation: when required by applicable law in the jurisdiction of the Republic of the Marshall Islands.\n(d) In MED procedures conducted by the Regulated Partners: technical provision of the APP ID and related data necessary when evidentiary reports of service execution or requirements arising from the need for their defense are requested through legal, regulatory or compliance demands.\n\n5.2. Mooze DOES NOT sell, rent, trade, assign or share data with third parties for purposes of marketing, advertising, behavioral analytics or any purpose not described in this Policy.\n\n5.3. To enable the sending of push notifications, the device notification token is processed by the Firebase Cloud Messaging service, provided by Google LLC, exclusively for that purpose. No other personal data is shared with Google for sending notifications.';

  @override
  String get privacy_section_6_body =>
      '6.1. When the User contacts Mooze through the support channels (e-mail suporte@mooze.app or Telegram), the data voluntarily shared by the User during the communication (such as username on messaging platforms, message content and any screenshots) will be used exclusively for the purpose of handling the request.\n\n6.2. Mooze does not, as a rule, associate support communication data with APP IDs or wallet addresses, except when the User voluntarily provides such information for the purpose of resolving a specific problem.';

  @override
  String get privacy_section_7_body =>
      '7.1. Mooze adopts reasonable technical and organizational measures, consistent with the applicable state of the art, to protect the data under its responsibility against unauthorized access, destruction, loss, alteration, or improper communication or disclosure.\n\n7.2. The data collected by Mooze is stored on protected infrastructure, with access controls and encryption in transit and at rest.\n\n7.3. Mooze cannot guarantee absolute security in the transmission of data over the internet or in electronic storage systems. The User acknowledges that no method of transmission or electronic storage is entirely immune to failures.';

  @override
  String get privacy_section_8_body =>
      '8.1. The data collected by Mooze is retained for the following periods:\n(a) APP ID: 5 (five) years from the last operation. After this period, it will be deleted, unless there is a legal retention obligation.\n(b) Wallet addresses, descriptors, public keys and blinding keys: 5 (five) years from the last operation, for purposes of verification, reconciliation and compliance with any legal obligations.\n(c) Transaction data: 5 (five) years from the date of the transaction.\n(d) Technical device data: deleted after 5 (five) years of inactivity.\n\n8.2. The above periods may be extended when necessary for: (a) compliance with a legal obligation; (b) compliance with a court order; (c) defense in judicial, administrative or arbitral proceedings; (d) improvement of anti-fraud systems, whether Mooze\'s own or joint with the Regulated Partners and Partner Infratechs, in the minimum necessary volume and in pseudonymized form whenever possible.';

  @override
  String get privacy_section_9_body =>
      '9.1. In observance of the LGPD, and notwithstanding that Mooze is not established in Brazil, Mooze recognizes the following rights of the User, to the extent applicable to the processing actually carried out:\n(a) confirmation of the existence of processing of pseudo-anonymous data;\n(b) evaluation of a request for deletion of the APP ID associated with the User\'s device and with the user of the Mooze software service\n\n9.2. The exercise of the rights provided for in clause 9.1 may be requested by the User through the channels indicated in Section 12 of this Policy.\n\n9.3. Mooze will respond to requests within 15 (fifteen) business days, under the LGPD, with a justified extension permitted in cases of technical complexity or volume.\n\n9.4. Deletion of the APP ID, once the request is fulfilled, will result in the deactivation of the device\'s access to the Services involving a FIAT reference (Service A and Merchant Mode under the terms of use). If the App is reinstalled, the device\'s access to the Services via FIAT means will remain blocked until a new formal request, sent from the same e-mail address used in the deletion request, with express and full acceptance of these Terms and the Privacy Policy.\n\n9.5. Certain data may be retained, or its deletion denied, even after a deletion request, when necessary for: (a) compliance with a legal obligation; (b) the regular exercise of rights in judicial, administrative or arbitral proceedings; (c) fraud prevention (especially if the user, with the user\'s APP ID, has pending involvement in payment disputes that have occurred, for example, MED), under art. 7, IX, and art. 16 of the LGPD; in accordance with the periods indicated in Section 8.';

  @override
  String get privacy_section_10_body =>
      '10.1. The data collected by Mooze is stored and processed on technology infrastructure located outside Brazilian territory.\n\n10.2. The data jurisdiction applicable to the processing activity carried out by Mooze is the Republic of the Marshall Islands, where Mooze is organized and operates.\n\n10.3. The operational data transmitted to the Regulated Partners during the performance of Service A under the terms of use is processed and stored in Brazil, under Brazilian jurisdiction and in compliance with the LGPD, under the exclusive responsibility of the Regulated Partners in their capacity as autonomous Controllers.\n\n10.4. The transfer of data from Brazil to Mooze\'s infrastructure (if any), to the extent it constitutes an international transfer for purposes of the LGPD, is carried out on the basis of the applicable legal grounds (art. 33 of the LGPD), including, as the case may be, the need to perform a contract to which the User is a party and compliance with a legal obligation.';

  @override
  String get privacy_section_11_body =>
      '11.1. Mooze reserves the right to change this Policy at any time by publishing the updated version in the App and at https://mooze.app/, with an indication of the date of the new version.\n\n11.2. Material changes will be communicated to the User through the App or the Telegram support channel.\n\n11.3. Continued use of the App after the publication of changes constitutes tacit acceptance of the updated Policy.';

  @override
  String get privacy_section_12_body =>
      '12.1. For questions or requests related to this Privacy Policy, the User may contact Mooze through the following official channels:\n(a) E-mail: suporte@mooze.app\n(b) Telegram support channel: https://t.me/+zkNS6KIDsEcyZDkx (also accessible via https://moozeapp.keepo.bio)\n(c) Automated FAQ via Telegram\n\n12.2. Formal notices related to personal data must be addressed to Mooze Labs LLC, Trust Company Complex, Ajeltake Island, Ajeltake Road, Majuro, Marshall Islands MH96960, Republic of the Marshall Islands, with a copy to the e-mail suporte@mooze.app; such forwarding details may be obtained by contacting this same e-mail address.\n\n12.3. Mooze will use efforts to respond to communications within 15 (fifteen) business days.';

  @override
  String get developer_title => 'Wallet Hub';

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
  String get developer_bitcoin_tip => 'Bitcoin tip';

  @override
  String get developer_unavailable => 'unavailable';

  @override
  String get developer_liquid_balances => 'Liquid Balances';

  @override
  String get developer_section_synchronisation => 'Synchronisation';

  @override
  String get developer_section_diagnostics => 'Diagnostics';

  @override
  String get developer_time_just_now => 'just now';

  @override
  String developer_time_seconds_ago(int seconds) {
    return '${seconds}s ago';
  }

  @override
  String developer_time_minutes_ago(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String developer_time_hours_ago(int hours) {
    return '${hours}h ago';
  }

  @override
  String developer_time_days_ago(int days) {
    return '${days}d ago';
  }

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
  String get logs_overview_title => 'Log activity';

  @override
  String get logs_overview_subtitle => 'Real-time application diagnostics';

  @override
  String get logs_source_label => 'Source';

  @override
  String get logs_levels_label => 'Levels';

  @override
  String get logs_entries_label => 'entries';

  @override
  String get logs_detail_tag => 'Tag';

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
  String get receive_connection_error =>
      'There was a connection problem. Please try again.';

  @override
  String get receive_network_bitcoin_onchain => 'Bitcoin On-chain';

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
  String get receive_select_asset_first => 'Select an asset first';

  @override
  String get receive_network_label_bitcoin => 'Bitcoin';

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
  String get receive_amount_helper_optional =>
      'Amount optional for Bitcoin/Liquid';

  @override
  String get receive_amount_sats_label => 'Amount in Satoshis:';

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
  String get tx_detail_swap_completed => 'Swap Completed';

  @override
  String get tx_detail_swap_in_progress => 'Swap In Progress';

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
  String swap_amount_bounds(Object max, Object min) {
    return 'Min: $min sats · Max: $max sats (balance)';
  }

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
  String get qr_scanner_supported_networks => 'Bitcoin • Liquid';

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
  String get qr_validation_lightning_unsupported =>
      'Lightning is not supported for sending';

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
  String get cpf_screen_title => 'Payer identification';

  @override
  String get cpf_screen_subtitle =>
      'Enter the payer\'s CPF or CNPJ to generate the Pix QR code.';

  @override
  String get cpf_field_label => 'CPF / CNPJ';

  @override
  String get cpf_field_hint => '000.000.000-00';

  @override
  String get cpf_error_required => 'Enter the CPF';

  @override
  String get cpf_error_incomplete => 'Enter a valid CPF or CNPJ';

  @override
  String get cpf_error_invalid => 'Invalid CPF or CNPJ';

  @override
  String get cpf_continue => 'Continue';

  @override
  String get cpf_save_as_favorite => 'Save as favorite';

  @override
  String get cpf_save_this_payer => 'Save this payer';

  @override
  String get cpf_favorite_label => 'Payer name';

  @override
  String get cpf_favorite_label_hint => 'e.g. John Smith';

  @override
  String get cpf_favorites_title => 'Favorite payers';

  @override
  String get cpf_favorites_empty_title => 'No saved payers';

  @override
  String get cpf_favorites_empty_subtitle =>
      'Add a payer to reuse their CPF on future charges.';

  @override
  String get cpf_favorites_add => 'Add payer';

  @override
  String get cpf_favorites_use_another => 'Use another CPF';

  @override
  String get cpf_favorites_remove => 'Remove';

  @override
  String get cpf_favorites_section => 'Saved payers';

  @override
  String get cpf_favorites_view_all => 'View all';

  @override
  String get cpf_or_enter_manually => 'Or enter a CPF';

  @override
  String get cpf_favorites_label_required => 'Enter a name';

  @override
  String get cpf_favorites_duplicate => 'This CPF is already saved';

  @override
  String get cpf_favorites_add_title => 'Add payer';

  @override
  String get cpf_favorites_edit_title => 'Edit payer';

  @override
  String get cpf_favorites_save => 'Save';

  @override
  String get cpf_favorites_search_hint => 'Search by name';

  @override
  String get cpf_favorites_search_empty => 'No payers found';

  @override
  String get cpf_favorites_edit => 'Edit';

  @override
  String get cpf_favorites_actions => 'Actions';

  @override
  String get cpf_favorites_error => 'Couldn\'t load payers';

  @override
  String get cpf_favorites_removed => 'Payer removed';

  @override
  String get cpf_favorites_delete_title => 'Remove payer?';

  @override
  String cpf_favorites_delete_body(String label) {
    return 'Remove $label from favorite payers?';
  }

  @override
  String get cpf_payment_warning =>
      'Use a Pix account linked to the provided CPF. Payments made from an account with a different account holder will be declined.';

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
  String get pix_deposit_status_processing_refund_1_3_label => 'Refunding 1/3';

  @override
  String get pix_deposit_status_processing_refund_2_3_label => 'Refunding 2/3';

  @override
  String get pix_deposit_status_processing_refund_3_3_label => 'Refunding 3/3';

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
  String get pix_tutorial_step1_title => 'Receive payments with PIX';

  @override
  String get pix_tutorial_step1_body =>
      'Tap here to access the PIX area and start receiving payments quickly.';

  @override
  String get pix_tutorial_step2_title => 'Quick access';

  @override
  String get pix_tutorial_step2_body =>
      'You can also access the PIX area from this shortcut available throughout the app.';

  @override
  String get pix_tutorial_step3_title => 'How you receive payments';

  @override
  String get pix_tutorial_step3_body =>
      'By default, payments are received in DEPIX, a digital asset pegged 1:1 to the Brazilian Real. Every 1 DEPIX is equivalent to R\$1.00.';

  @override
  String get pix_tutorial_step4_title => 'Choose another asset';

  @override
  String get pix_tutorial_step4_body =>
      'If you prefer, you can change the receiving asset and receive payments directly in Liquid Bitcoin (L-BTC).';

  @override
  String get pix_tutorial_step5_title => 'Convert anytime';

  @override
  String get pix_tutorial_step5_body =>
      'Even if you receive payments in DEPIX, you can later convert your balance to L-BTC or USDT using the Swap screen.';

  @override
  String get pix_tutorial_step6_title => 'Your receiving limit';

  @override
  String get pix_tutorial_step6_body =>
      'Check your minimum, maximum, and daily limits. Your limits may increase as you continue using the app.';

  @override
  String get pix_tutorial_step7_title => 'Enter the amount';

  @override
  String get pix_tutorial_step7_body =>
      'Choose the amount you want to charge. For this tutorial, we will use R\$50.00 as an example.';

  @override
  String get pix_tutorial_step8_title => 'Generate a PIX charge';

  @override
  String get pix_tutorial_step8_body =>
      'After entering an amount, simply drag this button to the end to create a PIX payment request.';

  @override
  String get pix_tutorial_step9_title => 'QR Code ready';

  @override
  String get pix_tutorial_step9_body =>
      'Once the button is dragged, a PIX QR Code will be generated.';

  @override
  String get pix_tutorial_done_title => 'Tutorial completed';

  @override
  String get pix_tutorial_done_body =>
      'You now know how to receive payments with PIX, choose your receiving asset, understand limits, and generate payment QR Codes.';

  @override
  String get pix_tutorial_restart => 'Restart Tutorial';

  @override
  String get pix_tutorial_settings_replay => 'Replay PIX tutorial';

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
  String get merchant_payment_method_title => 'How will the customer pay?';

  @override
  String get merchant_payment_method_subtitle =>
      'Choose an option to continue.';

  @override
  String get merchant_payment_method_qr_title => 'Pix QR Code';

  @override
  String get merchant_payment_method_qr_description =>
      'Show the QR Code. The customer pays in the bank app.';

  @override
  String get merchant_payment_method_link_title => 'Payment link';

  @override
  String get merchant_payment_method_link_description =>
      'Generate a link for the customer to pay from anywhere.';

  @override
  String get merchant_payment_method_tag_instant => 'Instant';

  @override
  String get merchant_payment_method_tag_cpf => 'Asks for CPF';

  @override
  String get merchant_payment_method_tag_remote => 'Remote';

  @override
  String get merchant_payment_method_tag_browser => 'In a browser';

  @override
  String merchant_payment_receive_in(String asset) {
    return 'You receive in $asset';
  }

  @override
  String get merchant_payment_link_scan_hint =>
      'The customer scans the QR Code with the phone camera and pays in a browser.';

  @override
  String get merchant_payment_link_share => 'Share link';

  @override
  String get merchant_payment_link_creating => 'Creating payment link...';

  @override
  String get merchant_payment_link_open => 'Open in browser';

  @override
  String get merchant_payment_link_open_failed =>
      'We could not open the browser.';

  @override
  String merchant_payment_link_share_message(String amount, String url) {
    return 'Pay $amount with Pix: $url';
  }

  @override
  String get merchant_payment_link_done => 'Finish sale';

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
  String get merchant_tutorial_skip => 'Skip';

  @override
  String get merchant_total_label => 'Sale total';

  @override
  String get merchant_edit_action => 'Edit';

  @override
  String get merchant_clear_cart_confirm_title => 'Clear the cart?';

  @override
  String get merchant_clear_cart_confirm_body =>
      'This removes the items of this sale.';

  @override
  String get merchant_product_name_required => 'Enter the product name.';

  @override
  String get merchant_product_price_required =>
      'Enter a price greater than zero.';

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
  String get pix_fees_back_to_top => 'Back to top';

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
  String get tx_detail_fee => 'Fee';

  @override
  String tx_detail_datetime(String date, String time) {
    return '$date at $time';
  }

  @override
  String get tx_detail_swap_label => 'Asset swap';

  @override
  String get tx_detail_sent => 'Sent';

  @override
  String get tx_detail_received => 'Received';

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
  String get tx_detail_view_send_tx => 'View send transaction';

  @override
  String get tx_detail_view_refund_tx => 'View refund transaction';

  @override
  String get tx_detail_send_tx_id => 'Send TX ID';

  @override
  String get tx_detail_refund_tx_id => 'Refund TX ID';

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
  String get pin_change_title => 'Change PIN';

  @override
  String get pin_change_min_length => 'PIN must be at least 6 characters';

  @override
  String get pin_change_yours => 'Create your new ';

  @override
  String get pin_change_intro_prefix => 'Your new ';

  @override
  String get pin_change_intro_suffix =>
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
  String get wallet_send_error_self_transfer =>
      'You can\'t send to your own address';

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
  String get wallet_action_buy => 'PIX';

  @override
  String get wallet_assets_section_title => 'Assets';

  @override
  String get wallet_transactions_section_title => 'Transactions';

  @override
  String get wallet_section_see_more => 'See more';

  @override
  String get wallet_holding_allocation_title => 'Allocation';

  @override
  String get wallet_tx_date_today => 'Today';

  @override
  String get wallet_tx_date_yesterday => 'Yesterday';

  @override
  String get wallet_action_more => 'More';

  @override
  String get wallet_more_sheet_title => 'More actions';

  @override
  String get wallet_more_buy_pix => 'Buy with PIX';

  @override
  String get wallet_balance_show => 'Show balance';

  @override
  String get wallet_balance_hide => 'Hide balance';

  @override
  String get wallet_balance_hidden => 'Balance hidden';

  @override
  String get wallet_balance_change_unit_hint => 'Change unit';

  @override
  String get wallet_amount_hidden => 'Amount hidden';

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
  String get address_ownership_field_balance => 'Balance';

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

  @override
  String get converting_details_title => 'Conversion in progress';

  @override
  String get converting_details_refund_title => 'Swap could not complete';

  @override
  String get converting_details_refund_message =>
      'Boltz flagged this swap as refundable. Your funds are safe — claim them back to your wallet using the refund flow below.';

  @override
  String get converting_details_refund_button => 'Get refund';

  @override
  String get converting_details_completed_title => 'Conversion completed';

  @override
  String get converting_details_completed_message =>
      'The funds have arrived on the destination chain. The full swap is now visible in your transaction history.';

  @override
  String get converting_details_back_to_home => 'Back to home';

  @override
  String converting_details_converting_label(String from, String to) {
    return 'Converting $from → $to';
  }

  @override
  String get converting_details_peg_in => 'Peg-in';

  @override
  String get converting_details_peg_out => 'Peg-out';

  @override
  String get converting_details_you_sent => 'You sent';

  @override
  String get converting_details_youll_receive => 'You\'ll receive';

  @override
  String get converting_details_phase_preparing => 'Preparing';

  @override
  String get converting_details_phase_broadcasting => 'Broadcasting';

  @override
  String get converting_details_phase_awaiting_confirmations =>
      'Awaiting confirmations';

  @override
  String get converting_details_phase_failed => 'Failed';

  @override
  String get converting_details_phase_refundable => 'Refundable';

  @override
  String get converting_details_direction => 'Direction';

  @override
  String get converting_details_direction_peg_in =>
      'Peg-in (BTC on-chain → LBTC)';

  @override
  String get converting_details_direction_peg_out =>
      'Peg-out (LBTC → BTC on-chain)';

  @override
  String get converting_details_sent => 'Sent';

  @override
  String get converting_details_estimated_receive => 'Estimated receive';

  @override
  String get converting_details_started => 'Started';

  @override
  String get converting_details_destination_address => 'Destination address';

  @override
  String get converting_details_swap_id => 'Swap ID';

  @override
  String get converting_details_bitcoin_send_tx => 'Bitcoin send tx';

  @override
  String get converting_details_liquid_send_tx => 'Liquid send tx';

  @override
  String get converting_details_local_id => 'Local ID';

  @override
  String get converting_details_help_footer =>
      'Chain swaps move funds between Bitcoin and Liquid Bitcoin (L-BTC) and typically settle in 30 to 60 minutes after the lockup tx confirms. Your funds are not lost — they are temporarily locked in the swap contract while the destination chain catches up.';

  @override
  String get converting_details_explanation_preparing =>
      'Building the lockup transaction and reserving the swap with the chain-swap service.';

  @override
  String get converting_details_explanation_broadcasting_bitcoin =>
      'Signing and broadcasting the lockup transaction to the Bitcoin network.';

  @override
  String get converting_details_explanation_broadcasting_liquid =>
      'Signing and broadcasting the lockup transaction to the Liquid network.';

  @override
  String get converting_details_explanation_broadcasted_peg_in =>
      'Your Bitcoin lockup has been broadcast. Once it confirms, the chain-swap service will claim it and send LBTC to your wallet.';

  @override
  String get converting_details_explanation_broadcasted_peg_out =>
      'Your LBTC has been sent to the chain-swap service. Once it processes, you\'ll receive BTC on the Bitcoin network.';

  @override
  String get converting_details_explanation_failed =>
      'The swap could not be completed. Any funds reserved for the swap will be refunded automatically.';

  @override
  String get converting_details_explanation_refundable =>
      'Boltz flagged the swap as refundable. Tap \"Get refund\" to send the locked funds back to your wallet.';

  @override
  String get pending_swap_refund_available => 'Swap refund available';

  @override
  String get pending_swap_status_preparing => 'Preparing swap…';

  @override
  String get pending_swap_status_broadcasting => 'Broadcasting to network…';

  @override
  String get pending_swap_status_broadcasted =>
      'Broadcasted — waiting for confirmations';

  @override
  String get pending_swap_status_failed => 'Swap failed';

  @override
  String get pending_swap_status_refundable => 'Tap to claim your refund';

  @override
  String pending_swap_refundable_amount(String amount) {
    return 'Refundable: $amount';
  }

  @override
  String get pix_first_time_title => 'About PIX payments';

  @override
  String get pix_first_time_description =>
      'All PIX payments go through a security review and may be:';

  @override
  String get pix_first_time_item_completed => 'Settled within 72 hours';

  @override
  String get pix_first_time_item_refunded => 'Refunded to the payer';

  @override
  String get pix_first_time_security_note =>
      'This review is required to keep all users safe.';

  @override
  String get pix_first_time_accept_button => 'I understand and accept';

  @override
  String pix_first_time_accept_button_counting(int seconds) {
    return 'I understand and accept ($seconds)';
  }

  @override
  String get swap_btc_lbtc_warning_title => 'Notice: Cross-network swap';

  @override
  String get swap_btc_lbtc_warning_intro =>
      'Important information about the BTC to LBTC swap:';

  @override
  String get swap_btc_lbtc_warning_cross_chain =>
      'This is a swap between different blockchains (Bitcoin and Liquid Network).';

  @override
  String get swap_btc_lbtc_warning_confirmations =>
      'The swap depends on confirmations on both blockchains, which may take some time.';

  @override
  String get swap_btc_lbtc_warning_fee_changes =>
      'If network fees change, Breez may flag the asset as a \"refund\".';

  @override
  String get swap_btc_lbtc_warning_manual_refund =>
      'If that happens, you\'ll need to request the refund manually inside the app.';

  @override
  String get swap_btc_lbtc_warning_funds_safe =>
      'Your funds are always safe, even in case of a refund.';

  @override
  String get swap_btc_lbtc_warning_accept_button => 'I understand and accept';

  @override
  String swap_btc_lbtc_warning_accept_button_counting(int seconds) {
    return 'I understand and accept ($seconds)';
  }

  @override
  String asset_activity_market_price(String ticker) {
    return '$ticker price';
  }

  @override
  String get asset_activity_summary_title => 'Summary';

  @override
  String get asset_activity_received_total => 'Received total';

  @override
  String get asset_activity_sent_total => 'Sent total';

  @override
  String get asset_activity_current_balance => 'Current balance';

  @override
  String get asset_activity_transactions => 'Transactions';

  @override
  String get asset_activity_section_title => 'Movements';

  @override
  String get asset_activity_first => 'First activity';

  @override
  String get asset_activity_last => 'Last activity';

  @override
  String get asset_activity_highlights_title => 'Highlights';

  @override
  String get asset_activity_largest_receive => 'Largest receive';

  @override
  String get asset_activity_largest_send => 'Largest send';

  @override
  String get asset_activity_total_volume => 'Total volume';

  @override
  String get asset_activity_history_title => 'Transactions';

  @override
  String get analytics_opt_in => 'Share usage data (optional)';

  @override
  String get analytics_description =>
      'Help improve Mooze by sending PostHog screens visited and action outcomes, with a random identifier and basic app and device information. We do not send your recovery phrase, PIN, addresses, balances or amounts. No screen recording. You can turn this off at any time in Settings.';

  @override
  String get analytics_save_error =>
      'Could not update your usage data preference. Try again.';

  @override
  String get pix_hub_title => 'Pix area';

  @override
  String get pix_hub_demo_badge => 'Demo';

  @override
  String get pix_hub_demo_badge_semantics => 'Demonstration content';

  @override
  String get pix_hub_demo_notice_title => 'Demonstration mode';

  @override
  String get pix_hub_demo_notice_body =>
      'Send, receive, keys, links and history use fictional data. No money leaves your account. Only the wallet deposit uses the real Mooze service.';

  @override
  String get pix_hub_shortcut_send => 'Send';

  @override
  String get pix_hub_shortcut_receive => 'Receive';

  @override
  String get pix_hub_shortcut_deposit => 'Deposit';

  @override
  String get pix_hub_more_operations => 'More operations';

  @override
  String get pix_hub_action_pay_key => 'Pay with a Pix key';

  @override
  String get pix_hub_action_pay_key_subtitle =>
      'Enter a CPF, CNPJ, phone number, email or random key.';

  @override
  String get pix_hub_action_pay_qr => 'Pay with a QR Code';

  @override
  String get pix_hub_action_pay_qr_subtitle =>
      'Use the camera to read the code.';

  @override
  String get pix_hub_action_copy_paste => 'Pix Copy and Paste';

  @override
  String get pix_hub_action_copy_paste_subtitle => 'Paste the charge code.';

  @override
  String get pix_hub_action_links => 'Payment links';

  @override
  String get pix_hub_action_links_subtitle => 'Create and share charges.';

  @override
  String get pix_hub_action_keys => 'My Pix keys';

  @override
  String get pix_hub_action_keys_subtitle => 'View, copy and share your keys.';

  @override
  String get pix_hub_action_history => 'Pix history';

  @override
  String get pix_hub_action_history_subtitle => 'See Pix movements only.';

  @override
  String get pix_hub_recent_recipients => 'Recent recipients';

  @override
  String get pix_hub_view_all => 'View all';

  @override
  String get pix_hub_pending_links => 'Pending charges';

  @override
  String get pix_hub_recent_activity => 'Recent activity';

  @override
  String get pix_hub_manage => 'Manage';

  @override
  String get pix_hub_empty_recipients_title => 'No recent recipients';

  @override
  String get pix_hub_empty_recipients_body =>
      'Recipients appear here after the first payment.';

  @override
  String get pix_hub_empty_links_title => 'No pending charges';

  @override
  String get pix_hub_empty_links_body =>
      'Create a payment link to receive from someone else.';

  @override
  String get pix_hub_empty_transactions_title => 'No Pix movements';

  @override
  String get pix_hub_empty_transactions_body =>
      'Movements appear here after the first operation.';

  @override
  String get pix_hub_empty_keys_title => 'No registered keys';

  @override
  String get pix_hub_empty_keys_body =>
      'Key registration depends on a Pix service that Mooze does not have yet.';

  @override
  String get pix_hub_error_title => 'Loading failed';

  @override
  String get pix_hub_error_body => 'Check the connection and try again.';

  @override
  String get pix_hub_menu_fees => 'View fees';

  @override
  String get pix_hub_menu_empty_preview_on => 'Show empty states';

  @override
  String get pix_hub_menu_empty_preview_off => 'Show demonstration data';

  @override
  String get pix_hub_send_title => 'Send Pix';

  @override
  String get pix_hub_key_input_title => 'What is the Pix key?';

  @override
  String get pix_hub_key_input_hint =>
      'Mooze accepts a CPF, CNPJ, phone number, email and random key. The app checks the format only.';

  @override
  String get pix_hub_key_input_label => 'Pix key';

  @override
  String get pix_hub_key_input_placeholder => 'name@email.com';

  @override
  String pix_hub_key_detected(String type) {
    return 'Format recognised: $type.';
  }

  @override
  String get pix_hub_key_error_empty => 'Enter the Pix key.';

  @override
  String get pix_hub_key_error_unrecognized =>
      'The key does not match any Pix format.';

  @override
  String get pix_hub_key_error_document =>
      'The CPF or CNPJ check digits do not match.';

  @override
  String get pix_hub_key_error_phone =>
      'Enter the phone number with country and area code. Example: +5511999990000.';

  @override
  String get pix_hub_key_error_email => 'The email address is invalid.';

  @override
  String get pix_hub_key_error_random =>
      'A random key has 32 characters and four hyphens.';

  @override
  String get pix_hub_key_type_cpf => 'CPF';

  @override
  String get pix_hub_key_type_cnpj => 'CNPJ';

  @override
  String get pix_hub_key_type_phone => 'Phone';

  @override
  String get pix_hub_key_type_email => 'Email';

  @override
  String get pix_hub_key_type_random => 'Random key';

  @override
  String get pix_hub_code_input_title => 'Paste the Pix code';

  @override
  String get pix_hub_code_input_hint =>
      'Mooze checks the structure and the checksum of the code. That check does not confirm that the charge exists.';

  @override
  String get pix_hub_code_input_placeholder => '00020126...';

  @override
  String get pix_hub_code_paste => 'Paste';

  @override
  String get pix_hub_code_sample => 'Use demonstration code';

  @override
  String get pix_hub_code_read_title => 'Data read from the code';

  @override
  String get pix_hub_code_local_check_warning =>
      'The data comes from the code itself. Mooze did not query any institution.';

  @override
  String get pix_hub_code_clipboard_empty => 'The clipboard is empty.';

  @override
  String get pix_hub_code_copied => 'Code copied.';

  @override
  String get pix_hub_code_error_empty => 'Enter the Pix code.';

  @override
  String get pix_hub_code_error_short => 'The code is too short.';

  @override
  String get pix_hub_code_error_malformed =>
      'The code does not follow the Pix standard.';

  @override
  String get pix_hub_code_error_not_pix => 'The code is not a Pix charge.';

  @override
  String get pix_hub_code_error_checksum =>
      'The checksum of the code does not match.';

  @override
  String get pix_hub_scan_permission_title => 'Camera blocked';

  @override
  String get pix_hub_scan_permission_body =>
      'Allow camera access to read the QR Code.';

  @override
  String get pix_hub_scan_open_settings => 'Open settings';

  @override
  String get pix_hub_scan_unavailable_title => 'Camera unavailable';

  @override
  String get pix_hub_scan_unavailable_body => 'Use Pix Copy and Paste instead.';

  @override
  String get pix_hub_scan_demo_hint =>
      'No camera available? Use the demonstration code to test the flow.';

  @override
  String get pix_hub_amount_title => 'Amount';

  @override
  String get pix_hub_amount_label => 'Pix amount';

  @override
  String get pix_hub_amount_error_empty => 'Enter an amount above zero.';

  @override
  String pix_hub_amount_error_max(String amount) {
    return 'The maximum amount is $amount.';
  }

  @override
  String get pix_hub_amount_fixed_hint =>
      'The code already sets the amount of the charge.';

  @override
  String get pix_hub_description_label => 'Description (optional)';

  @override
  String get pix_hub_description_hint => 'Message for the recipient';

  @override
  String get pix_hub_review_title => 'Review payment';

  @override
  String get pix_hub_review_amount_label => 'You will send';

  @override
  String get pix_hub_review_confirm => 'Confirm and pay';

  @override
  String get pix_hub_review_disclaimer =>
      'When you confirm, your wallet sends the DePix amount to the Pix provider. You cannot undo this transfer.';

  @override
  String get pix_hub_result_title => 'Result';

  @override
  String get pix_hub_result_success_title => 'Payment sent!';

  @override
  String get pix_hub_result_success_body =>
      'The record went into the demonstration history. No money was transferred.';

  @override
  String get pix_hub_result_failure_title => 'Simulated payment declined';

  @override
  String get pix_hub_result_disclaimer =>
      'This screen is a demonstration. It is not proof of a financial transaction.';

  @override
  String get pix_hub_result_try_again => 'Try another amount';

  @override
  String get pix_hub_flow_expired => 'The flow restarted. Start again.';

  @override
  String get pix_hub_back_to_hub => 'Back to Pix';

  @override
  String get pix_hub_summary_recipient => 'To';

  @override
  String get pix_hub_summary_payer => 'From';

  @override
  String get pix_hub_summary_institution => 'Institution';

  @override
  String get pix_hub_summary_document => 'Document';

  @override
  String get pix_hub_summary_method => 'Send method';

  @override
  String get pix_hub_summary_description => 'Description';

  @override
  String get pix_hub_summary_amount => 'Amount';

  @override
  String get pix_hub_summary_date => 'Date';

  @override
  String get pix_hub_summary_reference => 'Reference';

  @override
  String get pix_hub_summary_status => 'Status';

  @override
  String get pix_hub_summary_type => 'Type';

  @override
  String get pix_hub_summary_city => 'City';

  @override
  String get pix_hub_summary_created_at => 'Created on';

  @override
  String get pix_hub_summary_expires_at => 'Expires on';

  @override
  String get pix_hub_method_key => 'Pix key';

  @override
  String get pix_hub_method_qr => 'QR Code';

  @override
  String get pix_hub_method_copy_paste => 'Copy and Paste';

  @override
  String get pix_hub_method_recent => 'Recent recipient';

  @override
  String get pix_hub_receive_title => 'Receive Pix';

  @override
  String get pix_hub_receive_from_others => 'Receive from someone else';

  @override
  String get pix_hub_receive_create_charge => 'Create a charge';

  @override
  String get pix_hub_receive_create_charge_subtitle =>
      'Generate a QR Code and a Copy and Paste code.';

  @override
  String get pix_hub_receive_own_wallet => 'Add money to your wallet';

  @override
  String get pix_hub_receive_deposit_subtitle =>
      'Pay a Pix charge and get the amount in the Mooze wallet.';

  @override
  String get pix_hub_receive_deposit_note =>
      'The deposit uses the real Mooze service and converts reais into the chosen asset. It is not a charge for another person.';

  @override
  String get pix_hub_my_keys => 'My Pix keys';

  @override
  String get pix_hub_keys_unavailable_title =>
      'Registration and deletion unavailable';

  @override
  String get pix_hub_keys_unavailable_body =>
      'Mooze has no service to register or delete Pix keys yet. The keys above are fictional and demonstrate the screen.';

  @override
  String get pix_hub_key_copied => 'Key copied.';

  @override
  String pix_hub_key_share_message(String key) {
    return 'My demonstration Pix key: $key';
  }

  @override
  String get pix_hub_copy => 'Copy';

  @override
  String get pix_hub_share => 'Share';

  @override
  String get pix_hub_value_unavailable => 'Not informed';

  @override
  String get pix_hub_charge_key_label => 'Receiving key';

  @override
  String get pix_hub_charge_open_amount => 'The payer chooses the amount';

  @override
  String get pix_hub_charge_open_amount_hint =>
      'The charge carries no fixed amount.';

  @override
  String get pix_hub_charge_create => 'Generate charge';

  @override
  String pix_hub_charge_error_min(String amount) {
    return 'The minimum amount is $amount.';
  }

  @override
  String get pix_hub_charge_detail_title => 'Charge';

  @override
  String get pix_hub_charge_code_label => 'Copy and Paste code';

  @override
  String pix_hub_charge_share_message(String code) {
    return 'Demonstration Pix charge: $code';
  }

  @override
  String get pix_hub_charge_disclaimer =>
      'The QR Code and the code are demonstration content. No charge was registered with a Pix institution.';

  @override
  String get pix_hub_charge_create_another => 'Create another charge';

  @override
  String get pix_hub_link_create => 'Create link';

  @override
  String get pix_hub_link_reference_label => 'Reference';

  @override
  String get pix_hub_link_reference_hint => 'March subscription';

  @override
  String get pix_hub_link_reference_error => 'Enter a reference.';

  @override
  String pix_hub_link_amount_error(String min, String max) {
    return 'The amount must stay between $min and $max.';
  }

  @override
  String get pix_hub_link_single_use => 'Single use';

  @override
  String get pix_hub_link_single_use_hint =>
      'The link accepts one payment and closes.';

  @override
  String get pix_hub_link_reusable => 'Reusable';

  @override
  String get pix_hub_link_usage_label => 'Usage';

  @override
  String get pix_hub_link_review => 'Review link';

  @override
  String get pix_hub_link_confirm => 'Generate link';

  @override
  String get pix_hub_link_detail_title => 'Payment link';

  @override
  String get pix_hub_link_url_label => 'Link address';

  @override
  String get pix_hub_link_copied => 'Link copied.';

  @override
  String pix_hub_link_share_message(String url) {
    return 'Demonstration payment link: $url';
  }

  @override
  String get pix_hub_link_paid_at => 'Paid on';

  @override
  String get pix_hub_link_open_amount => 'Open amount';

  @override
  String get pix_hub_link_status_pending => 'Pending';

  @override
  String get pix_hub_link_status_paid => 'Paid';

  @override
  String get pix_hub_link_status_expired => 'Expired';

  @override
  String get pix_hub_link_disclaimer =>
      'The address is fictional and does not open a real checkout page.';

  @override
  String get pix_hub_history_filter_all => 'All';

  @override
  String get pix_hub_history_filter_sent => 'Sent';

  @override
  String get pix_hub_history_filter_received => 'Received';

  @override
  String get pix_hub_history_note =>
      'The list shows fictional Pix movements only. Wallet transactions stay in the wallet history.';

  @override
  String get pix_hub_tx_kind_sent => 'Pix sent';

  @override
  String get pix_hub_tx_kind_received => 'Pix received';

  @override
  String get pix_hub_tx_kind_deposit => 'Wallet deposit';

  @override
  String get pix_hub_tx_kind_payment_link => 'Payment link';

  @override
  String get pix_hub_tx_status_completed => 'Completed';

  @override
  String get pix_hub_tx_status_pending => 'Processing';

  @override
  String get pix_hub_tx_status_failed => 'Failed';

  @override
  String get pix_hub_tx_detail_title => 'Movement details';

  @override
  String get pix_hub_tx_detail_disclaimer =>
      'This record is fictional. It is not a payment receipt.';

  @override
  String get pix_hub_failure_load => 'The data could not be loaded.';

  @override
  String get pix_hub_failure_declined =>
      'The simulation declined the payment. The demonstration balance is R\$ 2,500.00.';

  @override
  String get pix_hub_failure_recipient => 'No recipient matches this data.';

  @override
  String get pix_hub_failure_amount =>
      'The amount is outside the accepted range.';

  @override
  String get pix_hub_failure_unknown => 'Something went wrong. Try again.';

  @override
  String get pix_hub_failure_network =>
      'No connection to the server. Check your internet and try again.';

  @override
  String get pix_hub_failure_session =>
      'We could not validate your session. Try again.';

  @override
  String get pix_hub_failure_not_eligible =>
      'Your account cannot create payment links yet. Level up to unlock this feature.';

  @override
  String get pix_hub_failure_rate_limited =>
      'Too many attempts. Wait a moment and try again.';

  @override
  String get pix_hub_failure_unavailable =>
      'The service is unavailable right now. Try again later.';

  @override
  String get pix_hub_failure_invalid_response =>
      'The server answered without the payment link. Try again.';

  @override
  String get pix_hub_failure_wallet =>
      'We could not get an address from your wallet. Try again.';

  @override
  String get pix_hub_subtitle =>
      'Send, receive and manage your payments through Pix.';

  @override
  String get pix_hub_other_operations => 'Other operations';

  @override
  String get pix_hub_action_pending => 'Pending payment requests';

  @override
  String get pix_hub_action_pending_subtitle => 'View and remove open charges.';

  @override
  String get pix_hub_action_other_transactions => 'Other transactions';

  @override
  String get pix_hub_action_other_transactions_subtitle =>
      'Pix histories, links and fees.';

  @override
  String get pix_hub_info_title => 'How Pix works';

  @override
  String get pix_hub_info_send_title => 'Send and receive';

  @override
  String get pix_hub_info_send_body =>
      'Sending a Pix uses your DePix balance. The Pix provider pays the recipient, and the Liquid network fee is paid in L-BTC. Charges, keys and links still use fictional data.';

  @override
  String get pix_hub_info_deposit_title => 'Wallet deposit';

  @override
  String get pix_hub_info_deposit_body =>
      'The deposit uses the real Mooze service. The amount in reais becomes the asset you choose in the wallet.';

  @override
  String get pix_hub_send_method_question => 'How do you want to send?';

  @override
  String get pix_hub_send_method_qr_description =>
      'Scan the code of the recipient.';

  @override
  String get pix_hub_send_method_code_description => 'Paste the Pix code.';

  @override
  String get pix_hub_send_method_recent_description =>
      'People you already paid.';

  @override
  String get pix_hub_key_type_label => 'Key type';

  @override
  String get pix_hub_key_hint_cpf => '000.000.000-00';

  @override
  String get pix_hub_key_hint_cnpj => '00.000.000/0000-00';

  @override
  String get pix_hub_key_hint_phone => 'e.g. 11 98765-4321';

  @override
  String get pix_hub_key_hint_email => 'name@email.com';

  @override
  String get pix_hub_key_hint_random => '00000000-0000-0000-0000-000000000000';

  @override
  String get pix_hub_summary_payment_method => 'Payment method';

  @override
  String get pix_hub_review_edit => 'Change details';

  @override
  String pix_hub_review_key_chip(String type) {
    return 'Pix key ($type)';
  }

  @override
  String pix_hub_result_to(String name) {
    return 'To $name';
  }

  @override
  String get pix_hub_result_datetime => 'Date and time';

  @override
  String get pix_hub_result_details => 'View details';

  @override
  String get pix_hub_deposit_gate_title => 'Before you deposit';

  @override
  String get pix_hub_deposit_gate_subtitle =>
      'Enter the CPF of the bank account that will pay and confirm the notice below.';

  @override
  String get pix_hub_deposit_cpf_hint =>
      'Mooze checks the format and the check digits. The app does not confirm who owns the bank account.';

  @override
  String get pix_hub_deposit_notice_title => 'Important';

  @override
  String get pix_hub_deposit_notice_body =>
      'To make deposits via Pix, you must use a bank account in your own name, registered under the same CPF as the one registered with Mooze. Do not use bank accounts belonging to third parties.';

  @override
  String get pix_hub_deposit_notice_ack => 'I read and understood the notice.';

  @override
  String get pix_hub_deposit_notice_screen_title => 'Deposit notice';

  @override
  String get pix_hub_deposit_cpf_stored_label => 'CPF informed';

  @override
  String get pix_hub_deposit_cpf_missing => 'No CPF informed.';

  @override
  String get pix_hub_deposit_change_cpf => 'Change CPF';

  @override
  String get pix_hub_pending_deposits => 'Deposits in progress';

  @override
  String get pix_hub_pending_deposits_empty_title => 'No deposit in progress';

  @override
  String get pix_hub_pending_deposits_empty_body =>
      'Deposits waiting for payment appear here.';

  @override
  String get pix_hub_pending_deposits_note =>
      'Mooze does not cancel a deposit in progress. The charge stops being valid when it expires.';

  @override
  String get pix_hub_pending_links_section => 'Payment links';

  @override
  String get pix_hub_pending_remove_title => 'Remove link?';

  @override
  String pix_hub_pending_remove_body(String reference) {
    return 'The link \"$reference\" leaves the demonstration list.';
  }

  @override
  String get pix_hub_pending_remove_confirm => 'Remove';

  @override
  String get pix_hub_pending_removed => 'Link removed.';

  @override
  String get pix_hub_other_section_history => 'Histories';

  @override
  String get pix_hub_other_deposit_history => 'Deposit history';

  @override
  String get pix_hub_other_deposit_history_subtitle =>
      'Your real Pix deposits.';

  @override
  String get pix_hub_other_section_tools => 'Tools';

  @override
  String get pix_hub_other_recipients_subtitle => 'People you already paid.';

  @override
  String get pix_hub_other_fees_subtitle => 'See the applied fees.';

  @override
  String get pix_hub_preferences => 'Preferences';

  @override
  String get pix_hub_preferences_limits => 'My limits';

  @override
  String get pix_hub_preferences_limits_subtitle =>
      'See the Pix limits of your account.';

  @override
  String get pix_hub_preferences_level => 'My level';

  @override
  String get pix_hub_preferences_level_subtitle =>
      'See your current level and how to raise it.';

  @override
  String get pix_hub_limits_subtitle =>
      'The values below come from your Mooze account.';

  @override
  String get pix_hub_limits_how_it_works => 'How the limits work';

  @override
  String get pix_hub_shortcut_receive_description =>
      'Share your key or generate a QR Code';

  @override
  String get pix_hub_failure_invalid_request =>
      'The server refused the data. Check the key, the CPF/CNPJ and the amount.';

  @override
  String get pix_hub_failure_limit_exceeded =>
      'The amount is above your current limit, or your account cannot send Pix yet.';

  @override
  String get pix_hub_failure_provider_refused =>
      'The Pix provider refused the transfer. Check that the key belongs to the CPF/CNPJ you entered.';

  @override
  String get pix_hub_failure_outcome_unknown =>
      'The service did not confirm the request. No funds left your wallet. Try again in a few minutes.';

  @override
  String get pix_hub_failure_quote_mismatch =>
      'The quote does not match the request. No funds were sent. Try again.';

  @override
  String get pix_hub_failure_quote_expired =>
      'The quote expired. Get a new quote to continue.';

  @override
  String get pix_hub_failure_insufficient_funds =>
      'Your DePix balance does not cover this transfer and its fee.';

  @override
  String get pix_hub_failure_insufficient_fee_asset =>
      'You need L-BTC to pay the Liquid network fee.';

  @override
  String get pix_hub_failure_funding_failed =>
      'The wallet could not build the DePix transfer. No funds left your wallet.';

  @override
  String get pix_hub_failure_unsupported_code =>
      'This code has no Pix key. Mooze pays codes that carry a key only.';

  @override
  String get pix_hub_tax_id_label => 'CPF or CNPJ of the key owner';

  @override
  String get pix_hub_tax_id_hint => '000.000.000-00';

  @override
  String get pix_hub_tax_id_help =>
      'The Pix provider checks that the key belongs to this document. Mooze does not store the number.';

  @override
  String get pix_hub_tax_id_error_empty => 'Enter the CPF or CNPJ.';

  @override
  String get pix_hub_tax_id_error_invalid => 'Invalid CPF or CNPJ.';

  @override
  String pix_hub_amount_error_min(String amount) {
    return 'The minimum amount is $amount.';
  }

  @override
  String get pix_hub_amount_error_balance =>
      'Your DePix balance does not cover this amount.';

  @override
  String pix_hub_amount_balance(String amount) {
    return 'Available balance: $amount';
  }

  @override
  String get pix_hub_amount_fee_hint =>
      'The Pix provider fee shows on the review and adds to the DePix amount.';

  @override
  String get pix_hub_summary_code_name => 'Name in the code';

  @override
  String get pix_hub_code_no_key => 'No Pix key (dynamic code)';

  @override
  String get pix_hub_review_receives => 'The recipient receives';

  @override
  String get pix_hub_review_provider_fee => 'Pix provider fee';

  @override
  String get pix_hub_review_depix_debit => 'Leaves your wallet';

  @override
  String get pix_hub_review_network_fee => 'Liquid network fee';

  @override
  String pix_hub_review_network_fee_value(String amount) {
    return '$amount sats (L-BTC)';
  }

  @override
  String get pix_hub_review_owner_document => 'Key owner document';

  @override
  String pix_hub_review_deadline(String time) {
    return 'Pay before $time';
  }

  @override
  String pix_hub_review_time_left(String time) {
    return '$time left';
  }

  @override
  String get pix_hub_review_expired => 'This quote expired.';

  @override
  String get pix_hub_review_new_quote => 'Get a new quote';

  @override
  String get pix_hub_result_processing_title => 'Pix in progress';

  @override
  String get pix_hub_result_processing_body =>
      'Your DePix was sent. The Pix provider is processing the transfer. This can take a few minutes.';

  @override
  String get pix_hub_result_completed_title => 'Pix delivered';

  @override
  String get pix_hub_result_completed_body =>
      'The Pix provider confirmed the payment to the recipient.';

  @override
  String get pix_hub_result_failed_title => 'Pix not completed';

  @override
  String get pix_hub_result_refunded_body =>
      'The provider returned the deposit to your refund address.';

  @override
  String get pix_hub_result_failed_body =>
      'The provider closed the request without paying the Pix. If the DePix does not return to your wallet, contact support with the request ID.';

  @override
  String get pix_hub_result_unknown_title => 'Result not confirmed';

  @override
  String get pix_hub_result_unknown_body =>
      'We could not confirm that the DePix transfer reached the network. Do not pay again. Follow the status below.';

  @override
  String get pix_hub_result_polling_stopped =>
      'The status has not changed yet. Refresh later.';

  @override
  String get pix_hub_result_status_error =>
      'The status could not be refreshed.';

  @override
  String get pix_hub_result_refresh => 'Refresh status';

  @override
  String get pix_hub_result_receipt => 'Open receipt';

  @override
  String get pix_hub_result_copy_id => 'Copy request ID';

  @override
  String get pix_hub_result_id_copied => 'ID copied.';

  @override
  String get pix_hub_summary_withdrawal_id => 'Request ID';

  @override
  String get pix_hub_summary_funding_txid => 'Liquid transaction';

  @override
  String get pix_hub_summary_end_to_end => 'End-to-end ID';

  @override
  String get pix_hub_summary_refund => 'Amount returned';

  @override
  String get pix_hub_withdrawal_status_checking => 'Checking…';

  @override
  String get pix_hub_withdrawal_status_creating => 'Creating';

  @override
  String get pix_hub_withdrawal_status_rejected => 'Rejected';

  @override
  String get pix_hub_withdrawal_status_uncertain => 'Being checked';

  @override
  String get pix_hub_withdrawal_status_unsent => 'Waiting for the deposit';

  @override
  String get pix_hub_withdrawal_status_sending => 'Sending the Pix';

  @override
  String get pix_hub_withdrawal_status_sent => 'Pix delivered';

  @override
  String get pix_hub_withdrawal_status_error => 'Provider error';

  @override
  String get pix_hub_withdrawal_status_canceled => 'Canceled';

  @override
  String get pix_hub_withdrawal_status_refunded => 'Refunded';

  @override
  String get pix_hub_withdrawal_status_replaced => 'Replaced';

  @override
  String get pix_hub_withdrawal_status_unknown => 'Unknown';

  @override
  String get pix_hub_pending_withdrawals_title => 'Pix in progress';

  @override
  String pix_hub_pending_withdrawal_item(String amount, String key) {
    return '$amount to $key';
  }

  @override
  String get pix_hub_pending_withdrawal_hint => 'Tap to see the status.';

  @override
  String get pix_hub_send_key_title => 'Who do you want to send to?';

  @override
  String get pix_hub_send_key_label => 'Enter the details of who receives';

  @override
  String get pix_hub_send_key_hint => 'CPF/CNPJ, phone, email or Pix key';

  @override
  String get pix_hub_send_key_scan => 'Scan QR Code';

  @override
  String get pix_hub_send_key_clear => 'Clear';

  @override
  String get pix_hub_send_key_code_detected =>
      'Pix Copy and Paste code recognised.';

  @override
  String get pix_hub_send_key_ambiguous => 'Is this number a CPF or a phone?';

  @override
  String get pix_hub_amount_question => 'How much do you want to send?';

  @override
  String get pix_hub_tax_id_valid => 'Valid document';
}
