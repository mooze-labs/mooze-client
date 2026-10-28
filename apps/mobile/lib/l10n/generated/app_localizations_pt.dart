// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get common_back => 'Voltar';

  @override
  String get common_cancel => 'Cancelar';

  @override
  String get common_confirm => 'Confirmar';

  @override
  String get common_save => 'Salvar';

  @override
  String get common_close => 'Fechar';

  @override
  String get common_continue => 'Continuar';

  @override
  String get common_next => 'Próximo';

  @override
  String get common_ok => 'OK';

  @override
  String get common_retry => 'Tentar novamente';

  @override
  String get common_loading => 'Carregando...';

  @override
  String get common_processing => 'Processando...';

  @override
  String get common_sending => 'Enviando...';

  @override
  String get common_confirming => 'Confirmando...';

  @override
  String get common_verifying => 'Verificando...';

  @override
  String get common_understood => 'Entendi';

  @override
  String get common_no_thanks => 'Não, obrigado';

  @override
  String get common_max => 'MAX';

  @override
  String get common_yes => 'Sim';

  @override
  String get common_no => 'Não';

  @override
  String get common_finish => 'Concluir';

  @override
  String get common_redo => 'Refazer';

  @override
  String get nav_home => 'Início';

  @override
  String get nav_menu => 'Menu';

  @override
  String get nav_pix => 'Pix';

  @override
  String get onboarding_get_started => 'Começar';

  @override
  String get pix_send_confirm_title => 'Confirmar pagamento';

  @override
  String get pix_send_error_title => 'Erro no pagamento';

  @override
  String get pix_send_processing_payment => 'Processando pagamento...';

  @override
  String get common_taking_longer =>
      'Está demorando mais que o normal. Verifique sua conexão.';

  @override
  String get error_something_went_wrong => 'Algo deu errado. Tente novamente.';

  @override
  String get send_clipboard_address_found => 'Endereço copiado detectado';

  @override
  String get send_clipboard_use => 'Usar';

  @override
  String get pix_clipboard_key_found => 'Chave PIX copiada detectada';

  @override
  String get deeplink_invalid_payment => 'Link de pagamento inválido';

  @override
  String get error_open_link => 'Não foi possível abrir o link';

  @override
  String get error_opening_link => 'Erro ao abrir o link';

  @override
  String get error_open_browser => 'Não foi possível abrir o navegador.';

  @override
  String error_unexpected(String error) {
    return 'Erro inesperado: $error';
  }

  @override
  String error_generic(String error) {
    return 'Erro: $error';
  }

  @override
  String get error_load_data => 'Erro ao carregar dados. Tente novamente.';

  @override
  String get error_load_data_short => 'Erro ao carregar dados';

  @override
  String get error_load_data_title => 'Erro ao Carregar Dados';

  @override
  String get error_no_internet =>
      'Sem conexão com a internet. Verifique sua conexão.';

  @override
  String get error_server_unavailable =>
      'Servidor temporariamente indisponível. Tente novamente.';

  @override
  String get error_server_communication =>
      'Erro de comunicação com o servidor. Tente novamente.';

  @override
  String get error_authentication_failed => 'Não foi possível autenticar.';

  @override
  String get error_access_denied => 'Acesso negado. Verifique suas permissões.';

  @override
  String get error_service_not_found =>
      'Serviço não encontrado. Tente novamente mais tarde.';

  @override
  String get settings_title => 'Configurações';

  @override
  String get settings_section_security => 'SEGURANÇA';

  @override
  String get settings_section_appearance => 'APARÊNCIA';

  @override
  String get settings_section_language => 'IDIOMA';

  @override
  String get settings_section_currency => 'MOEDA';

  @override
  String get settings_section_account => 'CONTA E BENEFÍCIOS';

  @override
  String get settings_section_legal => 'LEGAL';

  @override
  String get settings_section_developer => 'DESENVOLVEDOR';

  @override
  String get settings_section_help => 'AJUDA';

  @override
  String get settings_view_recovery_phrase => 'Ver frase de recuperação';

  @override
  String get settings_change_pin => 'Mudar PIN';

  @override
  String get settings_biometric_auth => 'Autenticação biométrica';

  @override
  String get settings_security => 'Segurança';

  @override
  String get security_session_lock_title => 'Usar bloqueio por Biometria/PIN';

  @override
  String get security_session_lock_subtitle =>
      'Exigir autenticação após um período de inatividade';

  @override
  String get security_privacy_shield_title => 'Proteger o alternador de apps';

  @override
  String get security_privacy_shield_subtitle =>
      'Ocultar o conteúdo da carteira no alternador de apps';

  @override
  String get security_lock_after => 'Bloquear após';

  @override
  String get security_timeout_immediate => 'Imediatamente';

  @override
  String get security_timeout_15s => '15 segundos';

  @override
  String get security_timeout_30s => '30 segundos';

  @override
  String get security_timeout_1m => '1 minuto';

  @override
  String get security_timeout_5m => '5 minutos';

  @override
  String get privacy_shield_locked_title => 'Aplicativo bloqueado';

  @override
  String get privacy_shield_locked_subtitle => 'Autentique-se para continuar';

  @override
  String get settings_delete_wallet => 'Deletar carteira';

  @override
  String get settings_theme => 'Tema';

  @override
  String get settings_language => 'Idioma';

  @override
  String get settings_change_currency => 'Alterar moeda';

  @override
  String get settings_referral_code => 'Cupom de indicação';

  @override
  String get settings_terms => 'Termos de uso';

  @override
  String get settings_license => 'Licença GPL';

  @override
  String get settings_logs => 'Logs';

  @override
  String get settings_log_details => 'Detalhes do log';

  @override
  String get settings_contact_support => 'Contatar suporte';

  @override
  String get settings_section_network => 'REDE';

  @override
  String get settings_node_config => 'Configuração de nodes';

  @override
  String get node_config_title => 'Configuração de nodes';

  @override
  String get node_config_section_mode => 'MODO';

  @override
  String get node_config_section_custom => 'ENDPOINTS';

  @override
  String get node_config_section_advanced => 'AVANÇADO';

  @override
  String get node_config_mode_default_title => 'Modo padrão';

  @override
  String get node_config_mode_default_subtitle =>
      'Usa os servidores recomendados pelo sistema, com fallback automático entre Bitcoin, Liquid e Lightning.';

  @override
  String get node_config_mode_custom_title => 'Modo personalizado';

  @override
  String get node_config_mode_custom_subtitle =>
      'Avançado — conecte-se aos seus próprios servidores Electrum.';

  @override
  String get node_config_advanced_warning =>
      'Configure apenas se você sabe o que está fazendo. URLs inválidas podem impedir o app de sincronizar.';

  @override
  String get node_config_bitcoin_label => 'Endpoint Bitcoin Mainnet';

  @override
  String get node_config_bitcoin_hint => 'ssl://seu-node.tld:50002';

  @override
  String get node_config_bitcoin_helper =>
      'Formato: esquema://host:porta. Use ssl:// para conexões criptografadas. Deixe vazio para usar o node padrão.';

  @override
  String get node_config_liquid_label => 'Endpoint Liquid Network';

  @override
  String get node_config_liquid_hint => 'seu-node.tld:50002';

  @override
  String get node_config_liquid_helper =>
      'Formato: host:porta. O LWK usa TLS automaticamente. Deixe vazio para usar o node padrão.';

  @override
  String get node_config_lightning_note =>
      'O node Lightning é gerenciado automaticamente pelo Breez SDK e não pode ser personalizado.';

  @override
  String get node_config_fallback_toggle_title =>
      'Permitir fallback automático';

  @override
  String get node_config_fallback_toggle_subtitle =>
      'Se o seu node falhar, o app tenta automaticamente os servidores padrão.';

  @override
  String get node_config_save => 'Salvar configurações';

  @override
  String get node_config_url_required => 'Obrigatório no modo personalizado';

  @override
  String get node_config_url_invalid =>
      'Use o formato host:porta (ou esquema://host:porta)';

  @override
  String get node_config_at_least_one =>
      'Configure ao menos um endpoint, ou volte ao modo padrão.';

  @override
  String get node_config_unsaved_title => 'Alterações não salvas';

  @override
  String get node_config_unsaved_message =>
      'Você tem alterações que ainda não foram salvas. Deseja salvá-las antes de sair?';

  @override
  String get node_config_unsaved_discard => 'Descartar';

  @override
  String get node_config_save_success => 'Configurações de node salvas';

  @override
  String node_config_save_error(String error) {
    return 'Falha ao salvar: $error';
  }

  @override
  String get node_config_load_error =>
      'Não foi possível carregar as configurações de node';

  @override
  String get support_telegram_open_error => 'Não foi possível abrir o Telegram';

  @override
  String get support_screen_title => 'Central de Suporte';

  @override
  String get support_help_title => 'Como podemos ajudar?';

  @override
  String get support_help_subtitle =>
      'Para um atendimento mais eficiente, compartilhe o código abaixo com nosso suporte.';

  @override
  String get support_user_code_label => 'Seu código de identificação';

  @override
  String get support_user_code_load_error_title =>
      'Não foi possível carregar seu código';

  @override
  String get support_user_code_load_error_msg =>
      'Ocorreu um erro ao carregar suas informações';

  @override
  String get support_user_code_not_found => 'Não encontramos suas informações';

  @override
  String get support_contact_button => 'Falar com o suporte';

  @override
  String get biometric_auth_reason =>
      'Confirme sua identidade para ativar a autenticação biométrica';

  @override
  String get biometric_enabled_success => 'Autenticação biométrica ativada.';

  @override
  String get biometric_disabled_info => 'Autenticação biométrica desativada.';

  @override
  String get biometric_disable_error => 'Erro ao desativar biometria.';

  @override
  String get biometric_save_error => 'Erro ao salvar configuração.';

  @override
  String biometric_auth_error(String error) {
    return '$error';
  }

  @override
  String get biometric_setup_enable_q => 'Ativar biometria?';

  @override
  String get biometric_setup_explanation =>
      'Use Face ID, impressão digital ou a senha do dispositivo para acessar sua carteira com mais rapidez e segurança.';

  @override
  String get biometric_setup_enable => 'Ativar biometria';

  @override
  String seed_fetch_error(String error) {
    return 'Erro: $error';
  }

  @override
  String get seed_not_found => 'Nenhuma seed encontrada.';

  @override
  String get seed_screen_title => 'Frase de Recuperação';

  @override
  String get seed_words_of => 'Palavras de ';

  @override
  String get seed_recovery_word => 'Recuperação';

  @override
  String get seed_save_warning =>
      'Anote estas palavras em um local seguro. Elas são a única forma de recuperar sua carteira.';

  @override
  String get screenshot_blocked_title => 'Captura de tela bloqueada';

  @override
  String get screenshot_blocked_message =>
      'Esta tela contém informações sensíveis da sua carteira e não pode ser capturada.';

  @override
  String get screenshot_blocked_warning =>
      'Para sua segurança, nunca tire capturas de tela da sua frase de recuperação (seed phrase). Qualquer pessoa com acesso à sua frase de recuperação pode obter controle total da sua carteira.';

  @override
  String get screenshot_blocked_acknowledge => 'Entendi';

  @override
  String get seed_copy => 'Copiar seed';

  @override
  String get seed_copied => 'Copiado';

  @override
  String get seed_confirm_phrase => 'Confirmar frase';

  @override
  String seed_confirmed_words_count(int count) {
    return 'Palavras confirmadas ($count)';
  }

  @override
  String get seed_remove_last => 'Remover última';

  @override
  String get pin_confirm_title => 'Confirmar PIN';

  @override
  String get pin_confirm_yours => 'Confirme seu ';

  @override
  String get pin_word => 'PIN';

  @override
  String get pin_confirm_instruction_1 => 'Digite novamente o ';

  @override
  String get pin_confirm_instruction_2 => 'PIN ';

  @override
  String get pin_confirm_instruction_3 => 'que você acabou de criar.';

  @override
  String get pin_mismatch => 'PINs não coincidem';

  @override
  String get pin_validate_title => 'Validar PIN';

  @override
  String get pin_validate_security => 'Validação de segurança';

  @override
  String get pin_validate_action => 'Validar ';

  @override
  String get pin_validate_body =>
      'Digite seu PIN para continuar com segurança.';

  @override
  String get pin_incorrect => 'PIN incorreto. Tente novamente.';

  @override
  String get pin_use_biometric => 'Usar biometria';

  @override
  String get pin_use_pin => 'Usar PIN';

  @override
  String get pin_use_device_password => 'Use a senha do dispositivo';

  @override
  String get pin_forgot => 'Esqueceu seu PIN?';

  @override
  String get pin_biometric_unavailable =>
      'Biometria ou senha do sistema não disponível.';

  @override
  String get pin_biometric_access_reason =>
      'Use sua biometria para acessar sua carteira';

  @override
  String get pin_reset_biometric_reason =>
      'Use sua biometria ou senha do dispositivo para redefinir o PIN';

  @override
  String get theme_system => 'Sistema';

  @override
  String get theme_light => 'Claro';

  @override
  String get theme_dark => 'Escuro';

  @override
  String get language_portuguese => 'Português';

  @override
  String get language_english => 'Inglês';

  @override
  String get language_spanish => 'Espanhol';

  @override
  String get language_system => 'Idioma do dispositivo';

  @override
  String get delete_wallet_title => 'Deletar carteira';

  @override
  String get delete_wallet_warning_title => 'Atenção ao deletar sua ';

  @override
  String get delete_wallet_word => 'carteira';

  @override
  String get delete_wallet_warning_subtitle =>
      'Ao deletar, será necessário passar novamente pelo sistema TRUST e você perderá acesso aos fundos se não tiver salvo sua frase de recuperação.';

  @override
  String get delete_wallet_pix_limits_title => 'Limites PIX';

  @override
  String get delete_wallet_pix_limits_desc =>
      'Eu estou ciente de que precisarei passar novamente pelo sistema TRUST e que meus limites de PIX serão resetados.';

  @override
  String get delete_wallet_funds_loss_title => 'Perda de fundos';

  @override
  String get delete_wallet_funds_loss_desc =>
      'Eu estou ciente que perderei acesso aos meus fundos caso não tenha guardado minha frase de recuperação.';

  @override
  String get delete_wallet_button => 'Deletar carteira';

  @override
  String get delete_wallet_error =>
      'Erro ao deletar carteira. Tente novamente.';

  @override
  String get referral_title => 'Código de Indicação';

  @override
  String get referral_applied_success => 'Código aplicado com sucesso!';

  @override
  String get referral_error_empty_code => 'Código não pode ser vazio.';

  @override
  String get referral_error_invalid_code =>
      'Código inválido. Verifique e tente novamente.';

  @override
  String get referral_error_apply_failed =>
      'Erro ao adicionar código. Tente novamente.';

  @override
  String get referral_error_fetch_failed =>
      'Erro ao buscar código de indicação.';

  @override
  String get referral_error_validate_failed => 'Erro ao validar código.';

  @override
  String get license_title => 'Licença GPL v3';

  @override
  String get license_subtitle => 'GNU General Public License';

  @override
  String get license_version_line =>
      'Versão 3, 29 de junho de 2007 • Free Software Foundation';

  @override
  String get license_copyleft_title => 'Copyleft License';

  @override
  String get license_copyleft_desc =>
      'Esta licença garante que o software permaneça livre. Qualquer distribuição deve incluir o código-fonte.';

  @override
  String get license_free_software_title => 'Software Livre';

  @override
  String get license_free_software_subtitle => 'Liberdade garantida';

  @override
  String get license_redistributable_title => 'Redistribuível';

  @override
  String get license_redistributable_subtitle => 'Com código-fonte';

  @override
  String get license_copyleft_short_title => 'Copyleft';

  @override
  String get license_copyleft_short_subtitle => 'Derivados livres';

  @override
  String get license_copyright_line =>
      'Copyright © 2007 Free Software Foundation, Inc.';

  @override
  String get license_fsf_link => 'Free Software Foundation';

  @override
  String get license_full_link => 'Licença Completa';

  @override
  String get license_section_preamble => 'Preâmbulo';

  @override
  String get license_section_definitions => 'Definições';

  @override
  String get license_section_source => 'Código-fonte';

  @override
  String get license_section_basic_perms => 'Permissões Básicas';

  @override
  String get license_section_legal_rights =>
      'Protegendo os Direitos Legais dos Usuários';

  @override
  String get license_section_verbatim => 'Transmitindo Cópias Literais';

  @override
  String get license_section_modified =>
      'Transmitindo Versões Modificadas dos Fontes';

  @override
  String get license_section_non_source => 'Transmitindo Formas Não Fonte';

  @override
  String get license_section_additional => 'Termos Adicionais';

  @override
  String get license_section_termination => 'Terminação';

  @override
  String get license_section_acceptance =>
      'Aceitação Não Exigida para Ter Cópias';

  @override
  String get license_section_downstream =>
      'Licenciamento Automático de Destinatários Downstream';

  @override
  String get license_section_patents => 'Patentes';

  @override
  String get license_section_no_surrender =>
      'Não Entregar a Liberdade dos Outros';

  @override
  String get license_section_agpl =>
      'Uso com a Licença Pública Geral Affero GNU';

  @override
  String get license_section_revisions => 'Versões Revisadas desta Licença';

  @override
  String get license_section_warranty => 'Aviso Legal de Garantia';

  @override
  String get license_section_liability => 'Limitação de Responsabilidade';

  @override
  String get license_section_interpretation =>
      'Interpretação das Seções 15 e 16';

  @override
  String get license_section_preamble_body =>
      'A Licença Pública Geral GNU é uma licença livre, com copyleft, para softwares e outros tipos de trabalhos.\n\nAs licenças para a maioria dos softwares e outros trabalhos práticos são projetadas para tirar sua liberdade de compartilhar e alterar os trabalhos. Em contrapartida, a Licença Pública Geral GNU destina-se a garantir a sua liberdade de compartilhar e alterar todas as versões de um programa, para se certificar de que permaneça como software livre para todos os seus usuários.\n\nQuando falamos de software livre, estamos nos referindo à liberdade, não ao preço. Nossas Licenças Públicas Gerais são projetadas para garantir que você tenha a liberdade de distribuir cópias de software livre, que você receba o código-fonte ou possa obtê-lo, que você possa mudar o software ou usar partes dele em novos programas livres e que você saiba que pode fazer essas coisas.';

  @override
  String get license_section_definitions_body =>
      'Esta Licença refere-se à versão 3 da Licença Pública Geral GNU.\n\nCopyright também significa leis do tipo direito autoral que se aplicam a outros tipos de trabalhos, tal como máscaras de semicondutores.\n\nO Programa refere-se a qualquer trabalho com direito autoral licenciado sob esta Licença. Cada licenciado é endereçado como você. Licenciados e destinatários podem ser indivíduos ou organizações.\n\nModificar um trabalho significa copiar ou adaptar tudo ou parte do trabalho de uma forma a ser necessário ter permissão de direitos autorais, além da criação de uma cópia exata.';

  @override
  String get license_section_source_body =>
      'O código-fonte para um trabalho significa a forma preferida do trabalho para fazer modificações nele. Código objeto significa qualquer forma não fonte de um trabalho.\n\nUma Interface Padrão significa uma interface que seja um padrão oficial definido por um corpo de padrões reconhecido ou, no caso de interfaces especificadas para uma linguagem de programação específica, que seja amplamente utilizada entre desenvolvedores que trabalham naquela linguagem.';

  @override
  String get license_section_basic_perms_body =>
      'Todos os direitos concedidos sob esta Licença são concedidos para o termo de direito autoral sobre o Programa e são irrevogáveis desde que as condições estabelecidas sejam atendidas. Esta Licença afirma explicitamente a sua permissão ilimitada para executar o Programa não modificado.\n\nVocê pode fazer, executar e propagar trabalhos cobertos que você não transmite, sem condições, desde que sua licença permaneça em vigor.';

  @override
  String get license_section_legal_rights_body =>
      'Nenhum trabalho coberto deve ser considerado parte de uma medida tecnológica efetiva sob qualquer lei aplicável que cumpra as obrigações previstas no artigo 11 do tratado de direitos autorais da OMPI.\n\nQuando você transmite um trabalho coberto, você renuncia a qualquer poder legal para proibir a evasão de medidas tecnológicas.';

  @override
  String get license_section_verbatim_body =>
      'Você pode transmitir cópias literais do código-fonte do Programa na medida que você o recebe, em qualquer meio, desde que você publique de forma consistente e apropriada em cada cópia um aviso de direitos autorais apropriado.\n\nVocê pode cobrar qualquer preço ou nenhum preço por cada cópia que você transmite, e você pode oferecer proteção de suporte ou garantia por uma taxa.';

  @override
  String get license_section_modified_body =>
      'Você pode transmitir um trabalho baseado no Programa, ou as modificações para produzi-lo a partir do Programa, na forma de código-fonte sob os termos da seção 4, desde que você também atenda a todas essas condições:\n\na) O trabalho deve levar avisos proeminentes afirmando que você o modificou e dando uma data relevante.\nb) O trabalho deve levar avisos proeminentes afirmando que ele está lançado sob esta Licença.';

  @override
  String get license_section_non_source_body =>
      'Você pode transmitir um trabalho coberto na forma de código objeto nos termos das seções 4 e 5, desde que você também transmita o Fonte Correspondente legível por máquina sob os termos desta Licença.\n\nO Fonte Correspondente pode estar em um servidor diferente (operado por você ou um terceiro) que suporte instalações de cópia equivalentes.';

  @override
  String get license_section_additional_body =>
      'Permissões adicionais são termos que complementam os termos desta Licença fazendo exceções de uma ou mais de suas condições. As permissões adicionais que são aplicáveis a todo o Programa devem ser tratadas como se estivessem incluídas nesta Licença.\n\nVocê pode colocar permissões adicionais em material, adicionado por você a um trabalho coberto, para o qual você tenha ou possa dar permissão de direitos autorais apropriados.';

  @override
  String get license_section_termination_body =>
      'Você não pode propagar ou modificar um trabalho coberto, exceto conforme expressamente previsto nesta Licença. Qualquer tentativa de propagar ou modificá-la é inválida e terminará automaticamente os seus direitos sob esta Licença.\n\nNo entanto, se você cessar toda violação desta Licença, a sua licença de um detentor de direitos autorais específicos é reintegrada provisoriamente.';

  @override
  String get license_section_acceptance_body =>
      'Você não é obrigado a aceitar esta Licença para receber ou executar uma cópia do Programa. A propagação auxiliar de um trabalho coberto que ocorre apenas como consequência da utilização da transmissão ponto a ponto para receber uma cópia também não exige aceitação.';

  @override
  String get license_section_downstream_body =>
      'Cada vez que você transmite um trabalho coberto, o destinatário recebe automaticamente uma licença dos licenciadores originais, para executar, modificar e propagar esse trabalho, sujeito a esta Licença.\n\nVocê não pode impor restrições adicionais sobre o exercício dos direitos concedidos ou afirmados sob esta Licença.';

  @override
  String get license_section_patents_body =>
      'Um contribuidor é um detentor de direitos autorais que autoriza o uso sob esta Licença do Programa ou um trabalho no qual o Programa se baseia.\n\nCada contribuidor concede-lhe uma licença de patente não exclusiva, mundial, livre de royalties sob os principais pedidos de patente do contribuidor.';

  @override
  String get license_section_no_surrender_body =>
      'Se as condições que forem impostas a você (seja por ordem judicial, acordo ou de outra forma) contradizem as condições desta Licença, elas não lhe eximem das condições desta Licença.\n\nSe você não pode transmitir um trabalho coberto para satisfazer simultaneamente suas obrigações sob esta Licença e quaisquer outras obrigações pertinentes, então você não pode transmitir isso.';

  @override
  String get license_section_agpl_body =>
      'Não obstante qualquer outra disposição desta Licença, você tem permissão para vincular ou combinar qualquer trabalho coberto com um trabalho licenciado sob a versão 3 da Licença Pública Geral Affero GNU em um único trabalho combinado.';

  @override
  String get license_section_revisions_body =>
      'A Free Software Foundation pode publicar versões periódicas e/ou novas da Licença Pública Geral GNU de tempos em tempos. Essas novas versões serão semelhantes em espírito à versão atual, mas podem diferir em detalhes para resolver novos problemas ou preocupações.\n\nCada versão recebe um número de versão distinto.';

  @override
  String get license_section_warranty_body =>
      'NÃO HÁ NENHUMA GARANTIA PARA O PROGRAMA, NA EXTENSÃO PERMITIDA PELA LEI APLICÁVEL. EXCETO QUANDO TUDO INDICADO POR ESCRITO, OS DETENTORES DE DIREITOS AUTORAIS E/OU OUTRAS PARTES FORNECEM O PROGRAMA COMO ESTÁ SEM GARANTIA DE QUALQUER TIPO.\n\nTODO O RISCO SOBRE A QUALIDADE E O DESEMPENHO DO PROGRAMA ESTÁ COM VOCÊ. SE O PROGRAMA APRESENTAR DEFEITO, VOCÊ ASSUME O CUSTO DE TODA A MANUTENÇÃO, REPARAÇÃO OU CORREÇÃO NECESSÁRIA.';

  @override
  String get license_section_liability_body =>
      'EM NENHUM CASO, A MENOS QUE EXIGIDO PELA LEI APLICÁVEL OU ACORDADO POR ESCRITO, QUALQUER DETENTOR DE DIREITOS AUTORAIS, OU QUALQUER OUTRA PARTE QUE MODIFICA E/OU TRANSMITE O PROGRAMA COMO PERMITIDO ACIMA, SE RESPONSABILIZARÁ POR DANOS.\n\nISTO INCLUI QUALQUER DANO GERAL, ESPECIAL, INCIDENTAL OU CONSEQUENCIAL QUE SURGIR DO USO OU INCAPACIDADE DE USAR O PROGRAMA, MESMO SE TAL DETENTOR OU OUTRA PARTE TENHA SIDO AVISADO DA POSSIBILIDADE DE TAIS DANOS.';

  @override
  String get license_section_interpretation_body =>
      'Se a renúncia de garantia e a limitação de responsabilidade previstos acima não puderem ter efeito legal local de acordo com seus termos, os tribunais revisionais aplicarão a lei local que se aproxima mais de uma renúncia absoluta a toda a responsabilidade civil em conexão com o Programa, a menos que uma garantia ou suposição de responsabilidade acompanhe uma cópia do Programa em troca de uma taxa.';

  @override
  String get license_end_terms => 'FIM DOS TERMOS E CONDIÇÕES';

  @override
  String get terms_title => 'Termos de Uso';

  @override
  String get terms_subtitle => 'Mooze Wallet';

  @override
  String get terms_intro =>
      'Ao utilizar o aplicativo Mooze, você concorda integralmente com estes termos. Leia atentamente antes de prosseguir.';

  @override
  String get terms_warning_title => 'Aviso Importante';

  @override
  String get terms_warning_message =>
      'Você é o único responsável por manter suas senhas de recuperação seguras. A perda dessas informações implica perda irreversível das unidades digitais.';

  @override
  String get terms_self_custody_title => 'Autocustódia';

  @override
  String get terms_self_custody_subtitle => 'Você controla seus fundos';

  @override
  String get terms_privacy_title => 'Privacidade';

  @override
  String get terms_privacy_subtitle => 'Dados protegidos';

  @override
  String get terms_beta_title => 'Beta';

  @override
  String get terms_beta_subtitle => 'Em desenvolvimento';

  @override
  String get terms_last_updated => 'Última atualização: 18/04/2026';

  @override
  String get terms_privacy_policy_link => 'Ver Política de Privacidade';

  @override
  String get terms_preamble => 'Preâmbulo — Oferta Passiva e Auto-Acesso';

  @override
  String get terms_preamble_body =>
      'Os presentes Termos de Uso regem a relação entre a Mooze Labs LLC e o Usuário que, por iniciativa própria e exclusiva, obtém, instala e utiliza o aplicativo Mooze Wallet.\n\nA disponibilização do Aplicativo em plataformas de distribuição global (Google Play Store, Apple App Store, lojas similares ou repositório público de APK) constitui mera colocação passiva de software. Qualquer utilização do Aplicativo decorre de busca ativa e em interesse voluntário do Usuário, o qual declara acessar a Mooze por decisão pessoal.';

  @override
  String get terms_section_1 => '1. Aceitação dos Termos';

  @override
  String get terms_section_2 => '2. Natureza Jurídica da Mooze';

  @override
  String get terms_section_3 => '3. Definições';

  @override
  String get terms_section_4 => '4. Descrição dos Serviços';

  @override
  String get terms_section_5 => '5. Modelo Não-Custodial e Autocustódia';

  @override
  String get terms_section_6 => '6. Responsabilidades do Usuário';

  @override
  String get terms_section_7 => '7. Tarifas e Taxas de Serviço';

  @override
  String get terms_section_8 =>
      '8. Referência de Preços e Ausência de Recomendação de Investimento';

  @override
  String get terms_section_9 => '9. Limitação de Responsabilidade';

  @override
  String get terms_section_10 => '10. Política Antifraude e Segurança';

  @override
  String get terms_section_11 =>
      '11. Monitoramento, Prevenção a Fraudes e Suspensão de Serviços';

  @override
  String get terms_section_12 =>
      '12. Obrigações Legais do Usuário e Restrições Jurisdicionais';

  @override
  String get terms_section_13 => '13. Jurisdição e Lei Aplicável';

  @override
  String get terms_section_14 => '14. Resolução de Disputas';

  @override
  String get terms_section_15 => '15. Propriedade Intelectual';

  @override
  String get terms_section_16 => '16. Disposições Gerais';

  @override
  String get terms_section_17 => '17. Idade Mínima';

  @override
  String get terms_section_18 => '18. Alterações dos Termos';

  @override
  String get terms_section_19 => '19. Contato';

  @override
  String get privacy_section_header => 'Política de Privacidade — Mooze Wallet';

  @override
  String get privacy_section_1 => '1. Compromisso com a Privacidade';

  @override
  String get privacy_section_2 => '2. Definições';

  @override
  String get privacy_section_3 => '3. Dados Coletados e Não Coletados';

  @override
  String get privacy_section_4 =>
      '4. Tratamento de Dados em Operações com Referencial Fiat';

  @override
  String get privacy_section_5 => '5. Compartilhamento de Dados';

  @override
  String get privacy_section_6 => '6. Comunicação com a Mooze';

  @override
  String get privacy_section_7 => '7. Segurança';

  @override
  String get privacy_section_8 => '8. Retenção de Dados';

  @override
  String get privacy_section_9 =>
      '9. Direitos do Usuário (LGPD e Jurisdições Equivalentes)';

  @override
  String get privacy_section_10 =>
      '10. Jurisdição de Dados e Transferências Internacionais';

  @override
  String get privacy_section_11 => '11. Alterações';

  @override
  String get privacy_section_12 => '12. Contato';

  @override
  String get terms_section_1_body =>
      '1.1. Ao acessar, instalar ou utilizar o aplicativo Mooze Wallet (\"Aplicativo\"), o Usuário declara ter lido, compreendido e aceito integralmente os presentes Termos de Uso (\"Termos\") e a Política de Privacidade que os acompanha.\n\n1.2. A utilização do Aplicativo constitui aceitação expressa, informada, consciente e irrevogável de todas as disposições contidas neste documento.\n\n1.3. Caso o Usuário não concorde com qualquer disposição destes Termos, deverá cessar imediatamente a utilização do Aplicativo, desinstalá-lo de seus dispositivos e abster-se de qualquer interação com os Serviços. A continuidade de uso do Aplicativo, após a publicação destes Termos ou de versões atualizadas posteriormente, constitui concordância integral com os termos vigentes.\n\n1.4. Estes Termos constituem contrato vinculante internacional entre o Usuário e a Mooze Labs LLC, regido exclusivamente pelas leis da República das Ilhas Marshall (\"RMI\"), nos limites estabelecidos na Seção 13.\n\n1.5. O Usuário reconhece que obteve o Aplicativo através de informação livre e conhecida, com decisão própria final, sendo o único responsável capaz.';

  @override
  String get terms_section_2_body =>
      '2.1. A Mooze Labs LLC (\"Mooze\") é sociedade de responsabilidade limitada regularmente constituída sob a Associations Law da República das Ilhas Marshall (Título 52, Marshall Islands Revised Code), RMI.\n\n2.2. A Mooze atua exclusivamente como provedora de serviços de software (Software-as-a-Service). Sua atividade consiste no desenvolvimento, manutenção e disponibilização de infraestrutura tecnológica para operação de carteiras digitais autocustodiais nas redes Bitcoin, Liquid Network e Lightning Network, bem como na orquestração programática de chamadas de software (API calls) entre o dispositivo do Usuário e infraestruturas de terceiros.\n\n2.3. A Mooze NÃO é, não opera como, não se apresenta como, e não deve ser interpretada como:\n(a) corretora, exchange, plataforma de negociação, plataforma de trading, formador de mercado (market maker) ou plataforma de liquidez de ativos digitais;\n(b) instituição financeira, instituição de pagamento, sociedade de crédito, cooperativa de crédito ou entidade equiparada;\n(c) prestadora de serviços de câmbio, casa de câmbio ou operadora de câmbio;\n(d) transmissora de dinheiro (money transmitter) ou prestadora de serviços monetários (money services business — MSB);\n(e) prestadora de serviços de ativos virtuais (Virtual Asset Service Provider — VASP) nos termos da Banking (Amendment) Act, 2020 — P.L. 2020-61, Seção 102(ii), da República das Ilhas Marshall;\n(f) prestadora de serviços de ativos virtuais nos termos da Lei n. 14.478/2022 (Marco Legal dos Criptoativos do Brasil) ou da Resolução CVM n. 175;\n(g) entidade sujeita às obrigações da FATF Recommendation 15 enquanto VASP;\n(h) custodiante, depositária, fiel depositária ou administradora de ativos digitais ou de recursos financeiros de terceiros;\n(i) consultora de investimentos, prestadora de aconselhamento financeiro ou analista de valores mobiliários.\n\n2.4. A Mooze não exerce custódia, posse, controle discricionário de saldos em nome de usuários, titularidade, domínio, direito de uso, fruição ou disposição sobre quaisquer ativos digitais ou valores monetários pertencentes ao usuário. O processamento transitório, programático e automatizado de ativos digitais pela infraestrutura da Mooze durante a execução dos Serviços constitui roteamento técnico, análogo ao processamento de pacotes de dados por equipamento de rede (roteador), sem que a Mooze adquira, em qualquer momento ou sob qualquer forma, direito, interesse, titularidade beneficiária (beneficial ownership).\n\n2.5. A Mooze não realiza, em nenhuma hipótese: (i) operações de exchange; (ii) conversão entre moedas fiduciárias; (iii) conversão entre moeda fiduciária e ativo digital ou entre ativos digitais executada em nome do Usuário e sua titularidade; (iv) intermediação financeira; (v) transmissão de valores em nome de terceiros. Toda e qualquer operação envolvendo moeda fiduciária (reais brasileiros) é processada integralmente por parceiras reguladas pelo Banco Central do Brasil, conforme descrito na Seção 4. Toda e qualquer conversão entre ativos digitais é executada diretamente pelo Usuário, por meio de protocolos descentralizados peer-to-peer (atomic swap), sem que a Mooze atue como contraparte.\n\n2.6. Nos termos da Banking (Amendment) Act, 2020 (P.L. 2020-61) da República das Ilhas Marshall, Capítulo 1, Seção 102(ii), a definição de VASP (Virtual Asset Service Provider) abrange exclusivamente pessoas naturais ou jurídicas que, como atividade empresarial e \"por conta ou em nome de outra pessoa natural ou jurídica\" (\"for or on behalf of another natural or legal person\"), realizam uma ou mais das seguintes atividades: (i) câmbio entre ativos virtuais e moedas fiduciárias; (ii) câmbio entre formas de ativos virtuais; (iii) transferência de ativos virtuais; (iv) guarda e/ou administração de ativos virtuais ou de instrumentos que permitam controle sobre ativos virtuais; (v) participação e provisão de serviços financeiros relacionados à oferta e/ou venda de um ativo virtual por um emissor. A Mooze não realiza nenhuma das atividades (i) a (v) \"por conta ou em nome\" de terceiros, uma vez que: (a) opera exclusivamente como provedora de software não-custodial; (b) não detém, nem tem capacidade técnica de deter, chaves privadas do Usuário; (c) não executa conversões em nome do Usuário, limitando-se a orquestrar chamadas programáticas entre o Usuário e provedores terceiros; (d) não participa como contraparte em qualquer transferência ou atomic swap.\n\n2.7. A Mooze não está sujeita às AML Regulations 2002 da República das Ilhas Marshall (com emendas) enquanto VASP, por não satisfazer o critério legal de prestação de serviço \"por conta ou em nome\" de terceiros. O cumprimento de obrigações de prevenção à lavagem de dinheiro (AML), conheça seu cliente (KYC) e da \"Travel Rule\" relativa a transferências acima de USD 1.000,00 cabe exclusivamente às Parceiras Reguladas e demais VASPs intervenientes no fluxo operacional descrito na Seção 4.\n\n2.8. A Mooze é membro oficial da Liquid Federation (Blockstream), com PAK Entry ativo, atestando sua participação no ecossistema da Liquid Network como entidade tecnológica. A participação na Liquid Federation constitui vínculo técnico-operacional, e não vínculo societário, de representação ou de responsabilidade solidária com a Blockstream ou com demais membros da federação.';

  @override
  String get terms_section_3_body =>
      'Para fins destes Termos, os seguintes termos possuem os significados indicados:\n\n3.1. \"Aplicativo\" ou \"Mooze Wallet\": software de carteira digital autocustodial desenvolvido pela Mooze, disponibilizado para dispositivos móveis iOS e Android (via lojas como Google Play Store, Apple App Store e similares, também via arquivo APK de distribuição direta).\n\n3.2. \"Usuário\": pessoa natural, maior de 18 (dezoito) anos e com capacidade civil plena, que instala, acessa ou utiliza o Aplicativo por iniciativa própria.\n\n3.3. \"Autocustódia\" ou \"Self-Custody\": modelo no qual o Usuário detém controle técnico exclusivo sobre suas chaves privadas e frases-semente (seed phrases), sem que a Mooze ou qualquer terceiro tenha acesso, cópia, conhecimento ou capacidade técnica de reconstruir tais informações.\n\n3.4. \"Frase-Semente\" ou \"Seed Phrase\": sequência de 12 (doze) ou 24 (vinte e quatro) palavras, gerada localmente no dispositivo do Usuário de acordo com o padrão aberto BIP39, que constitui o único mecanismo de recuperação da carteira digital do Usuário.\n\n3.5. \"Liquid Network\": sidechain federada do Bitcoin, desenvolvida e mantida pela Blockstream e pela Liquid Federation, que permite a emissão e transferência de ativos digitais com tecnologia de Confidential Transactions.\n\n3.6. \"DEPIX\": token digital emitido na Liquid Network pela Eulen.app LLC (entidade constituída em São Cristóvão e Neves — Saint Kitts and Nevis) em cooperação com o projeto depix.info, cujo valor é pareado ao real brasileiro (BRL) na razão de 1 (um) DEPIX para R\$ 1,00 (um real). Conforme descrito no whitepaper público disponível em depix.info, o DEPIX é colateralizado parcialmente em moedas fiduciárias e majoritariamente em Bitcoin, por meio de protocolos NITI (Non-custodial Interlinked Tokenization Infrastructure) nas redes on-chain e na Liquid Network. A Mooze NÃO é emissora, administradora, garantidora ou responsável pela paridade, lastro ou liquidez do DEPIX.\n\n3.7. \"L-BTC\": representação técnica de Bitcoin na Liquid Network, emitida 1:1 contra Bitcoin depositado no peg-in federado, utilizada para transações dentro dessa rede.\n\n3.8. \"Atomic Swap\": mecanismo criptográfico de troca direta entre dois ativos digitais, executado diretamente na blockchain ou sidechain, sem intermediário custodiante, no qual ambas as pontas da transação se concretizam simultaneamente ou nenhuma delas se efetiva (all-or-nothing).\n\n3.9. \"SideSwap\": protocolo público e de código aberto para execução de atomic swaps na Liquid Network.\n\n3.10. \"Confidential Transactions\": tecnologia nativa da Liquid Network que oculta valores e tipos de ativos em transações, sendo visíveis apenas para as partes envolvidas mediante os respectivos blinding keys (chaves de ocultação).\n\n3.11. \"APP ID\": identificador técnico gerado a partir de funcionalidades criptográficas do dispositivo do Usuário (MediaDRM em Android, DeviceCheck em iOS), resultando em hash unidirecional. O APP ID é utilizado exclusivamente para prevenção a fraudes e controle de limites operacionais, não permite identificação pessoal do Usuário e não constitui dado pessoal identificável nos termos da LGPD ou de legislação equivalente.\n\n3.12. \"Parceiras Reguladas\": instituições financeiras e de pagamento brasileiras, devidamente autorizadas e reguladas pelo Banco Central do Brasil, que participam do processamento de operações envolvendo moeda fiduciária (PIX). Sendo estas, e não se limitando somente às citadas:\n(a) PLEBIT.COM.BR Soluções em Tecnologia Ltda — CNPJ 43.375.652/0001-13;\n(b) Fits Instituição de Pagamento — CNPJ 13.203.354/0001-85;\n(c) Celcoin — CNPJ 13.935.893/0001-09;\n(d) PLEBZ INTERMEDIACAO DE PAGAMENTOS LTDA — CNPJ 45.808.899/0001-01.\n\n3.13. \"Eulen.app LLC\": sociedade constituída em São Cristóvão e Neves (Saint Kitts and Nevis), emissora do token DEPIX e responsável pela infraestrutura tecnológica de tokenização descrita em seu whitepaper público.\n\n3.14. \"PIX\": sistema de pagamentos instantâneos instituído, regulado e operado pelo Banco Central do Brasil.\n\n3.15. \"Serviços\": conjunto de funcionalidades de software disponibilizadas pela Mooze ao Usuário por meio do Aplicativo, conforme descritas na Seção 4.\n\n3.16. \"Protocolo NITI\": protocolo descentralizado utilizado para verificação e roteamento de transações na Liquid Network.\n\n3.17. \"Blinding Key\" ou \"Chave de Ocultação\": chave criptográfica associada a uma Confidential Transaction na Liquid Network, que permite ao detentor visualizar os valores e tipos de ativos transacionados naquela transação específica.\n\n3.18. \"MED\" (\"Mecanismo Especial de Devolução\"): mecanismo instituído pelo Banco Central do Brasil para devolução de valores em transações PIX, aplicável em casos de fraude ou falha operacional, regido pela Resolução BCB aplicável e operado exclusivamente pelas instituições participantes do arranjo PIX.\n\n3.19. \"Breez\" ou \"Breez SDK\": kit de desenvolvimento de software (SDK) de terceiro, utilizado pela Mooze para integração técnica com a Lightning Network.\n\n3.20. “Hodle”: serviço de terceiro utilizado para funcionalidades complementares envolvendo o sistema PIX.\n\n3.21. “Infratechs Parceiras”: empresas terceiras que fornecem serviços de infraestrutura tecnológica financeira utilizados pela Mooze na orquestração de seus Serviços de software, sem prestar serviços diretamente aos Usuários finais do Aplicativo e sem qualquer vínculo contratual direto com o Usuário.\n\n3.22. \"FATF\": Financial Action Task Force — Grupo de Ação Financeira Internacional, organismo intergovernamental referenciado nestes Termos para fins de definição de VASP e aplicação da Recommendation 15.\n\n3.23. \"Oferta Passiva\" ou \"Reverse Solicitation\": modalidade de disponibilização de serviço em que o cliente busca o provedor por decisão e iniciativa própria.';

  @override
  String get terms_section_4_body =>
      'A Mooze disponibiliza ao Usuário, por meio do Aplicativo, serviços de software organizados em modalidades independentes entre si. Cada modalidade constitui serviço tecnológico autônomo, com objeto, funcionamento e base contratual distintos. A utilização de uma modalidade não obriga nem condiciona a utilização das demais.\n\n4.1. SERVIÇO A — ORQUESTRAÇÃO DE SOFTWARE PARA AQUISIÇÃO DE TOKENS DIGITAIS\n\n4.1.1. O Serviço A consiste na disponibilização, pela Mooze, de interface de software que orquestra programaticamente a comunicação entre o dispositivo do Usuário, as Parceiras Reguladas e a infraestrutura de emissão de tokens digitais operada pela Eulen.app LLC e demais Infratechs Parceiras.\n\n4.1.2. O fluxo operacional do Serviço A ocorre conforme descrito a seguir:\n(a) O Usuário, por meio do Aplicativo, informa o valor em reais (BRL) que deseja utilizar para aquisição de DEPIX e gera um código QR PIX, no qual via sua plataforma de início da operação, fornece todos os dados necessários para transação, podendo ser, chaves públicas, endereços de wallet, valores e informações de dispositivo gerais;\n(b) O pagamento PIX é recebido, processado e liquidado integralmente por uma das Parceiras Reguladas (PLEBIT.COM.BR, Fits Instituição de Pagamento, Celcoin ou PLEBZ), que são as únicas entidades autorizadas a receber e processar recursos em moeda fiduciária em ambas as direções de fluxos de transações FIAT;\n(c) A Parceira Regulada comunica os dados de liquidação do PIX à Eulen.app LLC;\n(d) A Eulen.app LLC emite a quantidade correspondente de tokens DEPIX na Liquid Network;\n(e) O software da Mooze captura o endereço de carteira do Usuário — endereço público derivado matematicamente das chaves privadas sob controle exclusivo do Usuário — e transmite esse endereço à infraestrutura da Eulen.app LLC para que os tokens DEPIX sejam entregues diretamente ao endereço de autocustódia do Usuário;\n(f) Os tokens DEPIX são entregues, por meio do sistema conjunto de processamento iniciado via software com a Eulen.app LLC, diretamente via roteamento programático direcionada ao endereço de autocustódia do Usuário na Liquid Network.\n\n4.1.3. O Serviço A constitui prestação de serviços tecnológicos de software, realizada por meio de infraestrutura integrada entre a Mooze, parceiros especializados e prestadores de serviço do ecossistema. A Mooze coordena chamadas de API (application programming interface) entre o dispositivo do Usuário, as Parceiras Reguladas, a Eulen.app LLC e as Infratechs Parceiras, incluindo o sistema de verificação automatizado descrito na cláusula 4.1.4, sem adquirir titularidade, posse beneficiária ou controle sobre os ativos roteados fora de escopos programáticos predefinidos.\n\n4.1.4. O processamento de ativos digitais no âmbito do Serviço A envolve múltiplas camadas de verificação técnica e operacional realizadas por sistemas integrados de parceiros e prestadores de serviço especializados. A conclusão do processamento pode decorrer de procedimentos de análise conjunta que, conforme a natureza e características da operação, são regidos pelas seguintes características:\n(a) O processamento é regido por sistemas automatizados integrados, cujos critérios são determinados por participantes do ecossistema tecnológico; os desfechos possíveis são: (i) conclusão da operação, com entrega dos ativos ao endereço de autocustódia do Usuário; ou (ii) reversão da operação, com retorno dos ativos à Eulen.app LLC e comunicação de estorno do pagamento PIX às Parceiras Reguladas;\n(b) não existem destinos técnicos alternativos para os ativos além dos descritos em (a)(i) e (a)(ii) — a estrutura do sistema não comporta desvios;\n(c) os sistemas automatizados integrados não comportam intervenção discricionária em operações individuais;\n(d) a Mooze não adquire, em nenhum momento, titularidade beneficiária (beneficial ownership), direito real, direito de uso, fruição ou disposição sobre os tokens em trânsito;\n(e) os tokens em trânsito não são comingled (misturados) com ativos da Mooze, nem utilizados como lastro, garantia ou reserva para qualquer obrigação da Mooze;\n(f) a operação de entrega constitui handoff atômico (atomic handoff): até o momento imediatamente anterior à liberação ao Usuário, os tokens permanecem sob controle técnico programático com destino predefinido à própria operação;\n(g) a manutenção técnica do sistema antifraude (correção de defeitos, atualização de regras programáticas, calibragem de thresholds) constitui desenvolvimento de software e não configura intervenção discricionária sobre operações individuais.\n\n4.1.5. Operações no âmbito do Serviço A podem ser submetidas a procedimentos de verificação realizados por sistemas automatizados integrados de parceiros do ecossistema tecnológico. A duração e a metodologia dos procedimentos de verificação são determinadas por esses sistemas automatizados, podendo resultar em processamento imediato ou em análise adicional por período variável conforme a natureza e características da operação. Durante o processamento:\n(a) os ativos permanecem em trânsito automatizado, sem comingling com ativos de outras operações e sem fungibilidade com patrimônio da Mooze;\n(b) a Mooze não exerce, nem pode exercer, uso, fruição, empréstimo, investimento, rehipoteca ou qualquer forma de aproveitamento econômico sobre os tokens em transição;\n(c) expirado o período de verificação sem sinalização de inconsistência, os ativos são liberados automaticamente ao endereço de autocustódia do Usuário;\n(d) o processamento transitório não constitui custódia, guarda, depósito ou administração de ativos em nome do Usuário, uma vez que (i) não decorre de acordo de guarda ou depósito com o Usuário, mas de procedimento técnico do ecossistema aplicado via rota de processamento para a entrega, e (ii) em nenhum momento a Mooze adquire titularidade beneficiária ou poder discricionário sobre os ativos.\n\n4.1.6. Operações podem ser revertidas quando sistemas automatizados integrados ou Parceiras Reguladas detectarem sinalizações de risco, inconsistências técnicas ou requisitos regulatórios aplicáveis (incluindo MED). Nesse caso, os ativos digitais são revertidos à Eulen.app LLC via blockchain dentro do tempo de processamento das respectivas redes utilizadas. O processamento do estorno do pagamento PIX em moeda fiduciária é de responsabilidade exclusiva das Parceiras Reguladas, sob jurisdição e regulação do Banco Central do Brasil, podendo levar até 7 (sete) dias corridos contados em média do início da operação. O prazo adicional entre a reversão do processo dos tokens à Eulen.app LLC e a conclusão do estorno PIX refere-se exclusivamente ao tempo de processamento do sistema bancário brasileiro pelas Parceiras Reguladas, período no qual a Mooze não detém quaisquer tokens ou recursos financeiros relacionados à operação.\n\n4.1.7. O processamento do pagamento PIX, incluindo a verificação de identidade do pagador (KYC), a prevenção à lavagem de dinheiro (AML), o cumprimento da \"Travel Rule\" em transferências cross-border de ativos virtuais em eventos de triggers de valores regulados e demais obrigações regulatórias perante o Banco Central do Brasil, o Conselho de Controle de Atividades Financeiras (COAF) e a Receita Federal do Brasil, é de responsabilidade exclusiva das Parceiras Reguladas e demais VASPs intervenientes, nos limites de suas respectivas atividades.\n\n4.1.8. A emissão de tokens DEPIX é de responsabilidade exclusiva da Eulen.app LLC e do projeto depix.info, que operam de forma independente da Mooze. A Mooze não garante a paridade, a liquidez, o lastro, a solvência ou a continuidade da operação do DEPIX, nem a Mooze representa ou responde pelas operações relacionadas ao DEPIX, à Eulen.app LLC e suas parcerias contratuais.\n\n4.1.9. O Serviço A constitui prestação de serviço de software (SaaS), não configurando: (a) serviço financeiro; (b) operação exchange; (c) intermediação financeira; (d) transmissão de valores; (e) prestação de serviço de ativos virtuais (VASP) nos termos da Banking (Amendment) Act, 2020 (RMI) ou de leis regulatórias de território brasileiro; (f) qualquer atividade sujeita a regulação financeira, bancária ou securitária.\n\n4.2. SERVIÇO B — INTERFACE PARA PROTOCOLO DESCENTRALIZADO DE CONVERSÃO ENTRE UNIDADES DIGITAIS\n\n4.2.1. O Serviço B consiste na disponibilização, pela Mooze, de interface de software que permite ao Usuário interagir com o protocolo SideSwap para execução de atomic swaps entre ativos digitais na Liquid Network, bem como, quando aplicável, com o Breez SDK para acesso à Lightning Network.\n\n4.2.2. O Serviço B é inteiramente independente do Serviço A. A utilização de um Serviço não implica nem obriga a utilização do outro.\n\n4.2.3. O fluxo operacional do Serviço B ocorre conforme descrito a seguir:\n(a) O Usuário, a partir de sua carteira autocustodial no Aplicativo, inicia voluntariamente uma solicitação de conversão entre ativos digitais (por exemplo, DEPIX para L-BTC);\n(b) O software da Mooze apresenta ao Usuário interface gráfica para interação com o protocolo SideSwap (ou Breez SDK, quando aplicável);\n(c) O atomic swap é executado diretamente na Liquid Network (ou na Lightning Network, quando aplicável), por meio do protocolo correspondente, entre o Usuário e a liquidez disponível no protocolo;\n(d) A Mooze não participa como contraparte, custodiante, formadora de mercado ou provedora de liquidez em qualquer etapa do atomic swap;\n(e) A conversão ocorre de forma peer-to-peer, diretamente na blockchain ou sidechain, garantida criptograficamente pelo mecanismo de atomic swap — não há, em nenhum momento, intermediário detendo ambos os lados da operação.\n\n4.2.4. A função da Mooze no Serviço B é análoga à de um navegador de internet (web browser) que provê acesso a um sítio eletrônico: a Mooze fornece a interface de software para que o Usuário interaja com protocolo descentralizado, sem participar da execução do protocolo em si.\n\n4.2.5. O protocolo SideSwap é público, de código aberto e opera de forma descentralizada na Liquid Network. O Breez SDK é software de terceiro, público, utilizado para acesso à Lightning Network. A Mooze não controla, opera, administra, governa ou mantém qualquer um desses protocolos ou SDKs.\n\n4.2.6. O Serviço B não constitui atividade de corretagem, exchange, intermediação financeira, câmbio, negociação, formação de mercado ou liquidação de ativos. Constitui exclusivamente a prestação de interface de software para acesso a protocolos descentralizados.\n\n4.2.7. A Mooze não garante: (a) a disponibilidade de liquidez nos protocolos utilizados; (b) a execução bem-sucedida de atomic swaps; (c) as taxas de conversão praticadas pelos protocolos; (d) a continuidade operacional dos protocolos ou SDKs de terceiros.\n\n4.2.8. Para acesso à Lightning Network, a Mooze disponibiliza a integração técnica com o Breez SDK público, sujeito aos mesmos termos aqui descritos para o SideSwap.\n\n4.2.9. Quando o Usuário seleciona, por decisão própria e voluntária, ativo digital final distinto do DEPIX (por exemplo, L-BTC), o software da Mooze orquestra sequencialmente a execução do Serviço A (aquisição de DEPIX) seguida do Serviço B (conversão de DEPIX para o ativo selecionado via protocolo descentralizado Sideswap). A conversão é executada integralmente pelo protocolo descentralizado. A Mooze limita-se a orquestrar as chamadas de software necessárias para que o ativo final se encontre disponível via endereço de autocustódia do Usuário. O Usuário reconhece que essa orquestração sequencial constitui prestação de serviço de software (SaaS) automatizado e não configura atividade de câmbio de responsabilidade da Mooze, corretagem, intermediação financeira ou atividade de VASP, em razão da execução exclusiva via protocolo Sideswap.\n\n4.3. MODO COMERCIANTE\n\n4.3.1. O Aplicativo disponibiliza funcionalidade denominada \"Modo Comerciante\", que permite ao Usuário receber pagamentos via PIX diretamente em sua carteira autocustodial no Aplicativo, tanto de terceiros pagadores quanto na forma de autopagamentos.\n\n4.3.2. O Modo Comerciante utiliza a mesma infraestrutura tecnológica descrita no Serviço A (cláusula 4.1), aplicando-se integralmente as mesmas disposições relativas à natureza do serviço, às responsabilidades das Parceiras Reguladas e à ausência de custódia pela Mooze.\n\n4.3.3. O Modo Comerciante constitui funcionalidade de software, não configurando serviço de adquirência, subadquirência, credenciamento, arranjo de pagamento, gateway de pagamento ou qualquer serviço financeiro regulado. O código QR de pagamento PIX é gerado pelo próprio Usuário-comerciante por meio do Aplicativo, utilizando a infraestrutura das Parceiras Reguladas. A Mooze não participa, intermedia, conhece, valida ou endossa a relação comercial subjacente entre o Usuário-comerciante e o pagador. O pagador realiza pagamento PIX convencional à Parceira Regulada, sem qualquer interação, vínculo contratual ou comunicação direta com a Mooze.\n\n4.3.4. Pagamentos recebidos através do Modo Comerciante estão sujeitos a procedimentos de verificação realizados por sistemas de parceiros e prestadores de serviço integrados. A conclusão do processamento pode decorrer de períodos variáveis, desde minutos até vários dias, conforme os procedimentos aplicáveis determinados por cada participante da cadeia de processamento.\n\n4.3.5. Pagamentos podem ser revertidos quando sistemas integrados de análise detectarem inconsistências técnicas, requisitos regulatórios ou outras condições que resultem em não-conclusão da operação. A reversão será processada pelos prestadores de serviço responsáveis pelo fluxo original. O Usuário que utilizar o Modo Comerciante NÃO deverá entregar produto ou serviço ao pagador antes da confirmação final do pagamento por meio das funções de acompanhamento disponíveis no Aplicativo.\n\n4.3.6. Quaisquer prejuízos, danos ou conflitos decorrentes de entrega de produto ou serviço antes da confirmação final do processamento do pagamento são de responsabilidade exclusiva do Usuário-comerciante, não cabendo responsabilidade à Mooze, às Parceiras Reguladas ou às Infratechs Parceiras.\n\n4.3.7. O Usuário que utilizar o Modo Comerciante responsabiliza-se integralmente, na esfera civil, tributária e criminal, pelas operações realizadas por meio do Aplicativo, incluindo operações realizadas por terceiros que utilizem o dispositivo sob sua tutela física.\n\n4.3.8. Dúvidas operacionais sobre pagamentos devem ser direcionadas ao suporte da Mooze via suporte@mooze.app.\n\n4.4. NATUREZA DO ECOSSISTEMA TECNOLÓGICO INTEGRADO\n\n4.4.1. Os Serviços disponibilizados pela Mooze operam em ecossistema tecnológico complexo envolvendo múltiplos prestadores de serviço, infraestruturas de terceiros, protocolos descentralizados e sistemas integrados.\n\n4.4.2. A execução de operações no âmbito dos Serviços envolve, de forma não exaustiva: (a) infraestrutura de software desenvolvida pela Mooze; (b) sistemas de parceiros e prestadores especializados; (c) infraestruturas das Parceiras Reguladas; (d) protocolos blockchain públicos; (e) sistemas de análise e verificação operados conjuntamente por participantes do ecossistema.\n\n4.4.3. A Mooze não possui controle exclusivo sobre a totalidade dos componentes, sistemas e processos envolvidos na execução dos Serviços. Decisões sobre processamento, aprovação, prazo, reversão ou não-realização de operações podem decorrer de sistemas automatizados, procedimentos de terceiros, requisitos regulatórios ou condições técnicas aplicadas por qualquer participante do ecossistema.\n\n4.4.4. O Usuário reconhece que a prestação dos Serviços constitui coordenação tecnológica entre múltiplos agentes, não configurando relação unilateral ou serviço prestado exclusivamente pela Mooze. A Mooze atua como provedora de componentes de integração de software dentro de ecossistema mais amplo.';

  @override
  String get terms_section_5_body =>
      '5.1. O Aplicativo opera sob modelo de autocustódia integral. As chaves privadas e frases-semente são geradas e armazenadas exclusivamente no dispositivo do Usuário, sendo tecnicamente inacessíveis à Mooze.\n\n5.2. A Mooze não tem, em nenhum momento e sob nenhuma circunstância, acesso, conhecimento, posse, controle, cópia, backup, custódia ou capacidade técnica de reconstrução das chaves privadas, frases-semente ou senhas do Usuário.\n\n5.3. O Usuário é único e exclusivo responsável pela guarda, segurança e integridade de suas chaves privadas, frases-semente e senhas. A perda desses elementos resulta na perda permanente e irreversível do acesso aos ativos digitais armazenados na carteira.\n\n5.4. A Mooze não possui capacidade técnica para recuperar, restaurar, acessar, transferir ou recriar ativos digitais do Usuário em caso de perda das chaves privadas ou frases-semente. Solicitações nesse sentido são tecnicamente impossíveis de atender.\n\n5.5. Os endereços de carteira do Usuário e chaves públicas são derivados matematicamente, por meio de algoritmo criptográfico determinístico, de suas chaves privadas. A Mooze utiliza esses dados exclusivamente como parâmetro técnico de roteamento automatizado durante a execução dos Serviços, transmitindo-os via infraestrutura para entrega direta dos ativos ao Usuário.\n\n5.6. O Usuário reconhece que a autocustódia é o pilar estrutural do modelo da Mooze e elemento determinante do seu enquadramento jurídico como não-VASP. Qualquer tentativa de contornar o modelo de autocustódia (por exemplo, exigir da Mooze a guarda de chaves, a custódia de ativos ou a recuperação discricionária de frases-semente) é incompatível com a natureza do Serviço, não será atendida.';

  @override
  String get terms_section_6_body =>
      '6.1. GUARDA DE SENHAS E FRASES-SEMENTE\n\n6.1.1. O Usuário é integral e exclusivamente responsável pela criação, armazenamento e proteção de suas senhas, chaves privadas e frases-semente.\n\n6.1.2. O Usuário deve armazenar sua frase-semente em local seguro, preferencialmente offline (em suporte físico como papel, aço gravado ou dispositivo dedicado), e nunca compartilhá-la com terceiros, inclusive com a Mooze ou qualquer pessoa que se apresente como representante da Mooze.\n\n6.1.3. A Mooze NUNCA solicita ao Usuário, por qualquer meio de comunicação (e-mail, Telegram, telefone, redes sociais, anúncios, chat in-app), suas chaves privadas, frases-semente ou senhas. Qualquer solicitação nesse sentido deve ser considerada tentativa de fraude e reportada ao suporte oficial via suporte@mooze.app.\n\n6.1.4. O usuário é o único responsável na verificação de legitimidade em casos de comunicação ou tentativas de phishing, comunicação via canais homógrafos se passando pela Mooze, sob esse conhecimento via estes termos, orienta-se que, comunicados com domínio homógrafo ou suspeito similar o da Mooze, usuário deve contatar reencaminhando contatos ou mensagens suspeitas (vide seção 6.1.3.) para suporte@mooze.app para auxílio e certificação, a Mooze opera comunicação com clientes exclusivamente via domínio mooze.app.\n\n6.2. CONSEQUÊNCIAS DA PERDA DE ACESSO\n\n6.2.1. A perda da frase-semente implica a perda permanente e irreversível do acesso a todos os ativos digitais armazenados na carteira associada.\n\n6.2.2. A Mooze não pode restaurar, recuperar ou recriar o acesso à carteira do Usuário em caso de perda da frase-semente.\n\n6.2.3. O Usuário reconhece e aceita que a autocustódia implica responsabilidade integral e exclusiva sobre seus ativos digitais, incluindo o risco de perda total e definitiva por ato ou omissão e imperícia próprios em relação às tecnologias Blockchain e criptomoedas.\n\n6.2.4. O usuário ao desinstalar o aplicativo da Mooze, rotacionar dados via plataformas de acesso aos serviços via Mooze, rotacionar carteiras, frases sementes sob mesmo aparelho ou em aparelhos diferentes, fica ciente do fato da possibilidade de perda de dados, como armazenamento de históricos blockchain, históricos de pagamentos via processadoras parceiras, possibilidade de perda de avaliação sobre scores internos de reputação de usuário via sistemas e serviços da Mooze (score e limite de transações relacionados a transações bancárias via parceiras reguladas) e quaisquer dados não limitados a estes que salvos localmente para privacidade e segurança, essas ações podem decorrer destas consequências, o usuário aqui se declara completamente ciente das consequências dessas ações.\n\n6.3. SEGURANÇA DO DISPOSITIVO E FONTE DE OBTENÇÃO DOS SERVIÇOS\n\n6.3.1. O Usuário é responsável pela segurança do dispositivo móvel utilizado para acessar o Aplicativo, incluindo: (a) manutenção do sistema operacional atualizado; (b) utilização de autenticação biométrica ou senha forte de dispositivo; (c) proteção contra malware e aplicativos de origem não confiável; (d) abstenção de realizar root, jailbreak ou utilização de emuladores, o usuário pode baixar o aplicativo via lojas autorizadas oficiais via identificação da Mooze ou através de fontes como seu Github oficial (github.com/mooze-labs), quais ambas as fontes possuem formas de verificação de autenticidade da fonte de serviços e aplicações como, verificação de autenticidade do aplicativo e sua integridade via verificações de ID hash nos repositórios públicos, a Mooze não se responsabiliza por qualquer problema advindo de usuários que usem fontes de download de aplicação ou fontes de serviços adulterados e ou fraudulentos, nem prejuízos decorrentes da não verificação de fonte de serviços ou obtenção de aplicações, o usuário consente aqui que pode utilizar-se de verificação via Github oficial da Mooze e métodos seguros de segurança de lojas oficiais disponíveis.\n\n6.3.2. A Mooze não se responsabiliza por perdas decorrentes de comprometimento do dispositivo do Usuário, incluindo infecção por malware, acesso não autorizado ao dispositivo, interceptação de dados por terceiros ou uso de dispositivos modificados.';

  @override
  String get terms_section_7_body =>
      '7.1. A utilização dos Serviços está sujeita a taxas de processamento e tecnologia (\"Taxa de Serviço\" ou \"Taxa de Serviço de Software\") cobradas em razão da operação do ecossistema tecnológico descrito na Seção 4.\n\n7.2. As Taxas de Serviço remuneram os prestadores de infraestrutura tecnológica envolvidos na operação, incluindo mas não limitado a: desenvolvimento e manutenção de software, integração de sistemas, processamento de operações, infraestrutura de rede, segurança e demais serviços técnicos necessários ao funcionamento do ecossistema.\n\n7.3. A Taxa de Serviço de Software é calculada como percentual do valor da operação e deduzida do montante de ativos digitais entregues ao Usuário. O percentual vigente é exibido ao Usuário na tela de confirmação da operação, antes de sua efetivação, e também divulgado nos menus informativos do Aplicativo.\n\n7.4. A Mooze reserva-se o direito de alterar os percentuais da Taxa de Serviço de Software a qualquer momento, mediante atualização no Aplicativo ou necessidades de pareamento referencial em cotações Bitcoin (exemplo: taxas de rede Bitcoin Liquid e referenciais similares em Bitcoin podem sofrer ajuste devido cotação flutuante). A continuidade de utilização do Aplicativo após a alteração constitui aceitação dos novos percentuais ou necessidades de valores referenciais não fixados.\n\n7.5. A Taxa de Serviço de Software constitui remuneração por serviço de software (SaaS), de natureza análoga às taxas cobradas por plataformas tecnológicas por utilização de seus serviços. Não constitui tarifa financeira, comissão de corretagem, taxa de câmbio, spread cambial ou encargo financeiro de qualquer natureza.\n\n7.6. As Parceiras Reguladas, os protocolos descentralizados (SideSwap, Breez, Lightning) e as Infratechs Parceiras podem aplicar suas próprias tarifas, spreads, taxas ou custos de rede, independentes da Taxa de Serviço de Software da Mooze, sobre os quais a Mooze não exerce controle nem responsabilidade. A Mooze informa esses repasses ao Usuário na tela de confirmação da operação de forma fixa ou flutuante na plataforma utilizada.\n\n7.7. Custos de mineração e taxas de rede (network fees) relativos a transações nas redes Bitcoin, Liquid Network ou Lightning Network são de responsabilidade do Usuário e independentes da Taxa de Serviço de Software. Taxas de rede incorridas durante a execução dos Serviços pelas Parceiras Reguladas, Infratechs Parceiras ou protocolos utilizados poderão ser repassadas ao Usuário, somando-se à Taxa de Serviço de Software, conforme exibido na tela de confirmação antes da efetivação.';

  @override
  String get terms_section_8_body =>
      '8.1. Os valores de referência exibidos no Aplicativo para ativos digitais (Bitcoin, L-BTC, DEPIX, L-USDT e outros) são obtidos de fontes públicas de mercado e servem exclusivamente como referência informativa.\n\n8.2. A Mooze não garante a exatidão, a precisão ou a atualização em tempo real dos preços exibidos. A variação de preço entre o momento da exibição e o momento da efetivação de uma operação é inerente ao funcionamento de mercados de ativos digitais.\n\n8.3. A exibição de preços no Aplicativo: (a) não constitui oferta, oferta pública, recomendação, aconselhamento de investimento, análise de valor mobiliário ou garantia de valor; (b) não configura oferta pública de valores mobiliários nos termos da Lei n. 6.385/76 ou de legislação equivalente; (c) não se qualifica como \"investment advice\" ou \"solicitation\" nos termos das regulações dos Estados Unidos, União Europeia, Reino Unido ou qualquer outra jurisdição.\n\n8.4. O Usuário reconhece que ativos digitais estão sujeitos a alta volatilidade e que pode sofrer perdas significativas de valor. A Mooze não se responsabiliza por perdas decorrentes de variação de preços.';

  @override
  String get terms_section_9_body =>
      '9.1. A Mooze fornece o Aplicativo e os Serviços \"no estado em que se encontram\" (as is) e \"conforme disponibilidade\" (as available), sem garantias de qualquer natureza, expressas ou implícitas, incluindo, sem limitação, garantias de comerciabilidade, adequação a propósito específico ou não-infringência.\n\n9.2. A Mooze não será responsável por:\n(a) perdas de ativos digitais decorrentes de perda, comprometimento ou uso indevido de chaves privadas, frases-semente ou senhas pelo Usuário;\n(b) perdas decorrentes de comprometimento do dispositivo do Usuário e utilização de Plataforma falsa (homógrafa / domínio falso) ou aplicativo adulterado ou baixado em fonte não oficial;\n(c) indisponibilidade, falhas, atrasos, forks, reorganizações ou interrupções na Liquid Network, na rede Bitcoin, na Lightning Network ou em qualquer outra rede blockchain ou sidechain;\n(d) falhas, indisponibilidade ou atrasos nos serviços prestados pelas Parceiras Reguladas, pela Eulen.app LLC, pelo projeto depix.info, pelo protocolo SideSwap, pelo Breez SDK ou por quaisquer provedores de infraestrutura de terceiros;\n(e) atos de fraude, phishing, engenharia social, SIM swap ou qualquer forma de ataque dirigido ao Usuário por terceiros (incluindo obtenção de aplicação ou serviço software fraudulento qual o usuário consentiu uso sem verificação de fonte como comentado no item 6.3), inclusive por comunicação enganosa, uso de contatos de e-mail homógrafos, domínios semelhantes ao domínio oficial da Mooze, aplicativos adulterados, perfis falsos em redes sociais ou mensageiros, e quaisquer outras modalidades de ataque dirigidas ao Usuário, cuja prevenção não está sob controle da Mooze;\n(f) erros na inserção de endereços de carteira pelo Usuário, resultando em envio de ativos digitais a endereços incorretos; falhas de envio ou recebimento de ativos em plataformas e serviços de terceiros; recusa de ativos por serviços de terceiros; falhas em contratos inteligentes em quaisquer redes blockchain iniciados direta ou indiretamente pelo Usuário por meio de sua autocustódia; utilização de taxas de rede (fees) insuficientes que acarretem não mineração ou atraso da transação; utilização dos Serviços via PIX, por terceiros, para atividades dolosas ou ilícitas, não obstante a existência de sistemas antifraude conjuntos — casos nos quais a Mooze não se responsabiliza, por não intermediar, endossar ou validar a relação subjacente entre o Usuário-comerciante e o pagador;\n(g) alterações regulatórias que afetem a disponibilidade dos Serviços em determinada jurisdição, incluindo interrupção ou descontinuação total em resposta a exigências legais supervenientes;\n(h) variação no valor de ativos digitais;\n(i) decisões de investimento tomadas pelo Usuário com base em informações exibidas no Aplicativo ou em qualquer outro material da Mooze;\n(j) danos indiretos, incidentais, consequenciais, punitivos, lucros cessantes, perda de oportunidade, perda de dados ou perda reputacional.\n\n9.2.1. A Mooze não se responsabiliza por: (i) decisões tomadas por sistemas programáticos automatizados participantes do ecossistema; (ii) prazos de processamento determinados por infraestruturas de terceiros ou Parceiras Reguladas; (iii) critérios de análise aplicados por prestadores de serviço especializados; (iv) reversões solicitadas por instituições financeiras, Parceiras Reguladas ou autoridades reguladoras.\n\n9.3. A Mooze não se responsabiliza por quaisquer obrigações tributárias, fiscais, regulatórias, trabalhistas ou legais do Usuário decorrentes da posse, utilização, conversão, alienação, recebimento ou movimentação de ativos digitais. A responsabilidade pelo cumprimento de obrigações tributárias — incluindo, quando aplicável, quaisquer instruções normativas ou obrigações acessórias relacionadas a criptoativos e ou declaração de rendimentos sob sua legislação de residência fiscal — é integralmente do Usuário, incluindo a responsabilidade de monitorar transações próprias onchain para cumprir obrigações de caráter pessoal e próprio.\n\n9.4. O Aplicativo pode operar em versão BETA, podendo coexistir com versões de release estável por tempo determinado. O Usuário concorda que, durante o período BETA, podem ocorrer defeitos, instabilidades ou interrupções, e aceita todos os riscos decorrentes.\n\n9.5. As frases-semente geradas no Aplicativo são compatíveis com o padrão aberto BIP39 e com a Liquid Network. Em caso de indisponibilidade crítica do Aplicativo, descontinuação dos Serviços ou encerramento das atividades da Mooze, o Usuário poderá recuperar o acesso a seus ativos digitais importando suas frases-semente em qualquer software de carteira compatível com a rede correspondente (por exemplo, o Blockstream App para a Liquid Network e rede Bitcoin onchain qual automaticamente deriva todos os saldos em posse de usuário e seus históricos blockchains). Esta previsão constitui garantia estrutural da autocustódia e elemento integrante do modelo não-custodial da Mooze.';

  @override
  String get terms_section_10_body =>
      '10.1. A Mooze implementa mecanismos de segurança em nível de software para prevenção de fraudes, incluindo:\n(a) vinculação de APP ID (identificador técnico de dispositivo) a operações realizadas;\n(b) sistema de scoring por níveis de risco;\n(c) limites progressivos por operação conforme histórico do APP ID;\n(d) detecção de padrões anômalos (smurfing, bursting, autopagamentos coordenados, uso de múltiplos dispositivos para uma mesma operação, uso de emuladores, uso de dispositivos modificados).\n\n10.2. As medidas antifraude da Mooze são de natureza exclusivamente tecnológica, aplicadas ao fluxo de software, e não substituem as obrigações de prevenção à lavagem de dinheiro (AML), de identificação de clientes (KYC) e da \"Travel Rule\" das Parceiras Reguladas e demais VASPs intervenientes.\n\n10.3. As Parceiras Reguladas são as únicas responsáveis pelo cumprimento de obrigações de AML e KYC perante o Banco Central do Brasil, o COAF e demais autoridades competentes, nos termos da Lei n. 9.613/1998, da Lei n. 14.478/2022 e da regulamentação aplicável ou demais leis futuras que venham a ser acessórias.';

  @override
  String get terms_section_11_body =>
      '11.1. A Mooze reserva-se o direito de suspender, limitar ou encerrar o acesso de um APP ID aos Serviços, com ou sem aviso prévio, nas seguintes hipóteses:\n(a) detecção de padrão indicativo de fraude, atividade ilícita ou tentativa de abuso dos Serviços;\n(b) utilização de dispositivos comprometidos, rooted, com jailbreak, emuladores ou ferramentas de manipulação;\n(c) tentativa de contornar os mecanismos de segurança, antifraude, limites operacionais do Aplicativo, tentativas de sabotagem ou ataques a infraestrutura Mooze;\n(d) padrões indicativos de utilização dos Serviços para lavagem de dinheiro, financiamento ao terrorismo, sanções ou qualquer finalidade ilícita;\n(e) solicitação fundamentada de autoridade competente ou determinação judicial válida;\n(f) utilização a partir de jurisdição restrita nos termos da cláusula 12.1(a).\n\n11.2. A suspensão de acesso atinge exclusivamente a capacidade do APP ID de iniciar novas operações que utilizam-se de conexões ao sistema PIX das parceiras reguladas por meio do Aplicativo. Os ativos digitais em autocustódia do Usuário permanecem integralmente sob seu controle, uma vez que estão armazenados em sua própria carteira e são acessíveis por meio de sua frase-semente em qualquer software de carteira compatível com a rede correspondente.\n\n11.3. A Mooze cooperará com autoridades competentes mediante determinação judicial válida, observadas as limitações técnicas inerentes ao modelo autocustodial (a Mooze não possui acesso a chaves privadas, frases-semente ou ativos digitais do Usuário). A cooperação da Mooze limita-se ao fornecimento dos dados efetivamente sob sua posse técnica (APP ID, endereços públicos, dados de transação, blinding keys), nos termos da Seção 5 da Política de Privacidade.\n\n11.4. Os procedimentos de MED são processados pelas Parceiras Reguladas, entidades participantes do sistema PIX. A Mooze colabora tecnologicamente com as Parceiras Reguladas, fornecendo informações de APP ID e dados de transação quando solicitada, mas não opera como participante do sistema PIX.';

  @override
  String get terms_section_12_body =>
      '12.1. O Usuário declara, garante e assume, de forma expressa e informada, que:\n(a) utiliza os Serviços em conformidade com a legislação aplicável em sua jurisdição de domicílio e residência. O Usuário declara não ser residente, domiciliado, cidadão, nacional ou \"US Person\" nos termos da Regulation S (SEC), nem residente, nacional ou cidadão de: (i) Estados Unidos da América e seus territórios; (ii) Reino Unido; (iii) Estados-Membros da União Europeia e do Espaço Econômico Europeu; (iv) jurisdições constantes das listas de sanções OFAC (U.S. Office of Foreign Assets Control), das sanções do Conselho de Segurança das Nações Unidas, das sanções da União Europeia ou do Reino Unido; (v) jurisdições classificadas pelo FATF como High-Risk Jurisdictions Subject to a Call for Action, a Mooze poderá fazer uso de meios de verificação de regionalidade para cumprir tais verificações, qual o usuário fica ciente e de acordo. Caso se constate, a qualquer tempo, que o Usuário é residente, nacional ou cidadão de jurisdição restrita, o acesso do APP ID aos Serviços poderá ser imediatamente suspenso ou encerrado. A presente cláusula não estende, em nenhuma hipótese, jurisdição regulatória sobre a Mooze Labs LLC em relação a tais jurisdições, tendo efeito exclusivamente de filtro contratual;\n(b) os recursos utilizados em operações via PIX são de origem lícita e comprovável, decorrentes de atividades legalmente exercidas;\n(c) não utiliza os Serviços para lavagem de dinheiro, financiamento ao terrorismo, evasão fiscal, evasão de sanções, tráfico de pessoas, tráfico de entorpecentes, corrupção ou qualquer finalidade ilícita;\n(d) é o responsável exclusivo pela declaração e pagamento de tributos incidentes sobre a posse, utilização, recebimento, conversão ou alienação de ativos digitais em sua jurisdição, incluindo, quando aplicável, o cumprimento da Instruções Normativas nacionais relativas à sua residência fiscal ou cidadania atual.\n(e) deve utilizar os Serviços somente com conhecimento das obrigações de regimento de criptoativos de sua residência fiscal ou nacionalidade e reconhece que a Mooze não se enquadra como prestadora de serviços de ativos virtuais (PSAV) nos termos da referida lei, uma vez que (i) não realiza custódia, intermediação, administração, negociação ou corretagem de ativos virtuais em nome ou por conta de terceiros, (ii) opera exclusivamente como provedora de software não-custodial, (iii) tem sede fora do território brasileiro, em jurisdição estrangeira;\n(f) compreende e aceita que obteve acesso aos Serviços por busca ativa e voluntária própria (reverse solicitation), sem que tenha sido objeto de coerção ou persuasão linguística de nenhuma natureza iniciada pela Mooze;\n(g) compreende e aceita os riscos inerentes à tecnologia blockchain, incluindo volatilidade, risco regulatório, risco de forks, risco tecnológico e risco de perda total.\n\n12.2. A Mooze não presta serviços de consultoria tributária, fiscal ou jurídica. O Usuário deve buscar orientação profissional independente para o cumprimento de suas obrigações legais.\n\n12.3. A Mooze não realiza, em nome do Usuário, declarações fiscais, relatórios de operações, informes de rendimentos ou comunicações a qualquer autoridade tributária. O Usuário é o único responsável por tais obrigações.\n\n12.4. A Mooze não presta Serviços a pessoas politicamente expostas (PEPs) sujeitas a restrições específicas de jurisdições sancionadoras, devendo o Usuário declarar-se adequadamente e abster-se de utilizar os Serviços em violação a tais restrições.';

  @override
  String get terms_section_13_body =>
      '13.1. Estes Termos são regidos exclusivamente pelas leis da República das Ilhas Marshall, incluindo, em especial, a Associations Law (Título 52, MIRC) e a Banking (Amendment) Act, 2020 (P.L. 2020-61).\n\n13.2. A Mooze Labs LLC é entidade regularmente constituída na República das Ilhas Marshall e opera a partir dessa jurisdição. A Mooze NÃO possui estabelecimento permanente, filial, sucursal, escritório de representação, agência, preposto ou qualquer forma de presença física, operacional ou jurídica no Brasil ou em qualquer outra jurisdição, exceto pela jurisdição de constituição.\n\n13.3. A relação entre a Mooze e as Parceiras Reguladas é regida por contratos internacionais independentes, os quais não criam qualquer vínculo societário, relação de representação, agência, mandato, preposição, consórcio ou responsabilidade solidária entre a Mooze e tais parceiras.\n\n13.4. A eventual utilização dos Serviços por Usuário domiciliado no Brasil não implica, por si só, submissão da Mooze à jurisdição brasileira, em razão do caráter de Oferta Passiva e da ausência de estabelecimento no país, observados os limites das leis imperativas aplicáveis.';

  @override
  String get terms_section_14_body =>
      '14.1. Qualquer disputa, controvérsia ou reclamação decorrente destes Termos, ou a eles relacionada, será resolvida, a exclusivo critério da Mooze:\n(a) pelos tribunais competentes da República das Ilhas Marshall; ou\n(b) por arbitragem internacional conduzida sob as Regras de Arbitragem da UNCITRAL (Comissão das Nações Unidas para o Direito Comercial Internacional), por árbitro único, no idioma inglês, com sede da arbitragem a ser definida pela Mooze.\n\n14.2. O Usuário renuncia a qualquer foro que não os indicados na cláusula 14.1, exceto quando a renúncia for vedada por lei imperativa de sua jurisdição de domicílio.\n\n14.3. Antes de iniciar qualquer procedimento formal, o Usuário deverá enviar notificação redigida à Mooze mediante dados completos obtidos de aplicativo ou Plataforma Mooze, pelo canal indicado na Seção 19, descrevendo detalhadamente a necessidade. As partes envidarão esforços de boa-fé para resolução amigável no prazo de 30 (trinta) dias corridos a partir do recebimento da notificação.\n\n14.4. Em caso de arbitragem, cada parte arcará com seus próprios custos e honorários, e os custos administrativos da arbitragem serão suportados pela parte vencida, na medida do permitido pelas Regras UNCITRAL.';

  @override
  String get terms_section_15_body =>
      '15.1. Todo o software, código-fonte, design, interface gráfica, marcas, logotipos, nomes comerciais, conteúdo editorial e documentação do Aplicativo são de propriedade exclusiva da Mooze Labs LLC ou de seus licenciadores, salvo quando expressamente disponibilizados como código aberto em repositório oficial da Mooze no GitHub. O que não for expressamente disponibilizado como código aberto permanece protegido pela legislação aplicável de propriedade intelectual.\n\n15.2. A utilização do Aplicativo não confere ao Usuário qualquer direito de propriedade intelectual sobre o Aplicativo ou seus componentes, salvo os direitos limitados de uso pessoal decorrentes destes Termos.\n\n15.3. É vedada a reprodução, modificação, distribuição, engenharia reversa, descompilação, desmontagem ou criação de obras derivadas do Aplicativo sem autorização expressa e por escrito da Mooze, à exceção do que for expressamente disponibilizado como código aberto no repositório oficial da Mooze e utilizado nos termos da licença ali indicada.\n\n15.4. O código-fonte do Aplicativo está disponibilizado publicamente em https://github.com/mooze-labs/mooze-client sob os termos da licença ali indicada. O uso do código-fonte está sujeito exclusivamente aos termos dessa licença, independentemente dos presentes Termos.';

  @override
  String get terms_section_16_body =>
      '16.1. INTEGRALIDADE\nEstes Termos, conjuntamente com a Política de Privacidade que os acompanha, constituem o acordo integral entre a Mooze e o Usuário em relação ao objeto aqui tratado, substituindo quaisquer acordos, entendimentos, memorandos ou comunicações anteriores, orais ou escritos.\n\n16.2. SEVERABILIDADE\nSe qualquer disposição destes Termos for declarada inválida, nula, ilegal ou inexequível por tribunal ou árbitro competente, as demais disposições permanecerão em pleno vigor e efeito. A disposição inválida será interpretada e, sendo possível, substituída por disposição válida que mais se aproxime da intenção original das partes e do equilíbrio econômico-jurídico do contrato.\n\n16.3. RENÚNCIA\nA omissão ou tolerância da Mooze em exigir o cumprimento de qualquer disposição destes Termos, em uma ou mais ocasiões, não constituirá renúncia ao direito de exigi-la posteriormente.\n\n16.4. CESSÃO\nO Usuário não pode ceder, transferir, sublicenciar ou onerar seus direitos ou obrigações decorrentes destes Termos sem autorização prévia e por escrito da Mooze. A Mooze pode ceder livremente seus direitos e obrigações decorrentes destes Termos a qualquer entidade afiliada, sucessora, adquirente ou cessionária, mediante notificação ao Usuário pelos canais oficiais.\n\n16.5. FORÇA MAIOR E ILEGALIDADE SUPERVENIENTE\nA Mooze não será responsável por atraso ou impossibilidade de cumprimento de suas obrigações decorrente de eventos fora de seu controle razoável, incluindo, sem limitação:\n(a) falhas ou interrupções na Liquid Network, na rede Bitcoin, na Lightning Network ou em qualquer rede blockchain;\n(b) indisponibilidade de serviços das Parceiras Reguladas ou de provedores de infraestrutura de terceiros;\n(c) ataques cibernéticos, falhas de infraestrutura de internet ou de telecomunicações;\n(d) decisões governamentais, regulatórias ou judiciais, em qualquer jurisdição, que restrinjam ou inviabilizem a operação;\n(e) desastres naturais, pandemias, guerras, greves, distúrbios civis ou estados de emergência;\n(f) alterações legislativas ou regulatórias que tornem a prestação dos Serviços ilegal ou inviável em determinada jurisdição, caso no qual a Mooze poderá suspender ou encerrar os Serviços na respectiva jurisdição sem responsabilidade adicional, observada a autocustódia dos ativos do Usuário.\n\n16.6. INDENIZAÇÃO\nO Usuário concorda em indenizar, defender e isentar a Mooze, suas afiliadas, diretores, membros, empregados, contratados, agentes e licenciadores de quaisquer reclamações, danos, perdas, custos (incluindo honorários advocatícios razoáveis) e responsabilidades decorrentes de:\n(a) utilização dos Serviços pelo Usuário em desconformidade com estes Termos;\n(b) violação de qualquer lei ou regulamento aplicável pelo Usuário;\n(c) reclamações de terceiros relacionadas a atos ou omissões do Usuário;\n(d) prestação de informações falsas, inexatas ou omissas pelo Usuário, inclusive quanto a declarações falsas sobre não-residência em jurisdições restritas e sobre a origem lícita de recursos.\n\n16.7. DISTRIBUIÇÃO DO APLICATIVO\nA distribuição do Aplicativo em plataformas digitais, incluindo Google Play Store, Apple App Store e demais canais, é realizada conjuntamente pela Mooze LLC, sociedade de responsabilidade limitada constituída no Estado de Delaware, Estados Unidos, na qualidade de distribuidora autorizada da Mooze Labs LLC, nos termos de contrato de distribuição independente celebrado entre as partes. A Mooze LLC (Delaware) atua exclusivamente como distribuidora e representante para fins de publicação em plataformas digitais, sem assumir quaisquer responsabilidades de desenvolvimento, operação, suporte ao usuário, conformidade regulatória ou custódia de ativos. A titularidade, o desenvolvimento, a operação e todas as responsabilidades legais, regulatórias e contratuais relativas ao Aplicativo e aos Serviços permanecem exclusivamente com a Mooze Labs LLC (República das Ilhas Marshall). A relação entre a Mooze Labs LLC e a Mooze LLC (Delaware) não altera a natureza jurídica, o enquadramento regulatório, a jurisdição aplicável ou quaisquer disposições destes Termos. O cumprimento das políticas de distribuição das lojas de aplicativos (incluindo, sem limitação, as políticas Cryptocurrency Exchanges and Software Wallets — Google Play e App Store Review Guidelines 3.1.5 — Apple) é realizado mediante declaração de que a Mooze Wallet é carteira exclusivamente não-custodial, fora do escopo que exige licença VASP para publicação.\n\n16.8. IDIOMA\nEstes Termos são redigidos originalmente em português do Brasil. Em caso de traduções para outros idiomas, a versão em português prevalece em eventual divergência de interpretação, todos os termos aqui redigidos apresentados, principalmente em português brasileiro, existem com o único e exclusivo fim de esclarecimento ao público regional do LATAM, principal região onde os serviços PIX do Brasil existem com maior alcance, não devendo ser interpretado este fato de comunicação como intenção de sede e ou execução de serviços software sob territórios além da constituição da Mooze Labs LLC.';

  @override
  String get terms_section_17_body =>
      '17.1. O Aplicativo e os Serviços são destinados exclusivamente a pessoas naturais com idade igual ou superior a 18 (dezoito) anos.\n\n17.2. Ao utilizar o Aplicativo, o Usuário declara ter pelo menos 18 (dezoito) anos de idade e possuir capacidade civil plena para celebrar contratos vinculantes.\n\n17.3. A Mooze reserva-se o direito de suspender ou encerrar o acesso de qualquer Usuário em relação ao qual se verifique ser menor de 18 (dezoito) anos não emancipado.\n\n17.4. O Aplicativo constitui exclusivamente software de gestão de carteira digital autocustodial e instrumentação de operações financeiras com ativos digitais, não configurando rede social, plataforma de mídia social, serviço de mensageria, plataforma de streaming, serviço de entretenimento, aplicação de jogos eletrônicos ou qualquer modalidade de plataforma digital com funcionalidades de engajamento ou interação social entre usuários.\n\nEm razão dessa natureza, a Mooze não se enquadra no escopo de aplicação da Lei n. 15.211/2025 (Lei de Proteção de Crianças e Adolescentes no Ambiente Digital — \"ECA Digital\"), cujas obrigações se dirigem a redes sociais, plataformas de entretenimento, jogos eletrônicos e serviços com funcionalidades aditivas ou de engajamento comportamental. A Mooze não disponibiliza, e não possui capacidade técnica de disponibilizar:\n\n(a) funcionalidades de criação, publicação ou compartilhamento de conteúdo entre usuários;\n(b) mecanismos de interação social (curtidas, comentários, reações, compartilhamentos);\n(c) redes de contatos, seguidores, amizades ou conexões entre usuários;\n(d) algoritmos de recomendação de conteúdo, feeds personalizados ou scroll infinito;\n(e) chat, mensageria, comunicação direta ou indireta entre usuários do Aplicativo;\n(f) perfis públicos de usuários, timelines ou espaços de conteúdo gerado por usuários;\n(g) mecanismos de gamificação, recompensas por engajamento, notificações comportamentais ou recursos projetados para maximizar o tempo de uso.\n\nA utilização dos Serviços por brasileiros pressupõe, de forma estrutural e inafastável, a capacidade civil plena do Usuário, nos termos dos artigos 3º, 4º e 5º da Lei n. 10.406/2002 (Código Civil Brasileiro), uma vez que os Serviços envolvem celebração de contratos vinculantes e disposição de ativos financeiros — atos jurídicos que menores não emancipados são legalmente inaptos a praticar por conta própria. Esse requisito estrutural configura, por si só, mecanismo jurídico de exclusão do público infanto-juvenil incompatível com qualquer enquadramento como plataforma digital sujeita às obrigações da Lei n. 15.211/2025 ou às disposições do Estatuto da Criança e do Adolescente (Lei n. 8.069/1990) aplicáveis a serviços de entretenimento e conteúdo.';

  @override
  String get terms_section_18_body =>
      '18.1. A Mooze reserva-se o direito de alterar estes Termos a qualquer momento, publicando a versão atualizada no Aplicativo e em https://mooze.app/termosdeuso/, com indicação da data da nova versão.\n\n18.2. Alterações relevantes serão comunicadas ao Usuário por meio do Aplicativo, canal de suporte no Telegram ou comunicação via e-mail, quando disponível.\n\n18.3. A continuidade de utilização do Aplicativo após a publicação de alterações constitui aceitação tácita dos Termos atualizados.\n\n18.4. O Usuário que não concordar com as alterações deverá cessar a utilização do Aplicativo. Os ativos digitais em autocustódia do Usuário permanecem sob seu exclusivo controle e são acessíveis por meio de sua frase-semente em qualquer software de carteira compatível.';

  @override
  String get terms_section_19_body =>
      '19.1. Para dúvidas, solicitações ou comunicações relacionadas a estes Termos, o Usuário poderá contatar a Mooze pelos seguintes canais oficiais:\n(a) E-mail de suporte: suporte@mooze.app\n(b) Canal de suporte no Telegram: https://t.me/+zkNS6KIDsEcyZDkx (também acessível via https://moozeapp.keepo.bio)\n(c) FAQ automatizado via Telegram\n\n19.2. Notificações formais de natureza jurídica (incluindo notificações de disputa nos termos da cláusula 14.3, intimações, citações ou ordens judiciais) devem ser endereçadas por escrito à Mooze Labs LLC, Trust Company Complex, Ajeltake Island, Ajeltake Road, Majuro, Marshall Islands MH96960, República das Ilhas Marshall, com cópia para o e-mail suporte@mooze.app, não constituindo citação válida o envio por quaisquer outros canais ou jurisdições.\n\n19.3. A Mooze envidará esforços para responder a comunicações de suporte no prazo de 2 (dois) a 10 (dez) dias úteis. Notificações formais serão respondidas nos prazos aplicáveis da legislação de RMI ou da arbitragem UNCITRAL, conforme o caso.';

  @override
  String get privacy_section_header_body =>
      'Data da última atualização: 18/04/2026\n\nMooze Labs LLC\nRepública das Ilhas Marshall\nhttps://mooze.app';

  @override
  String get privacy_section_1_body =>
      '1.1. A Mooze Labs LLC (\"Mooze\"), sociedade regularmente constituída na República das Ilhas Marshall, está comprometida com a proteção da privacidade e com a minimização de dados pessoais no uso do aplicativo Mooze Wallet (\"Aplicativo\").\n\n1.2. Esta Política de Privacidade (\"Política\") descreve quais informações são coletadas, como são utilizadas, com quem são compartilhadas e quais direitos o Usuário possui em relação a seus dados.\n\n1.3. A Mooze adota o princípio de minimização de dados como pilar central de sua operação. O Aplicativo foi projetado para funcionar sem a coleta de dados pessoais identificáveis pela Mooze.\n\n1.4. Esta Política deve ser lida em conjunto com os Termos de Uso do Aplicativo.';

  @override
  String get privacy_section_2_body =>
      '2.1. Todos os termos definidos nos Termos de Uso e utilizados nesta Política possuem os mesmos significados atribuídos na Seção 3 dos Termos de Uso, salvo disposição expressa em contrário neste documento.\n\n2.2. Para fins desta Política, aplicam-se adicionalmente as seguintes definições:\n(a) \"Dados Pessoais\": qualquer informação relacionada a pessoa natural identificada ou identificável, nos termos da Lei Geral de Proteção de Dados (Lei n. 13.709/2018 — LGPD) ou de legislação equivalente.\n(b) \"Tratamento\": toda operação realizada com Dados Pessoais, incluindo coleta, armazenamento, uso, compartilhamento e eliminação.\n(c) \"LGPD\": Lei Geral de Proteção de Dados do Brasil (Lei n. 13.709/2018).\n(d) \"Controlador\" e \"Operador\": as figuras definidas na LGPD, aplicáveis, quando cabível, às relações entre a Mooze, o Usuário e as Parceiras Reguladas.';

  @override
  String get privacy_section_3_body =>
      '3.1. DADOS QUE A MOOZE NÃO COLETA NEM ARMAZENA\nA Mooze NÃO faz coleta em seus sistemas ou servidores, em relação a Usuários do Aplicativo:\n(a) CPF, RG, passaporte ou qualquer documento de identificação civil;\n(b) nome civil completo;\n(c) número de telefone;\n(d) endereço residencial ou de correspondência;\n(e) data de nascimento;\n(f) dados biométricos (a identificação de dispositivo utilizada é hash criptográfico unidirecional, não constituindo biometria pessoal);\n(g) chaves privadas, frases-semente ou senhas do Usuário;\n(h) imagens, fotografias ou vídeos: a câmera do dispositivo é acessada exclusivamente para leitura de códigos QR (endereços e faturas de pagamento), com processamento realizado localmente no próprio dispositivo; nenhuma imagem ou captura é coletada, armazenada ou transmitida à Mooze ou a terceiros.\n\n3.2. DADOS QUE A MOOZE COLETA\nA Mooze coleta exclusivamente os seguintes dados:\n(a) APP ID: identificador técnico de dispositivo, gerado a partir de funcionalidades do sistema operacional (MediaDRM em dispositivos Android, DeviceCheck em dispositivos iOS). O APP ID é hash criptográfico unidirecional que, isoladamente, não permite a identificação pessoal do Usuário. É utilizado exclusivamente para prevenção a fraudes e controle de limites operacionais.\n(b) Dados de carteira: descriptors, endereços e chaves públicas derivados matematicamente das chaves do Usuário, utilizados como parâmetro técnico de roteamento automatizado para a entrega de ativos digitais ao Usuário durante a execução dos Serviços, nenhum desses dados permite à Mooze mover ou acessar fundos de usuários.\n(c) Blinding keys (chaves de ocultação): chaves criptográficas associadas a Confidential Transactions na Liquid Network, retidas pela Mooze exclusivamente para verificação e reconciliação de transações processadas por meio do Aplicativo nas funções envolvendo Infratechs Parceiras via PIX.\n(d) Dados de transação: registros das operações realizadas por meio do Aplicativo, incluindo valores, tipos de ativos, carimbos temporais (timestamps), hashes de transação e status de execução. Esses dados são retidos para fins de prestação do Serviço, suporte ao Usuário, reconciliação com parceiros e cumprimento de eventuais obrigações legais aplicáveis à Mooze enquanto entidade não-VASP.\n(e) Dados técnicos de dispositivo: informações genéricas de funcionamento do Aplicativo, como versão do sistema operacional, modelo do dispositivo, versão do Aplicativo instalada e logs internos essenciais para resolução de suporte e depuração técnica. Esses dados não permitem a identificação pessoal do Usuário.\n(f) Token de notificação (push): identificador técnico gerado pelo serviço Firebase Cloud Messaging (Google LLC), utilizado exclusivamente para o envio de notificações operacionais, como alertas de transação, ao dispositivo do Usuário. O token não contém dados pessoais identificáveis, não é utilizado para publicidade, e sua geração depende de permissão de notificações concedida pelo Usuário no dispositivo.\n\n3.3. PERMISSÕES DO DISPOSITIVO\nO Aplicativo solicita as seguintes permissões do dispositivo, sempre mediante autorização do Usuário no sistema operacional e com as finalidades a seguir indicadas:\n(a) Câmera: exclusivamente para leitura de códigos QR (endereços e faturas de pagamento), com processamento local; imagens não são coletadas, armazenadas nem transmitidas;\n(b) Notificações: exclusivamente para o envio de alertas operacionais de transação, por meio do serviço Firebase Cloud Messaging (Google LLC);\n(c) Autenticação biométrica ou credencial do dispositivo: exclusivamente para bloqueio de acesso local ao Aplicativo, processada pelo próprio sistema operacional do dispositivo; a Mooze não coleta, acessa nem armazena dados biométricos;\n(d) Acesso à rede e à internet: para comunicação com as redes Bitcoin, Liquid Network e Lightning Network e com os provedores de infraestrutura descritos nesta Política.';

  @override
  String get privacy_section_4_body =>
      '4.1. Quando o Usuário realiza operações que envolvem pagamento via PIX (Serviço A relativos termos de uso), os dados necessários ao processamento do pagamento — incluindo nome civil do pagador, CPF do pagador, chave PIX, dados bancários e demais dados necessários ao cumprimento de obrigações de KYC, AML e Travel Rule — são coletados e processados exclusivamente pelas Parceiras Reguladas no Brasil via serviços indiretos ou diretos com nossas parceiras tecnológicas, nos limites de suas respectivas atividades via automações em sistemas vínculados ao sistema financeiro brasileiro.\n\n4.2. As Parceiras Reguladas são:\n\n(a) PLEBIT.COM.BR Soluções em Tecnologia Ltda — CNPJ 43.375.652/0001-13;\n(b) Fits Instituição de Pagamento — CNPJ 13.203.354/0001-85;\n(c) Celcoin — CNPJ 13.935.893/0001-09;\n(d) PLEBZ INTERMEDIACAO DE PAGAMENTOS LTDA — CNPJ 45.808.899/0001-01.\n\nEsta lista de parceiras pode diminuir ou ser acrescentada, de acordo modificações ou mudanças contratuais e suas disponibilidades.\n\n4.3. A coleta, o armazenamento e o tratamento de dados pessoais pelas Parceiras Reguladas são regidos pelas respectivas políticas de privacidade dessas entidades, em conformidade com a LGPD e com a regulamentação do Banco Central do Brasil. Cada Parceira Regulada atua como Controlador autônomo dos dados pessoais por ela tratados.\n\n4.4. A comunicação entre o software da Mooze e as Parceiras Reguladas limita-se a dados estritamente necessários ao roteamento automatizado da operação (valor, chaves públicas, endereço de carteira de destino, identificador da operação, identificadores criptográficos irreversíveis derivados de dados do pagador e quando necessário, APP ID para fins antifraude).\n\n4.5. A Eulen.app LLC, enquanto provedora de infraestrutura tecnológica e emissora do token DEPIX e demais parceiras infratechs podem coletar e processar dados operacionais necessários para a emissão dos tokens e atividades correlacionadas, conforme políticas de privacidade próprias, sem que a Mooze atue como Controlador de tais dados.';

  @override
  String get privacy_section_5_body =>
      '5.1. A Mooze compartilha dados exclusivamente nas seguintes hipóteses:\n(a) Com as Parceiras Reguladas e com a Eulen.app LLC: dados estritamente necessários ao roteamento automatizado das operações (endereços de carteira, valores, identificadores de operação e APP ID quando necessário para fins antifraude).\n(b) Mediante determinação judicial: a Mooze poderá fornecer os dados sob sua posse (APP ID, endereços de carteira, blinding keys e dados correlacionados coletados) mediante ordem judicial válida emanada de tribunal competente, observadas as regras de reconhecimento internacional de decisões judiciais aplicáveis a entidades sediadas na República das Ilhas Marshall.\n(c) Para cumprimento de obrigação legal: quando exigido por lei aplicável na jurisdição da República das Ilhas Marshall.\n(d) Em procedimentos de MED conduzidos pelas Parceiras Reguladas: fornecimento técnico de APP ID e dados correlacionados necessários quando relatórios probatórios de execução de serviço ou exigências sob necessidade de defesa das mesmas for requisitado via demandas legais, regulatórias ou de compliance.\n\n5.2. A Mooze NÃO vende, aluga, comercializa, cede ou compartilha dados com terceiros para fins de marketing, publicidade, analytics comportamental ou qualquer finalidade não descrita nesta Política.\n\n5.3. Para viabilizar o envio de notificações push, o token de notificação do dispositivo é processado pelo serviço Firebase Cloud Messaging, fornecido pelo Google LLC, exclusivamente com essa finalidade. Nenhum outro dado pessoal é compartilhado com o Google para o envio de notificações.';

  @override
  String get privacy_section_6_body =>
      '6.1. Quando o Usuário contata a Mooze por meio dos canais de suporte (e-mail suporte@mooze.app ou Telegram), os dados compartilhados voluntariamente pelo Usuário durante a comunicação (como nome de usuário em plataformas de mensagens, conteúdo das mensagens e eventuais capturas de tela) serão utilizados exclusivamente para fins de atendimento à solicitação.\n\n6.2. A Mooze não associa, como regra, dados de comunicação de suporte a APP IDs ou endereços de carteira, exceto quando o próprio Usuário fornecer tais informações voluntariamente para fins de resolução de problema específico.';

  @override
  String get privacy_section_7_body =>
      '7.1. A Mooze adota medidas técnicas e organizacionais razoáveis, compatíveis com o estado da arte aplicável, para proteger os dados sob sua responsabilidade contra acesso não autorizado, destruição, perda, alteração, comunicação ou divulgação indevidas.\n\n7.2. Os dados coletados pela Mooze são armazenados em infraestrutura protegida, com controles de acesso e criptografia em trânsito e em repouso.\n\n7.3. A Mooze não pode garantir segurança absoluta na transmissão de dados pela internet ou em sistemas de armazenamento eletrônico. O Usuário reconhece que nenhum método de transmissão ou armazenamento eletrônico é integralmente imune a falhas.';

  @override
  String get privacy_section_8_body =>
      '8.1. Os dados coletados pela Mooze são retidos pelos seguintes períodos:\n(a) APP ID: 5 (cinco) anos contados da última operação. Após esse período, será eliminado, salvo obrigação legal de retenção.\n(b) Endereços de carteira, descriptors, chaves públicas e blinding keys: 5 (cinco) anos contados da última operação, para fins de verificação, reconciliação e cumprimento de eventuais obrigações legais.\n(c) Dados de transação: 5 (cinco) anos contados da data da transação.\n(d) Dados técnicos de dispositivo: eliminados após 5 (cinco) anos de inatividade.\n\n8.2. Os prazos acima poderão ser estendidos quando necessário para: (a) cumprimento de obrigação legal; (b) atendimento a ordem judicial; (c) defesa em procedimento judicial, administrativo ou arbitral; (d) aprimoramento de sistemas antifraude próprios ou conjuntos com Parceiras Reguladas e Infratechs Parceiras, em volume minimamente necessário e de forma pseudonimizada sempre que possível.';

  @override
  String get privacy_section_9_body =>
      '9.1. Em observância à LGPD, e sem prejuízo de a Mooze não estar estabelecida no Brasil, a Mooze reconhece ao Usuário, na medida aplicável ao tratamento efetivamente realizado, os seguintes direitos:\n(a) confirmação da existência de tratamento de dados pseudoanônimos;\n(b) avaliação de solicitação de eliminação do APP ID associado a seu dispositivo e usuário de serviço software Mooze\n\n9.2. O exercício dos direitos previstos na cláusula 9.1 pode ser solicitado pelo Usuário por meio dos canais indicados na Seção 12 desta Política.\n\n9.3. A Mooze responderá às solicitações no prazo de 15 (quinze) dias úteis, nos termos da LGPD, admitida prorrogação fundamentada em casos de complexidade técnica ou volume.\n\n9.4. A eliminação do APP ID, uma vez atendida a solicitação, resultará na desativação do acesso do dispositivo aos Serviços que envolvam referencial FIAT (Serviço A e Modo Comerciante de acordo termos de uso). Em caso de reinstalação do Aplicativo, o acesso do aparelho aos Serviços via meios FIAT permanecerá bloqueado até nova solicitação formal, encaminhada pelo mesmo e-mail utilizado na solicitação de exclusão, com aceitação expressa e integral destes Termos e da Política de Privacidade.\n\n9.5. Determinados dados poderão ser retidos ou negados de exclusão mesmo após solicitação de eliminação, quando necessário para: (a) cumprimento de obrigação legal; (b) exercício regular de direitos em processo judicial, administrativo ou arbitral; (c) prevenção a fraudes (principalmente se o usuário com seu APP ID tiver andamento em envolvimentos sob contestações de pagamentos ocorridas, exemplo, MED), nos termos do art. 7º, IX, e do art. 16 da LGPD; conforme prazos indicados na Seção 8.';

  @override
  String get privacy_section_10_body =>
      '10.1. Os dados coletados pela Mooze são armazenados e processados em infraestrutura tecnológica localizada fora do território brasileiro.\n\n10.2. A jurisdição de dados aplicável à atividade de tratamento pela Mooze é a República das Ilhas Marshall, onde a Mooze está constituída e opera.\n\n10.3. Os dados operacionais transmitidos às Parceiras Reguladas durante a execução do Serviço A sob os termos de uso, são processados e armazenados no Brasil, sob a jurisdição brasileira e em conformidade com a LGPD, sob responsabilidade exclusiva das Parceiras Reguladas na qualidade de Controladores autônomos.\n\n10.4. A transferência de dados do Brasil para a infraestrutura da Mooze (quando houver), na medida em que constitua transferência internacional para fins da LGPD, é realizada com base nas hipóteses legais aplicáveis (art. 33 da LGPD), incluindo, conforme o caso, a necessidade de execução de contrato do qual o Usuário é parte e o cumprimento de obrigação legal.';

  @override
  String get privacy_section_11_body =>
      '11.1. A Mooze reserva-se o direito de alterar esta Política a qualquer momento, publicando a versão atualizada no Aplicativo e em https://mooze.app/, com indicação da data da nova versão.\n\n11.2. Alterações relevantes serão comunicadas ao Usuário por meio do Aplicativo ou do canal de suporte no Telegram.\n\n11.3. A continuidade de utilização do Aplicativo após a publicação de alterações constitui aceitação tácita da Política atualizada.';

  @override
  String get privacy_section_12_body =>
      '12.1. Para dúvidas ou solicitações relacionadas a esta Política de Privacidade, o Usuário poderá contatar a Mooze pelos seguintes canais oficiais:\n(a) E-mail: suporte@mooze.app\n(b) Canal de suporte no Telegram: https://t.me/+zkNS6KIDsEcyZDkx (também acessível via https://moozeapp.keepo.bio)\n(c) FAQ automatizado via Telegram\n\n12.2. Notificações formais relacionadas a dados pessoais devem ser endereçadas à Mooze Labs LLC, Trust Company Complex, Ajeltake Island, Ajeltake Road, Majuro, Marshall Islands MH96960, República das Ilhas Marshall, com cópia para o e-mail suporte@mooze.app, tais dados de encaminhamento poderão ser obtidos mediante contato por este mesmo e-mail.\n\n12.3. A Mooze envidará esforços para responder às comunicações no prazo de 15 (quinze) dias úteis.';

  @override
  String get developer_title => 'Hub da Carteira';

  @override
  String get developer_copy_debug_tooltip => 'Copiar informações de debug';

  @override
  String get developer_debug_copied => 'Informações de debug copiadas!';

  @override
  String get developer_sync_light_success => 'Sincronização rápida concluída!';

  @override
  String get developer_sync_full_success => 'Sincronização completa concluída!';

  @override
  String get developer_rescan_success =>
      'Swaps onchain reescaneados com sucesso!';

  @override
  String get developer_refundables_title => 'Reembolsos pendentes';

  @override
  String developer_refundables_message(int count) {
    return 'Encontrada(s) $count transação(ões) pendente(s) que podem ser reembolsadas.\n\nDeseja visualizá-las agora?';
  }

  @override
  String get developer_later => 'Mais tarde';

  @override
  String get developer_view_now => 'Ver agora';

  @override
  String get developer_email_ready => 'Email pronto para envio!';

  @override
  String get developer_share_logs_success => 'Logs compartilhados com sucesso!';

  @override
  String developer_sync_light_error(String error) {
    return 'Falha na sincronização rápida: $error';
  }

  @override
  String developer_sync_full_error(String error) {
    return 'Falha na sincronização completa: $error';
  }

  @override
  String developer_rescan_error(String error) {
    return 'Falha ao reescanear swaps: $error';
  }

  @override
  String developer_export_error(String error) {
    return 'Falha ao exportar logs: $error';
  }

  @override
  String developer_share_logs_error(String error) {
    return 'Erro ao compartilhar logs: $error';
  }

  @override
  String developer_log_retention_days(int days) {
    return '$days dias';
  }

  @override
  String get developer_clear_memory_success =>
      'Logs da memória limpos com sucesso!';

  @override
  String get developer_clear_db_success => 'Logs do banco limpos com sucesso!';

  @override
  String get developer_clear_all_success => 'Todos os logs limpos com sucesso!';

  @override
  String developer_clear_error(String error) {
    return 'Erro ao limpar logs: $error';
  }

  @override
  String get developer_system_info => 'Informações do sistema';

  @override
  String get developer_app_version => 'Versão do app';

  @override
  String get developer_sdk_version => 'Versão do SDK';

  @override
  String get developer_balance => 'Saldo';

  @override
  String get developer_pending_balance => 'Saldo pendente';

  @override
  String get developer_logs_memory => 'Logs (Memória)';

  @override
  String get developer_logs_db => 'Logs (Banco)';

  @override
  String get developer_log_retention_label => 'Retenção de logs';

  @override
  String get developer_tools_title => 'Ferramentas';

  @override
  String get developer_tools_subtitle => 'Sincronização, logs e diagnósticos';

  @override
  String get developer_action_light_sync => 'Light Sync';

  @override
  String get developer_action_light_sync_tooltip =>
      'Sincronização rápida (transações, saldos, preços)';

  @override
  String get developer_action_full_sync => 'Full Sync';

  @override
  String get developer_action_full_sync_tooltip =>
      'Sincronização completa da blockchain';

  @override
  String get developer_action_rescan => 'Rescan';

  @override
  String get developer_action_rescan_tooltip => 'Reescanear swaps onchain';

  @override
  String get developer_action_refund => 'Reembolso';

  @override
  String get developer_action_refund_tooltip => 'Ir para tela de reembolso';

  @override
  String get developer_action_view_logs => 'Ver Logs';

  @override
  String get developer_action_view_logs_tooltip => 'Ver logs do aplicativo';

  @override
  String get developer_action_export => 'Exportar';

  @override
  String get developer_action_export_tooltip => 'Exportar logs como ZIP';

  @override
  String get developer_action_clear_logs => 'Limpar Logs';

  @override
  String get developer_action_clear_logs_tooltip => 'Limpar todos os logs';

  @override
  String get developer_bitcoin_tip => 'Bloco Bitcoin atual';

  @override
  String get developer_unavailable => 'indisponível';

  @override
  String get developer_liquid_balances => 'Saldos Liquid';

  @override
  String get developer_section_synchronisation => 'Sincronização';

  @override
  String get developer_section_diagnostics => 'Diagnósticos';

  @override
  String get developer_time_just_now => 'agora mesmo';

  @override
  String developer_time_seconds_ago(int seconds) {
    return 'há ${seconds}s';
  }

  @override
  String developer_time_minutes_ago(int minutes) {
    return 'há ${minutes}min';
  }

  @override
  String developer_time_hours_ago(int hours) {
    return 'há ${hours}h';
  }

  @override
  String developer_time_days_ago(int days) {
    return 'há ${days}d';
  }

  @override
  String get export_logs_title => 'Exportar Logs';

  @override
  String get export_logs_description =>
      'Os logs do aplicativo ajudam nossa equipe a resolver problemas. Como você gostaria de compartilhar?';

  @override
  String get export_logs_by_email => 'Enviar por E-mail';

  @override
  String get export_logs_share => 'Salvar/Compartilhar';

  @override
  String get clear_logs_title => 'Limpar Logs';

  @override
  String get clear_logs_description => 'Escolha o que deseja limpar:';

  @override
  String get clear_logs_option_memory => 'Memória';

  @override
  String clear_logs_option_memory_desc(int count) {
    return 'Limpar apenas logs em memória ($count logs)';
  }

  @override
  String get clear_logs_option_db => 'Banco de dados';

  @override
  String clear_logs_option_db_desc(int count) {
    return 'Limpar apenas logs do banco ($count logs)';
  }

  @override
  String get clear_logs_option_all => 'Todos';

  @override
  String get clear_logs_option_all_desc => 'Limpar memória, arquivos e banco';

  @override
  String get clear_logs_cancel => 'Cancelar';

  @override
  String get logs_viewer_title => 'Logs do aplicativo';

  @override
  String get logs_viewer_loading => 'Carregando logs...';

  @override
  String get logs_viewer_empty => 'Nenhum log encontrado';

  @override
  String get logs_source_memory => 'Memória';

  @override
  String get logs_source_database => 'Banco de dados';

  @override
  String get logs_source_all => 'Todos';

  @override
  String get logs_filter_search_hint => 'Buscar logs...';

  @override
  String get logs_filter_all => 'Todos';

  @override
  String get logs_detail_level => 'Nível';

  @override
  String get logs_detail_timestamp => 'Data/hora';

  @override
  String get logs_detail_message => 'Mensagem:';

  @override
  String get logs_detail_error_label => 'Erro:';

  @override
  String get logs_detail_stack_trace => 'Stack Trace:';

  @override
  String get logs_detail_copy => 'Copiar log';

  @override
  String get logs_detail_copied => 'Log copiado!';

  @override
  String get logs_overview_title => 'Atividade de logs';

  @override
  String get logs_overview_subtitle => 'Diagnóstico do app em tempo real';

  @override
  String get logs_source_label => 'Origem';

  @override
  String get logs_levels_label => 'Níveis';

  @override
  String get logs_entries_label => 'entradas';

  @override
  String get logs_detail_tag => 'Tag';

  @override
  String get receive_title => 'Receber Ativos';

  @override
  String get receive_info_title => 'Como receber ativos';

  @override
  String get receive_info_step1_title => 'Selecione o ativo';

  @override
  String get receive_info_step1_desc =>
      'Escolha qual criptomoeda você deseja receber';

  @override
  String get receive_info_step2_title => 'Escolha a rede';

  @override
  String get receive_info_step2_desc =>
      'Bitcoin (on-chain), Lightning ou Liquid';

  @override
  String get receive_info_step3_title => 'Gere o QR code';

  @override
  String get receive_info_step3_desc =>
      'Compartilhe com quem vai enviar o pagamento';

  @override
  String get receive_info_close_hint => 'Toque fora desta área para fechar';

  @override
  String get receive_qr_title => 'Receber Pagamento';

  @override
  String get receive_qr_amount_label => 'Valor:';

  @override
  String get receive_qr_description_label => 'Descrição:';

  @override
  String get receive_qr_address_title => 'Endereço de Recebimento';

  @override
  String get receive_qr_copy_address => 'Copiar Endereço';

  @override
  String get receive_qr_copied => 'Copiado!';

  @override
  String receive_qr_error(String error) {
    return 'Erro ao gerar QR: $error';
  }

  @override
  String get receive_connection_error =>
      'Houve um problema de conexão. Por favor, tente novamente.';

  @override
  String get receive_network_bitcoin_onchain => 'Bitcoin On-chain';

  @override
  String get receive_network_liquid_network => 'Liquid Network';

  @override
  String get receive_network_unknown => 'Desconhecida';

  @override
  String get receive_select_asset => 'Selecione um ativo';

  @override
  String get receive_select_network => 'Selecione a rede';

  @override
  String get receive_asset_hint_btc =>
      'Bitcoin on-chain é a única rede disponível para BTC';

  @override
  String get receive_asset_hint_lbtc => 'Bitcoin L2 suporta Lightning e Liquid';

  @override
  String receive_asset_hint_liquid_only(String name) {
    return '$name suporta apenas rede Liquid';
  }

  @override
  String get receive_select_asset_first => 'Selecione um ativo primeiro';

  @override
  String get receive_network_label_bitcoin => 'Bitcoin';

  @override
  String get receive_network_label_liquid => 'Liquid';

  @override
  String get receive_network_subtitle_onchain => 'On-chain';

  @override
  String get receive_network_subtitle_instant => 'Instantâneo';

  @override
  String get receive_network_subtitle_private => 'Privado';

  @override
  String get receive_amount_label => 'Valor';

  @override
  String get receive_amount_hint_required => 'Digite o valor (obrigatório)';

  @override
  String get receive_amount_hint_optional => 'Digite o valor (opcional)';

  @override
  String get receive_amount_helper_disabled =>
      'Selecione um ativo e rede primeiro';

  @override
  String get receive_amount_helper_optional =>
      'Valor opcional para Bitcoin/Liquid';

  @override
  String get receive_amount_sats_label => 'Valor em Satoshis:';

  @override
  String get receive_bitcoin_valid => 'Valor válido para Bitcoin';

  @override
  String get receive_liquid_valid => 'Valor válido para Liquid';

  @override
  String get receive_description_label => 'Descrição (opcional)';

  @override
  String get receive_description_hint => 'Ex: Pagamento do almoço';

  @override
  String get receive_description_add => 'Adicionar descrição';

  @override
  String get receive_generate_qr => 'Gerar fatura';

  @override
  String get receive_select_asset_network => 'Selecione um ativo e rede';

  @override
  String get receive_conversion_loading => 'Carregando conversões...';

  @override
  String get receive_conversion_equivalent => 'Conversões equivalentes:';

  @override
  String get receive_satoshis_label => 'Satoshis:';

  @override
  String get wallet_title => 'Minha Carteira';

  @override
  String get wallet_assets_tab => 'Ativos';

  @override
  String get wallet_balance_available => 'Saldo disponível:';

  @override
  String get wallet_send => 'Enviar';

  @override
  String get wallet_receive => 'Receber';

  @override
  String get wallet_send_title => 'Revisar Transação';

  @override
  String get wallet_send_all_title => 'Revisar Envio Total';

  @override
  String get wallet_send_calculating_total =>
      'Calculando envio total de fundos...';

  @override
  String get wallet_send_preparing => 'Preparando transação...';

  @override
  String get wallet_send_prepare_error => 'Erro ao preparar transação';

  @override
  String get wallet_send_dust_warning =>
      'Há problemas com esta transação. Verifique os dados.';

  @override
  String get wallet_send_all_info =>
      'Enviando todos os fundos disponíveis. As taxas serão deduzidas automaticamente do valor total.';

  @override
  String get wallet_send_destination_network => 'Rede de Destino';

  @override
  String get wallet_send_destination_address => 'Endereço de Destino';

  @override
  String get wallet_send_fee_details => 'Detalhes das Taxas';

  @override
  String get wallet_send_network_fee => 'Taxa da Rede';

  @override
  String get wallet_send_service_fee => 'Taxa de Serviço';

  @override
  String get wallet_send_total_fees => 'Total das Taxas';

  @override
  String get wallet_send_free => 'Gratuito';

  @override
  String get wallet_send_loading_price => 'Carregando preço...';

  @override
  String get wallet_send_calc_value_error => 'Erro ao calcular valor';

  @override
  String get wallet_send_calculating_value => 'Calculando valor...';

  @override
  String get wallet_send_tx_error_title => 'Erro na Transação';

  @override
  String get wallet_send_tx_error_desc =>
      'Não foi possível enviar a transação:';

  @override
  String get wallet_send_tx_error_check =>
      'Verifique os dados e tente novamente.';

  @override
  String wallet_send_wallet_error(String description) {
    return 'Erro ao acessar carteira: $description';
  }

  @override
  String get wallet_send_send_all_label => 'Enviar Tudo';

  @override
  String wallet_send_asset_label(String asset) {
    return 'Enviar $asset';
  }

  @override
  String get wallet_onchain_network => 'Bitcoin On-chain';

  @override
  String get wallet_amount => 'Valor';

  @override
  String get wallet_network_fee => 'Taxa de rede';

  @override
  String get wallet_total => 'Total';

  @override
  String get wallet_destination => 'Destino';

  @override
  String get wallet_fee_calculated_note =>
      'A taxa foi calculada com base na velocidade selecionada.';

  @override
  String get wallet_slide_to_confirm => 'Deslizar para confirmar';

  @override
  String get wallet_speed_economic => 'Econômica';

  @override
  String get wallet_speed_economic_desc => 'Confirmação mais lenta, taxa menor';

  @override
  String get wallet_speed_normal => 'Normal';

  @override
  String get wallet_speed_normal_desc => 'Equilíbrio entre velocidade e custo';

  @override
  String get wallet_speed_priority => 'Prioritária';

  @override
  String get wallet_speed_priority_desc =>
      'Confirmação mais rápida, taxa maior';

  @override
  String wallet_speed_label(String speed) {
    return 'Velocidade: $speed';
  }

  @override
  String get wallet_tx_not_found => 'Transação não encontrada';

  @override
  String get wallet_tx_not_found_error => 'Erro: Transação não encontrada';

  @override
  String wallet_send_tx_error(String error) {
    return 'Erro ao enviar transação: $error';
  }

  @override
  String get wallet_fee_speed_title => 'Velocidade da transação';

  @override
  String get wallet_fee_economic => 'Econômica';

  @override
  String get wallet_fee_economic_eta => '~60+ min';

  @override
  String get wallet_fee_normal => 'Normal';

  @override
  String get wallet_fee_normal_eta => '~30 min';

  @override
  String get wallet_fee_fast => 'Rápida';

  @override
  String get wallet_fee_fast_eta => '~10 min';

  @override
  String get tx_confirmed_title => 'Transação Confirmada!';

  @override
  String tx_received_asset(String ticker) {
    return 'Você recebeu $ticker';
  }

  @override
  String get tx_received => 'Recebido';

  @override
  String get tx_id => 'ID da Transação';

  @override
  String get tx_back_to_dashboard => 'Voltar para Dashboard';

  @override
  String get tx_history_title => 'Histórico de transações';

  @override
  String get tx_history_pix_title => 'Histórico do PIX';

  @override
  String get tx_detail_title => 'Detalhes da Transação';

  @override
  String get tx_detail_swap_unfinished => 'Swap não concluído';

  @override
  String get tx_detail_swap_refunded => 'Swap reembolsado';

  @override
  String get tx_detail_swap_completed => 'Troca concluída';

  @override
  String get tx_detail_swap_in_progress => 'Troca em andamento';

  @override
  String get tx_detail_refund_available_msg =>
      'Esta transação não foi concluída com sucesso. Seus fundos estão seguros e disponíveis para reembolso. Use o botão abaixo para solicitar o reembolso.';

  @override
  String get tx_detail_refund_processed_msg =>
      'O reembolso desta transação já foi processado ou está sendo enviado. Seus fundos foram ou serão devolvidos em breve.';

  @override
  String get tx_filter_title => 'Filtros';

  @override
  String get tx_filter_sort_by => 'Ordenar por';

  @override
  String get tx_filter_type => 'Tipo de transação';

  @override
  String get tx_filter_status => 'Status';

  @override
  String get tx_filter_currency => 'Moeda';

  @override
  String get tx_filter_period => 'Período';

  @override
  String get tx_filter_period_custom => 'Período personalizado';

  @override
  String get tx_filter_clear_period => 'Limpar período';

  @override
  String get tx_filter_clear_filters => 'Limpar filtros';

  @override
  String get tx_filter_apply => 'Aplicar filtros';

  @override
  String get tx_type_all => 'Todas';

  @override
  String get tx_type_send => 'Envio';

  @override
  String get tx_type_receive => 'Recebimento';

  @override
  String get tx_type_swap => 'Swap';

  @override
  String get tx_status_all => 'Todos';

  @override
  String get tx_status_pending => 'Pendente';

  @override
  String get tx_status_confirmed => 'Confirmado';

  @override
  String get tx_status_failed => 'Falhou';

  @override
  String get tx_status_refundable => 'Reembolsável';

  @override
  String get wallet_errors_insufficient_funds =>
      'Fundos insuficientes na carteira.';

  @override
  String get wallet_errors_invalid_address => 'Endereço inválido.';

  @override
  String get wallet_errors_connection_failed => 'Conexão falhou.';

  @override
  String get wallet_errors_tx_cannot_finalize =>
      'Transação não pode ser finalizada.';

  @override
  String get wallet_errors_invalid_asset => 'Ativo inválido.';

  @override
  String get wallet_errors_invalid_amount => 'Valor inválido.';

  @override
  String get wallet_errors_connection => 'Erro de conexão';

  @override
  String get wallet_errors_internal => 'Falha interna';

  @override
  String get swap_title => 'Swap';

  @override
  String get swap_you_send => 'Você envia';

  @override
  String get swap_you_receive => 'Você recebe';

  @override
  String swap_rate_line(String from, String rate, String to) {
    return '1 $from = $rate $to';
  }

  @override
  String get swap_insufficient_balance =>
      'Saldo insuficiente para realizar o swap';

  @override
  String get swap_updating_quote => 'Atualizando cotação...';

  @override
  String swap_amount_bounds(Object max, Object min) {
    return 'Mín: $min sats · Máx: $max sats (saldo)';
  }

  @override
  String swap_min_value_sats(String sats) {
    return 'Valor mínimo: $sats sats';
  }

  @override
  String swap_min_amount_sats(String sats) {
    return 'Quantidade mínima é $sats sats';
  }

  @override
  String get swap_no_liquidity_title => 'Sem Liquidez';

  @override
  String get swap_no_liquidity_body =>
      'No momento não há liquidez disponível na Sideswap para realizar esta operação.';

  @override
  String get swap_use_asset_value => 'Usar valor em ativo';

  @override
  String swap_use_currency_value(String currency) {
    return 'Usar valor em $currency';
  }

  @override
  String swap_expires_in(int seconds) {
    return 'Expira em ${seconds}s';
  }

  @override
  String get swap_quote_refreshing => 'Atualizando cotação...';

  @override
  String get swap_quote_outdated_title => 'Cotação desatualizada';

  @override
  String get swap_quote_outdated_body =>
      'Toque em atualizar para obter a cotação mais recente.';

  @override
  String get swap_refresh_action => 'Atualizar';

  @override
  String get swap_rate_label => 'Cotação';

  @override
  String get swap_confirm_title => 'Confirmar Swap';

  @override
  String get swap_confirm_estimate => 'Estimativa';

  @override
  String get swap_confirm_sending => 'Enviando:';

  @override
  String get swap_confirm_boltz_fee => 'Taxa de serviço da Boltz:';

  @override
  String get swap_confirm_tx_fee => 'Taxa da transação:';

  @override
  String get swap_confirm_total_fees => 'Total de taxas:';

  @override
  String get swap_confirm_receiving => 'Recebendo:';

  @override
  String get swap_confirm_server_fee => 'Taxa do servidor';

  @override
  String get swap_confirm_fixed_fee => 'Taxa fixa';

  @override
  String get swap_confirm_total_fees_short => 'Total de taxas';

  @override
  String swap_confirm_error(String error) {
    return 'Erro na confirmação: $error';
  }

  @override
  String get pix_confirm_title => 'Confirmar transação';

  @override
  String get pix_generating_qr => 'Gerando QR Code...';

  @override
  String get pix_processing_unavailable =>
      'Não é possível processar transações PIX no momento. Por favor, tente novamente mais tarde.';

  @override
  String get pix_select_asset => 'Selecione um ativo';

  @override
  String get pix_floating_rate_title => 'Câmbio Flutuante';

  @override
  String get pix_floating_rate_body =>
      'Importante: o LBTC tem variação de preço.\nPor isso, o valor em reais que você recebe pode ser diferente do valor esperado.\nA conversão para reais usa a cotação do momento da finalização.';

  @override
  String get pix_dont_show_again => 'Não exibir novamente';

  @override
  String get pix_disclaimer_header => 'Para uma melhor experiência PIX:';

  @override
  String get pix_disclaimer_max_consecutive =>
      'Máx. 3 PIX consecutivos do mesmo titular em 30 min.';

  @override
  String get pix_disclaimer_daily_limit =>
      'Limite R\$ 5.000/dia por titular (nível bancário).';

  @override
  String get pix_disclaimer_outside_rules =>
      'Transferências fora das regras são devolvidas ao pagador.';

  @override
  String get pix_disclaimer_analyzed =>
      '100% dos PIX são analisados por infra conjunta — estorno automático se suspeita de automação.';

  @override
  String get pix_disclaimer_avg_time =>
      'Tempo médio: 5 a 25 min. PIX c/ sinal de risco bancário: 3–7 dias úteis (estornável).';

  @override
  String get pix_deposit_title => 'Detalhes do Depósito PIX';

  @override
  String get pix_deposit_label => 'Depósito PIX';

  @override
  String get pix_deposit_date => 'Data';

  @override
  String get pix_deposit_target_asset => 'Ativo de destino';

  @override
  String get pix_deposit_value => 'Valor';

  @override
  String get pix_deposit_pix_key => 'Chave PIX';

  @override
  String get pix_deposit_id => 'ID do Depósito';

  @override
  String get pix_deposit_received_value => 'Valor recebido';

  @override
  String get pix_deposit_tx_id => 'TX ID';

  @override
  String get pix_deposit_expired => 'Prazo expirado';

  @override
  String get pix_deposit_time_remaining => 'Tempo restante para pagar';

  @override
  String get pix_deposit_invalid => 'Este PIX não é mais válido';

  @override
  String get pix_deposit_info => 'Informações';

  @override
  String get pix_deposit_view_explorer => 'Ver no Explorer';

  @override
  String get pix_deposit_view_chain => 'Visualizar na blockchain';

  @override
  String get human_verif_title => 'Verificação de Humanidade';

  @override
  String get human_verif_intro_title => 'Verifique sua humanidade';

  @override
  String get human_verif_intro_body =>
      'Para garantir a segurança da plataforma, precisamos verificar que você é uma pessoa real.';

  @override
  String get human_verif_step1_title => 'Pagamento simbólico';

  @override
  String get human_verif_step1_desc =>
      'Você fará um PIX de apenas R\$ 1,00 para nossa chave. O valor será devolvido imediatamente após o pagamento.';

  @override
  String get human_verif_step2_title => 'Receba o código';

  @override
  String get human_verif_step2_desc =>
      'Você receberá o valor de volta com um código único na mensagem.';

  @override
  String get human_verif_step3_title => 'Valide sua identidade';

  @override
  String get human_verif_step3_desc =>
      'Digite o código recebido para confirmar sua humanidade.';

  @override
  String get human_verif_payment_title => 'Pagamento de Verificação';

  @override
  String get human_verif_time_remaining_prefix => 'Você tem ';

  @override
  String get human_verif_minutes_and => 'minutos e ';

  @override
  String get human_verif_seconds => 'segundos ';

  @override
  String get human_verif_to_pay => 'para concluir o pagamento.';

  @override
  String get human_verif_pix_key => 'Chave PIX';

  @override
  String get human_verif_time_expired_title => 'Tempo Esgotado';

  @override
  String get human_verif_time_expired_body =>
      'O tempo para realizar o pagamento expirou. Por favor, tente novamente.';

  @override
  String get human_verif_after_payment =>
      'Após o pagamento, você receberá um código na mensagem do PIX de retorno.';

  @override
  String get human_verif_already_paid => 'Já fiz o pagamento';

  @override
  String get human_verif_code_title => 'Validar Código';

  @override
  String get human_verif_code_prompt_prefix => 'Digite o ';

  @override
  String get human_verif_code_word => 'código';

  @override
  String get human_verif_code_body =>
      'Insira o código de 6 dígitos que você recebeu na mensagem do PIX de retorno.';

  @override
  String get human_verif_code_invalid => 'Código inválido. Tente novamente.';

  @override
  String get human_verif_code_help =>
      'Verifique o campo de mensagem do PIX que você recebeu de volta.';

  @override
  String get human_verif_back_to_payment => 'Voltar para o pagamento';

  @override
  String get phone_verif_title => 'Verificação';

  @override
  String get phone_verif_humanity_title => 'Verificação de Humanidade';

  @override
  String get phone_verif_humanity_body =>
      'Para garantir a segurança, precisamos confirmar que você é uma pessoa real. O número de telefone será usado apenas para enviar um código de verificação. Nenhum dado será armazenado ou vinculado à sua carteira.';

  @override
  String get phone_verif_method_title => 'Escolher Método';

  @override
  String get phone_verif_inform_prefix => 'Informe seu ';

  @override
  String get phone_verif_phone_number => 'número de telefone';

  @override
  String get phone_verif_method_subtitle =>
      'Escolha como deseja receber o código de verificação';

  @override
  String get phone_verif_number_label => 'Número';

  @override
  String get phone_verif_number_hint => 'Digite seu número';

  @override
  String get phone_verif_send_code => 'Enviar código';

  @override
  String get phone_verif_code_title => 'Confirmar Código';

  @override
  String get phone_verif_code_prompt_prefix => 'Digite o ';

  @override
  String get phone_verif_code_word => 'código recebido';

  @override
  String phone_verif_code_body(String phone) {
    return 'Enviamos um código de 6 dígitos para o número $phone via Telegram.';
  }

  @override
  String get phone_verif_verify => 'Verificar';

  @override
  String phone_verif_resend_in(String seconds) {
    return 'Reenviar em 00:$seconds';
  }

  @override
  String get phone_verif_resend_code => 'Reenviar código';

  @override
  String get refund_screen_title => 'Reembolso de Transação';

  @override
  String get refund_available_title => 'Reembolsos Disponíveis';

  @override
  String refund_retry_progress(int current, int max) {
    return 'Tentativa $current de $max';
  }

  @override
  String get refund_loading_long => 'Aguarde, pode demorar um pouco...';

  @override
  String get refund_empty_title => 'Nenhum Reembolso Disponível';

  @override
  String get refund_empty_body =>
      'Você não tem transações pendentes de reembolso.';

  @override
  String get refund_pull_to_refresh => 'Puxe para baixo para atualizar';

  @override
  String get refund_speed_title => 'Velocidade da Transação';

  @override
  String get refund_insufficient_for_fee =>
      'Fundos insuficientes para cobrir a taxa de transação';

  @override
  String refund_fee_load_error(String error) {
    return 'Erro ao recuperar taxas: $error';
  }

  @override
  String get refund_calculating_fees => 'Calculando taxas...';

  @override
  String get refund_amount_too_small =>
      'Valor muito pequeno para cobrir as taxas de transação';

  @override
  String get refund_confirm_button => 'Confirmar Reembolso';

  @override
  String refund_process_error(String error) {
    return 'Erro ao processar reembolso: $error';
  }

  @override
  String get refund_none_found => 'Nenhum swap reembolsável encontrado';

  @override
  String get refund_details_title => 'Detalhes do Reembolso';

  @override
  String get refund_auto_send_info =>
      'Não se preocupe, o reembolso em Bitcoin será enviado automaticamente para o endereço da sua wallet.';

  @override
  String get refund_info_title => 'Informações do Reembolso';

  @override
  String get refund_label_amount => 'Valor';

  @override
  String get refund_label_transaction => 'Transação';

  @override
  String get refund_label_date => 'Data';

  @override
  String get refund_label_refund_amount => 'Valor do Reembolso';

  @override
  String get refund_address_label => 'Endereço Bitcoin';

  @override
  String get refund_address_hint => 'Insira o endereço Bitcoin';

  @override
  String get refund_address_required => 'Por favor, insira um endereço Bitcoin';

  @override
  String get refund_address_invalid => 'Endereço Bitcoin inválido';

  @override
  String get refund_address_invalid_long =>
      'Endereço Bitcoin inválido. Use um endereço válido (ex: 1..., 3..., bc1...)';

  @override
  String get refund_status_pending => 'Pendente';

  @override
  String get refund_status_available => 'Disponível';

  @override
  String get refund_action_retransmit => 'Retransmitir';

  @override
  String get refund_speed_select_title => 'Selecione a velocidade da transação';

  @override
  String get refund_amount_too_small_short =>
      'Valor muito pequeno para cobrir as taxas';

  @override
  String get refund_fee_label_economy => 'Economia';

  @override
  String get refund_fee_label_standard => 'Padrão';

  @override
  String get refund_fee_label_fast => 'Rápido';

  @override
  String get refund_fee_label_urgent => 'Urgente';

  @override
  String get refund_fee_time_24h => '~24 horas';

  @override
  String get refund_fee_time_1h => '~1 hora';

  @override
  String get refund_fee_time_30m => '~30 minutos';

  @override
  String get refund_fee_time_10m => '~10 minutos';

  @override
  String refund_fee_rate(int rate) {
    return 'Taxa: $rate sat/vB';
  }

  @override
  String refund_fee_total(String amount) {
    return 'Total: $amount sats';
  }

  @override
  String get refund_success_title => 'Reembolso Iniciado!';

  @override
  String get refund_success_body =>
      'Seu reembolso foi processado com sucesso. Em breve os fundos estarão disponíveis no endereço informado.';

  @override
  String get refund_success_amount_label => 'Valor Reembolsado';

  @override
  String get refund_success_txid_label => 'Transaction ID';

  @override
  String get refund_success_back_dashboard => 'Voltar para Dashboard';

  @override
  String get refund_test_title => '🧪 Teste de Refund';

  @override
  String get refund_test_heading => 'Modo de Teste - Refund';

  @override
  String get refund_test_description =>
      'Use esta tela para testar o fluxo completo de refund com dados simulados, sem precisar de transações reais.';

  @override
  String get refund_test_button_mock => 'Testar com Dados Mock';

  @override
  String get refund_test_button_real_sdk => 'Testar com SDK Real';

  @override
  String get refund_test_mock_data_title => 'Dados Mock Incluídos';

  @override
  String get refund_test_mock_item_swaps => '• 3 swaps reembolsáveis';

  @override
  String get refund_test_mock_item_amounts =>
      '• Valores: 0.001, 0.0025, 0.0005 BTC';

  @override
  String get refund_test_mock_item_fees => '• 4 opções de taxa diferentes';

  @override
  String get refund_test_mock_item_address =>
      '• Endereço Bitcoin pré-preenchido';

  @override
  String get refund_test_mock_item_success =>
      '• Simula sucesso em 90% dos casos';

  @override
  String get refund_test_advanced_title => '🧪 Teste de Refund Avançado';

  @override
  String get refund_test_clear_tooltip => 'Limpar transações mock';

  @override
  String get refund_test_cleared_snack => 'Transações mockadas removidas';

  @override
  String get refund_test_advanced_heading =>
      'Teste de Refund com\nTransações Reais';

  @override
  String get refund_test_advanced_description =>
      'Simule transações Peg In refundable baseadas em\ndados reais para testar o fluxo completo de reembolso.';

  @override
  String get refund_test_load_mock_button => 'Carregar Transações Mock';

  @override
  String refund_test_loaded_snack(int count) {
    return '$count transações mockadas carregadas';
  }

  @override
  String refund_test_mock_list_title(int count) {
    return 'Transações Mockadas ($count)';
  }

  @override
  String get refund_test_flow_button => 'Testar Fluxo de Refund (Mock SDK)';

  @override
  String get refund_test_real_tx_title => 'Sobre a Transação Real';

  @override
  String get refund_test_real_tx_type => '🔹 Tipo: Peg In (BTC → LBTC)';

  @override
  String get refund_test_real_tx_id => '🔹 TX ID: 5e2159e9b5fbf7023b2800...';

  @override
  String get refund_test_real_tx_sent =>
      '🔹 Valor enviado: 52574 sats (402 sats de taxa)';

  @override
  String get refund_test_real_tx_expected =>
      '🔹 Valor esperado: 52172 sats (LBTC)';

  @override
  String get refund_test_real_tx_date => '🔹 Data: 04/02/2026 às 00:17:10';

  @override
  String get refund_test_real_tx_lockup =>
      '🔹 Lockup TX: 2622dd4f5a1c69f7cea5...';

  @override
  String get refund_test_real_tx_address =>
      '🔹 Endereço: bc1p62e2r4jnr3v985uqk...';

  @override
  String get refund_test_real_tx_warning =>
      'Status: REFUNDABLE\nEsta transação falhou e os fundos podem ser reembolsados para o endereço Bitcoin original.';

  @override
  String get refund_test_badge_refundable => 'REFUNDABLE';

  @override
  String get refund_test_badge_confirmed => 'CONFIRMED';

  @override
  String refund_test_card_amount(String amount) {
    return 'Valor: $amount sats';
  }

  @override
  String refund_test_card_id(String id) {
    return 'ID: $id';
  }

  @override
  String refund_test_card_to(String address) {
    return 'Para: $address';
  }

  @override
  String get qr_scanner_searching => 'Procurando QR Code...';

  @override
  String get qr_scanner_found => 'QR Code encontrado!';

  @override
  String get qr_scanner_position_hint =>
      'Posicione o QR code dentro da área destacada';

  @override
  String get qr_scanner_supported_networks => 'Bitcoin • Liquid';

  @override
  String get qr_scanner_flash_label => 'Flash';

  @override
  String get qr_scanner_camera_label => 'Câmera';

  @override
  String get qr_validation_empty => 'QR code vazio';

  @override
  String get qr_validation_unrecognized => 'Formato de QR code não reconhecido';

  @override
  String get qr_validation_lightning_unsupported_symbols =>
      'Lightning com símbolos especiais (₿, #, \$) não é suportado';

  @override
  String get qr_validation_lnurl_bip353_unsupported =>
      'Formato LNURL BIP 353 não é suportado no momento. Use um endereço Lightning válido ou LNURL de walletofsatoshi.com';

  @override
  String get qr_validation_boltz_invalid => 'Invoice BOLTZ inválido';

  @override
  String get qr_validation_boltz_no_amount =>
      'Invoice BOLTZ sem valor não é suportado. Por favor, gere um invoice com valor definido';

  @override
  String get qr_validation_liquid_invalid =>
      'Endereço Liquid inválido no QR code';

  @override
  String get qr_validation_liquid_format_error =>
      'Erro ao processar QR Liquid: formato inválido';

  @override
  String get qr_validation_bitcoin_invalid =>
      'Endereço Bitcoin inválido no QR code';

  @override
  String get qr_validation_bitcoin_format_error =>
      'Erro ao processar QR Bitcoin: formato inválido';

  @override
  String get qr_validation_lightning_unsupported =>
      'Lightning não é suportado para envio';

  @override
  String get qr_validation_lnurl_unsupported =>
      'LNURL não suportado. Use walletofsatoshi.com ou outro provedor compatível';

  @override
  String get qr_validation_invalid_default => 'QR code inválido';

  @override
  String get tx_sent_title => 'Transação Enviada!';

  @override
  String tx_sent_subtitle(String ticker) {
    return 'Seu $ticker foi enviado com sucesso';
  }

  @override
  String get tx_sent_status_label => 'Enviado';

  @override
  String get tx_sent_track_history =>
      'Você pode acompanhar o status na seção de histórico.';

  @override
  String get setup_first_access_title => 'Como você quer começar?';

  @override
  String get setup_first_access_subtitle =>
      'Você pode criar uma nova carteira protegida por você, ou importar uma já existente com sua chave.';

  @override
  String get setup_create_wallet_appbar => 'Criar carteira';

  @override
  String get setup_seed_length_title => 'Selecione o tamanho da ';

  @override
  String get setup_seed_length_highlight => 'frase-semente';

  @override
  String get setup_seed_length_subtitle =>
      'Você pode criar sua carteira com 12 ou 24 palavras. Ambas são seguras, mas cada opção tem seu nível de praticidade e proteção.';

  @override
  String get setup_seed_12_title => '12 Palavras';

  @override
  String get setup_seed_12_desc =>
      'Mais prática e rápida de configurar. Recomendada\npara iniciantes ou quem prefere simplicidade sem\nabrir mão da segurança.';

  @override
  String get setup_seed_24_title => '24 Palavras (recomendado)';

  @override
  String get setup_seed_24_desc =>
      'Proporciona mais segurança. Recomendada para\nquem deseja proteger valores maiores ou busca o\nmáximo de segurança.';

  @override
  String get setup_generate_seed_button => 'Gerar frase de recuperação';

  @override
  String get setup_confirm_seed_appbar => 'Confirme sua frase';

  @override
  String get setup_confirm_seed_title => 'Confirmação de ';

  @override
  String get setup_confirm_seed_highlight => 'Segurança';

  @override
  String get setup_confirm_seed_subtitle =>
      'Selecione as palavras na ordem correta para confirmar sua frase de recuperação.';

  @override
  String get setup_confirm_seed_error =>
      'Uma ou mais palavras estão incorretas. Tente novamente.';

  @override
  String setup_seed_word_label(int position) {
    return 'Palavra #$position: ';
  }

  @override
  String get setup_import_appbar => 'Importar Carteira';

  @override
  String get setup_import_restart_tooltip => 'Recomeçar';

  @override
  String get setup_import_instruction_title =>
      'Digite sua frase de recuperação';

  @override
  String get setup_import_instruction_body =>
      'Digite cada palavra da sua seed phrase (12 ou 24 palavras). O sistema oferecerá sugestões BIP39 conforme você digita. Pressione espaço ou clique para confirmar cada palavra.';

  @override
  String get setup_import_seed_valid =>
      'Seed phrase válida! Pronta para importar.';

  @override
  String get setup_import_checksum_invalid =>
      'Checksum inválido. Verifique as palavras.';

  @override
  String get setup_import_tip =>
      'Dica: Pressione espaço para confirmar a primeira sugestão rapidamente';

  @override
  String get setup_import_button => 'Importar Carteira';

  @override
  String get setup_import_cleanup_warning =>
      'Aviso: Alguns arquivos antigos não puderam ser removidos. O app pode precisar ser reiniciado.';

  @override
  String get setup_clipboard_detected_title => 'Frase semente detectada';

  @override
  String get setup_clipboard_detected_body =>
      'Detectamos uma frase na área de transferência';

  @override
  String get setup_clipboard_paste_button => 'Colar';

  @override
  String get setup_clipboard_ignore_button => 'Ignorar';

  @override
  String setup_input_hint_press_space(String word) {
    return 'Pressione espaço para confirmar \"$word\"';
  }

  @override
  String get setup_input_hint_default => 'Digite uma palavra BIP39...';

  @override
  String get setup_progress_label => 'Progresso';

  @override
  String setup_progress_count(int count, int target) {
    return '$count/$target palavras';
  }

  @override
  String setup_seed_invalid_word(String word) {
    return 'Palavra inválida: $word';
  }

  @override
  String setup_seed_wrong_count(int count) {
    return 'Frase deve ter 12, 15, 18, 21 ou 24 palavras. Encontradas: $count';
  }

  @override
  String setup_seed_invalid_words_list(String list) {
    return 'Palavras inválidas: $list';
  }

  @override
  String get setup_seed_invalid_checksum =>
      'Frase inválida. Verifique o checksum.';

  @override
  String get wallet_import_msg_processing => 'Processando...';

  @override
  String get wallet_import_msg_verifying => 'Verificando dados...';

  @override
  String get wallet_import_msg_initializing => 'Inicializando carteira...';

  @override
  String get wallet_import_phase_platform => 'Inicializando plataforma...';

  @override
  String get wallet_import_phase_database => 'Preparando banco de dados...';

  @override
  String get wallet_import_phase_credentials => 'Carregando credenciais...';

  @override
  String get wallet_import_phase_connecting => 'Conectando às redes...';

  @override
  String get wallet_import_phase_authenticating => 'Autenticando sessão...';

  @override
  String get wallet_import_phase_finalizing => 'Finalizando carteira...';

  @override
  String get wallet_import_msg_loading_balances => 'Carregando saldos...';

  @override
  String get wallet_import_msg_loading_transactions =>
      'Carregando transações...';

  @override
  String get wallet_import_msg_completed => 'Importação concluída ✓';

  @override
  String wallet_import_msg_synced(String name) {
    return '$name sincronizado ✓';
  }

  @override
  String wallet_import_msg_resynced(String name) {
    return '$name - resincronizado...';
  }

  @override
  String get wallet_import_datasource_liquid => 'Liquid Network';

  @override
  String get wallet_import_datasource_bitcoin => 'Bitcoin';

  @override
  String get wallet_import_datasource_lightning => 'Lightning';

  @override
  String get wallet_import_error_reconnecting => 'Tentando reconectar...';

  @override
  String get wallet_import_error_load_data => 'Erro ao carregar dados';

  @override
  String get wallet_import_error_connection => 'Erro de conexão';

  @override
  String get wallet_import_error_servers => 'Erro ao conectar servidores';

  @override
  String get wallet_import_error_servers_unavailable =>
      'Servidores indisponíveis';

  @override
  String get wallet_import_error_generic => 'Erro na importação';

  @override
  String get wallet_import_error_occurred => 'Ocorreu um erro';

  @override
  String wallet_import_error_reconnecting_count(String current, String max) {
    return 'Reconectando ($current/$max)';
  }

  @override
  String get wallet_import_error_reconnecting_servers =>
      'Tentando reconectar aos servidores...';

  @override
  String get wallet_import_error_no_connection =>
      'Não foi possível conectar aos servidores.\nVerifique sua conexão e tente novamente.';

  @override
  String get wallet_import_error_servers_long =>
      'Erro ao conectar aos servidores.\nTente novamente.';

  @override
  String get wallet_import_error_internet =>
      'Erro de conexão.\nVerifique sua internet.';

  @override
  String get wallet_import_error_wallet_data =>
      'Erro ao carregar dados da carteira.';

  @override
  String get wallet_import_error_unknown => 'Erro desconhecido';

  @override
  String get send_pix_appbar => 'Enviar PIX';

  @override
  String get send_pix_qr_title => 'Escanear QR Code PIX';

  @override
  String get send_pix_empty_key_error => 'Digite ou escaneie uma chave PIX';

  @override
  String get send_pix_insert_key => 'Insira a chave PIX';

  @override
  String get send_pix_paste_or_scan => 'Cole a chave ou escaneie o QR Code';

  @override
  String get send_pix_key_label => 'Chave PIX';

  @override
  String get send_pix_key_hint => 'exemplo@email.com ou chave aleatória';

  @override
  String get send_pix_accepted_types => 'Tipos de chave aceitos:';

  @override
  String get send_pix_type_email => 'E-mail';

  @override
  String get send_pix_type_phone => 'Telefone';

  @override
  String get send_pix_type_cpf_cnpj => 'CPF/CNPJ';

  @override
  String get cpf_screen_title => 'Identificação do pagador';

  @override
  String get cpf_screen_subtitle =>
      'Informe o CPF ou CNPJ do pagador para gerar o QR Code Pix.';

  @override
  String get cpf_field_label => 'CPF / CNPJ';

  @override
  String get cpf_field_hint => '000.000.000-00';

  @override
  String get cpf_error_required => 'Informe o CPF';

  @override
  String get cpf_error_incomplete => 'Digite um CPF ou CNPJ válido';

  @override
  String get cpf_error_invalid => 'CPF ou CNPJ inválido';

  @override
  String get cpf_continue => 'Continuar';

  @override
  String get cpf_save_as_favorite => 'Salvar como favorito';

  @override
  String get cpf_save_this_payer => 'Salvar este pagador';

  @override
  String get cpf_favorite_label => 'Nome do pagador';

  @override
  String get cpf_favorite_label_hint => 'Ex.: João Silva';

  @override
  String get cpf_favorites_title => 'Pagadores favoritos';

  @override
  String get cpf_favorites_empty_title => 'Nenhum pagador salvo';

  @override
  String get cpf_favorites_empty_subtitle =>
      'Adicione um pagador para reutilizar o CPF nas próximas cobranças.';

  @override
  String get cpf_favorites_add => 'Adicionar pagador';

  @override
  String get cpf_favorites_use_another => 'Usar outro CPF';

  @override
  String get cpf_favorites_remove => 'Remover';

  @override
  String get cpf_favorites_section => 'Pagadores salvos';

  @override
  String get cpf_favorites_view_all => 'Ver todos';

  @override
  String get cpf_or_enter_manually => 'Ou digite um CPF';

  @override
  String get cpf_favorites_label_required => 'Informe um nome';

  @override
  String get cpf_favorites_duplicate => 'Este CPF já está salvo';

  @override
  String get cpf_favorites_add_title => 'Adicionar pagador';

  @override
  String get cpf_favorites_edit_title => 'Editar pagador';

  @override
  String get cpf_favorites_save => 'Salvar';

  @override
  String get cpf_favorites_search_hint => 'Buscar por nome';

  @override
  String get cpf_favorites_search_empty => 'Nenhum pagador encontrado';

  @override
  String get cpf_favorites_edit => 'Editar';

  @override
  String get cpf_favorites_actions => 'Ações';

  @override
  String get cpf_favorites_error => 'Não foi possível carregar os pagadores';

  @override
  String get cpf_favorites_removed => 'Pagador removido';

  @override
  String get cpf_favorites_delete_title => 'Remover pagador?';

  @override
  String cpf_favorites_delete_body(String label) {
    return 'Remover $label dos pagadores favoritos?';
  }

  @override
  String get cpf_payment_warning =>
      'Use uma conta Pix vinculada ao CPF informado. Pagamentos de outra titularidade serão recusados.';

  @override
  String get send_pix_type_random => 'Chave aleatória';

  @override
  String get send_pix_lightning_info =>
      'Pagamento instantâneo usando Lightning Network';

  @override
  String get swap_success_title => 'Swap Realizado!';

  @override
  String get swap_success_body =>
      'Sua transação foi processada com sucesso, em instantes o saldo estará disponível na sua carteira.';

  @override
  String get swap_success_dialog_txid_copied => 'TX ID copiado!';

  @override
  String get send_pix_success_title => 'PIX Enviado!';

  @override
  String get send_pix_success_body =>
      'Seu pagamento PIX foi realizado com sucesso!';

  @override
  String get send_pix_success_value_sent => 'Valor enviado';

  @override
  String get send_pix_success_recipient_info =>
      'O destinatário já pode verificar o recebimento do PIX.';

  @override
  String get pix_deposit_status_pending_label => 'Pagamento Pendente';

  @override
  String get pix_deposit_status_under_review_label => 'Revisão bancária';

  @override
  String get pix_deposit_status_processing_1_2_label => 'Processando 1/2';

  @override
  String get pix_deposit_status_under_analysis_label => 'Em análise';

  @override
  String get pix_deposit_status_processing_2_2_label => 'Processando 2/2';

  @override
  String get pix_deposit_status_finished_label => 'Enviado';

  @override
  String get pix_deposit_status_expired_label => 'Expirado';

  @override
  String get pix_deposit_status_refunded_label => 'Pagamento estornado';

  @override
  String get pix_deposit_status_med_label => 'Contestado - MED';

  @override
  String get pix_deposit_status_processing_refund_1_3_label => 'Estornando 1/3';

  @override
  String get pix_deposit_status_processing_refund_2_3_label => 'Estornando 2/3';

  @override
  String get pix_deposit_status_processing_refund_3_3_label => 'Estornando 3/3';

  @override
  String get pix_deposit_status_completed_label => 'Concluído';

  @override
  String get pix_deposit_status_unknown_label => 'Revisão manual';

  @override
  String get pix_deposit_status_pending_plural => 'Pagamentos Pendentes';

  @override
  String get pix_deposit_status_under_review_plural => 'Em Análise';

  @override
  String get pix_deposit_status_processing_plural => 'Processando';

  @override
  String get pix_deposit_status_in_transit_plural => 'A caminho';

  @override
  String get pix_deposit_status_under_analysis_plural => 'Em análise';

  @override
  String get pix_deposit_status_finished_plural => 'Enviados';

  @override
  String get pix_deposit_status_expired_plural => 'Expirados';

  @override
  String get pix_deposit_status_refunded_plural => 'Pagamentos estornados';

  @override
  String get pix_deposit_status_processing_refunds_plural =>
      'Processando estornos';

  @override
  String get pix_deposit_status_completed_plural => 'Concluídos';

  @override
  String get swap_error_processing =>
      'Aguarde alguns instantes antes de realizar outro swap. Sua transação anterior ainda está sendo processada.';

  @override
  String swap_error_insufficient_balance_detailed(int available, int required) {
    return 'Saldo insuficiente para este swap. Disponível: $available sats. Necessário (enviado + taxas): $required sats.';
  }

  @override
  String get swap_error_no_active_quote => 'Nenhum quote ativo';

  @override
  String get swap_error_timeout =>
      'Timeout: A operação demorou muito. Tente novamente.';

  @override
  String swap_error_unexpected(String error) {
    return 'Erro inesperado: $error';
  }

  @override
  String get tx_refund_failed_title => 'Transação Falhada';

  @override
  String get tx_refund_failed_body =>
      'Sua transação de peg-in não pode ser concluída. Clicando em OK, os seus bitcoins serão restituídos para sua carteira onchain.';

  @override
  String get tx_refund_status_label => 'Status';

  @override
  String get tx_refund_status_failed => 'Falhada';

  @override
  String get tx_refund_address_label => 'Endereço Bitcoin para Reembolso';

  @override
  String get tx_refund_address_hint => 'Insira o endereço Bitcoin';

  @override
  String get tx_refund_address_auto =>
      'Endereço gerado automaticamente da sua carteira';

  @override
  String get tx_refund_fees_fallback_warning =>
      'Usando taxas estimadas (API temporariamente indisponível)';

  @override
  String get tx_refund_screen_deprecated =>
      'Esta tela está obsoleta. Por favor, use o novo fluxo de estorno.';

  @override
  String get tx_refund_dialog_title => 'Reembolso Iniciado';

  @override
  String get tx_refund_dialog_body =>
      'Seu reembolso foi processado com sucesso!';

  @override
  String get tx_refund_dialog_txid_label => 'TX ID:';

  @override
  String get human_verif_success_title => 'Humanidade Confirmada!';

  @override
  String get human_verif_success_body =>
      'Sua identidade foi verificada com sucesso. Agora você pode utilizar todos os recursos da plataforma.';

  @override
  String get human_verif_success_card_title => 'Verificação completa';

  @override
  String get human_verif_success_card_body => 'Você é uma pessoa real';

  @override
  String get human_verif_success_refund_info =>
      'Seu PIX de R\$ 1,00 foi devolvido com sucesso.';

  @override
  String get pix_received_title => 'PIX Recebido!';

  @override
  String get pix_received_body => 'Seu depósito está sendo processado';

  @override
  String get pix_deposit_id_label => 'ID do Depósito';

  @override
  String get pix_main_tab_receive => 'Receber';

  @override
  String get pix_main_tab_send => 'Enviar';

  @override
  String get pix_info_title => 'Informações sobre PIX';

  @override
  String get pix_info_processing_title => 'Prazo de processamento';

  @override
  String get pix_info_processing_body =>
      'Pagamentos via PIX podem ser processados em até 72 horas úteis após a confirmação.';

  @override
  String get pix_info_lbtc_variation_title => 'Variação de câmbio (LBTC)';

  @override
  String get pix_info_lbtc_variation_body =>
      'Ao escolher receber em LBTC, o valor final pode variar devido à cotação do momento da conversão. Você pode receber mais ou menos que o calculado.';

  @override
  String get pix_info_fees_title => 'Sobre as taxas';

  @override
  String get pix_info_fees_body =>
      'As taxas variam conforme o valor da transação. Valores menores têm taxas fixas, valores maiores têm taxas percentuais decrescentes.';

  @override
  String get pix_info_fees_button => 'Ver detalhes das taxas';

  @override
  String get pix_limits_title => 'Limites de Pagamento';

  @override
  String get pix_limits_intro => 'Entenda como funciona os pagamentos PIX:';

  @override
  String get pix_limits_initial_label => 'Limite Inicial';

  @override
  String get pix_limits_initial_value => 'R\$ 20,00';

  @override
  String get pix_limits_max_label => 'Limite Máximo';

  @override
  String get pix_limits_max_value => 'R\$ 3.000,00';

  @override
  String get pix_limits_explanation =>
      'Ao decorrer de pagamentos efetuados, seus limites de transação podem evoluir até o limite máximo de R\$ 3.000,00 por transação, de acordo sua pontuação de confiança junto ao aplicativo da Mooze.';

  @override
  String get pix_limits_trust_info =>
      'Consulte seus níveis de confiança no menu, opção \"Nível da carteira\".';

  @override
  String get pix_limits_increase_info =>
      'Para aumentar seus limites, o uso frequente de pagamentos vai elevar seus limites gradualmente.';

  @override
  String pix_limits_button_understood_countdown(int seconds) {
    return 'Entendi ($seconds)';
  }

  @override
  String get swap_pending_dialog_title => 'Transação Pendente';

  @override
  String get refund_mock_simulation_error =>
      'Erro simulado: Falha na transmissão da transação';

  @override
  String get merchant_welcome_title => 'Bem-vindo ao Modo Comerciante!';

  @override
  String get merchant_welcome_body =>
      'Aqui você tem um mini PDV: cadastre itens, some valores e cobre seus clientes de forma rápida.';

  @override
  String get merchant_step_enter_value_title => 'Digite o valor desejado';

  @override
  String get merchant_step_enter_value_body =>
      'Vamos começar inserindo um valor de R\$ 20,00 usando o teclado abaixo.';

  @override
  String get merchant_step_add_value_title => 'Adicionar valor';

  @override
  String get merchant_step_add_value_body =>
      'Agora toque no botão \'+\' verde para adicionar o valor à lista de itens.';

  @override
  String get merchant_step_items_tab_title => 'Aba de Itens';

  @override
  String get merchant_step_items_tab_body =>
      'Toque aqui para ver seus produtos cadastrados e criar novos itens.';

  @override
  String get merchant_step_create_product_title => 'Criar produto';

  @override
  String get merchant_step_create_product_body =>
      'Toque no botão \'+\' para criar automaticamente o produto \'Produto 01\' com preço de R\$ 21,00.';

  @override
  String get merchant_step_edit_delete_title => 'Editar e Deletar produtos';

  @override
  String get merchant_step_edit_delete_body =>
      'Arraste este produto da direita para a esquerda para ver as opções de editar e excluir.';

  @override
  String get merchant_step_finalize_title => 'Finalizar venda';

  @override
  String get merchant_step_finalize_body =>
      'Quando tiver itens no carrinho (mínimo R\$ 20,00), toque aqui para finalizar a venda.';

  @override
  String get merchant_step_clear_cart_title => 'Limpar carrinho';

  @override
  String get merchant_step_clear_cart_body =>
      'Se quiser começar do zero, toque aqui para limpar todos os itens do carrinho.';

  @override
  String get merchant_tutorial_done_title => 'Tutorial Concluído!';

  @override
  String get merchant_tutorial_done_body =>
      'Agora você já sabe usar todas as funcionalidades do Modo Comerciante. Pronto para começar?';

  @override
  String get pix_tutorial_step1_title => 'Receba pagamentos com PIX';

  @override
  String get pix_tutorial_step1_body =>
      'Toque aqui para acessar a área PIX e começar a receber pagamentos rapidamente.';

  @override
  String get pix_tutorial_step2_title => 'Acesso rápido';

  @override
  String get pix_tutorial_step2_body =>
      'Você também pode acessar a área PIX por este atalho disponível em todo o aplicativo.';

  @override
  String get pix_tutorial_step3_title => 'Como você recebe pagamentos';

  @override
  String get pix_tutorial_step3_body =>
      'Por padrão, os pagamentos são recebidos em DEPIX, um ativo digital atrelado 1:1 ao Real. Cada 1 DEPIX equivale a R\$1,00.';

  @override
  String get pix_tutorial_step4_title => 'Escolha outro ativo';

  @override
  String get pix_tutorial_step4_body =>
      'Se preferir, você pode alterar o ativo de recebimento e receber pagamentos diretamente em Liquid Bitcoin (L-BTC).';

  @override
  String get pix_tutorial_step5_title => 'Converta quando quiser';

  @override
  String get pix_tutorial_step5_body =>
      'Mesmo recebendo pagamentos em DEPIX, você pode converter seu saldo para L-BTC ou USDT depois, usando a tela de Swap.';

  @override
  String get pix_tutorial_step6_title => 'Seu limite de recebimento';

  @override
  String get pix_tutorial_step6_body =>
      'Confira seus limites mínimos, máximos e o limite diário. Seus limites podem aumentar conforme o uso do aplicativo.';

  @override
  String get pix_tutorial_step7_title => 'Informe o valor';

  @override
  String get pix_tutorial_step7_body =>
      'Escolha o valor que deseja receber. Para este tutorial, usaremos R\$50,00 como exemplo.';

  @override
  String get pix_tutorial_step8_title => 'Gere uma cobrança PIX';

  @override
  String get pix_tutorial_step8_body =>
      'Depois de informar um valor, basta arrastar este botão até o fim para criar uma solicitação de pagamento PIX.';

  @override
  String get pix_tutorial_step9_title => 'QR Code pronto';

  @override
  String get pix_tutorial_step9_body =>
      'Após arrastar o botão, um QR Code PIX será gerado.';

  @override
  String get pix_tutorial_done_title => 'Tutorial concluído';

  @override
  String get pix_tutorial_done_body =>
      'Agora você sabe como receber pagamentos com PIX, escolher seu ativo de recebimento, entender os limites e gerar QR Codes de pagamento.';

  @override
  String get pix_tutorial_restart => 'Reiniciar tutorial';

  @override
  String get pix_tutorial_settings_replay => 'Rever tutorial do PIX';

  @override
  String get merchant_default_product_name => 'Produto 01';

  @override
  String get merchant_loose_value => 'Valor Avulso';

  @override
  String get merchant_add_item_first =>
      'Adicione itens ao carrinho antes de finalizar a venda';

  @override
  String get merchant_min_sale_value =>
      'O valor mínimo para finalizar a venda é de R\$ 20,00';

  @override
  String merchant_add_product_error(String error) {
    return 'Erro ao adicionar produto: $error';
  }

  @override
  String merchant_update_product_error(String error) {
    return 'Erro ao atualizar produto: $error';
  }

  @override
  String merchant_remove_product_error(String error) {
    return 'Erro ao remover produto: $error';
  }

  @override
  String get merchant_tab_keypad => 'Teclado';

  @override
  String get merchant_tab_items => 'Itens';

  @override
  String get merchant_load_products_error => 'Erro ao carregar produtos';

  @override
  String get merchant_mode_header => 'Modo comerciante';

  @override
  String get merchant_clear_cart => 'Limpar';

  @override
  String get merchant_no_products_title => 'Nenhum produto cadastrado';

  @override
  String get merchant_no_products_body =>
      'Comece adicionando seu primeiro produto\nclicando no botão + abaixo';

  @override
  String get merchant_delete_item_title => 'Deletar item';

  @override
  String merchant_delete_item_confirm(String name) {
    return 'Deseja realmente deletar \"$name\"?';
  }

  @override
  String get merchant_delete_action => 'Deletar';

  @override
  String get merchant_add_product_title => 'Adicionar Produto';

  @override
  String get merchant_edit_product_title => 'Editar Produto';

  @override
  String get merchant_product_name_label => 'Nome do produto';

  @override
  String get merchant_product_name_hint => 'Digite o nome do produto';

  @override
  String get merchant_price_label => 'Preço';

  @override
  String get merchant_add_action => 'Adicionar';

  @override
  String get merchant_min_sale_short => 'Mínimo R\$ 20,00';

  @override
  String get merchant_finalize_sale_button => 'Finalizar Venda';

  @override
  String get merchant_charge_receive_title => 'Receber';

  @override
  String get merchant_charge_instruction_prefix =>
      'Escolha o ativo que deseja receber na ';

  @override
  String get merchant_limit_daily => 'Limite diário';

  @override
  String get merchant_limit_per_transaction => 'Por transação';

  @override
  String get merchant_limit_min => 'Valor mínimo';

  @override
  String get merchant_limits_load_error => 'Erro ao carregar limites';

  @override
  String get merchant_generate_qr => 'Gerar QR Code';

  @override
  String get merchant_payment_method_title => 'Como o cliente vai pagar?';

  @override
  String get merchant_payment_method_subtitle =>
      'Escolha uma opção para continuar.';

  @override
  String get merchant_payment_method_qr_title => 'QR Code Pix';

  @override
  String get merchant_payment_method_qr_description =>
      'Mostre o QR Code. O cliente paga no app do banco.';

  @override
  String get merchant_payment_method_link_title => 'Link de pagamento';

  @override
  String get merchant_payment_method_link_description =>
      'Gere um link para o cliente pagar de onde estiver.';

  @override
  String get merchant_payment_method_tag_instant => 'Na hora';

  @override
  String get merchant_payment_method_tag_cpf => 'Pede CPF';

  @override
  String get merchant_payment_method_tag_remote => 'À distância';

  @override
  String get merchant_payment_method_tag_browser => 'No navegador';

  @override
  String merchant_payment_receive_in(String asset) {
    return 'Você recebe em $asset';
  }

  @override
  String get merchant_payment_link_scan_hint =>
      'O cliente escaneia o QR Code com a câmera do celular e paga pelo navegador.';

  @override
  String get merchant_payment_link_share => 'Compartilhar link';

  @override
  String get merchant_payment_link_creating => 'Gerando link de pagamento...';

  @override
  String get merchant_payment_link_open => 'Abrir no navegador';

  @override
  String get merchant_payment_link_open_failed =>
      'Não foi possível abrir o navegador.';

  @override
  String merchant_payment_link_share_message(String amount, String url) {
    return 'Pague $amount com Pix: $url';
  }

  @override
  String get merchant_payment_link_done => 'Concluir venda';

  @override
  String merchant_validation_min_amount(String amount) {
    return 'Valor mínimo: R\$ $amount';
  }

  @override
  String merchant_validation_max_per_tx(String amount) {
    return 'Limite por transação: R\$ $amount';
  }

  @override
  String get merchant_exit_ready => 'Pronto para vender?';

  @override
  String get merchant_exit_new_payment => 'Receber novo pagamento';

  @override
  String get merchant_exit_back_to_wallet => 'Quer acessar a carteira?';

  @override
  String get merchant_items_section => 'Itens';

  @override
  String merchant_qty_prefix(int qty) {
    return 'x$qty';
  }

  @override
  String get merchant_tutorial_skip => 'Pular';

  @override
  String get merchant_total_label => 'Total da venda';

  @override
  String get merchant_edit_action => 'Editar';

  @override
  String get merchant_clear_cart_confirm_title => 'Limpar carrinho?';

  @override
  String get merchant_clear_cart_confirm_body =>
      'Os itens desta venda serão removidos.';

  @override
  String get merchant_product_name_required => 'Informe o nome do produto.';

  @override
  String get merchant_product_price_required =>
      'Informe um preço maior que zero.';

  @override
  String get common_error => 'Erro';

  @override
  String get error_open_browser_link_copied =>
      'Não foi possível abrir o navegador. Link copiado para área de transferência.';

  @override
  String get pix_you_will_receive => 'Você receberá';

  @override
  String pix_of_amount(String amount) {
    return 'de R\$ $amount';
  }

  @override
  String get pix_fees_applied => 'Taxas aplicadas';

  @override
  String get pix_fee_fixed_label => 'Taxa fixa';

  @override
  String get pix_fee_fixed_mooze => 'Taxa fixa (Mooze)';

  @override
  String get pix_fee_fixed_for_small_subtitle => 'Para valores até R\$ 55';

  @override
  String get pix_fee_mooze => 'Taxa Mooze';

  @override
  String get pix_fee_processor => 'Taxa da processadora';

  @override
  String get pix_fee_referral_discount => 'Já com 15% de desconto aplicado';

  @override
  String pix_fee_savings(String amount) {
    return 'Você economizou R\$ $amount com o código de indicação!';
  }

  @override
  String get pix_waiting_amount_title => 'Aguardando valor';

  @override
  String get pix_waiting_amount_body =>
      'Digite um valor válido para ver\no resumo da transação';

  @override
  String get pix_payment_screen_title => 'Pagamento PIX';

  @override
  String pix_qr_generation_error(String error) {
    return 'Falha ao gerar QR code: $error';
  }

  @override
  String get pix_payment_expired_body =>
      'O tempo para realizar o pagamento expirou. Por favor, gere um novo PIX.';

  @override
  String get pix_fees_screen_header_title => 'Taxas Transparentes';

  @override
  String get pix_fees_screen_header_subtitle =>
      'Conheça nossas taxas de depósito via PIX';

  @override
  String get pix_fees_screen_fixed_fee_title => 'Taxa Fixa';

  @override
  String get pix_fees_screen_fixed_fee_subtitle =>
      'Para depósitos até R\$ 55,00';

  @override
  String get pix_fees_screen_fixed_fee_breakdown =>
      'R\$ 1,00 Mooze + R\$ 1,00 Processadora';

  @override
  String get pix_fees_screen_percentage_title => 'Taxas Percentuais';

  @override
  String get pix_fees_screen_percentage_subtitle =>
      'Para depósitos acima de R\$ 55,00';

  @override
  String get pix_fees_screen_tab_no_discount => 'Sem Desconto';

  @override
  String get pix_fees_screen_tab_with_discount => 'Com Desconto';

  @override
  String pix_fees_screen_fee_range_before(String percentage) {
    return 'antes $percentage%';
  }

  @override
  String pix_fees_screen_fee_range_label(String min, String max) {
    return 'R\$ $min até R\$ $max';
  }

  @override
  String get pix_fees_screen_referral_title => 'Bônus de Indicação';

  @override
  String get pix_fees_screen_referral_subtitle => 'Use um código de indicação';

  @override
  String get pix_fees_screen_referral_discount => '15% de desconto';

  @override
  String get pix_fees_screen_referral_disclaimer =>
      'Todas as taxas percentuais são multiplicadas por 0,85';

  @override
  String get pix_fees_screen_examples_title => 'Exemplos Práticos';

  @override
  String get pix_fees_screen_example_deposit => 'Depósito';

  @override
  String get pix_fees_screen_example_receive => 'Você recebe';

  @override
  String get pix_fees_screen_example_with_referral => 'Com indicação';

  @override
  String get pix_fees_screen_example_fee_label => 'Taxa';

  @override
  String pix_fees_screen_fee_calculation_of(String percentage, String amount) {
    return '$percentage% de R\$ $amount';
  }

  @override
  String get pix_fees_screen_footer_title => 'Informações Importantes';

  @override
  String get pix_fees_back_to_top => 'Voltar ao topo';

  @override
  String get pix_fees_screen_footer_info_1 =>
      'A taxa fixa de R\$ 2,00 se aplica apenas a depósitos até R\$ 55,00';

  @override
  String get pix_fees_screen_footer_info_2 =>
      'Para valores acima de R\$ 55,00, as taxas percentuais são aplicadas';

  @override
  String get pix_fees_screen_footer_info_3 =>
      'O desconto de 15% com indicação se aplica apenas às taxas percentuais';

  @override
  String get pix_fees_screen_footer_info_4 =>
      'As taxas são deduzidas automaticamente do valor depositado';

  @override
  String get tx_detail_blockchain => 'Blockchain';

  @override
  String get tx_detail_fee => 'Taxa';

  @override
  String tx_detail_datetime(String date, String time) {
    return '$date às $time';
  }

  @override
  String get tx_detail_swap_label => 'Troca entre ativos';

  @override
  String get tx_detail_sent => 'Enviado';

  @override
  String get tx_detail_received => 'Recebido';

  @override
  String get tx_detail_expected => 'Esperado';

  @override
  String get tx_type_redeposit => 'Auto-redepósito';

  @override
  String get tx_type_unknown => 'Desconhecido';

  @override
  String get tx_status_failed_processed => 'Reembolso Processado';

  @override
  String get tx_status_refundable_pending => 'Aguardando Reembolso';

  @override
  String get tx_status_confirmed_fem => 'Confirmada';

  @override
  String get tx_detail_confirmations => 'Confirmações';

  @override
  String get tx_detail_confirmations_full => '6+ confirmações';

  @override
  String tx_detail_confirmations_progress(int count) {
    return '$count/6 confirmações';
  }

  @override
  String get tx_detail_preimage_label => 'Preimagem';

  @override
  String get tx_detail_preimage_pending =>
      'Preimagem pendente: Assim que sua transação for confirmada, a preimagem aparecerá aqui';

  @override
  String tx_detail_submarine_btc_to_lbtc(String from, String to) {
    return 'Swap de rede: Você enviou $from e receberá $to. Assim que a transação onchain for confirmada, os fundos aparecerão automaticamente na Liquid Network.';
  }

  @override
  String tx_detail_submarine_lbtc_to_btc(String from, String to) {
    return 'Swap de rede: Você enviou $from e receberá $to. Assim que processado, a transação será enviada para a blockchain Bitcoin.';
  }

  @override
  String get tx_detail_submarine_generic =>
      'Swap de rede: Transação entre diferentes redes. Aguarde a confirmação.';

  @override
  String get tx_detail_submarine_default =>
      'Esta transação representa uma troca de rede. Assim que confirmada, você receberá os fundos na rede de destino.';

  @override
  String get tx_detail_request_refund => 'Solicitar Reembolso';

  @override
  String get tx_detail_request_refund_subtitle => 'Recuperar seus fundos agora';

  @override
  String get tx_detail_view_send => 'Ver Envio';

  @override
  String get tx_detail_view_receive => 'Ver Recebimento';

  @override
  String get tx_detail_view_send_tx => 'Ver transação de envio';

  @override
  String get tx_detail_view_refund_tx => 'Ver transação de reembolso';

  @override
  String get tx_detail_send_tx_id => 'ID TX Envio';

  @override
  String get tx_detail_refund_tx_id => 'ID TX Reembolso';

  @override
  String get tx_detail_validate_payment => 'Validar Pagamento';

  @override
  String get tx_detail_verify_preimage => 'Verificar preimagem';

  @override
  String tx_detail_send_id_label(String chain) {
    return 'ID Envio ($chain)';
  }

  @override
  String tx_detail_receive_id_label(String chain) {
    return 'ID Recebimento ($chain)';
  }

  @override
  String get main_settings_title => 'Ajustes';

  @override
  String get main_settings_section_merchant => 'COMERCIANTE';

  @override
  String get main_settings_section_transactions => 'TRANSAÇÕES';

  @override
  String get main_settings_section_settings => 'CONFIGURAÇÕES';

  @override
  String get main_settings_section_wallet => 'CARTEIRA';

  @override
  String get main_settings_section_external_links => 'LINKS EXTERNOS';

  @override
  String get main_settings_section_fees => 'TAXAS';

  @override
  String get main_settings_section_version => 'VERSÃO';

  @override
  String get main_settings_settings_label => 'Configurações';

  @override
  String get main_settings_wallet_level => 'Nível da carteira';

  @override
  String get main_settings_pix_fees => 'Taxas do PIX';

  @override
  String get main_settings_btc_services => 'Serviços via Bitcoin';

  @override
  String get main_settings_support => 'Suporte';

  @override
  String get onboarding_1_title => 'Seu dinheiro, sob seu controle';

  @override
  String get onboarding_1_body =>
      'Receba, envie e gerencie Bitcoin com privacidade real. Uma carteira feita pra quem valoriza liberdade.';

  @override
  String get onboarding_2_title => 'Segurança em primeiro lugar';

  @override
  String get onboarding_2_body =>
      'Sua chave, sua responsabilidade. Proteja seu patrimônio com criptografia e backups locais.';

  @override
  String get onboarding_3_title => 'Pronto para começar?';

  @override
  String get onboarding_3_body =>
      'Crie ou importe sua carteira em segundos e assuma o controle do seu Bitcoin.';

  @override
  String get first_access_create_wallet => 'Criar Carteira';

  @override
  String get first_access_import_wallet => 'Importar carteira';

  @override
  String get first_access_terms_prefix => 'Eu li e concordo com os ';

  @override
  String get first_access_terms_link => 'Termos e Condições';

  @override
  String get level_my_levels => 'Meus Níveis';

  @override
  String level_label(int n) {
    return 'Nível $n';
  }

  @override
  String get level_current => 'Nível atual: ';

  @override
  String level_progress(int percent) {
    return 'Progresso: $percent%';
  }

  @override
  String level_next(String name) {
    return 'Próximo: $name';
  }

  @override
  String get level_load_error => 'Erro ao carregar nível';

  @override
  String get level_load_retry => 'Tente novamente mais tarde.';

  @override
  String get level_user_label => 'Nível de usuário';

  @override
  String get level_desc_bronze =>
      'Comece movimentando pequenos valores e desbloqueie os primeiros benefícios.';

  @override
  String get level_desc_silver =>
      'Quanto mais você gasta, mais sobe de nível. Alcance o nível Prata.';

  @override
  String get level_desc_gold =>
      'Nível Gold com limites aumentados para movimentações maiores.';

  @override
  String get level_desc_max =>
      'Nível máximo com os maiores limites e benefícios exclusivos.';

  @override
  String get wallet_levels_title => 'Níveis da Carteira';

  @override
  String get wallet_levels_api_down_title => 'API Indisponível';

  @override
  String get wallet_levels_api_down_body =>
      'Os dados podem estar desatualizados. Algumas funcionalidades estão temporariamente indisponíveis.';

  @override
  String get wallet_levels_load_error_title =>
      'Erro ao carregar níveis da carteira';

  @override
  String get wallet_levels_load_error_body =>
      'Verifique sua conexão com a internet e tente novamente';

  @override
  String get wallet_levels_header_title => 'Cresça com a Mooze';

  @override
  String get wallet_levels_header_subtitle =>
      'Quanto mais você movimenta, mais benefícios e limites desbloqueia.';

  @override
  String get wallet_levels_quick_unlock_title => 'Desbloqueie';

  @override
  String get wallet_levels_quick_unlock_subtitle => 'Aumente limites';

  @override
  String get wallet_levels_quick_earn_title => 'Ganhe';

  @override
  String get wallet_levels_quick_earn_subtitle => 'Benefícios extras';

  @override
  String get wallet_levels_quick_status_title => 'Status';

  @override
  String get wallet_levels_quick_status_subtitle => 'Reconhecimento VIP';

  @override
  String get wallet_levels_current_limits_title => 'Seus Limites Atuais';

  @override
  String wallet_levels_current_level(String levelName) {
    return 'Nível: $levelName';
  }

  @override
  String get wallet_levels_limit_per_transaction => 'Por transação';

  @override
  String get wallet_levels_limit_daily => 'Limite diário';

  @override
  String get wallet_levels_limit_minimum => 'Mínimo';

  @override
  String get wallet_levels_next_level_hint =>
      'Continue usando para desbloquear o próximo nível!';

  @override
  String wallet_levels_next_level_hint_named(String nextLevelName) {
    return 'Continue usando para desbloquear o próximo nível $nextLevelName!';
  }

  @override
  String get wallet_levels_load_limits_error_title =>
      'Erro ao carregar limites';

  @override
  String get wallet_levels_load_limits_error_body =>
      'Tente novamente mais tarde ou contate o suporte.';

  @override
  String get update_available_short => 'Nova atualização disponível';

  @override
  String get update_available_body =>
      'Atualize para obter melhorias e correções';

  @override
  String get update_available_button => 'ATUALIZAR';

  @override
  String get update_dialog_title => 'Atualização Disponível';

  @override
  String get update_dialog_body =>
      'Uma nova versão do aplicativo está disponível.';

  @override
  String get update_current_version => 'Versão atual:';

  @override
  String get update_new_version => 'Nova versão:';

  @override
  String get update_dialog_recommend =>
      'Recomendamos atualizar para obter as melhorias mais recentes e correções de bugs.';

  @override
  String get update_later => 'MAIS TARDE';

  @override
  String get info_overlay_dismiss_hint => 'Toque fora desta área para fechar';

  @override
  String get auth_syncing => 'Sincronizando...';

  @override
  String get api_down_dialog_title => 'API Indisponível';

  @override
  String get api_down_dialog_body =>
      'A API da Mooze está temporariamente indisponível.';

  @override
  String get api_down_maintenance_title =>
      'O servidor pode estar em manutenção';

  @override
  String get api_down_warning_list =>
      '• PIX não disponível\n• Sincronização pausada\n• Dados em cache sendo usados';

  @override
  String get api_down_dialog_footer =>
      'Por favor, tente novamente em alguns minutos.';

  @override
  String get api_down_indicator => 'API Indisponível';

  @override
  String get sync_error_indicator => 'Erro de Sync';

  @override
  String get sync_error_dialog_title => 'Erro de Sincronização';

  @override
  String get sync_error_dialog_body =>
      'Não foi possível sincronizar os serviços Mooze.';

  @override
  String get sync_error_warning => 'Operação não autorizada';

  @override
  String get pin_create_title => 'Criar PIN';

  @override
  String get pin_create_min_length => 'PIN deve ter pelo menos 6 caracteres';

  @override
  String get pin_create_yours => 'Crie seu ';

  @override
  String get pin_create_intro_prefix => 'O ';

  @override
  String get pin_create_intro_suffix =>
      'será utilizado para autorizar transações e acessar sua carteira.';

  @override
  String get pin_change_title => 'Alterar PIN';

  @override
  String get pin_change_min_length => 'PIN deve ter pelo menos 6 caracteres';

  @override
  String get pin_change_yours => 'Crie seu novo ';

  @override
  String get pin_change_intro_prefix => 'Seu novo ';

  @override
  String get pin_change_intro_suffix =>
      'será utilizado para autorizar transações e acessar sua carteira.';

  @override
  String get currency_select_title => 'Selecionar Moeda';

  @override
  String get currency_display_label => 'Moeda de exibição';

  @override
  String get currency_display_description =>
      'Escolha a moeda usada para exibir preços e valores em todo o app.';

  @override
  String get currency_brl_name => 'Brasil (Real Brasileiro)';

  @override
  String get currency_usd_name => 'Estados Unidos (Dólar)';

  @override
  String get referral_save_title => 'Economize com indicações!';

  @override
  String get referral_discount_badge => 'ATÉ 15% DE DESCONTO';

  @override
  String get referral_save_description =>
      'Digite seu código de indicação e aproveite descontos exclusivos em todas as taxas da plataforma.';

  @override
  String get referral_active_title => 'Desconto Ativo';

  @override
  String referral_code_with_value(String code) {
    return 'Código: $code';
  }

  @override
  String get referral_savings_message =>
      'Você está economizando em todas as transações!';

  @override
  String get referral_apply_code => 'Aplicar Código';

  @override
  String get referral_validating => 'Validando...';

  @override
  String get referral_api_down_warning =>
      'A API está indisponível. Não é possível aplicar códigos de indicação no momento.';

  @override
  String get referral_input_unavailable => 'Indisponível';

  @override
  String get referral_input_hint => 'Ex: MOOZE123';

  @override
  String get referral_input_label => 'Código de Indicação';

  @override
  String get pix_fee_conversion_title => 'Taxas de conversão';

  @override
  String get pix_fee_discount_active_short => 'Desconto ativo';

  @override
  String get pix_fee_tier1_range => 'R\$ 20 a R\$ 55';

  @override
  String get pix_fee_tier1_value => 'R\$ 2,00 fixo *';

  @override
  String get pix_fee_tier2_range => 'R\$ 55 a R\$ 499';

  @override
  String get pix_fee_tier2_value => '3,5%';

  @override
  String get pix_fee_tier3_range => 'R\$ 500 a R\$ 3.000';

  @override
  String get pix_fee_tier3_value => '3% *';

  @override
  String get pix_fee_footnote_discount =>
      '* 15% de desconto para usuários com código de indicação.';

  @override
  String get pix_fee_footnote_network =>
      '* Taxas de rede/spread variável por conta do usuário.';

  @override
  String get pix_fee_discount_chip_15 => '−15%';

  @override
  String get support_user_code_load_error_inline => 'Erro ao carregar código';

  @override
  String get support_user_code_unique => 'Código único';

  @override
  String get wallet_send_appbar_title => 'Enviar ativos';

  @override
  String get wallet_send_instruction_prefix =>
      'Escolha o ativo que quer enviar na ';

  @override
  String get wallet_send_address_label => 'Endereço de destino';

  @override
  String get wallet_send_address_hint => 'Digite ou cole o endereço';

  @override
  String get wallet_send_address_scan_qr => 'Escanear QR Code';

  @override
  String get wallet_send_address_paste => 'Colar';

  @override
  String get wallet_send_address_clear => 'Limpar';

  @override
  String get wallet_send_address_paste_empty => 'Área de transferência vazia';

  @override
  String get wallet_send_select_asset => 'Selecione um ativo';

  @override
  String get wallet_send_available_balance => 'Saldo disponível';

  @override
  String get wallet_send_balance_unavailable => 'Indisponível';

  @override
  String get wallet_send_balance_load_error => 'Erro ao carregar';

  @override
  String get wallet_send_amount_label => 'Valor';

  @override
  String get wallet_send_amount_hint => 'Digite o valor';

  @override
  String get wallet_send_amount_in_sats => 'Valor em Satoshis:';

  @override
  String get wallet_send_amount_valid => 'Valor válido!';

  @override
  String get wallet_send_conversion_asset => 'Ativo';

  @override
  String get wallet_send_conversion_sats => 'Satoshis';

  @override
  String get wallet_send_conversion_fiat => 'Fiat';

  @override
  String get wallet_send_drain_title => 'Envio Total de Fundos';

  @override
  String wallet_send_drain_body(String asset) {
    return 'Você selecionou enviar todos os fundos do ativo $asset.';
  }

  @override
  String get wallet_send_drain_ready =>
      'Pronto para revisar - as taxas serão deduzidas do valor total';

  @override
  String get wallet_send_fee_estimated => 'Taxa estimada';

  @override
  String get wallet_send_fee_calculating => 'Calculando taxa...';

  @override
  String get wallet_send_fee_calc_error => 'Erro ao calcular taxa';

  @override
  String get wallet_send_fee_free => 'Gratuito';

  @override
  String get wallet_send_lbtc_disclaimer_title =>
      'Como funciona o envio de ativos';

  @override
  String get wallet_send_lbtc_disclaimer_body =>
      'Para enviar ativos (Bitcoin L2, DePIX ou USDT), você precisa manter um saldo de Bitcoin L2 na sua carteira.';

  @override
  String get wallet_send_lbtc_network_fees_title => 'Taxas de rede';

  @override
  String get wallet_send_lbtc_network_fees_desc =>
      'O saldo de Bitcoin L2 é usado para pagar as taxas dos mineradores da rede Liquid.';

  @override
  String get wallet_send_lbtc_obtain_title => 'Como obter Bitcoin L2';

  @override
  String get wallet_send_lbtc_obtain_desc_disclaimer =>
      'Use a função SWAP ou receba Bitcoin via Lightning ou Liquid.';

  @override
  String get wallet_send_lbtc_obtain_desc_info =>
      'Use a função SWAP para converter Bitcoin (Lightning ou on-chain) em Bitcoin L2 diretamente no aplicativo.';

  @override
  String get wallet_send_lbtc_disclaimer_tip =>
      'Mantenha um pequeno saldo de Bitcoin L2 para garantir que suas transações sejam processadas.';

  @override
  String wallet_send_lbtc_disclaimer_understood_countdown(int seconds) {
    return 'Entendi ($seconds)';
  }

  @override
  String get wallet_send_lbtc_info_title => 'Informações sobre taxas';

  @override
  String get wallet_send_lbtc_info_step1_title =>
      'Bitcoin L2 para taxas de rede';

  @override
  String get wallet_send_lbtc_info_step1_desc =>
      'Para enviar DePIX, USDT ou qualquer ativo da rede Liquid, você precisa ter Bitcoin L2 (Liquid Bitcoin) na carteira. Ele é usado para pagar os mineradores da rede.';

  @override
  String get wallet_send_lbtc_info_step3_title =>
      'Receba via Lightning ou Liquid';

  @override
  String get wallet_send_lbtc_info_step3_desc =>
      'Receba Bitcoin via Lightning Network ou Liquid para obter Bitcoin L2 na sua carteira sem usar o SWAP.';

  @override
  String get wallet_send_lbtc_go_swap => 'Ir para SWAP';

  @override
  String get wallet_send_lbtc_insufficient_title => 'Bitcoin L2 insuficiente';

  @override
  String wallet_send_lbtc_insufficient_body(String asset) {
    return 'Você precisa de Bitcoin L2 para pagar as taxas dos mineradores ao enviar $asset:';
  }

  @override
  String get wallet_send_lbtc_insufficient_swap_prefix => 'Use a função ';

  @override
  String get wallet_send_lbtc_insufficient_swap_suffix =>
      ' para obter Bitcoin L2';

  @override
  String get wallet_send_lbtc_insufficient_lightning =>
      'Receba Bitcoin via Lightning ou Liquid para obter Bitcoin L2';

  @override
  String get wallet_send_lbtc_banner_title =>
      'Bitcoin L2 necessário para taxas';

  @override
  String get wallet_send_lbtc_banner_body =>
      'Para enviar DePIX ou USDT, você precisa ter Bitcoin L2 na carteira para pagar as taxas da rede.';

  @override
  String get wallet_send_lbtc_banner_action => 'Obter via SWAP';

  @override
  String get wallet_send_network_unidentified => 'Rede não identificada';

  @override
  String get wallet_send_network_bitcoin => 'Bitcoin On-chain';

  @override
  String get wallet_send_network_liquid => 'Liquid Network';

  @override
  String get wallet_send_network_unknown => 'Rede desconhecida';

  @override
  String get wallet_send_predefined_label => 'Valor pré-definido';

  @override
  String get wallet_send_predefined_body =>
      'Este invoice/endereço possui um valor pré-definido. O campo de quantia foi automaticamente preenchido.';

  @override
  String wallet_send_predefined_label_value(String label) {
    return 'Label: $label';
  }

  @override
  String wallet_send_predefined_message_value(String message) {
    return 'Mensagem: $message';
  }

  @override
  String get wallet_send_review_preparing => 'Preparando...';

  @override
  String get wallet_send_review_drain => 'Revisar Envio Total';

  @override
  String get wallet_send_review_transaction => 'Revisar Transação';

  @override
  String wallet_send_review_lbtc_insufficient_error(String asset) {
    return 'Saldo de Bitcoin L2 insuficiente para taxas.\n\nPara enviar $asset, você precisa de Bitcoin L2 para pagar os mineradores da rede. Use a função SWAP ou receba Bitcoin via Lightning ou Liquid.';
  }

  @override
  String get wallet_send_review_insufficient_error =>
      'Saldo insuficiente para realizar o envio.\n\nVerifique se você tem saldo suficiente para cobrir o valor e as taxas da rede.';

  @override
  String get wallet_send_review_prepare_error =>
      'Não foi possível preparar a transação. Tente novamente.';

  @override
  String get wallet_send_loading_conversions => 'Carregando conversões...';

  @override
  String get wallet_send_equivalent_conversions => 'Conversões equivalentes:';

  @override
  String get wallet_send_satoshis_label => 'Satoshis:';

  @override
  String get wallet_send_validation_attention => 'Atenção';

  @override
  String get wallet_send_validation_help =>
      'As validações são verificadas automaticamente conforme você digita.';

  @override
  String get wallet_send_error_address_required => 'Endereço é obrigatório';

  @override
  String get wallet_send_error_address_invalid =>
      'Endereço inválido ou não suportado';

  @override
  String wallet_send_error_asset_liquid_only(String asset) {
    return '$asset só pode ser enviado pela rede Liquid ou Lightning';
  }

  @override
  String get wallet_send_error_liquid_only =>
      'Para enviar ativos Liquid use Bitcoin L2, Depix ou USDT';

  @override
  String get wallet_send_error_amount_positive =>
      'Valor deve ser maior que zero';

  @override
  String get wallet_send_error_balance_check =>
      'Erro ao verificar saldo disponível';

  @override
  String get wallet_send_error_insufficient_balance => 'Saldo insuficiente';

  @override
  String get wallet_send_error_address_unrecognized =>
      'Endereço inválido ou não reconhecido';

  @override
  String get wallet_send_error_self_transfer =>
      'Você não pode enviar para o seu próprio endereço';

  @override
  String get wallet_send_error_pending_payments =>
      'Não é possível enviar o saldo total enquanto há pagamentos pendentes. Aguarde a conclusão dos pagamentos e tente novamente.';

  @override
  String wallet_send_error_validation_failed(String error) {
    return 'Não foi possível validar a transação: $error';
  }

  @override
  String get wallet_send_error_amount_exceeds_balance =>
      'Valor informado é maior que o saldo disponível';

  @override
  String wallet_send_error_insufficient_with_fees(
    String total,
    String amount,
    String fee,
    String satText,
    String balance,
  ) {
    return 'Saldo insuficiente. Você precisa de $total sats ($amount + $fee $satText de taxa), mas tem apenas $balance sats disponíveis';
  }

  @override
  String wallet_send_error_fee_calc_failed(String error) {
    return 'Não foi possível calcular as taxas: $error';
  }

  @override
  String wallet_send_error_validate_balance_fees(String error) {
    return 'Erro ao validar saldo e taxas: $error';
  }

  @override
  String get wallet_send_error_min_usdt => 'Valor mínimo para USDT é 0.5 USDT';

  @override
  String get wallet_send_error_min_depix =>
      'Valor mínimo para Depix é 1.0 Depix';

  @override
  String wallet_send_error_validate_limits(String error) {
    return 'Erro ao validar limites de envio: $error';
  }

  @override
  String get wallet_action_receive => 'RECEBER';

  @override
  String get wallet_action_send => 'ENVIAR';

  @override
  String get wallet_action_buy => 'PIX';

  @override
  String get wallet_assets_section_title => 'Ativos';

  @override
  String get wallet_transactions_section_title => 'Transações';

  @override
  String get wallet_section_see_more => 'Ver mais';

  @override
  String get wallet_holding_allocation_title => 'Distribuição';

  @override
  String get wallet_tx_date_today => 'Hoje';

  @override
  String get wallet_tx_date_yesterday => 'Ontem';

  @override
  String get wallet_action_more => 'Mais';

  @override
  String get wallet_more_sheet_title => 'Mais ações';

  @override
  String get wallet_more_buy_pix => 'Comprar com PIX';

  @override
  String get wallet_balance_show => 'Mostrar saldo';

  @override
  String get wallet_balance_hide => 'Ocultar saldo';

  @override
  String get wallet_balance_hidden => 'Saldo oculto';

  @override
  String get wallet_balance_change_unit_hint => 'Alterar unidade';

  @override
  String get wallet_amount_hidden => 'Valor oculto';

  @override
  String wallet_tx_sent(String ticker) {
    return 'Enviou $ticker';
  }

  @override
  String wallet_tx_received(String ticker) {
    return 'Recebeu $ticker';
  }

  @override
  String wallet_tx_swap_pair(String from, String to) {
    return 'Swap: $from para $to';
  }

  @override
  String wallet_tx_redeposit(String ticker) {
    return 'Autodepositou $ticker';
  }

  @override
  String get wallet_tx_unknown => 'Tipo de transação desconhecido';

  @override
  String get wallet_tx_load_error_title =>
      'Não foi possível carregar transações';

  @override
  String get wallet_tx_load_error_retry => 'Tente novamente mais tarde';

  @override
  String get wallet_tx_empty_title => 'Nenhuma transação encontrada';

  @override
  String get wallet_tx_empty_body =>
      'Seu histórico de transações aparecerá aqui assim que você realizar alguma movimentação.';

  @override
  String get wallet_all_assets_title => 'Todos os Ativos';

  @override
  String get wallet_all_assets_subtitle =>
      'Acompanhe a cotação de todos os ativos disponíveis';

  @override
  String get wallet_all_assets_favorite_hint =>
      'Toque no ícone para favoritar — ';

  @override
  String wallet_all_assets_favorite_count(int count) {
    return '$count/2 selecionados';
  }

  @override
  String wallet_asset_chart_title(String period) {
    return 'Gráfico - $period';
  }

  @override
  String get wallet_asset_chart_unavailable => 'Gráfico Indisponível';

  @override
  String get wallet_asset_chart_load_error =>
      'Não foi possível carregar o gráfico';

  @override
  String get wallet_asset_stats_high => 'Máxima';

  @override
  String get wallet_asset_stats_low => 'Mínima';

  @override
  String get wallet_asset_stats_current => 'Atual';

  @override
  String get wallet_holding_appbar_title => 'Ativos';

  @override
  String get wallet_holding_action_send => 'Enviar';

  @override
  String get wallet_holding_action_receive => 'Receber';

  @override
  String get wallet_holding_action_swap => 'Swap';

  @override
  String wallet_holding_unexpected_error(String error) {
    return 'Erro inesperado: $error';
  }

  @override
  String get wallet_holding_empty => 'Nenhum ativo encontrado';

  @override
  String get wallet_holding_no_balance => 'Sem saldo';

  @override
  String get wallet_holding_load_error_title => 'Erro ao carregar ativos';

  @override
  String get wallet_holding_pending_payments_title => 'Pagamentos em análise';

  @override
  String wallet_holding_pending_payments_total(String currency, String value) {
    return 'Total: $currency $value';
  }

  @override
  String get wallet_holding_calculating => 'Calculando...';

  @override
  String get pix_receive_appbar_title => 'Receber PIX';

  @override
  String get pix_receive_api_unavailable =>
      'Não é possível processar transações PIX no momento. Por favor, tente novamente mais tarde.';

  @override
  String get pix_receive_info_title => 'Informações sobre PIX';

  @override
  String get pix_receive_info_step1_title => 'Prazo de processamento';

  @override
  String get pix_receive_info_step1_desc =>
      'Pagamentos via PIX podem ser processados em até 72 horas úteis após a confirmação.';

  @override
  String get pix_receive_info_step2_title => 'Variação de câmbio (LBTC)';

  @override
  String get pix_receive_info_step2_desc =>
      'Ao escolher receber em LBTC, o valor final pode variar devido à cotação do momento da conversão. Você pode receber mais ou menos que o calculado.';

  @override
  String get pix_receive_info_step3_title => 'Sobre as taxas';

  @override
  String get pix_receive_info_step3_desc =>
      'As taxas variam conforme o valor da transação. Valores menores têm taxas fixas, valores maiores têm taxas percentuais decrescentes.';

  @override
  String get pix_receive_info_see_fees => 'Ver detalhes das taxas';

  @override
  String get pix_receive_instruction_prefix =>
      'Escolha o ativo que deseja receber na ';

  @override
  String get pix_receive_tip_more_payments =>
      'Faça mais pagamentos para liberar novos limites';

  @override
  String get pix_receive_advance => 'Avançar';

  @override
  String get pix_receive_my_level => 'Meu Nível';

  @override
  String get pix_receive_you_add => 'Você adiciona';

  @override
  String get pix_receive_my_limits => 'Meus limites';

  @override
  String get pix_receive_see_levels => 'Ver níveis';

  @override
  String get pix_receive_daily_limit => 'Limite diário';

  @override
  String get pix_receive_per_transaction => 'Por transação';

  @override
  String get pix_receive_min => 'Mín.';

  @override
  String get pix_receive_limits_error => 'Erro ao carregar limites';

  @override
  String pix_receive_details(String detail) {
    return 'Detalhes: $detail';
  }

  @override
  String get pix_receive_validation_invalid_amount => 'Digite um valor válido';

  @override
  String pix_receive_validation_below_min(String amount) {
    return 'Valor mínimo: R\$ $amount';
  }

  @override
  String pix_receive_validation_above_transaction(String amount) {
    return 'Limite por transação: R\$ $amount';
  }

  @override
  String get pix_tip_consecutive_daily =>
      'Máx. 3 PIX seguidos do mesmo titular em 30 min · Limite de R\$ 5.000/dia por titular.';

  @override
  String get pix_tip_outside_rules_returned =>
      'Pagamentos fora das regras são devolvidos automaticamente ao remetente.';

  @override
  String get pix_tip_processing_avg_time =>
      'Processamento em 5–25 min. PIX com sinal de risco bancário pode levar 3–7 dias (estornável).';

  @override
  String get pix_payment_appbar_title => 'Pagamento PIX';

  @override
  String pix_payment_qr_error(String error) {
    return 'Falha ao gerar QR code: $error';
  }

  @override
  String get pix_payment_time_expired_body =>
      'O tempo para realizar o pagamento expirou. Por favor, gere um novo PIX.';

  @override
  String get tx_filter_pix_title => 'Filtros PIX';

  @override
  String get tx_filter_deposit_status => 'Status do depósito';

  @override
  String get tx_filter_most_recent => 'Mais Recente';

  @override
  String get tx_filter_oldest => 'Mais Antigo';

  @override
  String get tx_filter_select_period => 'Selecionar Período';

  @override
  String get tx_filter_select => 'Selecione';

  @override
  String get tx_filter_to => 'para';

  @override
  String get tx_filter_start_after_end_error =>
      'A data de início não pode ser posterior à data de término.';

  @override
  String get tx_history_refresh_debug => 'Atualizar (Debug)';

  @override
  String tx_history_filters_active(String description) {
    return 'Filtros ativos - $description';
  }

  @override
  String get tx_history_clear => 'Limpar';

  @override
  String tx_history_filter_count(int filtered, int total, String description) {
    return '$filtered de $total transações - $description';
  }

  @override
  String get tx_history_filter_refunds => 'Reembolsos';

  @override
  String tx_history_filter_from(String date) {
    return 'A partir de $date';
  }

  @override
  String tx_history_filter_until(String date) {
    return 'Até $date';
  }

  @override
  String get tx_history_filter_oldest_first => 'Mais antigos primeiro';

  @override
  String get tx_history_filter_default => 'Todos';

  @override
  String get pix_filter_status_pending => 'Pagamento Pendente';

  @override
  String get pix_filter_status_processing => 'Processando 1/2';

  @override
  String get pix_filter_status_finished => 'Enviado';

  @override
  String get pix_filter_status_expired => 'Expirado';

  @override
  String get address_explorer_title => 'Endereços e UTXOs';

  @override
  String get address_explorer_search_hint => 'Buscar endereço…';

  @override
  String get address_explorer_search_match_onchain =>
      'Endereço encontrado em On-chain.';

  @override
  String get address_explorer_search_match_liquid =>
      'Endereço encontrado em Liquid.';

  @override
  String address_explorer_search_match_at_index(String chain, int index) {
    return '$chain · índice $index';
  }

  @override
  String get address_explorer_search_no_match =>
      'Endereço não pertence à sua carteira.';

  @override
  String get address_explorer_tab_onchain => 'On-chain';

  @override
  String get address_explorer_tab_liquid => 'Liquid';

  @override
  String address_explorer_load_more(int count) {
    return 'Carregar mais $count endereços';
  }

  @override
  String get address_explorer_loading_more => 'Carregando…';

  @override
  String get address_explorer_loading => 'Carregando endereços…';

  @override
  String get address_explorer_empty => 'Nenhum endereço encontrado.';

  @override
  String address_explorer_load_error(String error) {
    return 'Falha ao carregar endereços: $error';
  }

  @override
  String get address_explorer_address_copied => 'Endereço copiado';

  @override
  String get address_explorer_status_used => 'USADO';

  @override
  String get address_explorer_status_unused => 'NÃO UTILIZADO';

  @override
  String address_explorer_utxo_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count UTXOs',
      one: '1 UTXO',
      zero: 'sem UTXOs',
    );
    return '$_temp0';
  }

  @override
  String get address_explorer_utxos_section => 'UTXOs';

  @override
  String get address_explorer_utxos_tap_to_expand => 'toque para expandir';

  @override
  String get address_explorer_utxos_tap_to_collapse => 'toque para recolher';

  @override
  String address_explorer_summary(int total, int used, int utxos) {
    return '$total endereços · $used usados · $utxos UTXOs';
  }

  @override
  String address_explorer_summary_addresses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count endereços',
      one: '1 endereço',
    );
    return '$_temp0';
  }

  @override
  String address_explorer_summary_status(int used, int unused) {
    return '$used usados • $unused não utilizados';
  }

  @override
  String address_explorer_summary_utxos_total(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count UTXOs',
      one: '1 UTXO',
      zero: 'sem UTXOs',
    );
    return '$_temp0';
  }

  @override
  String address_explorer_total_received(String amount) {
    return 'Recebido: $amount';
  }

  @override
  String get address_explorer_filter_all => 'Todos';

  @override
  String get address_explorer_filter_used => 'Usados';

  @override
  String get address_explorer_filter_unused => 'Não utilizados';

  @override
  String get address_explorer_filter_with_utxos => 'Com UTXOs';

  @override
  String get address_explorer_filter_empty =>
      'Nenhum endereço corresponde ao filtro atual.';

  @override
  String get address_explorer_full_address_title => 'Endereço';

  @override
  String get address_explorer_full_address_copy => 'Copiar endereço';

  @override
  String get address_explorer_close => 'Fechar';

  @override
  String get address_ownership_title => 'Verificar endereço';

  @override
  String get address_ownership_description =>
      'Cole um endereço para verificar a propriedade';

  @override
  String get address_ownership_subtitle => 'Suporta Bitcoin e Liquid';

  @override
  String get address_ownership_input_hint => 'bc1q… / lq1… / 1A1z…';

  @override
  String get address_ownership_paste_tooltip => 'Colar';

  @override
  String get address_ownership_clear_tooltip => 'Limpar';

  @override
  String get address_ownership_verify => 'Verificar';

  @override
  String get address_ownership_verifying => 'Verificando…';

  @override
  String get address_ownership_clear => 'Limpar';

  @override
  String get address_ownership_paste_feedback =>
      'Colado da área de transferência';

  @override
  String get address_ownership_clear_feedback => 'Limpo';

  @override
  String address_ownership_detected(String chain) {
    return 'Detectado: $chain';
  }

  @override
  String get address_ownership_invalid_format => 'Formato de endereço inválido';

  @override
  String get address_ownership_owned_title => 'Seu endereço';

  @override
  String get address_ownership_not_owned_title => 'Não é o seu endereço';

  @override
  String get address_ownership_field_type => 'Tipo';

  @override
  String get address_ownership_field_utxos => 'UTXOs';

  @override
  String get address_ownership_field_used => 'Usado';

  @override
  String get address_ownership_field_balance => 'Saldo';

  @override
  String get address_ownership_yes => 'Sim';

  @override
  String get address_ownership_no => 'Não';

  @override
  String get address_ownership_chain_bitcoin => 'Bitcoin';

  @override
  String get address_ownership_chain_liquid => 'Liquid';

  @override
  String address_ownership_index_label(int index) {
    return 'índice $index';
  }

  @override
  String get address_ownership_status_used => 'usado';

  @override
  String get address_ownership_status_unused => 'não utilizado';

  @override
  String get settings_section_addresses => 'ENDEREÇOS';

  @override
  String get settings_verify_address => 'Verificar endereço';

  @override
  String get settings_address_explorer => 'Endereços e UTXOs';

  @override
  String get converting_details_title => 'Conversão em andamento';

  @override
  String get converting_details_refund_title => 'O swap não pôde ser concluído';

  @override
  String get converting_details_refund_message =>
      'A Boltz sinalizou este swap como reembolsável. Seus fundos estão seguros — recupere-os para sua carteira usando o fluxo de reembolso abaixo.';

  @override
  String get converting_details_refund_button => 'Obter reembolso';

  @override
  String get converting_details_completed_title => 'Conversão concluída';

  @override
  String get converting_details_completed_message =>
      'Os fundos chegaram à rede de destino. O swap completo já aparece no seu histórico de transações.';

  @override
  String get converting_details_back_to_home => 'Voltar para início';

  @override
  String converting_details_converting_label(String from, String to) {
    return 'Convertendo $from → $to';
  }

  @override
  String get converting_details_peg_in => 'Peg-in';

  @override
  String get converting_details_peg_out => 'Peg-out';

  @override
  String get converting_details_you_sent => 'Você enviou';

  @override
  String get converting_details_youll_receive => 'Você receberá';

  @override
  String get converting_details_phase_preparing => 'Preparando';

  @override
  String get converting_details_phase_broadcasting => 'Transmitindo';

  @override
  String get converting_details_phase_awaiting_confirmations =>
      'Aguardando confirmações';

  @override
  String get converting_details_phase_failed => 'Falhou';

  @override
  String get converting_details_phase_refundable => 'Reembolsável';

  @override
  String get converting_details_direction => 'Direção';

  @override
  String get converting_details_direction_peg_in =>
      'Peg-in (BTC on-chain → LBTC)';

  @override
  String get converting_details_direction_peg_out =>
      'Peg-out (LBTC → BTC on-chain)';

  @override
  String get converting_details_sent => 'Enviado';

  @override
  String get converting_details_estimated_receive => 'Recebimento estimado';

  @override
  String get converting_details_started => 'Iniciado';

  @override
  String get converting_details_destination_address => 'Endereço de destino';

  @override
  String get converting_details_swap_id => 'ID do swap';

  @override
  String get converting_details_bitcoin_send_tx => 'Transação de envio Bitcoin';

  @override
  String get converting_details_liquid_send_tx => 'Transação de envio Liquid';

  @override
  String get converting_details_local_id => 'ID local';

  @override
  String get converting_details_help_footer =>
      'Os chain swaps movem fundos entre Bitcoin e Liquid Bitcoin (L-BTC) e geralmente são liquidados em 30 a 60 minutos após a confirmação da transação de bloqueio. Seus fundos não estão perdidos — eles ficam temporariamente bloqueados no contrato do swap enquanto a rede de destino se atualiza.';

  @override
  String get converting_details_explanation_preparing =>
      'Construindo a transação de bloqueio e reservando o swap com o serviço de chain-swap.';

  @override
  String get converting_details_explanation_broadcasting_bitcoin =>
      'Assinando e transmitindo a transação de bloqueio para a rede Bitcoin.';

  @override
  String get converting_details_explanation_broadcasting_liquid =>
      'Assinando e transmitindo a transação de bloqueio para a rede Liquid.';

  @override
  String get converting_details_explanation_broadcasted_peg_in =>
      'Seu bloqueio de Bitcoin foi transmitido. Assim que confirmar, o serviço de chain-swap irá reivindicá-lo e enviar LBTC para sua carteira.';

  @override
  String get converting_details_explanation_broadcasted_peg_out =>
      'Seu LBTC foi enviado para o serviço de chain-swap. Assim que for processado, você receberá BTC na rede Bitcoin.';

  @override
  String get converting_details_explanation_failed =>
      'O swap não pôde ser concluído. Quaisquer fundos reservados para o swap serão reembolsados automaticamente.';

  @override
  String get converting_details_explanation_refundable =>
      'A Boltz sinalizou o swap como reembolsável. Toque em \"Obter reembolso\" para enviar os fundos bloqueados de volta para sua carteira.';

  @override
  String get pending_swap_refund_available => 'Reembolso de swap disponível';

  @override
  String get pending_swap_status_preparing => 'Preparando swap…';

  @override
  String get pending_swap_status_broadcasting => 'Transmitindo para a rede…';

  @override
  String get pending_swap_status_broadcasted =>
      'Transmitido — aguardando confirmações';

  @override
  String get pending_swap_status_failed => 'Falha no swap';

  @override
  String get pending_swap_status_refundable =>
      'Toque para solicitar seu reembolso';

  @override
  String pending_swap_refundable_amount(String amount) {
    return 'Reembolsável: $amount';
  }

  @override
  String get pix_first_time_title => 'Atenção sobre pagamentos PIX';

  @override
  String get pix_first_time_description =>
      'Todos os pagamentos PIX passam por análise de segurança e podem ser:';

  @override
  String get pix_first_time_item_completed => 'Efetivados em até 72 horas';

  @override
  String get pix_first_time_item_refunded => 'Estornados para o pagante';

  @override
  String get pix_first_time_security_note =>
      'Esta análise é necessária para garantir a segurança de todos os usuários.';

  @override
  String get pix_first_time_accept_button => 'Compreendo e aceito';

  @override
  String pix_first_time_accept_button_counting(int seconds) {
    return 'Compreendo e aceito ($seconds)';
  }

  @override
  String get swap_btc_lbtc_warning_title => 'Atenção: Swap entre Redes';

  @override
  String get swap_btc_lbtc_warning_intro =>
      'Informações importantes sobre o swap BTC para LBTC:';

  @override
  String get swap_btc_lbtc_warning_cross_chain =>
      'Este é um swap entre diferentes blockchains (Bitcoin e Liquid Network).';

  @override
  String get swap_btc_lbtc_warning_confirmations =>
      'O swap depende de confirmações em ambas as blockchains, o que pode levar algum tempo.';

  @override
  String get swap_btc_lbtc_warning_fee_changes =>
      'Em casos de mudanças nas taxas da rede, a Breez pode deixar o ativo como \"estorno\" (reembolso).';

  @override
  String get swap_btc_lbtc_warning_manual_refund =>
      'Se isso acontecer, você deverá solicitar o reembolso manualmente dentro do aplicativo.';

  @override
  String get swap_btc_lbtc_warning_funds_safe =>
      'Seus fundos estão sempre seguros, mesmo em caso de estorno.';

  @override
  String get swap_btc_lbtc_warning_accept_button => 'Entendi e Aceito';

  @override
  String swap_btc_lbtc_warning_accept_button_counting(int seconds) {
    return 'Entendi e Aceito ($seconds)';
  }

  @override
  String asset_activity_market_price(String ticker) {
    return 'Preço $ticker';
  }

  @override
  String get asset_activity_summary_title => 'Resumo';

  @override
  String get asset_activity_received_total => 'Recebido total';

  @override
  String get asset_activity_sent_total => 'Enviado total';

  @override
  String get asset_activity_current_balance => 'Saldo atual';

  @override
  String get asset_activity_transactions => 'Transações';

  @override
  String get asset_activity_section_title => 'Movimentações';

  @override
  String get asset_activity_first => 'Primeira movimentação';

  @override
  String get asset_activity_last => 'Última movimentação';

  @override
  String get asset_activity_highlights_title => 'Destaques';

  @override
  String get asset_activity_largest_receive => 'Maior recebimento';

  @override
  String get asset_activity_largest_send => 'Maior envio';

  @override
  String get asset_activity_total_volume => 'Volume movimentado';

  @override
  String get asset_activity_history_title => 'Transações';

  @override
  String get analytics_opt_in => 'Compartilhar dados de uso (opcional)';

  @override
  String get analytics_description =>
      'Ajude a melhorar o Mooze enviando ao PostHog telas visitadas e resultados de ações, com um identificador aleatório e informações básicas do aplicativo e dispositivo. Não enviamos sua frase, PIN, endereços, saldos ou valores. Sem gravação de tela. Você pode desativar a qualquer momento nos Ajustes.';

  @override
  String get analytics_save_error =>
      'Não foi possível atualizar a preferência de dados de uso. Tente novamente.';

  @override
  String get pix_hub_title => 'Área Pix';

  @override
  String get pix_hub_demo_badge => 'Demonstração';

  @override
  String get pix_hub_demo_badge_semantics => 'Conteúdo de demonstração';

  @override
  String get pix_hub_demo_notice_title => 'Modo demonstração';

  @override
  String get pix_hub_demo_notice_body =>
      'Enviar, receber, chaves, links e histórico usam dados fictícios. Nenhum valor sai da sua conta. Apenas o depósito na carteira usa o serviço real da Mooze.';

  @override
  String get pix_hub_shortcut_send => 'Enviar';

  @override
  String get pix_hub_shortcut_receive => 'Receber';

  @override
  String get pix_hub_shortcut_deposit => 'Depositar';

  @override
  String get pix_hub_more_operations => 'Mais operações';

  @override
  String get pix_hub_action_pay_key => 'Pagar com chave Pix';

  @override
  String get pix_hub_action_pay_key_subtitle =>
      'Informe CPF, CNPJ, celular, e-mail ou chave aleatória.';

  @override
  String get pix_hub_action_pay_qr => 'Pagar com QR Code';

  @override
  String get pix_hub_action_pay_qr_subtitle =>
      'Use a câmera para ler o código.';

  @override
  String get pix_hub_action_copy_paste => 'Pix Copia e Cola';

  @override
  String get pix_hub_action_copy_paste_subtitle => 'Cole o código da cobrança.';

  @override
  String get pix_hub_action_links => 'Links de pagamento';

  @override
  String get pix_hub_action_links_subtitle => 'Crie e compartilhe cobranças.';

  @override
  String get pix_hub_action_keys => 'Minhas chaves Pix';

  @override
  String get pix_hub_action_keys_subtitle =>
      'Veja, copie e compartilhe suas chaves.';

  @override
  String get pix_hub_action_history => 'Histórico Pix';

  @override
  String get pix_hub_action_history_subtitle =>
      'Veja apenas movimentações Pix.';

  @override
  String get pix_hub_recent_recipients => 'Contatos recentes';

  @override
  String get pix_hub_view_all => 'Ver todos';

  @override
  String get pix_hub_pending_links => 'Cobranças pendentes';

  @override
  String get pix_hub_recent_activity => 'Últimas movimentações';

  @override
  String get pix_hub_manage => 'Gerenciar';

  @override
  String get pix_hub_empty_recipients_title => 'Nenhum contato recente';

  @override
  String get pix_hub_empty_recipients_body =>
      'Os contatos aparecem aqui depois do primeiro pagamento.';

  @override
  String get pix_hub_empty_links_title => 'Nenhuma cobrança pendente';

  @override
  String get pix_hub_empty_links_body =>
      'Crie um link de pagamento para receber de outra pessoa.';

  @override
  String get pix_hub_empty_transactions_title => 'Nenhuma movimentação Pix';

  @override
  String get pix_hub_empty_transactions_body =>
      'As movimentações aparecem aqui depois da primeira operação.';

  @override
  String get pix_hub_empty_keys_title => 'Nenhuma chave cadastrada';

  @override
  String get pix_hub_empty_keys_body =>
      'O cadastro de chaves depende de um serviço Pix que a Mooze ainda não possui.';

  @override
  String get pix_hub_error_title => 'Não foi possível carregar';

  @override
  String get pix_hub_error_body => 'Verifique a conexão e tente novamente.';

  @override
  String get pix_hub_menu_fees => 'Ver taxas';

  @override
  String get pix_hub_menu_empty_preview_on => 'Ver estados vazios';

  @override
  String get pix_hub_menu_empty_preview_off => 'Mostrar dados de demonstração';

  @override
  String get pix_hub_send_title => 'Enviar Pix';

  @override
  String get pix_hub_key_input_title => 'Qual é a chave Pix?';

  @override
  String get pix_hub_key_input_hint =>
      'A Mooze aceita CPF, CNPJ, celular, e-mail e chave aleatória. O aplicativo confere apenas o formato.';

  @override
  String get pix_hub_key_input_label => 'Chave Pix';

  @override
  String get pix_hub_key_input_placeholder => 'exemplo@email.com';

  @override
  String pix_hub_key_detected(String type) {
    return 'Formato reconhecido: $type.';
  }

  @override
  String get pix_hub_key_error_empty => 'Informe a chave Pix.';

  @override
  String get pix_hub_key_error_unrecognized =>
      'A chave não corresponde a nenhum formato Pix.';

  @override
  String get pix_hub_key_error_document =>
      'Os dígitos verificadores do CPF ou do CNPJ não conferem.';

  @override
  String get pix_hub_key_error_phone =>
      'Informe o celular com DDI e DDD. Exemplo: +5511999990000.';

  @override
  String get pix_hub_key_error_email => 'O e-mail é inválido.';

  @override
  String get pix_hub_key_error_random =>
      'A chave aleatória tem 32 caracteres e quatro hífens.';

  @override
  String get pix_hub_key_type_cpf => 'CPF';

  @override
  String get pix_hub_key_type_cnpj => 'CNPJ';

  @override
  String get pix_hub_key_type_phone => 'Celular';

  @override
  String get pix_hub_key_type_email => 'E-mail';

  @override
  String get pix_hub_key_type_random => 'Chave aleatória';

  @override
  String get pix_hub_code_input_title => 'Cole o código Pix';

  @override
  String get pix_hub_code_input_hint =>
      'A Mooze confere a estrutura e o dígito de verificação do código. Essa checagem não confirma que a cobrança existe.';

  @override
  String get pix_hub_code_input_placeholder => '00020126...';

  @override
  String get pix_hub_code_paste => 'Colar';

  @override
  String get pix_hub_code_sample => 'Usar código de demonstração';

  @override
  String get pix_hub_code_read_title => 'Dados lidos do código';

  @override
  String get pix_hub_code_local_check_warning =>
      'Os dados vêm do próprio código. A Mooze não consultou nenhuma instituição.';

  @override
  String get pix_hub_code_clipboard_empty =>
      'A área de transferência está vazia.';

  @override
  String get pix_hub_code_copied => 'Código copiado.';

  @override
  String get pix_hub_code_error_empty => 'Informe o código Pix.';

  @override
  String get pix_hub_code_error_short => 'O código é curto demais.';

  @override
  String get pix_hub_code_error_malformed => 'O código não segue o padrão Pix.';

  @override
  String get pix_hub_code_error_not_pix => 'O código não é uma cobrança Pix.';

  @override
  String get pix_hub_code_error_checksum =>
      'O dígito de verificação do código não confere.';

  @override
  String get pix_hub_scan_permission_title => 'Câmera bloqueada';

  @override
  String get pix_hub_scan_permission_body =>
      'Libere o acesso à câmera para ler o QR Code.';

  @override
  String get pix_hub_scan_open_settings => 'Abrir ajustes';

  @override
  String get pix_hub_scan_unavailable_title => 'Câmera indisponível';

  @override
  String get pix_hub_scan_unavailable_body => 'Use o Pix Copia e Cola.';

  @override
  String get pix_hub_scan_demo_hint =>
      'Sem câmera disponível? Use o código de demonstração para testar o fluxo.';

  @override
  String get pix_hub_amount_title => 'Valor';

  @override
  String get pix_hub_amount_label => 'Valor do Pix';

  @override
  String get pix_hub_amount_error_empty => 'Informe um valor maior que zero.';

  @override
  String pix_hub_amount_error_max(String amount) {
    return 'O valor máximo é $amount.';
  }

  @override
  String get pix_hub_amount_fixed_hint =>
      'O código já define o valor da cobrança.';

  @override
  String get pix_hub_description_label => 'Descrição (opcional)';

  @override
  String get pix_hub_description_hint => 'Mensagem para quem recebe';

  @override
  String get pix_hub_review_title => 'Revisar pagamento';

  @override
  String get pix_hub_review_amount_label => 'Você vai enviar';

  @override
  String get pix_hub_review_confirm => 'Confirmar e pagar';

  @override
  String get pix_hub_review_disclaimer =>
      'Ao confirmar, sua carteira envia o valor em DePix ao provedor Pix. Não é possível desfazer esta transferência.';

  @override
  String get pix_hub_result_title => 'Resultado';

  @override
  String get pix_hub_result_success_title => 'Pagamento enviado!';

  @override
  String get pix_hub_result_success_body =>
      'O registro entrou no histórico de demonstração. Nenhum valor foi transferido.';

  @override
  String get pix_hub_result_failure_title => 'Pagamento simulado recusado';

  @override
  String get pix_hub_result_disclaimer =>
      'Esta tela é uma demonstração. Ela não comprova uma transação financeira.';

  @override
  String get pix_hub_result_try_again => 'Tentar outro valor';

  @override
  String get pix_hub_flow_expired =>
      'O fluxo foi reiniciado. Comece outra vez.';

  @override
  String get pix_hub_back_to_hub => 'Voltar ao Pix';

  @override
  String get pix_hub_summary_recipient => 'Para';

  @override
  String get pix_hub_summary_payer => 'De';

  @override
  String get pix_hub_summary_institution => 'Instituição';

  @override
  String get pix_hub_summary_document => 'Documento';

  @override
  String get pix_hub_summary_method => 'Forma de envio';

  @override
  String get pix_hub_summary_description => 'Descrição';

  @override
  String get pix_hub_summary_amount => 'Valor';

  @override
  String get pix_hub_summary_date => 'Data';

  @override
  String get pix_hub_summary_reference => 'Identificador';

  @override
  String get pix_hub_summary_status => 'Status';

  @override
  String get pix_hub_summary_type => 'Tipo';

  @override
  String get pix_hub_summary_city => 'Cidade';

  @override
  String get pix_hub_summary_created_at => 'Criada em';

  @override
  String get pix_hub_summary_expires_at => 'Expira em';

  @override
  String get pix_hub_method_key => 'Chave Pix';

  @override
  String get pix_hub_method_qr => 'QR Code';

  @override
  String get pix_hub_method_copy_paste => 'Copia e Cola';

  @override
  String get pix_hub_method_recent => 'Contato recente';

  @override
  String get pix_hub_receive_title => 'Receber Pix';

  @override
  String get pix_hub_receive_from_others => 'Receber de outra pessoa';

  @override
  String get pix_hub_receive_create_charge => 'Criar cobrança';

  @override
  String get pix_hub_receive_create_charge_subtitle =>
      'Gere um QR Code e um código Copia e Cola.';

  @override
  String get pix_hub_receive_own_wallet => 'Adicionar saldo na sua carteira';

  @override
  String get pix_hub_receive_deposit_subtitle =>
      'Pague um Pix e receba o valor na carteira Mooze.';

  @override
  String get pix_hub_receive_deposit_note =>
      'O depósito usa o serviço real da Mooze e converte reais no ativo escolhido. Ele não é uma cobrança para outra pessoa.';

  @override
  String get pix_hub_my_keys => 'Minhas chaves Pix';

  @override
  String get pix_hub_keys_unavailable_title =>
      'Cadastro e exclusão indisponíveis';

  @override
  String get pix_hub_keys_unavailable_body =>
      'A Mooze ainda não possui serviço para cadastrar ou excluir chaves Pix. As chaves acima são fictícias e servem para demonstrar a tela.';

  @override
  String get pix_hub_key_copied => 'Chave copiada.';

  @override
  String pix_hub_key_share_message(String key) {
    return 'Minha chave Pix de demonstração: $key';
  }

  @override
  String get pix_hub_copy => 'Copiar';

  @override
  String get pix_hub_share => 'Compartilhar';

  @override
  String get pix_hub_value_unavailable => 'Não informado';

  @override
  String get pix_hub_charge_key_label => 'Chave que recebe';

  @override
  String get pix_hub_charge_open_amount => 'Quem paga escolhe o valor';

  @override
  String get pix_hub_charge_open_amount_hint =>
      'A cobrança fica sem valor definido.';

  @override
  String get pix_hub_charge_create => 'Gerar cobrança';

  @override
  String pix_hub_charge_error_min(String amount) {
    return 'O valor mínimo é $amount.';
  }

  @override
  String get pix_hub_charge_detail_title => 'Cobrança';

  @override
  String get pix_hub_charge_code_label => 'Código Copia e Cola';

  @override
  String pix_hub_charge_share_message(String code) {
    return 'Cobrança Pix de demonstração: $code';
  }

  @override
  String get pix_hub_charge_disclaimer =>
      'O QR Code e o código são de demonstração. Nenhuma cobrança foi registrada em uma instituição Pix.';

  @override
  String get pix_hub_charge_create_another => 'Criar outra cobrança';

  @override
  String get pix_hub_link_create => 'Criar link';

  @override
  String get pix_hub_link_reference_label => 'Identificação';

  @override
  String get pix_hub_link_reference_hint => 'Mensalidade de março';

  @override
  String get pix_hub_link_reference_error => 'Informe uma identificação.';

  @override
  String pix_hub_link_amount_error(String min, String max) {
    return 'O valor deve ficar entre $min e $max.';
  }

  @override
  String get pix_hub_link_single_use => 'Uso único';

  @override
  String get pix_hub_link_single_use_hint =>
      'O link aceita um pagamento e encerra.';

  @override
  String get pix_hub_link_reusable => 'Reutilizável';

  @override
  String get pix_hub_link_usage_label => 'Uso';

  @override
  String get pix_hub_link_review => 'Revisar link';

  @override
  String get pix_hub_link_confirm => 'Gerar link';

  @override
  String get pix_hub_link_detail_title => 'Link de pagamento';

  @override
  String get pix_hub_link_url_label => 'Endereço do link';

  @override
  String get pix_hub_link_copied => 'Link copiado.';

  @override
  String pix_hub_link_share_message(String url) {
    return 'Link de pagamento de demonstração: $url';
  }

  @override
  String get pix_hub_link_paid_at => 'Pago em';

  @override
  String get pix_hub_link_open_amount => 'Valor livre';

  @override
  String get pix_hub_link_status_pending => 'Pendente';

  @override
  String get pix_hub_link_status_paid => 'Pago';

  @override
  String get pix_hub_link_status_expired => 'Expirado';

  @override
  String get pix_hub_link_disclaimer =>
      'O endereço é fictício e não abre uma página de pagamento real.';

  @override
  String get pix_hub_history_filter_all => 'Tudo';

  @override
  String get pix_hub_history_filter_sent => 'Enviados';

  @override
  String get pix_hub_history_filter_received => 'Recebidos';

  @override
  String get pix_hub_history_note =>
      'A lista mostra apenas movimentações Pix fictícias. As transações da carteira ficam no histórico da carteira.';

  @override
  String get pix_hub_tx_kind_sent => 'Pix enviado';

  @override
  String get pix_hub_tx_kind_received => 'Pix recebido';

  @override
  String get pix_hub_tx_kind_deposit => 'Depósito na carteira';

  @override
  String get pix_hub_tx_kind_payment_link => 'Link de pagamento';

  @override
  String get pix_hub_tx_status_completed => 'Concluído';

  @override
  String get pix_hub_tx_status_pending => 'Em processamento';

  @override
  String get pix_hub_tx_status_failed => 'Falhou';

  @override
  String get pix_hub_tx_detail_title => 'Detalhes da movimentação';

  @override
  String get pix_hub_tx_detail_disclaimer =>
      'Este registro é fictício. Ele não é um comprovante de pagamento.';

  @override
  String get pix_hub_failure_load => 'Não foi possível carregar os dados.';

  @override
  String get pix_hub_failure_declined =>
      'A simulação recusou o pagamento. O saldo de demonstração é de R\$ 2.500,00.';

  @override
  String get pix_hub_failure_recipient =>
      'Nenhum recebedor corresponde a esses dados.';

  @override
  String get pix_hub_failure_amount => 'O valor está fora do limite aceito.';

  @override
  String get pix_hub_failure_unknown => 'Algo deu errado. Tente novamente.';

  @override
  String get pix_hub_failure_network =>
      'Sem conexão com o servidor. Verifique a internet e tente novamente.';

  @override
  String get pix_hub_failure_session =>
      'Não foi possível validar sua sessão. Tente novamente.';

  @override
  String get pix_hub_failure_not_eligible =>
      'Sua conta ainda não pode criar links de pagamento. Suba de nível para liberar o recurso.';

  @override
  String get pix_hub_failure_rate_limited =>
      'Muitas tentativas seguidas. Aguarde um pouco e tente novamente.';

  @override
  String get pix_hub_failure_unavailable =>
      'O serviço está indisponível agora. Tente novamente mais tarde.';

  @override
  String get pix_hub_failure_invalid_response =>
      'O servidor respondeu sem o link de pagamento. Tente novamente.';

  @override
  String get pix_hub_failure_wallet =>
      'Não foi possível obter um endereço da sua carteira. Tente novamente.';

  @override
  String get pix_hub_subtitle =>
      'Envie, receba e gerencie seus pagamentos pelo Pix.';

  @override
  String get pix_hub_other_operations => 'Outras operações';

  @override
  String get pix_hub_action_pending => 'Cobranças pendentes';

  @override
  String get pix_hub_action_pending_subtitle =>
      'Veja e remova cobranças em aberto.';

  @override
  String get pix_hub_action_other_transactions => 'Outras transações';

  @override
  String get pix_hub_action_other_transactions_subtitle =>
      'Históricos, links e taxas do Pix.';

  @override
  String get pix_hub_info_title => 'Como o Pix funciona';

  @override
  String get pix_hub_info_send_title => 'Envio e recebimento';

  @override
  String get pix_hub_info_send_body =>
      'O envio de Pix usa seu saldo de DePix. O provedor Pix paga o destinatário, e a taxa da rede Liquid é paga em L-BTC. Cobranças, chaves e links ainda usam dados fictícios.';

  @override
  String get pix_hub_info_deposit_title => 'Depósito na carteira';

  @override
  String get pix_hub_info_deposit_body =>
      'O depósito usa o serviço real da Mooze. O valor em reais vira o ativo que você escolher na carteira.';

  @override
  String get pix_hub_send_method_question => 'Como você quer enviar?';

  @override
  String get pix_hub_send_method_qr_description =>
      'Escaneie o código do recebedor.';

  @override
  String get pix_hub_send_method_code_description => 'Cole o código Pix.';

  @override
  String get pix_hub_send_method_recent_description =>
      'Pessoas para quem você já enviou.';

  @override
  String get pix_hub_key_type_label => 'Tipo de chave';

  @override
  String get pix_hub_key_hint_cpf => '000.000.000-00';

  @override
  String get pix_hub_key_hint_cnpj => '00.000.000/0000-00';

  @override
  String get pix_hub_key_hint_phone => 'ex: 11 98765-4321';

  @override
  String get pix_hub_key_hint_email => 'nome@email.com';

  @override
  String get pix_hub_key_hint_random => '00000000-0000-0000-0000-000000000000';

  @override
  String get pix_hub_summary_payment_method => 'Forma de pagamento';

  @override
  String get pix_hub_review_edit => 'Alterar dados';

  @override
  String pix_hub_review_key_chip(String type) {
    return 'Chave Pix ($type)';
  }

  @override
  String pix_hub_result_to(String name) {
    return 'Para $name';
  }

  @override
  String get pix_hub_result_datetime => 'Data e hora';

  @override
  String get pix_hub_result_details => 'Ver detalhes';

  @override
  String get pix_hub_deposit_gate_title => 'Antes de depositar';

  @override
  String get pix_hub_deposit_gate_subtitle =>
      'Informe o CPF da conta bancária que vai pagar e confirme o aviso abaixo.';

  @override
  String get pix_hub_deposit_cpf_hint =>
      'A Mooze confere o formato e os dígitos verificadores. O aplicativo não confirma quem é o titular da conta bancária.';

  @override
  String get pix_hub_deposit_notice_title => 'Importante';

  @override
  String get pix_hub_deposit_notice_body =>
      'Para fazer depósitos via Pix, você precisa usar uma conta bancária em seu próprio nome, registrada sob o mesmo CPF cadastrado na Mooze. Não use contas bancárias de terceiros.';

  @override
  String get pix_hub_deposit_notice_ack => 'Li e entendi o aviso.';

  @override
  String get pix_hub_deposit_notice_screen_title => 'Aviso sobre depósitos';

  @override
  String get pix_hub_deposit_cpf_stored_label => 'CPF informado';

  @override
  String get pix_hub_deposit_cpf_missing => 'Nenhum CPF informado.';

  @override
  String get pix_hub_deposit_change_cpf => 'Alterar CPF';

  @override
  String get pix_hub_pending_deposits => 'Depósitos em andamento';

  @override
  String get pix_hub_pending_deposits_empty_title =>
      'Nenhum depósito em andamento';

  @override
  String get pix_hub_pending_deposits_empty_body =>
      'Os depósitos que aguardam pagamento aparecem aqui.';

  @override
  String get pix_hub_pending_deposits_note =>
      'A Mooze não cancela um depósito em andamento. A cobrança deixa de valer quando expira.';

  @override
  String get pix_hub_pending_links_section => 'Links de pagamento';

  @override
  String get pix_hub_pending_remove_title => 'Remover link?';

  @override
  String pix_hub_pending_remove_body(String reference) {
    return 'O link \"$reference\" sai da lista de demonstração.';
  }

  @override
  String get pix_hub_pending_remove_confirm => 'Remover';

  @override
  String get pix_hub_pending_removed => 'Link removido.';

  @override
  String get pix_hub_other_section_history => 'Históricos';

  @override
  String get pix_hub_other_deposit_history => 'Histórico de depósitos';

  @override
  String get pix_hub_other_deposit_history_subtitle =>
      'Seus depósitos reais pelo Pix.';

  @override
  String get pix_hub_other_section_tools => 'Ferramentas';

  @override
  String get pix_hub_other_recipients_subtitle =>
      'Pessoas para quem você já enviou.';

  @override
  String get pix_hub_other_fees_subtitle => 'Veja as taxas aplicadas.';

  @override
  String get pix_hub_preferences => 'Preferências';

  @override
  String get pix_hub_preferences_limits => 'Meus limites';

  @override
  String get pix_hub_preferences_limits_subtitle =>
      'Veja os limites do Pix na sua conta.';

  @override
  String get pix_hub_preferences_level => 'Meu nível';

  @override
  String get pix_hub_preferences_level_subtitle =>
      'Veja o nível atual e como subir de nível.';

  @override
  String get pix_hub_limits_subtitle =>
      'Os valores abaixo vêm da sua conta Mooze.';

  @override
  String get pix_hub_limits_how_it_works => 'Como os limites funcionam';

  @override
  String get pix_hub_shortcut_receive_description =>
      'Compartilhe sua chave ou gere um QR Code';

  @override
  String get pix_hub_failure_invalid_request =>
      'O servidor recusou os dados. Confira a chave, o CPF/CNPJ e o valor.';

  @override
  String get pix_hub_failure_limit_exceeded =>
      'O valor passa do seu limite atual, ou sua conta ainda não pode enviar Pix.';

  @override
  String get pix_hub_failure_provider_refused =>
      'O provedor Pix recusou o envio. Confira se a chave pertence ao CPF/CNPJ informado.';

  @override
  String get pix_hub_failure_outcome_unknown =>
      'O serviço não confirmou o pedido. Nenhum valor saiu da sua carteira. Tente de novo em alguns minutos.';

  @override
  String get pix_hub_failure_quote_mismatch =>
      'A cotação recebida não confere com o pedido. Nenhum valor foi enviado. Tente de novo.';

  @override
  String get pix_hub_failure_quote_expired =>
      'O prazo da cotação acabou. Peça uma nova cotação para continuar.';

  @override
  String get pix_hub_failure_insufficient_funds =>
      'Seu saldo de DePix não cobre este envio e a taxa.';

  @override
  String get pix_hub_failure_insufficient_fee_asset =>
      'Você precisa de L-BTC para pagar a taxa da rede Liquid.';

  @override
  String get pix_hub_failure_funding_failed =>
      'A carteira não conseguiu montar a transferência de DePix. Nenhum valor saiu da sua carteira.';

  @override
  String get pix_hub_failure_unsupported_code =>
      'Este código não tem chave Pix. O Mooze paga apenas códigos com chave.';

  @override
  String get pix_hub_tax_id_label => 'CPF ou CNPJ do dono da chave';

  @override
  String get pix_hub_tax_id_hint => '000.000.000-00';

  @override
  String get pix_hub_tax_id_help =>
      'O provedor Pix confere se a chave pertence a este documento. O Mooze não guarda o número.';

  @override
  String get pix_hub_tax_id_error_empty => 'Informe o CPF ou CNPJ.';

  @override
  String get pix_hub_tax_id_error_invalid => 'CPF ou CNPJ inválido.';

  @override
  String pix_hub_amount_error_min(String amount) {
    return 'O valor mínimo é $amount.';
  }

  @override
  String get pix_hub_amount_error_balance =>
      'Seu saldo de DePix não cobre este valor.';

  @override
  String pix_hub_amount_balance(String amount) {
    return 'Saldo disponível: $amount';
  }

  @override
  String get pix_hub_amount_fee_hint =>
      'A taxa do provedor Pix aparece na revisão e é somada ao valor em DePix.';

  @override
  String get pix_hub_summary_code_name => 'Nome no código';

  @override
  String get pix_hub_code_no_key => 'Sem chave Pix (código dinâmico)';

  @override
  String get pix_hub_review_receives => 'O destinatário recebe';

  @override
  String get pix_hub_review_provider_fee => 'Taxa do provedor Pix';

  @override
  String get pix_hub_review_depix_debit => 'Sai da sua carteira';

  @override
  String get pix_hub_review_network_fee => 'Taxa da rede Liquid';

  @override
  String pix_hub_review_network_fee_value(String amount) {
    return '$amount sats (L-BTC)';
  }

  @override
  String get pix_hub_review_owner_document => 'Documento do dono da chave';

  @override
  String pix_hub_review_deadline(String time) {
    return 'Pague até $time';
  }

  @override
  String pix_hub_review_time_left(String time) {
    return 'Faltam $time';
  }

  @override
  String get pix_hub_review_expired => 'O prazo desta cotação acabou.';

  @override
  String get pix_hub_review_new_quote => 'Pedir nova cotação';

  @override
  String get pix_hub_result_processing_title => 'Pix em processamento';

  @override
  String get pix_hub_result_processing_body =>
      'Seu DePix foi enviado. O provedor Pix está processando a transferência. Isso pode levar alguns minutos.';

  @override
  String get pix_hub_result_completed_title => 'Pix entregue';

  @override
  String get pix_hub_result_completed_body =>
      'O provedor Pix confirmou o pagamento ao destinatário.';

  @override
  String get pix_hub_result_failed_title => 'Pix não concluído';

  @override
  String get pix_hub_result_refunded_body =>
      'O provedor devolveu o depósito ao seu endereço de reembolso.';

  @override
  String get pix_hub_result_failed_body =>
      'O provedor encerrou o pedido sem pagar o Pix. Se o DePix não voltar à sua carteira, fale com o suporte e informe o ID do pedido.';

  @override
  String get pix_hub_result_unknown_title => 'Resultado não confirmado';

  @override
  String get pix_hub_result_unknown_body =>
      'Não conseguimos confirmar se a transferência de DePix chegou à rede. Não pague de novo. Acompanhe o status abaixo.';

  @override
  String get pix_hub_result_polling_stopped =>
      'O status ainda não mudou. Atualize mais tarde.';

  @override
  String get pix_hub_result_status_error =>
      'Não foi possível atualizar o status.';

  @override
  String get pix_hub_result_refresh => 'Atualizar status';

  @override
  String get pix_hub_result_receipt => 'Abrir comprovante';

  @override
  String get pix_hub_result_copy_id => 'Copiar ID do pedido';

  @override
  String get pix_hub_result_id_copied => 'ID copiado.';

  @override
  String get pix_hub_summary_withdrawal_id => 'ID do pedido';

  @override
  String get pix_hub_summary_funding_txid => 'Transação Liquid';

  @override
  String get pix_hub_summary_end_to_end => 'ID fim a fim';

  @override
  String get pix_hub_summary_refund => 'Valor devolvido';

  @override
  String get pix_hub_withdrawal_status_checking => 'Consultando…';

  @override
  String get pix_hub_withdrawal_status_creating => 'Criando';

  @override
  String get pix_hub_withdrawal_status_rejected => 'Recusado';

  @override
  String get pix_hub_withdrawal_status_uncertain => 'Em verificação';

  @override
  String get pix_hub_withdrawal_status_unsent => 'Aguardando o depósito';

  @override
  String get pix_hub_withdrawal_status_sending => 'Enviando o Pix';

  @override
  String get pix_hub_withdrawal_status_sent => 'Pix entregue';

  @override
  String get pix_hub_withdrawal_status_error => 'Erro no provedor';

  @override
  String get pix_hub_withdrawal_status_canceled => 'Cancelado';

  @override
  String get pix_hub_withdrawal_status_refunded => 'Devolvido';

  @override
  String get pix_hub_withdrawal_status_replaced => 'Substituído';

  @override
  String get pix_hub_withdrawal_status_unknown => 'Desconhecido';

  @override
  String get pix_hub_pending_withdrawals_title => 'Pix em andamento';

  @override
  String pix_hub_pending_withdrawal_item(String amount, String key) {
    return '$amount para $key';
  }

  @override
  String get pix_hub_pending_withdrawal_hint => 'Toque para ver o status.';

  @override
  String get pix_hub_send_key_title => 'Para quem você quer transferir?';

  @override
  String get pix_hub_send_key_label => 'Insira o dado de quem vai receber';

  @override
  String get pix_hub_send_key_hint => 'CPF/CNPJ, celular, e-mail ou chave Pix';

  @override
  String get pix_hub_send_key_scan => 'Ler QR Code';

  @override
  String get pix_hub_send_key_clear => 'Limpar';

  @override
  String get pix_hub_send_key_code_detected =>
      'Código Pix Copia e Cola reconhecido.';

  @override
  String get pix_hub_send_key_ambiguous =>
      'Este número é um CPF ou um celular?';

  @override
  String get pix_hub_amount_question => 'Quanto você quer transferir?';

  @override
  String get pix_hub_tax_id_valid => 'Documento válido';
}
