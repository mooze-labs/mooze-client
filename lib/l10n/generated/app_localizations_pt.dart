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
      'Formato: esquema://host:porta. Use ssl:// para conexões criptografadas.';

  @override
  String get node_config_liquid_label => 'Endpoint Liquid Network';

  @override
  String get node_config_liquid_hint => 'seu-node.tld:50002';

  @override
  String get node_config_liquid_helper =>
      'Formato: host:porta. O LWK usa TLS automaticamente.';

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
  String get terms_last_updated => 'Última atualização: 23/03/2026';

  @override
  String get terms_privacy_policy_link => 'Ver Política de Privacidade';

  @override
  String get terms_section_1 => '1. Aceitação dos Termos';

  @override
  String get terms_section_2 => '2. Natureza Jurídica e Enquadramento da Mooze';

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
  String get terms_section_8 => '8. Apreço Monetário e Referência de Preços';

  @override
  String get terms_section_9 => '9. Limitação de Responsabilidade';

  @override
  String get terms_section_10 => '10. Política Antifraude e Segurança';

  @override
  String get terms_section_11 =>
      '11. Monitoramento, Prevenção a Fraudes e Suspensão de Serviços';

  @override
  String get terms_section_12 => '12. Obrigações Legais do Usuário';

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
  String get privacy_section_9 => '9. Direitos do Usuário (LGPD)';

  @override
  String get privacy_section_10 => '10. Jurisdição de Dados';

  @override
  String get privacy_section_11 => '11. Alterações';

  @override
  String get privacy_section_12 => '12. Contato';

  @override
  String get terms_section_1_body =>
      '1.1. Ao acessar, instalar ou utilizar o aplicativo Mooze, o Usuário declara ter lido, compreendido e aceito integralmente os presentes Termos de Uso.\n\n1.2. A utilização do Aplicativo constitui aceitação tácita e irrevogável de todas as disposições contidas neste documento.\n\n1.3. Caso o Usuário não concorde com qualquer disposição destes Termos, deverá cessar imediatamente a utilização do Aplicativo e desinstalá-lo de seus dispositivos.\n\n1.4. Estes Termos constituem um contrato vinculante entre o Usuário e a Mooze Labs LLC, regido pelas leis da República das Ilhas Marshall.';

  @override
  String get terms_section_2_body =>
      '2.1. A Mooze Labs LLC é uma sociedade de responsabilidade limitada constituída sob a Associations Law da República das Ilhas Marshall.\n\n2.2. A Mooze atua exclusivamente como provedora de serviços de software para gerenciamento de carteiras digitais autocustodiais na rede Bitcoin e na Liquid Network.\n\n2.3. A Mooze NÃO é corretora, exchange, instituição financeira, prestadora de serviços de câmbio, transmissora de dinheiro, VASP, custodiante de ativos ou consultora de investimentos.\n\n2.4. A Mooze não exerce custódia, posse, controle discricionário ou domínio sobre quaisquer ativos digitais do Usuário. O processamento transitório pela infraestrutura da Mooze é análogo ao roteamento de pacotes de dados por um roteador de rede.\n\n2.5. A Mooze não realiza operações de câmbio ou intermediação financeira. Toda operação envolvendo reais brasileiros é processada por parceiras reguladas pelo Banco Central do Brasil.\n\n2.6. A Mooze opera exclusivamente como provedora de software não-custodial, sem acesso, controle ou custódia sobre ativos digitais dos Usuários.\n\n2.7. A Mooze é membro oficial da Liquid Federation (Blockstream), com PAK Entry ativo.';

  @override
  String get terms_section_3_body =>
      '3.1. Aplicativo ou Mooze Wallet: software de carteira digital autocustodial, disponível para iOS e Android.\n\n3.2. Usuário: toda pessoa natural que instala, acessa ou utiliza o Aplicativo.\n\n3.3. Autocustódia: modelo no qual o Usuário detém controle exclusivo sobre suas chaves privadas e frases-semente.\n\n3.4. Frase-Semente: sequência de 12 ou 24 palavras (padrão BIP39), único mecanismo de recuperação da carteira.\n\n3.5. Liquid Network: sidechain federada do Bitcoin, desenvolvida pela Blockstream.\n\n3.6. DEPIX: token digital na Liquid Network com valor pareado ao real brasileiro (R\$ 1,00 = 1 DEPIX).\n\n3.7. L-BTC: representação de Bitcoin na Liquid Network.\n\n3.8. Atomic Swap: troca direta entre ativos digitais sem intermediário custodiante.\n\n3.9. SideSwap: protocolo público para atomic swaps na Liquid Network.\n\n3.10. Confidential Transactions: tecnologia da Liquid Network que oculta valores e tipos de ativos em transações.\n\n3.11. APP ID: identificador único gerado pelo dispositivo, usado exclusivamente para prevenção a fraudes.\n\n3.12. Parceiras Reguladas: PLEBIT.COM.BR (CNPJ 43.375.652/0001-13), Fits Instituição de Pagamento (CNPJ 13.203.354/0001-85), Celcoin (CNPJ 13.935.893/0001-09), PLEBZ (CNPJ 45.808.899/0001-01).\n\n3.13. Eulen.app LLC: responsável pela emissão do token DEPIX.\n\n3.14. PIX: sistema de pagamentos instantâneos do Banco Central do Brasil.\n\n3.15. Serviços: funcionalidades de software disponibilizadas pela Mooze.';

  @override
  String get terms_section_4_body =>
      '4.1. SERVIÇO A — Orquestração de Software para Aquisição de Tokens Digitais\nA Mooze disponibiliza interface de software que orquestra automaticamente a comunicação entre o dispositivo do Usuário, as Parceiras Reguladas e a infraestrutura da Eulen.app LLC. O pagamento PIX é processado pelas Parceiras Reguladas; a Eulen.app LLC emite os tokens DEPIX; o software da Mooze roteia os tokens ao endereço de autocustódia do Usuário. A Mooze atua exclusivamente como orquestradora automatizada, sem adquirir titularidade sobre os ativos.\n\n4.2. SERVIÇO B — Interface para Protocolo Descentralizado de Conversão Entre Unidades Digitais\nA Mooze disponibiliza interface para o Usuário interagir com o protocolo SideSwap para atomic swaps na Liquid Network. A Mooze não participa como contraparte ou custodiante. A função da Mooze é análoga à de um navegador que provê acesso a websites. A Mooze também disponibiliza acesso via SDK Breez para a Lightning Network.\n\n4.3. MODO COMERCIANTE\nFuncionalidade que permite receber pagamentos via PIX em carteiras autocustodiais. O código QR PIX é gerado pelo próprio Usuário via Aplicativo. A Mooze não tem conhecimento da relação comercial subjacente. O Usuário NÃO deve entregar produto ou serviço antes da confirmação final do pagamento. Dúvidas: suporte@mooze.app.';

  @override
  String get terms_section_5_body =>
      '5.1. O Aplicativo opera sob modelo de autocustódia integral. As chaves privadas e frases-semente são geradas e armazenadas exclusivamente no dispositivo do Usuário, sendo inacessíveis à Mooze.\n\n5.2. A Mooze não tem, em nenhum momento, acesso, conhecimento, posse, controle ou cópia das chaves privadas, frases-semente ou senhas do Usuário.\n\n5.3. O Usuário é o único responsável pela guarda e segurança de suas chaves privadas e frases-semente. A perda desses elementos resulta na perda permanente e irreversível do acesso aos ativos digitais.\n\n5.4. A Mooze não possui capacidade técnica para recuperar, restaurar, acessar ou transferir ativos digitais do Usuário em caso de perda das chaves privadas ou frases-semente.\n\n5.5. Os endereços de carteira do Usuário são utilizados pela Mooze exclusivamente como parâmetro de roteamento automatizado durante a execução dos Serviços.';

  @override
  String get terms_section_6_body =>
      '6.1. GUARDA DE SENHAS E FRASES-SEMENTE\nO Usuário é integral e exclusivamente responsável pela criação, armazenamento e proteção de suas senhas, chaves privadas e frases-semente. A Mooze nunca solicitará ao Usuário suas chaves privadas, frases-semente ou senhas por qualquer meio de comunicação.\n\n6.2. CONSEQUÊNCIAS DA PERDA DE ACESSO\nA perda da frase-semente implica a perda permanente e irreversível do acesso a todos os ativos digitais. A Mooze não pode restaurar ou recuperar o acesso à carteira do Usuário em caso de perda.\n\n6.3. SEGURANÇA DO DISPOSITIVO\nO Usuário é responsável pela segurança do dispositivo, incluindo sistema operacional atualizado, autenticação biométrica e proteção contra malware. A Mooze não se responsabiliza por perdas decorrentes de comprometimento do dispositivo.';

  @override
  String get terms_section_7_body =>
      '7.1. A Mooze cobra Taxa de Serviço de Software pela utilização dos Serviços, calculada como percentual do valor da operação e deduzida dos ativos digitais entregues ao Usuário.\n\n7.2. O percentual vigente é exibido na tela de confirmação da operação, antes de sua efetivação.\n\n7.3. A Mooze reserva-se o direito de alterar os percentuais a qualquer momento. A continuidade de uso após alteração constitui aceitação.\n\n7.4. As Parceiras Reguladas, SideSwap, Breez Technologies e infratechs parceiras podem aplicar suas próprias tarifas, independentes da Taxa da Mooze.\n\n7.5. Custos de mineração (fees de rede) são de responsabilidade do Usuário e independentes da Taxa de Serviço. Os valores totais são exibidos na tela de confirmação antes da efetivação.';

  @override
  String get terms_section_8_body =>
      '8.1. Os valores de referência exibidos no Aplicativo para ativos digitais são obtidos de fontes públicas de mercado e servem exclusivamente como referência informativa.\n\n8.2. A Mooze não garante a exatidão ou atualização em tempo real dos preços exibidos. Variação de preço entre exibição e efetivação é inerente aos mercados de ativos digitais.\n\n8.3. A exibição de preços não constitui oferta, recomendação de investimento ou garantia de valor.\n\n8.4. O Usuário reconhece que ativos digitais estão sujeitos a alta volatilidade e que pode sofrer perdas significativas de valor.';

  @override
  String get terms_section_9_body =>
      '9.1. A Mooze fornece o Aplicativo e os Serviços no estado em que se encontram (as is), sem garantias de qualquer natureza.\n\n9.2. A Mooze não será responsável por: perdas de ativos por perda de chaves privadas; comprometimento do dispositivo; indisponibilidade de redes blockchain; falhas de Parceiras Reguladas, Eulen.app LLC ou SideSwap; atos de fraude por terceiros; erros na inserção de endereços de carteira; alterações regulatórias; variação de preços de ativos; decisões de investimento do Usuário; danos indiretos ou consequenciais.\n\n9.3. A responsabilidade total da Mooze está limitada ao valor das Taxas efetivamente pagas pelo Usuário nos últimos 12 meses.\n\n9.4. O Aplicativo encontra-se em modo BETA. O Usuário aceita todos os riscos associados.\n\n9.5. As frases-semente são compatíveis com BIP39 e com a Liquid Network. Em caso de indisponibilidade crítica, o Usuário pode recuperar ativos em qualquer carteira compatível (ex: Blockstream App).';

  @override
  String get terms_section_10_body =>
      '10.1. A Mooze implementa mecanismos de segurança incluindo:\n- Vinculação de APP ID a operações\n- Sistema de scoring por níveis de risco\n- Limites progressivos por APP ID\n- Detecção de padrões anômalos (smurfing, bursting, autopagamentos)\n\n10.2. As medidas antifraude da Mooze são de natureza exclusivamente tecnológica e não substituem as obrigações de AML e KYC das Parceiras Reguladas.\n\n10.3. As Parceiras Reguladas são as únicas responsáveis pelo cumprimento de obrigações de AML e KYC perante o Banco Central do Brasil.';

  @override
  String get terms_section_11_body =>
      '11.1. A Mooze reserva-se o direito de suspender, limitar ou encerrar o acesso de um APP ID aos Serviços sem aviso prévio em caso de: padrões indicativos de fraude; dispositivos comprometidos ou emuladores; tentativas de contornar mecanismos de segurança; padrões de lavagem de dinheiro ou financiamento ao terrorismo; solicitação de autoridade competente.\n\n11.2. A suspensão atinge apenas novas operações. Os ativos em autocustódia permanecem integralmente sob controle do Usuário, acessíveis pela frase-semente.\n\n11.3. A Mooze cooperará com autoridades competentes mediante determinação judicial, observadas as limitações técnicas do modelo autocustodial.';

  @override
  String get terms_section_12_body =>
      '12.1. O Usuário declara e garante que:\n- Utiliza os Serviços em conformidade com a legislação de sua jurisdição\n- Os recursos utilizados para pagamento via PIX são de origem lícita\n- Não utiliza os Serviços para lavagem de dinheiro, financiamento ao terrorismo ou evasão fiscal\n- É responsável exclusivo pela declaração e pagamento de tributos sobre ativos digitais\n- Tem conhecimento de que a Mooze não se enquadra como VASP nos termos da Lei n. 14.478/2022\n\n12.2. A Mooze não presta serviços de consultoria tributária, fiscal ou jurídica.\n\n12.3. A Mooze não realiza declarações fiscais em nome do Usuário.';

  @override
  String get terms_section_13_body =>
      '13.1. Estes Termos são regidos pelas leis da República das Ilhas Marshall.\n\n13.2. A Mooze Labs LLC é uma entidade constituída na República das Ilhas Marshall e opera a partir dessa jurisdição, sem presença física ou jurídica no Brasil.\n\n13.3. A relação entre a Mooze e as Parceiras Reguladas é regida por contratos internacionais independentes, sem criar responsabilidade solidária entre as partes.';

  @override
  String get terms_section_14_body =>
      '14.1. Qualquer disputa será resolvida, a exclusivo critério da Mooze, pelos tribunais da República das Ilhas Marshall ou por arbitragem internacional sob as Regras da UNCITRAL.\n\n14.2. O Usuário renuncia a qualquer foro que não os indicados, exceto quando vedado por lei imperativa de sua jurisdição.\n\n14.3. Antes de formalizar qualquer disputa, o Usuário deverá notificar a Mooze por escrito. As partes envidarão esforços de boa-fé para resolução amigável em 30 dias.';

  @override
  String get terms_section_15_body =>
      '15.1. Todo o software, código-fonte, design, marcas, logotipos e conteúdo do Aplicativo são de propriedade exclusiva da Mooze Labs LLC ou de seus licenciadores.\n\n15.2. A utilização do Aplicativo não confere ao Usuário qualquer direito de propriedade intelectual.\n\n15.3. É vedada a reprodução, modificação ou engenharia reversa do Aplicativo sem autorização expressa da Mooze.\n\n15.4. O código-fonte está disponível em https://github.com/mooze-labs/mooze-client sob os termos da licença ali indicada.';

  @override
  String get terms_section_16_body =>
      '16.1. INTEGRALIDADE\nEstes Termos e a Política de Privacidade constituem o acordo integral entre as partes, substituindo quaisquer acordos anteriores.\n\n16.2. SEVERABILIDADE\nSe qualquer disposição for declarada inválida, as demais permanecerão em pleno vigor.\n\n16.3. RENÚNCIA\nA omissão da Mooze em exigir o cumprimento de qualquer disposição não constitui renúncia ao direito de exigi-lo posteriormente.\n\n16.4. CESSÃO\nO Usuário não pode ceder seus direitos sem autorização prévia e por escrito da Mooze.\n\n16.5. FORÇA MAIOR\nA Mooze não será responsável por atrasos decorrentes de falhas em redes blockchain, indisponibilidade de Parceiras, ataques cibernéticos, decisões governamentais ou desastres naturais.\n\n16.6. INDENIZAÇÃO\nO Usuário concorda em indenizar a Mooze por reclamações decorrentes de uso indevido dos Serviços, violação de leis ou prestação de informações falsas.\n\n16.7. DISTRIBUIÇÃO\nA distribuição em plataformas digitais é realizada pela Mooze LLC (Delaware), como distribuidora autorizada, sem assumir responsabilidades de desenvolvimento ou operação.';

  @override
  String get terms_section_17_body =>
      '17.1. O Aplicativo e os Serviços são destinados exclusivamente a pessoas com idade igual ou superior a 18 anos.\n\n17.2. Ao utilizar o Aplicativo, o Usuário declara ter ao menos 18 anos e possuir capacidade civil plena.\n\n17.3. A Mooze reserva-se o direito de suspender o acesso de qualquer Usuário que se verifique ser menor de 18 anos.';

  @override
  String get terms_section_18_body =>
      '18.1. A Mooze reserva-se o direito de alterar estes Termos a qualquer momento, publicando a versão atualizada no Aplicativo e em https://mooze.app/termosdeuso/.\n\n18.2. Alterações relevantes serão comunicadas via Aplicativo, Telegram ou e-mail.\n\n18.3. A continuidade de uso após publicação de alterações constitui aceitação tácita dos Termos atualizados.\n\n18.4. O Usuário que não concordar com as alterações deverá cessar o uso. Os ativos em autocustódia permanecem acessíveis pela frase-semente.';

  @override
  String get terms_section_19_body =>
      '19.1. Para dúvidas, solicitações ou comunicações relacionadas a estes Termos:\n\n(a) E-mail: suporte@mooze.app\n(b) Telegram: https://t.me/+zkNS6KIDsEcyZDkx\n(c) FAQ automatizado via Telegram\n\n19.2. A Mooze envidará esforços para responder no prazo de 10 dias úteis.';

  @override
  String get privacy_section_header_body =>
      'Data da última atualização: 23/03/2026\n\nMooze Labs LLC, República das Ilhas Marshall';

  @override
  String get privacy_section_1_body =>
      '1.1. A Mooze Labs LLC está comprometida com a proteção da privacidade e a minimização de dados pessoais no uso do Aplicativo.\n\n1.2. Esta Política descreve quais informações são coletadas, como são utilizadas, com quem são compartilhadas e quais direitos o Usuário possui.\n\n1.3. A Mooze adota o princípio de minimização de dados como pilar central de sua operação. O Aplicativo foi projetado para funcionar sem coleta de dados pessoais identificáveis.';

  @override
  String get privacy_section_2_body =>
      'Todos os termos definidos nos Termos de Uso possuem os mesmos significados nesta Política. Aplicam-se adicionalmente:\n\n(a) Dados Pessoais: qualquer informação relacionada a pessoa natural identificada ou identificável (LGPD).\n(b) Tratamento: toda operação realizada com Dados Pessoais.\n(c) LGPD: Lei Geral de Proteção de Dados do Brasil (Lei n. 13.709/2018).';

  @override
  String get privacy_section_3_body =>
      'A MOOZE NÃO ARMAZENA:\nCPF, RG, endereços MAC, número de telefone, endereço residencial, data de nascimento, biometria pessoal, chaves privadas ou frases-semente.\n\nA MOOZE COLETA EXCLUSIVAMENTE:\n(a) APP ID: hash criptográfico do dispositivo, utilizado apenas para prevenção a fraudes.\n(b) Endereços de carteira na Liquid Network: utilizados como parâmetro de roteamento automatizado.\n(c) Blinding keys: retidas para verificação e reconciliação de transações.\n(d) Dados de transação: valores, tipos de ativos, timestamps e status de execução.\n(e) Dados técnicos do dispositivo: versão do SO, modelo e versão do Aplicativo — não permitem identificação pessoal.';

  @override
  String get privacy_section_4_body =>
      '4.1. Quando o Usuário realiza operações via PIX (Serviço A), os dados necessários para o processamento — incluindo KYC e AML — são coletados e processados exclusivamente pelas Parceiras Reguladas.\n\n4.2. Parceiras Reguladas: PLEBIT.COM.BR (CNPJ 43.375.652/0001-13), Fits Instituição de Pagamento (CNPJ 13.203.354/0001-85), Celcoin (CNPJ 13.935.893/0001-09), PLEBZ (CNPJ 45.808.899/0001-01).\n\n4.3. A Mooze não recebe, armazena ou tem acesso aos dados pessoais coletados pelas Parceiras Reguladas.';

  @override
  String get privacy_section_5_body =>
      '5.1. A Mooze compartilha dados exclusivamente:\n(a) Com Parceiras Reguladas e Eulen.app LLC: endereços de carteira, valores e APP ID quando necessário para antifraude.\n(b) Mediante determinação judicial válida.\n(c) Para cumprimento de obrigação legal na jurisdição das Ilhas Marshall.\n\n5.2. A Mooze NÃO vende, aluga ou compartilha dados com terceiros para fins de marketing ou publicidade.\n\n5.3. A Mooze NÃO utiliza rastreadores de terceiros, pixels de rastreamento ou SDKs de analytics que coletam dados pessoais.';

  @override
  String get privacy_section_6_body =>
      '6.1. Quando o Usuário contata a Mooze via e-mail (suporte@mooze.app) ou Telegram, os dados compartilhados voluntariamente serão utilizados exclusivamente para atendimento à solicitação.\n\n6.2. A Mooze não associa dados de comunicação a APP IDs ou endereços de carteira, exceto quando o próprio Usuário fornece tais informações voluntariamente.';

  @override
  String get privacy_section_7_body =>
      '7.1. A Mooze adota medidas técnicas e organizacionais razoáveis para proteger os dados contra acesso não autorizado, destruição ou divulgação indevida.\n\n7.2. Os dados coletados são armazenados em infraestrutura protegida com controles de acesso e criptografia.\n\n7.3. Nenhum método de transmissão ou armazenamento eletrônico é integralmente seguro.';

  @override
  String get privacy_section_8_body =>
      'Os dados coletados pela Mooze são retidos pelos seguintes períodos:\n\n(a) APP ID: 5 anos após a última operação.\n(b) Endereços de carteira e blinding keys: 5 anos para verificação e cumprimento de obrigações legais.\n(c) Dados de transação: 5 anos após a data da transação.\n(d) Dados técnicos de dispositivo: eliminados após 5 anos de inatividade.\n\nOs prazos podem ser estendidos para cumprimento de obrigação legal ou defesa em procedimento judicial.';

  @override
  String get privacy_section_9_body =>
      'Em observância à LGPD (Lei n. 13.709/2018), a Mooze reconhece os seguintes direitos ao Usuário:\n\n(a) Confirmação da existência de tratamento de dados\n(b) Acesso aos dados tratados\n(c) Correção de dados incompletos ou inexatos\n(d) Eliminação de dados tratados com consentimento\n(e) Informação sobre compartilhamento de dados\n(f) Revogação de consentimento\n(g) Solicitação de eliminação do APP ID associado ao dispositivo\n\nSolicitações via canais indicados na Seção 12 desta Política. Prazo de resposta: 15 dias úteis.';

  @override
  String get privacy_section_10_body =>
      '10.1. Os dados coletados pela Mooze são armazenados e processados em infraestrutura fora do território brasileiro.\n\n10.2. A jurisdição de dados aplicável é a República das Ilhas Marshall.\n\n10.3. Os dados operacionais transmitidos às Parceiras Reguladas durante o Serviço A são processados no Brasil, sob responsabilidade exclusiva das Parceiras Reguladas.';

  @override
  String get privacy_section_11_body =>
      '11.1. A Mooze reserva-se o direito de alterar esta Política a qualquer momento, publicando a versão atualizada no Aplicativo e em https://mooze.app/termosdeuso/.\n\n11.2. A continuidade de uso após a publicação constitui aceitação tácita da Política atualizada.';

  @override
  String get privacy_section_12_body =>
      '12.1. Para exercício de direitos, dúvidas ou solicitações:\n\n(a) E-mail: suporte@mooze.app\n(b) Telegram: https://t.me/+zkNS6KIDsEcyZDkx\n(c) FAQ automatizado via Telegram\n\n12.2. A Mooze envidará esforços para responder no prazo de 15 dias úteis.';

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
  String get receive_qr_lightning_invoice => 'Lightning Invoice';

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
  String get receive_network_bitcoin_onchain => 'Bitcoin On-chain';

  @override
  String get receive_network_lightning_network => 'Lightning Network';

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
  String get receive_lightning_amount_required_hint =>
      'Para Lightning, o valor é obrigatório';

  @override
  String get receive_select_asset_first => 'Selecione um ativo primeiro';

  @override
  String get receive_network_label_bitcoin => 'Bitcoin';

  @override
  String get receive_network_label_lightning => 'Lightning';

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
  String get receive_amount_helper_lightning =>
      'Valor obrigatório para Lightning';

  @override
  String get receive_amount_helper_optional =>
      'Valor opcional para Bitcoin/Liquid';

  @override
  String get receive_amount_sats_label => 'Valor em Satoshis:';

  @override
  String get receive_lightning_limits_unavailable =>
      'Não foi possível carregar limites Lightning';

  @override
  String receive_lightning_min_value(String amount) {
    return 'Valor mínimo: $amount sats';
  }

  @override
  String receive_lightning_max_value(String amount) {
    return 'Valor máximo: $amount sats';
  }

  @override
  String get receive_lightning_valid => 'Valor válido para Lightning';

  @override
  String get receive_lightning_limits_loading =>
      'Carregando limites Lightning...';

  @override
  String get receive_lightning_limits_error =>
      'Erro ao carregar limites Lightning';

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
  String get qr_scanner_supported_networks => 'Bitcoin • Lightning • Liquid';

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
  String get qr_validation_lightning_too_short =>
      'Lightning invoice muito curto';

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
  String get pix_deposit_status_processing_refund_1_2_label => 'Estornando 1/2';

  @override
  String get pix_deposit_status_processing_refund_2_2_label => 'Estornando 2/2';

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
  String get tx_detail_swap_label => 'Troca entre ativos';

  @override
  String get tx_detail_sent => 'Enviado';

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
  String get wallet_send_network_lightning => 'Lightning Network';

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
  String wallet_send_error_min_lightning(int amount) {
    return 'Valor mínimo para lightning é $amount sats';
  }

  @override
  String wallet_send_error_max_lightning(int amount) {
    return 'Valor máximo para lightning é $amount sats';
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
  String get wallet_assets_section_title => 'Ativos';

  @override
  String get wallet_transactions_section_title => 'Transações';

  @override
  String get wallet_section_see_more => 'Ver mais';

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
}
