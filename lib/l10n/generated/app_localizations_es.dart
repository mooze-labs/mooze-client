// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get common_back => 'Volver';

  @override
  String get common_cancel => 'Cancelar';

  @override
  String get common_confirm => 'Confirmar';

  @override
  String get common_save => 'Guardar';

  @override
  String get common_close => 'Cerrar';

  @override
  String get common_continue => 'Continuar';

  @override
  String get common_next => 'Siguiente';

  @override
  String get common_ok => 'OK';

  @override
  String get common_retry => 'Reintentar';

  @override
  String get common_loading => 'Cargando...';

  @override
  String get common_processing => 'Procesando...';

  @override
  String get common_sending => 'Enviando...';

  @override
  String get common_confirming => 'Confirmando...';

  @override
  String get common_verifying => 'Verificando...';

  @override
  String get common_understood => 'Entendido';

  @override
  String get common_no_thanks => 'No, gracias';

  @override
  String get common_max => 'MAX';

  @override
  String get common_yes => 'Sí';

  @override
  String get common_no => 'No';

  @override
  String get common_finish => 'Finalizar';

  @override
  String get common_redo => 'Rehacer';

  @override
  String get error_open_link => 'No se pudo abrir el enlace';

  @override
  String get error_opening_link => 'Error al abrir el enlace';

  @override
  String get error_open_browser => 'No se pudo abrir el navegador.';

  @override
  String error_unexpected(String error) {
    return 'Error inesperado: $error';
  }

  @override
  String error_generic(String error) {
    return 'Error: $error';
  }

  @override
  String get error_load_data =>
      'Error al cargar los datos. Inténtalo de nuevo.';

  @override
  String get error_load_data_short => 'Error al cargar los datos';

  @override
  String get error_load_data_title => 'Error al Cargar los Datos';

  @override
  String get error_no_internet => 'Sin conexión a internet. Verifica tu red.';

  @override
  String get error_server_unavailable =>
      'Servidor temporalmente no disponible. Inténtalo de nuevo.';

  @override
  String get error_server_communication =>
      'Error de comunicación con el servidor. Inténtalo de nuevo.';

  @override
  String get error_authentication_failed => 'No se pudo autenticar.';

  @override
  String get error_access_denied => 'Acceso denegado. Verifica tus permisos.';

  @override
  String get error_service_not_found =>
      'Servicio no encontrado. Inténtalo más tarde.';

  @override
  String get settings_title => 'Configuración';

  @override
  String get settings_section_security => 'SEGURIDAD';

  @override
  String get settings_section_appearance => 'APARIENCIA';

  @override
  String get settings_section_language => 'IDIOMA';

  @override
  String get settings_section_currency => 'MONEDA';

  @override
  String get settings_section_account => 'CUENTA Y BENEFICIOS';

  @override
  String get settings_section_legal => 'LEGAL';

  @override
  String get settings_section_developer => 'DESARROLLADOR';

  @override
  String get settings_section_help => 'AYUDA';

  @override
  String get settings_view_recovery_phrase => 'Ver frase de recuperación';

  @override
  String get settings_change_pin => 'Cambiar PIN';

  @override
  String get settings_biometric_auth => 'Autenticación biométrica';

  @override
  String get settings_delete_wallet => 'Eliminar billetera';

  @override
  String get settings_theme => 'Tema';

  @override
  String get settings_language => 'Idioma';

  @override
  String get settings_change_currency => 'Cambiar moneda';

  @override
  String get settings_referral_code => 'Código de referido';

  @override
  String get settings_terms => 'Términos de uso';

  @override
  String get settings_license => 'Licencia GPL';

  @override
  String get settings_logs => 'Registros';

  @override
  String get settings_log_details => 'Detalles del registro';

  @override
  String get settings_contact_support => 'Contactar soporte';

  @override
  String get settings_section_network => 'RED';

  @override
  String get settings_node_config => 'Configuración de nodos';

  @override
  String get node_config_title => 'Configuración de nodos';

  @override
  String get node_config_section_mode => 'MODO';

  @override
  String get node_config_section_custom => 'ENDPOINTS';

  @override
  String get node_config_section_advanced => 'AVANZADO';

  @override
  String get node_config_mode_default_title => 'Modo predeterminado';

  @override
  String get node_config_mode_default_subtitle =>
      'Usa los servidores recomendados por el sistema, con fallback automático entre Bitcoin, Liquid y Lightning.';

  @override
  String get node_config_mode_custom_title => 'Modo personalizado';

  @override
  String get node_config_mode_custom_subtitle =>
      'Avanzado — conéctate a tus propios servidores Electrum.';

  @override
  String get node_config_advanced_warning =>
      'Solo configura esto si sabes lo que haces. URLs inválidas pueden impedir que la app sincronice.';

  @override
  String get node_config_bitcoin_label => 'Endpoint Bitcoin Mainnet';

  @override
  String get node_config_bitcoin_hint => 'ssl://tu-nodo.tld:50002';

  @override
  String get node_config_bitcoin_helper =>
      'Formato: esquema://host:puerto. Usa ssl:// para conexiones cifradas.';

  @override
  String get node_config_liquid_label => 'Endpoint Liquid Network';

  @override
  String get node_config_liquid_hint => 'tu-nodo.tld:50002';

  @override
  String get node_config_liquid_helper =>
      'Formato: host:puerto. LWK negocia TLS automáticamente.';

  @override
  String get node_config_lightning_note =>
      'El nodo Lightning es gestionado automáticamente por el Breez SDK y no puede personalizarse.';

  @override
  String get node_config_fallback_toggle_title =>
      'Permitir fallback automático';

  @override
  String get node_config_fallback_toggle_subtitle =>
      'Si tu nodo falla, la app intentará automáticamente los servidores predeterminados.';

  @override
  String get node_config_save => 'Guardar configuración';

  @override
  String get node_config_url_required => 'Obligatorio en modo personalizado';

  @override
  String get node_config_url_invalid =>
      'Usa el formato host:puerto (o esquema://host:puerto)';

  @override
  String get node_config_unsaved_title => 'Cambios sin guardar';

  @override
  String get node_config_unsaved_message =>
      'Tienes cambios que aún no se han guardado. ¿Quieres guardarlos antes de salir?';

  @override
  String get node_config_unsaved_discard => 'Descartar';

  @override
  String get node_config_save_success => 'Configuración de nodos guardada';

  @override
  String node_config_save_error(String error) {
    return 'Error al guardar: $error';
  }

  @override
  String get node_config_load_error =>
      'No se pudo cargar la configuración de nodos';

  @override
  String get support_telegram_open_error => 'No se pudo abrir Telegram';

  @override
  String get support_screen_title => 'Centro de Soporte';

  @override
  String get support_help_title => '¿Cómo podemos ayudar?';

  @override
  String get support_help_subtitle =>
      'Para una atención más rápida, comparte el código de abajo con nuestro soporte.';

  @override
  String get support_user_code_label => 'Tu código de identificación';

  @override
  String get support_user_code_load_error_title =>
      'No se pudo cargar tu código';

  @override
  String get support_user_code_load_error_msg =>
      'Ocurrió un error al cargar tu información';

  @override
  String get support_user_code_not_found => 'No encontramos tu información';

  @override
  String get support_contact_button => 'Hablar con soporte';

  @override
  String get biometric_auth_reason =>
      'Confirma tu identidad para activar la autenticación biométrica';

  @override
  String get biometric_enabled_success => 'Autenticación biométrica activada.';

  @override
  String get biometric_disabled_info => 'Autenticación biométrica desactivada.';

  @override
  String get biometric_disable_error => 'Error al desactivar la biometría.';

  @override
  String get biometric_save_error => 'Error al guardar la configuración.';

  @override
  String biometric_auth_error(String error) {
    return 'Error de autenticación: $error';
  }

  @override
  String get biometric_setup_enable_q => '¿Activar biometría?';

  @override
  String get biometric_setup_explanation =>
      'Usa Face ID, huella digital o la contraseña del dispositivo para acceder a tu billetera de forma más rápida y segura.';

  @override
  String get biometric_setup_enable => 'Activar biometría';

  @override
  String seed_fetch_error(String error) {
    return 'Error: $error';
  }

  @override
  String get seed_not_found => 'No se encontró ninguna frase de recuperación.';

  @override
  String get seed_screen_title => 'Frase de Recuperación';

  @override
  String get seed_words_of => 'Palabras de ';

  @override
  String get seed_recovery_word => 'Recuperación';

  @override
  String get seed_save_warning =>
      'Anota estas palabras en un lugar seguro. Son la única forma de recuperar tu billetera.';

  @override
  String get seed_copy => 'Copiar frase';

  @override
  String get seed_copied => 'Copiado';

  @override
  String get seed_confirm_phrase => 'Confirmar frase';

  @override
  String seed_confirmed_words_count(int count) {
    return 'Palabras confirmadas ($count)';
  }

  @override
  String get seed_remove_last => 'Eliminar última';

  @override
  String get pin_confirm_title => 'Confirmar PIN';

  @override
  String get pin_confirm_yours => 'Confirma tu ';

  @override
  String get pin_word => 'PIN';

  @override
  String get pin_confirm_instruction_1 => 'Ingresa nuevamente el ';

  @override
  String get pin_confirm_instruction_2 => 'PIN ';

  @override
  String get pin_confirm_instruction_3 => 'que acabas de crear.';

  @override
  String get pin_mismatch => 'Los PIN no coinciden';

  @override
  String get pin_validate_title => 'Validar PIN';

  @override
  String get pin_validate_security => 'Validación de seguridad';

  @override
  String get pin_validate_action => 'Validar ';

  @override
  String get pin_validate_body =>
      'Ingresa tu PIN para continuar de forma segura.';

  @override
  String get pin_incorrect => 'PIN incorrecto. Inténtalo de nuevo.';

  @override
  String get pin_use_biometric => 'Usar biometría';

  @override
  String get pin_use_device_password => 'Usar contraseña del dispositivo';

  @override
  String get pin_forgot => '¿Olvidaste tu PIN?';

  @override
  String get pin_biometric_unavailable =>
      'Biometría o contraseña del sistema no disponibles.';

  @override
  String get pin_biometric_access_reason =>
      'Usa tu biometría para acceder a tu billetera';

  @override
  String get pin_reset_biometric_reason =>
      'Usa tu biometría o la contraseña del dispositivo para restablecer el PIN';

  @override
  String get theme_system => 'Sistema';

  @override
  String get theme_light => 'Claro';

  @override
  String get theme_dark => 'Oscuro';

  @override
  String get language_portuguese => 'Portugués';

  @override
  String get language_english => 'Inglés';

  @override
  String get language_spanish => 'Español';

  @override
  String get language_system => 'Idioma del dispositivo';

  @override
  String get delete_wallet_title => 'Eliminar billetera';

  @override
  String get delete_wallet_warning_title => 'Cuidado al eliminar tu ';

  @override
  String get delete_wallet_word => 'billetera';

  @override
  String get delete_wallet_warning_subtitle =>
      'Si la eliminas, deberás pasar nuevamente por la verificación TRUST y perderás el acceso a tus fondos si no guardaste tu frase de recuperación.';

  @override
  String get delete_wallet_pix_limits_title => 'Límites PIX';

  @override
  String get delete_wallet_pix_limits_desc =>
      'Entiendo que deberé pasar nuevamente por TRUST y que mis límites de PIX se restablecerán.';

  @override
  String get delete_wallet_funds_loss_title => 'Pérdida de fondos';

  @override
  String get delete_wallet_funds_loss_desc =>
      'Entiendo que perderé el acceso a mis fondos si no guardé mi frase de recuperación.';

  @override
  String get delete_wallet_button => 'Eliminar billetera';

  @override
  String get delete_wallet_error =>
      'Error al eliminar la billetera. Inténtalo de nuevo.';

  @override
  String get referral_title => 'Código de Referido';

  @override
  String get referral_applied_success => '¡Código aplicado con éxito!';

  @override
  String get referral_error_empty_code => 'El código no puede estar vacío.';

  @override
  String get referral_error_invalid_code =>
      'Código inválido. Verifique e inténtelo de nuevo.';

  @override
  String get referral_error_apply_failed =>
      'Error al aplicar el código. Inténtelo de nuevo.';

  @override
  String get referral_error_fetch_failed =>
      'Error al obtener el código de referido.';

  @override
  String get referral_error_validate_failed => 'Error al validar el código.';

  @override
  String get license_title => 'Licencia GPL v3';

  @override
  String get license_subtitle => 'GNU General Public License';

  @override
  String get license_version_line =>
      'Versión 3, 29 de junio de 2007 • Free Software Foundation';

  @override
  String get license_copyleft_title => 'Licencia Copyleft';

  @override
  String get license_copyleft_desc =>
      'Esta licencia garantiza que el software siga siendo libre. Toda distribución debe incluir el código fuente.';

  @override
  String get license_free_software_title => 'Software Libre';

  @override
  String get license_free_software_subtitle => 'Libertad garantizada';

  @override
  String get license_redistributable_title => 'Redistribuible';

  @override
  String get license_redistributable_subtitle => 'Con código fuente';

  @override
  String get license_copyleft_short_title => 'Copyleft';

  @override
  String get license_copyleft_short_subtitle => 'Derivados libres';

  @override
  String get license_copyright_line =>
      'Copyright © 2007 Free Software Foundation, Inc.';

  @override
  String get license_fsf_link => 'Free Software Foundation';

  @override
  String get license_full_link => 'Licencia Completa';

  @override
  String get license_section_preamble => 'Preámbulo';

  @override
  String get license_section_definitions => 'Definiciones';

  @override
  String get license_section_source => 'Código fuente';

  @override
  String get license_section_basic_perms => 'Permisos Básicos';

  @override
  String get license_section_legal_rights =>
      'Protección de los Derechos Legales de los Usuarios';

  @override
  String get license_section_verbatim => 'Distribución de Copias Literales';

  @override
  String get license_section_modified =>
      'Distribución de Versiones Modificadas del Código Fuente';

  @override
  String get license_section_non_source => 'Distribución de Formatos No Fuente';

  @override
  String get license_section_additional => 'Términos Adicionales';

  @override
  String get license_section_termination => 'Terminación';

  @override
  String get license_section_acceptance =>
      'Aceptación No Requerida para Tener Copias';

  @override
  String get license_section_downstream =>
      'Licenciamiento Automático de los Destinatarios Posteriores';

  @override
  String get license_section_patents => 'Patentes';

  @override
  String get license_section_no_surrender =>
      'No Renunciar a la Libertad de los Demás';

  @override
  String get license_section_agpl =>
      'Uso con la Licencia Pública General Affero de GNU';

  @override
  String get license_section_revisions =>
      'Versiones Revisadas de esta Licencia';

  @override
  String get license_section_warranty => 'Renuncia de Garantía';

  @override
  String get license_section_liability => 'Limitación de Responsabilidad';

  @override
  String get license_section_interpretation =>
      'Interpretación de las Secciones 15 y 16';

  @override
  String get license_section_preamble_body =>
      'La Licencia Pública General de GNU es una licencia libre con copyleft para software y otro tipo de obras.\n\nLas licencias de la mayoría del software y otras obras prácticas están diseñadas para privarle de la libertad de compartir y cambiar las obras. Por el contrario, la Licencia Pública General de GNU tiene como objetivo garantizar su libertad para compartir y cambiar todas las versiones de un programa, asegurando que siga siendo software libre para todos sus usuarios.\n\nCuando hablamos de software libre, nos referimos a libertad, no a precio. Nuestras Licencias Públicas Generales están diseñadas para garantizar que usted tenga la libertad de distribuir copias de software libre, que reciba el código fuente o pueda obtenerlo, que pueda modificar el software y que sepa que puede hacer estas cosas.';

  @override
  String get license_section_definitions_body =>
      'Esta Licencia hace referencia a la versión 3 de la Licencia Pública General de GNU.\n\nCopyright también significa las leyes similares al copyright que se aplican a otro tipo de obras, como las máscaras de semiconductores.\n\nEl Programa hace referencia a cualquier obra con copyright licenciada bajo esta Licencia. Cada licenciatario se denomina usted. Los licenciatarios y destinatarios pueden ser personas físicas u organizaciones.\n\nModificar una obra significa copiar o adaptar toda o parte de la obra de una manera que requiera permiso de copyright, distinto de la realización de una copia exacta.';

  @override
  String get license_section_source_body =>
      'El código fuente de una obra significa la forma preferida de la obra para realizar modificaciones en ella. El código objeto significa cualquier forma no fuente de una obra.\n\nUna Interfaz Estándar significa una interfaz que es un estándar oficial definido por un organismo de estándares reconocido o, en el caso de interfaces especificadas para un lenguaje de programación específico, una que es ampliamente utilizada entre los desarrolladores que trabajan en ese lenguaje.';

  @override
  String get license_section_basic_perms_body =>
      'Todos los derechos concedidos bajo esta Licencia se otorgan para el plazo del copyright sobre el Programa, y son irrevocables siempre que se cumplan las condiciones establecidas. Esta Licencia afirma explícitamente su permiso ilimitado para ejecutar el Programa sin modificar.\n\nPuede hacer, ejecutar y propagar obras cubiertas que no transmita, sin condiciones, siempre que su licencia permanezca vigente.';

  @override
  String get license_section_legal_rights_body =>
      'Ninguna obra cubierta debe considerarse parte de una medida tecnológica efectiva bajo ninguna ley aplicable que cumpla las obligaciones del artículo 11 del tratado de copyright de la OMPI.\n\nCuando transmite una obra cubierta, renuncia a cualquier poder legal para prohibir la evasión de medidas tecnológicas.';

  @override
  String get license_section_verbatim_body =>
      'Puede transmitir copias literales del código fuente del Programa tal como lo recibe, en cualquier medio, siempre que publique de manera conspicua y apropiada en cada copia un aviso de copyright apropiado.\n\nPuede cobrar cualquier precio o ningún precio por cada copia que transmita, y puede ofrecer soporte o protección de garantía a cambio de una tarifa.';

  @override
  String get license_section_modified_body =>
      'Puede transmitir una obra basada en el Programa, o las modificaciones para producirla a partir del Programa, en forma de código fuente bajo los términos de la sección 4, siempre que también cumpla todas estas condiciones:\n\na) La obra debe llevar avisos prominentes que indiquen que la modificó y que proporcionen una fecha relevante.\nb) La obra debe llevar avisos prominentes que indiquen que se publica bajo esta Licencia.';

  @override
  String get license_section_non_source_body =>
      'Puede transmitir una obra cubierta en forma de código objeto bajo los términos de las secciones 4 y 5, siempre que también transmita la Fuente Correspondiente legible por máquina bajo los términos de esta Licencia.\n\nLa Fuente Correspondiente puede estar en un servidor diferente operado por usted o un tercero que admita instalaciones de copia equivalentes.';

  @override
  String get license_section_additional_body =>
      'Los permisos adicionales son términos que complementan los términos de esta Licencia haciendo excepciones a una o más de sus condiciones. Los permisos adicionales que sean aplicables a todo el Programa deben tratarse como si estuvieran incluidos en esta Licencia.\n\nPuede incluir permisos adicionales sobre el material que añada a una obra cubierta, para el que tenga o pueda dar el permiso de copyright apropiado.';

  @override
  String get license_section_termination_body =>
      'No puede propagar ni modificar una obra cubierta, excepto según lo expresamente previsto en esta Licencia. Cualquier intento de propagar o modificarla es nulo y terminará automáticamente sus derechos bajo esta Licencia.\n\nSin embargo, si cesa toda violación de esta Licencia, su licencia de un titular de copyright específico se restablece provisionalmente.';

  @override
  String get license_section_acceptance_body =>
      'No está obligado a aceptar esta Licencia para recibir o ejecutar una copia del Programa. La propagación auxiliar de una obra cubierta que ocurra únicamente como consecuencia del uso de transmisión entre pares para recibir una copia tampoco requiere aceptación.';

  @override
  String get license_section_downstream_body =>
      'Cada vez que transmita una obra cubierta, el destinatario recibe automáticamente una licencia de los licenciantes originales para ejecutar, modificar y propagar esa obra, sujeto a esta Licencia.\n\nNo puede imponer restricciones adicionales sobre el ejercicio de los derechos otorgados o afirmados bajo esta Licencia.';

  @override
  String get license_section_patents_body =>
      'Un contribuidor es un titular de copyright que autoriza el uso bajo esta Licencia del Programa o una obra en la que se basa el Programa.\n\nCada contribuidor le otorga una licencia de patente no exclusiva, mundial y libre de regalías bajo las reclamaciones de patente esenciales de dicho contribuidor.';

  @override
  String get license_section_no_surrender_body =>
      'Si se le imponen condiciones, ya sea por orden judicial, acuerdo u otro modo, que contradigan las condiciones de esta Licencia, no le eximen de las condiciones de esta Licencia.\n\nSi no puede transmitir una obra cubierta de forma que satisfaga simultáneamente sus obligaciones bajo esta Licencia y cualquier otra obligación pertinente, entonces no puede transmitirla en absoluto.';

  @override
  String get license_section_agpl_body =>
      'Sin perjuicio de cualquier otra disposición de esta Licencia, tiene permiso para vincular o combinar cualquier obra cubierta con una obra licenciada bajo la versión 3 de la Licencia Pública General Affero de GNU en una sola obra combinada.';

  @override
  String get license_section_revisions_body =>
      'La Free Software Foundation puede publicar versiones revisadas y/o nuevas de la Licencia Pública General de GNU de vez en cuando. Estas nuevas versiones serán similares en espíritu a la versión actual, pero pueden diferir en detalle para abordar nuevos problemas o preocupaciones.\n\nA cada versión se le asigna un número de versión distintivo.';

  @override
  String get license_section_warranty_body =>
      'NO HAY NINGUNA GARANTÍA PARA EL PROGRAMA, EN LA MEDIDA PERMITIDA POR LA LEY APLICABLE. EXCEPTO CUANDO SE INDIQUE LO CONTRARIO POR ESCRITO, LOS TITULARES DEL COPYRIGHT Y/U OTRAS PARTES PROPORCIONAN EL PROGRAMA TAL CUAL SIN GARANTÍA DE NINGÚN TIPO.\n\nTODO EL RIESGO EN CUANTO A LA CALIDAD Y EL RENDIMIENTO DEL PROGRAMA RECAE SOBRE USTED. SI EL PROGRAMA RESULTA DEFECTUOSO, USTED ASUME EL COSTO DE TODOS LOS SERVICIOS, REPARACIONES O CORRECCIONES NECESARIOS.';

  @override
  String get license_section_liability_body =>
      'EN NINGÚN CASO, A MENOS QUE LO EXIJA LA LEY APLICABLE O SE ACUERDE POR ESCRITO, CUALQUIER TITULAR DEL COPYRIGHT, O CUALQUIER OTRA PARTE QUE MODIFIQUE Y/O TRANSMITA EL PROGRAMA COMO SE PERMITE ANTERIORMENTE, SERÁ RESPONSABLE DE DAÑOS.\n\nESTO INCLUYE CUALQUIER DAÑO GENERAL, ESPECIAL, INCIDENTAL O CONSECUENTE QUE SURJA DEL USO O DE LA IMPOSIBILIDAD DE USAR EL PROGRAMA, INCLUSO SI DICHO TITULAR U OTRA PARTE HAN SIDO ADVERTIDOS DE LA POSIBILIDAD DE TALES DAÑOS.';

  @override
  String get license_section_interpretation_body =>
      'Si la renuncia de garantía y la limitación de responsabilidad mencionadas anteriormente no pueden tener efecto legal local según sus términos, los tribunales revisores aplicarán la ley local que más se aproxime a una renuncia absoluta de toda responsabilidad civil en relación con el Programa, a menos que una garantía o asunción de responsabilidad acompañe a una copia del Programa a cambio de una tarifa.';

  @override
  String get license_end_terms => 'FIN DE LOS TÉRMINOS Y CONDICIONES';

  @override
  String get terms_title => 'Términos de Uso';

  @override
  String get terms_subtitle => 'Mooze Wallet';

  @override
  String get terms_intro =>
      'Al usar la aplicación Mooze, aceptas íntegramente estos términos. Léelos atentamente antes de continuar.';

  @override
  String get terms_warning_title => 'Aviso Importante';

  @override
  String get terms_warning_message =>
      'Eres el único responsable de mantener tu frase de recuperación segura. La pérdida de esta información implica la pérdida irreversible de tus activos digitales.';

  @override
  String get terms_self_custody_title => 'Autocustodia';

  @override
  String get terms_self_custody_subtitle => 'Tú controlas tus fondos';

  @override
  String get terms_privacy_title => 'Privacidad';

  @override
  String get terms_privacy_subtitle => 'Datos protegidos';

  @override
  String get terms_beta_title => 'Beta';

  @override
  String get terms_beta_subtitle => 'En desarrollo';

  @override
  String get terms_last_updated => 'Última actualización: 23/03/2026';

  @override
  String get terms_privacy_policy_link => 'Ver Política de Privacidad';

  @override
  String get terms_section_1 => '1. Aceptación de los Términos';

  @override
  String get terms_section_2 =>
      '2. Naturaleza Jurídica y Encuadramiento de Mooze';

  @override
  String get terms_section_3 => '3. Definiciones';

  @override
  String get terms_section_4 => '4. Descripción de los Servicios';

  @override
  String get terms_section_5 => '5. Modelo No Custodial y Autocustodia';

  @override
  String get terms_section_6 => '6. Responsabilidades del Usuario';

  @override
  String get terms_section_7 => '7. Tarifas y Cargos por Servicio';

  @override
  String get terms_section_8 =>
      '8. Referencia Monetaria e Información de Precios';

  @override
  String get terms_section_9 => '9. Limitación de Responsabilidad';

  @override
  String get terms_section_10 => '10. Política Antifraude y Seguridad';

  @override
  String get terms_section_11 =>
      '11. Monitoreo, Prevención de Fraudes y Suspensión de Servicios';

  @override
  String get terms_section_12 => '12. Obligaciones Legales del Usuario';

  @override
  String get terms_section_13 => '13. Jurisdicción y Ley Aplicable';

  @override
  String get terms_section_14 => '14. Resolución de Disputas';

  @override
  String get terms_section_15 => '15. Propiedad Intelectual';

  @override
  String get terms_section_16 => '16. Disposiciones Generales';

  @override
  String get terms_section_17 => '17. Edad Mínima';

  @override
  String get terms_section_18 => '18. Cambios en los Términos';

  @override
  String get terms_section_19 => '19. Contacto';

  @override
  String get privacy_section_header => 'Política de Privacidad — Mooze Wallet';

  @override
  String get privacy_section_1 => '1. Compromiso con la Privacidad';

  @override
  String get privacy_section_2 => '2. Definiciones';

  @override
  String get privacy_section_3 => '3. Datos Recopilados y No Recopilados';

  @override
  String get privacy_section_4 =>
      '4. Tratamiento de Datos en Operaciones con Referencial Fiat';

  @override
  String get privacy_section_5 => '5. Compartir Datos';

  @override
  String get privacy_section_6 => '6. Comunicación con Mooze';

  @override
  String get privacy_section_7 => '7. Seguridad';

  @override
  String get privacy_section_8 => '8. Retención de Datos';

  @override
  String get privacy_section_9 => '9. Derechos del Usuario (LGPD)';

  @override
  String get privacy_section_10 => '10. Jurisdicción de Datos';

  @override
  String get privacy_section_11 => '11. Cambios';

  @override
  String get privacy_section_12 => '12. Contacto';

  @override
  String get terms_section_1_body =>
      '1.1. Al acceder, instalar o utilizar la aplicación Mooze, el Usuario declara haber leído, comprendido y aceptado íntegramente estos Términos de Uso.\n\n1.2. La utilización de la Aplicación constituye aceptación tácita e irrevocable de todas las disposiciones contenidas en este documento.\n\n1.3. Si el Usuario no está de acuerdo con alguna disposición de estos Términos, deberá cesar inmediatamente el uso de la Aplicación y desinstalarla de sus dispositivos.\n\n1.4. Estos Términos constituyen un contrato vinculante entre el Usuario y Mooze Labs LLC, regido por las leyes de la República de las Islas Marshall.';

  @override
  String get terms_section_2_body =>
      '2.1. Mooze Labs LLC es una sociedad de responsabilidad limitada constituida bajo la Ley de Asociaciones de la República de las Islas Marshall.\n\n2.2. Mooze opera exclusivamente como proveedor de servicios de software para la gestión de carteras digitales autocustodiales en la red Bitcoin y en la Liquid Network.\n\n2.3. Mooze NO es correduría, exchange, institución financiera, prestadora de servicios de cambio, transmisora de dinero, VASP, custodiante de activos ni asesora de inversiones.\n\n2.4. Mooze no tiene en ningún momento custodia, posesión, control discrecional ni dominio sobre activos digitales del Usuario. El procesamiento transitorio por la infraestructura de Mooze es análogo al enrutamiento de paquetes de datos por un router de red.\n\n2.5. Mooze no realiza operaciones de cambio o intermediación financiera. Todas las operaciones que involucren reales brasileños son procesadas por socias reguladas por el Banco Central de Brasil.\n\n2.6. Mooze opera exclusivamente como proveedor de software no custodial, sin acceso, control ni custodia sobre activos digitales de los Usuarios.\n\n2.7. Mooze es miembro oficial de la Liquid Federation (Blockstream), con PAK Entry activo.';

  @override
  String get terms_section_3_body =>
      '3.1. Aplicación o Mooze Wallet: software de cartera digital autocustodial disponible para iOS y Android.\n\n3.2. Usuario: toda persona natural que instala, accede o utiliza la Aplicación.\n\n3.3. Autocustodia: modelo en el que el Usuario tiene control exclusivo sobre sus claves privadas y frases semilla.\n\n3.4. Frase Semilla: secuencia de 12 o 24 palabras (estándar BIP39), único mecanismo de recuperación de la cartera.\n\n3.5. Liquid Network: sidechain federada de Bitcoin desarrollada por Blockstream.\n\n3.6. DEPIX: token digital en la Liquid Network con valor vinculado al real brasileño (R\$ 1,00 = 1 DEPIX).\n\n3.7. L-BTC: representación de Bitcoin en la Liquid Network.\n\n3.8. Atomic Swap: intercambio directo entre activos digitales sin intermediario custodiante.\n\n3.9. SideSwap: protocolo público para atomic swaps en la Liquid Network.\n\n3.10. Confidential Transactions: tecnología de Liquid Network que oculta valores y tipos de activos en transacciones.\n\n3.11. APP ID: identificador único generado por el dispositivo, utilizado exclusivamente para prevención de fraudes.\n\n3.12. Socias Reguladas: PLEBIT.COM.BR (CNPJ 43.375.652/0001-13), Fits Instituição de Pagamento (CNPJ 13.203.354/0001-85), Celcoin (CNPJ 13.935.893/0001-09), PLEBZ (CNPJ 45.808.899/0001-01).\n\n3.13. Eulen.app LLC: responsable de la emisión del token DEPIX.\n\n3.14. PIX: sistema de pagos instantáneos del Banco Central de Brasil.\n\n3.15. Servicios: funcionalidades de software disponibilizadas por Mooze.';

  @override
  String get terms_section_4_body =>
      '4.1. SERVICIO A — Orquestación de Software para Adquisición de Tokens Digitales\nMooze disponibiliza una interfaz de software que orquesta automáticamente la comunicación entre el dispositivo del Usuario, las Socias Reguladas y la infraestructura de Eulen.app LLC. El pago PIX es procesado por las Socias Reguladas; Eulen.app LLC emite los tokens DEPIX; el software de Mooze enruta los tokens a la dirección autocustodial del Usuario. Mooze actúa exclusivamente como orquestador automatizado, sin adquirir titularidad sobre los activos.\n\n4.2. SERVICIO B — Interfaz para Protocolo Descentralizado de Conversión entre Unidades Digitales\nMooze proporciona una interfaz para que el Usuario interactúe con el protocolo SideSwap para atomic swaps en la Liquid Network. Mooze no participa como contraparte ni custodio. La función de Mooze es análoga a la de un navegador que provee acceso a sitios web. Mooze también provee acceso vía SDK Breez para la Lightning Network.\n\n4.3. MODO COMERCIANTE\nFuncionalidad que permite recibir pagos vía PIX en carteras autocustodiales. El código QR PIX es generado por el propio Usuario vía Aplicación. Mooze no tiene conocimiento de la relación comercial subyacente. El Usuario NO debe entregar producto o servicio antes de la confirmación final del pago. Consultas: suporte@mooze.app.';

  @override
  String get terms_section_5_body =>
      '5.1. La Aplicación opera bajo modelo de autocustodia integral. Las claves privadas y frases semilla son generadas y almacenadas exclusivamente en el dispositivo del Usuario, siendo inaccesibles para Mooze.\n\n5.2. Mooze no tiene en ningún momento acceso, conocimiento, posesión, control ni copia de las claves privadas, frases semilla o contraseñas del Usuario.\n\n5.3. El Usuario es el único responsable de la custodia y seguridad de sus claves privadas y frases semilla. La pérdida de estos elementos resulta en la pérdida permanente e irreversible del acceso a los activos digitales.\n\n5.4. Mooze no tiene capacidad técnica para recuperar, restaurar, acceder ni transferir activos digitales del Usuario en caso de pérdida de claves privadas o frases semilla.\n\n5.5. Las direcciones de cartera del Usuario son utilizadas por Mooze exclusivamente como parámetro de enrutamiento automatizado durante la ejecución de los Servicios.';

  @override
  String get terms_section_6_body =>
      '6.1. CUSTODIA DE CONTRASEÑAS Y FRASES SEMILLA\nEl Usuario es integral y exclusivamente responsable de la creación, almacenamiento y protección de sus contraseñas, claves privadas y frases semilla. Mooze nunca solicitará al Usuario sus claves privadas, frases semilla o contraseñas por ningún canal de comunicación.\n\n6.2. CONSECUENCIAS DE LA PÉRDIDA DE ACCESO\nLa pérdida de la frase semilla implica la pérdida permanente e irreversible del acceso a todos los activos digitales. Mooze no puede restaurar ni recuperar el acceso a la cartera del Usuario en caso de pérdida.\n\n6.3. SEGURIDAD DEL DISPOSITIVO\nEl Usuario es responsable de la seguridad del dispositivo, incluyendo sistema operativo actualizado, autenticación biométrica y protección contra malware. Mooze no se responsabiliza por pérdidas derivadas del compromiso del dispositivo.';

  @override
  String get terms_section_7_body =>
      '7.1. Mooze cobra una Tarifa de Servicio de Software por el uso de los Servicios, calculada como porcentaje del valor de la operación y deducida de los activos digitales entregados al Usuario.\n\n7.2. El porcentaje vigente se muestra en la pantalla de confirmación de la operación antes de su ejecución.\n\n7.3. Mooze se reserva el derecho de modificar los porcentajes en cualquier momento. La continuidad de uso tras la modificación constituye aceptación.\n\n7.4. Las Socias Reguladas, SideSwap, Breez Technologies y fintech socias pueden aplicar sus propias tarifas, independientes de la Tarifa de Mooze.\n\n7.5. Los costos de minería (comisiones de red) son responsabilidad del Usuario e independientes de la Tarifa de Servicio. Los valores totales se muestran en la pantalla de confirmación antes de la ejecución.';

  @override
  String get terms_section_8_body =>
      '8.1. Los valores de referencia mostrados en la Aplicación para activos digitales se obtienen de fuentes públicas de mercado y sirven exclusivamente como referencia informativa.\n\n8.2. Mooze no garantiza la exactitud ni la actualización en tiempo real de los precios mostrados. La variación de precio entre exhibición y ejecución es inherente a los mercados de activos digitales.\n\n8.3. La exhibición de precios no constituye oferta, recomendación de inversión ni garantía de valor.\n\n8.4. El Usuario reconoce que los activos digitales están sujetos a alta volatilidad y que puede sufrir pérdidas significativas de valor.';

  @override
  String get terms_section_9_body =>
      '9.1. Mooze proporciona la Aplicación y los Servicios tal como están (as is), sin garantías de ningún tipo.\n\n9.2. Mooze no será responsable por: pérdidas de activos por pérdida de claves privadas; compromiso del dispositivo; indisponibilidad de redes blockchain; fallos de Socias Reguladas, Eulen.app LLC o SideSwap; actos de fraude de terceros; errores en la inserción de direcciones de cartera; cambios regulatorios; variación de precios de activos; decisiones de inversión del Usuario; daños indirectos o consecuentes.\n\n9.3. La responsabilidad total de Mooze está limitada al valor de las Tarifas efectivamente pagadas por el Usuario en los últimos 12 meses.\n\n9.4. La Aplicación se encuentra en modo BETA. El Usuario acepta todos los riesgos asociados.\n\n9.5. Las frases semilla son compatibles con BIP39 y con la Liquid Network. En caso de indisponibilidad crítica, el Usuario puede recuperar activos en cualquier cartera compatible (ej: Blockstream App).';

  @override
  String get terms_section_10_body =>
      '10.1. Mooze implementa mecanismos de seguridad que incluyen:\n- Vinculación de APP ID a operaciones\n- Sistema de puntuación por niveles de riesgo\n- Límites progresivos por APP ID\n- Detección de patrones anómalos (smurfing, bursting, autopagos)\n\n10.2. Las medidas antifraude de Mooze son de naturaleza exclusivamente tecnológica y no sustituyen las obligaciones de AML y KYC de las Socias Reguladas.\n\n10.3. Las Socias Reguladas son las únicas responsables del cumplimiento de las obligaciones de AML y KYC ante el Banco Central de Brasil.';

  @override
  String get terms_section_11_body =>
      '11.1. Mooze se reserva el derecho de suspender, limitar o cancelar el acceso de un APP ID a los Servicios sin previo aviso en caso de: patrones indicativos de fraude; dispositivos comprometidos o emuladores; intentos de eludir mecanismos de seguridad; patrones de lavado de dinero o financiamiento al terrorismo; solicitud de autoridad competente.\n\n11.2. La suspensión afecta solo a nuevas operaciones. Los activos en autocustodia permanecen íntegramente bajo control del Usuario, accesibles por la frase semilla.\n\n11.3. Mooze cooperará con las autoridades competentes mediante orden judicial válida, observadas las limitaciones técnicas del modelo autocustodial.';

  @override
  String get terms_section_12_body =>
      '12.1. El Usuario declara y garantiza que:\n- Utiliza los Servicios en conformidad con la legislación de su jurisdicción\n- Los recursos utilizados para pago vía PIX son de origen lícito\n- No utiliza los Servicios para lavado de dinero, financiamiento al terrorismo ni evasión fiscal\n- Es responsable exclusivo de la declaración y pago de tributos sobre activos digitales\n- Tiene conocimiento de que Mooze no se encuadra como VASP en los términos de la Ley n. 14.478/2022\n\n12.2. Mooze no presta servicios de asesoría tributaria, fiscal ni jurídica.\n\n12.3. Mooze no realiza declaraciones fiscales en nombre del Usuario.';

  @override
  String get terms_section_13_body =>
      '13.1. Estos Términos se rigen por las leyes de la República de las Islas Marshall.\n\n13.2. Mooze Labs LLC es una entidad constituida en la República de las Islas Marshall y opera desde esa jurisdicción, sin presencia física ni jurídica en Brasil.\n\n13.3. La relación entre Mooze y las Socias Reguladas se rige por contratos internacionales independientes, sin crear responsabilidad solidaria entre las partes.';

  @override
  String get terms_section_14_body =>
      '14.1. Cualquier disputa será resuelta, a exclusivo criterio de Mooze, por los tribunales de la República de las Islas Marshall o mediante arbitraje internacional bajo las Reglas de la UNCITRAL.\n\n14.2. El Usuario renuncia a cualquier fuero que no sea el indicado, salvo cuando esté prohibido por ley imperativa de su jurisdicción.\n\n14.3. Antes de formalizar cualquier disputa, el Usuario deberá notificar a Mooze por escrito. Las partes realizarán esfuerzos de buena fe para una resolución amistosa en 30 días.';

  @override
  String get terms_section_15_body =>
      '15.1. Todo el software, código fuente, diseño, marcas, logotipos y contenido de la Aplicación son propiedad exclusiva de Mooze Labs LLC o de sus licenciantes.\n\n15.2. El uso de la Aplicación no confiere al Usuario ningún derecho de propiedad intelectual.\n\n15.3. Está prohibida la reproducción, modificación o ingeniería inversa de la Aplicación sin autorización expresa de Mooze.\n\n15.4. El código fuente está disponible en https://github.com/mooze-labs/mooze-client bajo los términos de la licencia allí indicada.';

  @override
  String get terms_section_16_body =>
      '16.1. INTEGRIDAD\nEstos Términos y la Política de Privacidad constituyen el acuerdo íntegro entre las partes, sustituyendo cualquier acuerdo anterior.\n\n16.2. DIVISIBILIDAD\nSi alguna disposición fuera declarada inválida, las demás permanecerán en plena vigencia.\n\n16.3. RENUNCIA\nLa omisión de Mooze en exigir el cumplimiento de cualquier disposición no constituye renuncia al derecho de exigirlo posteriormente.\n\n16.4. CESIÓN\nEl Usuario no puede ceder sus derechos sin autorización previa y por escrito de Mooze.\n\n16.5. FUERZA MAYOR\nMooze no será responsable por retrasos derivados de fallas en redes blockchain, indisponibilidad de Socias, ciberataques, decisiones gubernamentales o desastres naturales.\n\n16.6. INDEMNIZACIÓN\nEl Usuario acepta indemnizar a Mooze por reclamaciones derivadas del uso indebido de los Servicios, violación de leyes o suministro de información falsa.\n\n16.7. DISTRIBUCIÓN\nLa distribución en plataformas digitales es realizada por Mooze LLC (Delaware), como distribuidora autorizada, sin asumir responsabilidades de desarrollo ni operación.';

  @override
  String get terms_section_17_body =>
      '17.1. La Aplicación y los Servicios están destinados exclusivamente a personas con edad igual o superior a 18 años.\n\n17.2. Al utilizar la Aplicación, el Usuario declara tener al menos 18 años y poseer plena capacidad civil.\n\n17.3. Mooze se reserva el derecho de suspender el acceso de cualquier Usuario que se verifique ser menor de 18 años.';

  @override
  String get terms_section_18_body =>
      '18.1. Mooze se reserva el derecho de modificar estos Términos en cualquier momento, publicando la versión actualizada en la Aplicación y en https://mooze.app/termosdeuso/.\n\n18.2. Los cambios relevantes se comunicarán vía Aplicación, Telegram o correo electrónico.\n\n18.3. La continuidad del uso tras la publicación de cambios constituye aceptación tácita de los Términos actualizados.\n\n18.4. El Usuario que no esté de acuerdo con los cambios deberá cesar el uso. Los activos en autocustodia permanecen accesibles por la frase semilla.';

  @override
  String get terms_section_19_body =>
      '19.1. Para consultas, solicitudes o comunicaciones relacionadas con estos Términos:\n\n(a) Correo electrónico: suporte@mooze.app\n(b) Telegram: https://t.me/+zkNS6KIDsEcyZDkx\n(c) FAQ automatizado vía Telegram\n\n19.2. Mooze realizará esfuerzos para responder en el plazo de 10 días hábiles.';

  @override
  String get privacy_section_header_body =>
      'Última actualización: 23/03/2026\n\nMooze Labs LLC, República de las Islas Marshall';

  @override
  String get privacy_section_1_body =>
      '1.1. Mooze Labs LLC está comprometida con la protección de la privacidad y la minimización de datos personales en el uso de la Aplicación.\n\n1.2. Esta Política describe qué información se recopila, cómo se utiliza, con quién se comparte y qué derechos tiene el Usuario.\n\n1.3. Mooze adopta el principio de minimización de datos como pilar central de su operación. La Aplicación está diseñada para funcionar sin recopilar datos personales identificables.';

  @override
  String get privacy_section_2_body =>
      'Todos los términos definidos en los Términos de Uso tienen los mismos significados en esta Política. Adicionalmente:\n\n(a) Datos Personales: cualquier información relacionada con persona natural identificada o identificable (LGPD).\n(b) Tratamiento: toda operación realizada con Datos Personales.\n(c) LGPD: Ley General de Protección de Datos de Brasil (Ley n. 13.709/2018).';

  @override
  String get privacy_section_3_body =>
      'MOOZE NO ALMACENA:\nCPF, RG, direcciones MAC, número de teléfono, dirección residencial, fecha de nacimiento, biometría personal, claves privadas ni frases semilla.\n\nMOOZE RECOPILA EXCLUSIVAMENTE:\n(a) APP ID: hash criptográfico del dispositivo, utilizado solo para prevención de fraudes.\n(b) Direcciones de cartera en la Liquid Network: utilizadas como parámetro de enrutamiento automatizado.\n(c) Blinding keys: retenidas para verificación y reconciliación de transacciones.\n(d) Datos de transacción: valores, tipos de activos, timestamps y estado de ejecución.\n(e) Datos técnicos del dispositivo: versión del SO, modelo y versión de la Aplicación — no permiten identificación personal.';

  @override
  String get privacy_section_4_body =>
      '4.1. Cuando el Usuario realiza operaciones vía PIX (Servicio A), los datos necesarios para el procesamiento — incluyendo KYC y AML — son recopilados y procesados exclusivamente por las Socias Reguladas.\n\n4.2. Socias Reguladas: PLEBIT.COM.BR (CNPJ 43.375.652/0001-13), Fits Instituição de Pagamento (CNPJ 13.203.354/0001-85), Celcoin (CNPJ 13.935.893/0001-09), PLEBZ (CNPJ 45.808.899/0001-01).\n\n4.3. Mooze no recibe, almacena ni tiene acceso a los datos personales recopilados por las Socias Reguladas.';

  @override
  String get privacy_section_5_body =>
      '5.1. Mooze comparte datos exclusivamente:\n(a) Con Socias Reguladas y Eulen.app LLC: direcciones de cartera, valores y APP ID cuando sea necesario para antifraude.\n(b) Mediante orden judicial válida.\n(c) Para cumplimiento de obligación legal en la jurisdicción de las Islas Marshall.\n\n5.2. Mooze NO vende, alquila ni comparte datos con terceros para fines de marketing o publicidad.\n\n5.3. Mooze NO utiliza rastreadores de terceros, píxeles de seguimiento ni SDKs de análisis que recopilen datos personales.';

  @override
  String get privacy_section_6_body =>
      '6.1. Cuando el Usuario contacta a Mooze vía correo electrónico (suporte@mooze.app) o Telegram, los datos compartidos voluntariamente se utilizarán exclusivamente para atender la solicitud.\n\n6.2. Mooze no asocia datos de comunicación a APP IDs ni a direcciones de cartera, excepto cuando el propio Usuario proporciona tales informaciones voluntariamente.';

  @override
  String get privacy_section_7_body =>
      '7.1. Mooze adopta medidas técnicas y organizacionales razonables para proteger los datos contra acceso no autorizado, destrucción o divulgación indebida.\n\n7.2. Los datos recopilados son almacenados en infraestructura protegida con controles de acceso y cifrado.\n\n7.3. Ningún método de transmisión o almacenamiento electrónico es completamente seguro.';

  @override
  String get privacy_section_8_body =>
      'Los datos recopilados por Mooze se retienen por los siguientes períodos:\n\n(a) APP ID: 5 años tras la última operación.\n(b) Direcciones de cartera y blinding keys: 5 años para verificación y cumplimiento de obligaciones legales.\n(c) Datos de transacción: 5 años desde la fecha de la transacción.\n(d) Datos técnicos de dispositivo: eliminados tras 5 años de inactividad.\n\nLos plazos pueden extenderse para cumplimiento de obligación legal o defensa en procedimiento judicial.';

  @override
  String get privacy_section_9_body =>
      'En observancia de la LGPD (Ley n. 13.709/2018), Mooze reconoce los siguientes derechos al Usuario:\n\n(a) Confirmación de la existencia del tratamiento de datos\n(b) Acceso a los datos tratados\n(c) Corrección de datos incompletos o inexactos\n(d) Eliminación de datos tratados con consentimiento\n(e) Información sobre el compartir de datos\n(f) Revocación del consentimiento\n(g) Solicitud de eliminación del APP ID asociado al dispositivo\n\nSolicitudes vía canales indicados en la Sección 12 de esta Política. Plazo de respuesta: 15 días hábiles.';

  @override
  String get privacy_section_10_body =>
      '10.1. Los datos recopilados por Mooze son almacenados y procesados en infraestructura fuera del territorio brasileño.\n\n10.2. La jurisdicción de datos aplicable es la República de las Islas Marshall.\n\n10.3. Los datos operacionales transmitidos a las Socias Reguladas durante el Servicio A son procesados en Brasil, bajo responsabilidad exclusiva de las Socias Reguladas.';

  @override
  String get privacy_section_11_body =>
      '11.1. Mooze se reserva el derecho de modificar esta Política en cualquier momento, publicando la versión actualizada en la Aplicación y en https://mooze.app/termosdeuso/.\n\n11.2. La continuidad del uso tras la publicación constituye aceptación tácita de la Política actualizada.';

  @override
  String get privacy_section_12_body =>
      '12.1. Para ejercer derechos, consultas o solicitudes:\n\n(a) Correo electrónico: suporte@mooze.app\n(b) Telegram: https://t.me/+zkNS6KIDsEcyZDkx\n(c) FAQ automatizado vía Telegram\n\n12.2. Mooze realizará esfuerzos para responder en el plazo de 15 días hábiles.';

  @override
  String get developer_title => 'Herramientas de desarrollador';

  @override
  String get developer_copy_debug_tooltip => 'Copiar información de depuración';

  @override
  String get developer_debug_copied => '¡Información de depuración copiada!';

  @override
  String get developer_sync_light_success =>
      '¡Sincronización rápida completada!';

  @override
  String get developer_sync_full_success =>
      '¡Sincronización completa concluida!';

  @override
  String get developer_rescan_success =>
      '¡Swaps onchain reescaneados con éxito!';

  @override
  String get developer_refundables_title => 'Reembolsos pendientes';

  @override
  String developer_refundables_message(int count) {
    return 'Se encontraron $count transacción(es) pendiente(s) que pueden reembolsarse.\n\n¿Desea verlas ahora?';
  }

  @override
  String get developer_later => 'Más tarde';

  @override
  String get developer_view_now => 'Ver ahora';

  @override
  String get developer_email_ready => '¡Email listo para enviar!';

  @override
  String get developer_share_logs_success => '¡Logs compartidos con éxito!';

  @override
  String developer_sync_light_error(String error) {
    return 'Error en sincronización rápida: $error';
  }

  @override
  String developer_sync_full_error(String error) {
    return 'Error en sincronización completa: $error';
  }

  @override
  String developer_rescan_error(String error) {
    return 'Error al reescanear swaps: $error';
  }

  @override
  String developer_export_error(String error) {
    return 'Error al exportar logs: $error';
  }

  @override
  String developer_share_logs_error(String error) {
    return 'Error al compartir logs: $error';
  }

  @override
  String developer_log_retention_days(int days) {
    return '$days días';
  }

  @override
  String get developer_clear_memory_success =>
      '¡Logs de memoria limpiados con éxito!';

  @override
  String get developer_clear_db_success =>
      '¡Logs de la base de datos limpiados con éxito!';

  @override
  String get developer_clear_all_success =>
      '¡Todos los logs limpiados con éxito!';

  @override
  String developer_clear_error(String error) {
    return 'Error al limpiar logs: $error';
  }

  @override
  String get developer_system_info => 'Información del sistema';

  @override
  String get developer_app_version => 'Versión de la app';

  @override
  String get developer_sdk_version => 'Versión del SDK';

  @override
  String get developer_balance => 'Saldo';

  @override
  String get developer_pending_balance => 'Saldo pendiente';

  @override
  String get developer_logs_memory => 'Logs (Memoria)';

  @override
  String get developer_logs_db => 'Logs (Base de datos)';

  @override
  String get developer_log_retention_label => 'Retención de logs';

  @override
  String get developer_tools_title => 'Herramientas';

  @override
  String get developer_tools_subtitle => 'Sincronización, logs y diagnósticos';

  @override
  String get developer_action_light_sync => 'Light Sync';

  @override
  String get developer_action_light_sync_tooltip =>
      'Sincronización rápida (transacciones, saldos, precios)';

  @override
  String get developer_action_full_sync => 'Full Sync';

  @override
  String get developer_action_full_sync_tooltip =>
      'Sincronización completa de la blockchain';

  @override
  String get developer_action_rescan => 'Rescan';

  @override
  String get developer_action_rescan_tooltip => 'Reescanear swaps onchain';

  @override
  String get developer_action_refund => 'Reembolso';

  @override
  String get developer_action_refund_tooltip => 'Ir a pantalla de reembolso';

  @override
  String get developer_action_view_logs => 'Ver Logs';

  @override
  String get developer_action_view_logs_tooltip => 'Ver logs de la aplicación';

  @override
  String get developer_action_export => 'Exportar';

  @override
  String get developer_action_export_tooltip => 'Exportar logs como ZIP';

  @override
  String get developer_action_clear_logs => 'Limpiar Logs';

  @override
  String get developer_action_clear_logs_tooltip => 'Limpiar todos los logs';

  @override
  String get export_logs_title => 'Exportar Logs';

  @override
  String get export_logs_description =>
      'Los logs de la aplicación ayudan a nuestro equipo a resolver problemas. ¿Cómo desea compartirlos?';

  @override
  String get export_logs_by_email => 'Enviar por correo electrónico';

  @override
  String get export_logs_share => 'Guardar/Compartir';

  @override
  String get clear_logs_title => 'Limpiar Logs';

  @override
  String get clear_logs_description => 'Elija qué desea limpiar:';

  @override
  String get clear_logs_option_memory => 'Memoria';

  @override
  String clear_logs_option_memory_desc(int count) {
    return 'Limpiar solo logs en memoria ($count logs)';
  }

  @override
  String get clear_logs_option_db => 'Base de datos';

  @override
  String clear_logs_option_db_desc(int count) {
    return 'Limpiar solo logs de la base de datos ($count logs)';
  }

  @override
  String get clear_logs_option_all => 'Todos';

  @override
  String get clear_logs_option_all_desc =>
      'Limpiar memoria, archivos y base de datos';

  @override
  String get clear_logs_cancel => 'Cancelar';

  @override
  String get logs_viewer_title => 'Logs de la aplicación';

  @override
  String get logs_viewer_loading => 'Cargando logs...';

  @override
  String get logs_viewer_empty => 'No se encontraron logs';

  @override
  String get logs_source_memory => 'Memoria';

  @override
  String get logs_source_database => 'Base de datos';

  @override
  String get logs_source_all => 'Todos';

  @override
  String get logs_filter_search_hint => 'Buscar logs...';

  @override
  String get logs_filter_all => 'Todos';

  @override
  String get logs_detail_level => 'Nivel';

  @override
  String get logs_detail_timestamp => 'Fecha/hora';

  @override
  String get logs_detail_message => 'Mensaje:';

  @override
  String get logs_detail_error_label => 'Error:';

  @override
  String get logs_detail_stack_trace => 'Stack Trace:';

  @override
  String get logs_detail_copy => 'Copiar log';

  @override
  String get logs_detail_copied => '¡Log copiado!';

  @override
  String get receive_title => 'Recibir Activos';

  @override
  String get receive_info_title => 'Cómo recibir activos';

  @override
  String get receive_info_step1_title => 'Selecciona el activo';

  @override
  String get receive_info_step1_desc =>
      'Elige qué criptomoneda quieres recibir';

  @override
  String get receive_info_step2_title => 'Elige la red';

  @override
  String get receive_info_step2_desc =>
      'Bitcoin (on-chain), Lightning o Liquid';

  @override
  String get receive_info_step3_title => 'Genera el código QR';

  @override
  String get receive_info_step3_desc =>
      'Comparte con quien te va a enviar el pago';

  @override
  String get receive_info_close_hint => 'Toca fuera de esta área para cerrar';

  @override
  String get receive_qr_title => 'Recibir Pago';

  @override
  String get receive_qr_amount_label => 'Monto:';

  @override
  String get receive_qr_description_label => 'Descripción:';

  @override
  String get receive_qr_lightning_invoice => 'Lightning Invoice';

  @override
  String get receive_qr_address_title => 'Dirección de Recepción';

  @override
  String get receive_qr_copy_address => 'Copiar Dirección';

  @override
  String get receive_qr_copied => '¡Copiado!';

  @override
  String receive_qr_error(String error) {
    return 'Error al generar QR: $error';
  }

  @override
  String get receive_network_bitcoin_onchain => 'Bitcoin On-chain';

  @override
  String get receive_network_lightning_network => 'Lightning Network';

  @override
  String get receive_network_liquid_network => 'Liquid Network';

  @override
  String get receive_network_unknown => 'Desconocida';

  @override
  String get receive_select_asset => 'Selecciona un activo';

  @override
  String get receive_select_network => 'Selecciona la red';

  @override
  String get receive_asset_hint_btc =>
      'Bitcoin on-chain es la única red disponible para BTC';

  @override
  String get receive_asset_hint_lbtc => 'Bitcoin L2 soporta Lightning y Liquid';

  @override
  String receive_asset_hint_liquid_only(String name) {
    return '$name solo soporta la red Liquid';
  }

  @override
  String get receive_lightning_amount_required_hint =>
      'Para Lightning, el monto es obligatorio';

  @override
  String get receive_select_asset_first => 'Selecciona un activo primero';

  @override
  String get receive_network_label_bitcoin => 'Bitcoin';

  @override
  String get receive_network_label_lightning => 'Lightning';

  @override
  String get receive_network_label_liquid => 'Liquid';

  @override
  String get receive_network_subtitle_onchain => 'On-chain';

  @override
  String get receive_network_subtitle_instant => 'Instantáneo';

  @override
  String get receive_network_subtitle_private => 'Privado';

  @override
  String get receive_amount_label => 'Monto';

  @override
  String get receive_amount_hint_required => 'Ingresa el monto (obligatorio)';

  @override
  String get receive_amount_hint_optional => 'Ingresa el monto (opcional)';

  @override
  String get receive_amount_helper_disabled =>
      'Selecciona un activo y red primero';

  @override
  String get receive_amount_helper_lightning =>
      'Monto obligatorio para Lightning';

  @override
  String get receive_amount_helper_optional =>
      'Monto opcional para Bitcoin/Liquid';

  @override
  String get receive_amount_sats_label => 'Monto en Satoshis:';

  @override
  String get receive_lightning_limits_unavailable =>
      'No se pudieron cargar los límites de Lightning';

  @override
  String receive_lightning_min_value(String amount) {
    return 'Mínimo: $amount sats';
  }

  @override
  String receive_lightning_max_value(String amount) {
    return 'Máximo: $amount sats';
  }

  @override
  String get receive_lightning_valid => 'Monto válido para Lightning';

  @override
  String get receive_lightning_limits_loading =>
      'Cargando límites Lightning...';

  @override
  String get receive_lightning_limits_error =>
      'Error al cargar límites Lightning';

  @override
  String get receive_bitcoin_valid => 'Monto válido para Bitcoin';

  @override
  String get receive_liquid_valid => 'Monto válido para Liquid';

  @override
  String get receive_description_label => 'Descripción (opcional)';

  @override
  String get receive_description_hint => 'Ej: Pago del almuerzo';

  @override
  String get receive_generate_qr => 'Generar factura';

  @override
  String get receive_select_asset_network => 'Selecciona un activo y red';

  @override
  String get receive_conversion_loading => 'Cargando conversiones...';

  @override
  String get receive_conversion_equivalent => 'Conversiones equivalentes:';

  @override
  String get receive_satoshis_label => 'Satoshis:';

  @override
  String get wallet_title => 'Mi Billetera';

  @override
  String get wallet_assets_tab => 'Activos';

  @override
  String get wallet_balance_available => 'Saldo disponible:';

  @override
  String get wallet_send => 'Enviar';

  @override
  String get wallet_receive => 'Recibir';

  @override
  String get wallet_send_title => 'Revisar Transacción';

  @override
  String get wallet_send_all_title => 'Revisar Envío Total';

  @override
  String get wallet_send_calculating_total => 'Calculando envío total...';

  @override
  String get wallet_send_preparing => 'Preparando transacción...';

  @override
  String get wallet_send_prepare_error => 'Error al preparar la transacción';

  @override
  String get wallet_send_dust_warning =>
      'Hay problemas con esta transacción. Verifica los datos.';

  @override
  String get wallet_send_all_info =>
      'Enviando todos los fondos disponibles. Las tarifas se descontarán automáticamente del total.';

  @override
  String get wallet_send_destination_network => 'Red de Destino';

  @override
  String get wallet_send_destination_address => 'Dirección de Destino';

  @override
  String get wallet_send_fee_details => 'Detalle de Tarifas';

  @override
  String get wallet_send_network_fee => 'Tarifa de Red';

  @override
  String get wallet_send_service_fee => 'Tarifa de Servicio';

  @override
  String get wallet_send_total_fees => 'Tarifas Totales';

  @override
  String get wallet_send_free => 'Gratis';

  @override
  String get wallet_send_loading_price => 'Cargando precio...';

  @override
  String get wallet_send_calc_value_error => 'Error al calcular el monto';

  @override
  String get wallet_send_calculating_value => 'Calculando monto...';

  @override
  String get wallet_send_tx_error_title => 'Error en la Transacción';

  @override
  String get wallet_send_tx_error_desc => 'No se pudo enviar la transacción:';

  @override
  String get wallet_send_tx_error_check =>
      'Verifica los datos e inténtalo de nuevo.';

  @override
  String wallet_send_wallet_error(String description) {
    return 'Error al acceder a la billetera: $description';
  }

  @override
  String get wallet_send_send_all_label => 'Enviar Todo';

  @override
  String wallet_send_asset_label(String asset) {
    return 'Enviar $asset';
  }

  @override
  String get wallet_onchain_network => 'Bitcoin On-chain';

  @override
  String get wallet_amount => 'Monto';

  @override
  String get wallet_network_fee => 'Tarifa de red';

  @override
  String get wallet_total => 'Total';

  @override
  String get wallet_destination => 'Destino';

  @override
  String get wallet_fee_calculated_note =>
      'La tarifa se calculó según la velocidad seleccionada.';

  @override
  String get wallet_slide_to_confirm => 'Desliza para confirmar';

  @override
  String get wallet_speed_economic => 'Económica';

  @override
  String get wallet_speed_economic_desc =>
      'Confirmación más lenta, tarifa menor';

  @override
  String get wallet_speed_normal => 'Normal';

  @override
  String get wallet_speed_normal_desc => 'Equilibrio entre velocidad y costo';

  @override
  String get wallet_speed_priority => 'Prioritaria';

  @override
  String get wallet_speed_priority_desc =>
      'Confirmación más rápida, tarifa mayor';

  @override
  String wallet_speed_label(String speed) {
    return 'Velocidad: $speed';
  }

  @override
  String get wallet_tx_not_found => 'Transacción no encontrada';

  @override
  String get wallet_tx_not_found_error => 'Error: transacción no encontrada';

  @override
  String wallet_send_tx_error(String error) {
    return 'Error al enviar la transacción: $error';
  }

  @override
  String get wallet_fee_speed_title => 'Velocidad de la transacción';

  @override
  String get wallet_fee_economic => 'Económica';

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
  String get tx_confirmed_title => '¡Transacción Confirmada!';

  @override
  String tx_received_asset(String ticker) {
    return 'Recibiste $ticker';
  }

  @override
  String get tx_received => 'Recibido';

  @override
  String get tx_id => 'ID de Transacción';

  @override
  String get tx_back_to_dashboard => 'Volver al panel';

  @override
  String get tx_history_title => 'Historial de transacciones';

  @override
  String get tx_history_pix_title => 'Historial de PIX';

  @override
  String get tx_detail_title => 'Detalles de la Transacción';

  @override
  String get tx_detail_swap_unfinished => 'Swap no completado';

  @override
  String get tx_detail_swap_refunded => 'Swap reembolsado';

  @override
  String get tx_detail_refund_available_msg =>
      'Esta transacción no se completó con éxito. Tus fondos están seguros y disponibles para reembolso. Usa el botón de abajo para solicitarlo.';

  @override
  String get tx_detail_refund_processed_msg =>
      'El reembolso de esta transacción ya fue procesado o se está enviando. Tus fondos serán devueltos en breve.';

  @override
  String get tx_filter_title => 'Filtros';

  @override
  String get tx_filter_sort_by => 'Ordenar por';

  @override
  String get tx_filter_type => 'Tipo de transacción';

  @override
  String get tx_filter_status => 'Estado';

  @override
  String get tx_filter_currency => 'Moneda';

  @override
  String get tx_filter_period => 'Período';

  @override
  String get tx_filter_period_custom => 'Período personalizado';

  @override
  String get tx_filter_clear_period => 'Borrar período';

  @override
  String get tx_filter_clear_filters => 'Borrar filtros';

  @override
  String get tx_filter_apply => 'Aplicar filtros';

  @override
  String get tx_type_all => 'Todas';

  @override
  String get tx_type_send => 'Envío';

  @override
  String get tx_type_receive => 'Recepción';

  @override
  String get tx_type_swap => 'Swap';

  @override
  String get tx_status_all => 'Todos';

  @override
  String get tx_status_pending => 'Pendiente';

  @override
  String get tx_status_confirmed => 'Confirmado';

  @override
  String get tx_status_failed => 'Falló';

  @override
  String get tx_status_refundable => 'Reembolsable';

  @override
  String get wallet_errors_insufficient_funds =>
      'Fondos insuficientes en la billetera.';

  @override
  String get wallet_errors_invalid_address => 'Dirección inválida.';

  @override
  String get wallet_errors_connection_failed => 'Falló la conexión.';

  @override
  String get wallet_errors_tx_cannot_finalize =>
      'La transacción no puede finalizarse.';

  @override
  String get wallet_errors_invalid_asset => 'Activo inválido.';

  @override
  String get wallet_errors_invalid_amount => 'Monto inválido.';

  @override
  String get wallet_errors_connection => 'Error de conexión';

  @override
  String get wallet_errors_internal => 'Error interno';

  @override
  String get swap_title => 'Swap';

  @override
  String get swap_you_send => 'Tú envías';

  @override
  String get swap_you_receive => 'Tú recibes';

  @override
  String swap_rate_line(String from, String rate, String to) {
    return '1 $from = $rate $to';
  }

  @override
  String get swap_insufficient_balance =>
      'Saldo insuficiente para realizar el swap';

  @override
  String get swap_updating_quote => 'Actualizando cotización...';

  @override
  String swap_min_value_sats(String sats) {
    return 'Valor mínimo: $sats sats';
  }

  @override
  String swap_min_amount_sats(String sats) {
    return 'Cantidad mínima: $sats sats';
  }

  @override
  String get swap_no_liquidity_title => 'Sin Liquidez';

  @override
  String get swap_no_liquidity_body =>
      'En este momento no hay liquidez disponible en Sideswap para realizar esta operación.';

  @override
  String get swap_use_asset_value => 'Usar monto en activo';

  @override
  String swap_use_currency_value(String currency) {
    return 'Usar monto en $currency';
  }

  @override
  String get swap_confirm_title => 'Confirmar Swap';

  @override
  String get swap_confirm_estimate => 'Estimación';

  @override
  String get swap_confirm_sending => 'Enviando:';

  @override
  String get swap_confirm_boltz_fee => 'Tarifa de servicio Boltz:';

  @override
  String get swap_confirm_tx_fee => 'Tarifa de transacción:';

  @override
  String get swap_confirm_total_fees => 'Tarifas totales:';

  @override
  String get swap_confirm_receiving => 'Recibiendo:';

  @override
  String get swap_confirm_server_fee => 'Tarifa del servidor';

  @override
  String get swap_confirm_fixed_fee => 'Tarifa fija';

  @override
  String get swap_confirm_total_fees_short => 'Tarifas totales';

  @override
  String swap_confirm_error(String error) {
    return 'Error al confirmar: $error';
  }

  @override
  String get pix_confirm_title => 'Confirmar transacción';

  @override
  String get pix_generating_qr => 'Generando código QR...';

  @override
  String get pix_processing_unavailable =>
      'No es posible procesar transacciones PIX en este momento. Inténtalo más tarde.';

  @override
  String get pix_select_asset => 'Selecciona un activo';

  @override
  String get pix_floating_rate_title => 'Tipo de Cambio Flotante';

  @override
  String get pix_floating_rate_body =>
      'Importante: el LBTC tiene variación de precio.\nPor eso, el monto en BRL que recibes puede diferir del esperado.\nLa conversión a BRL usa el tipo de cambio al momento de la finalización.';

  @override
  String get pix_dont_show_again => 'No volver a mostrar';

  @override
  String get pix_disclaimer_header => 'Para una mejor experiencia con PIX:';

  @override
  String get pix_disclaimer_max_consecutive =>
      'Máx. 3 PIX consecutivos del mismo titular en 30 min.';

  @override
  String get pix_disclaimer_daily_limit =>
      'Límite R\$ 5.000/día por titular (nivel bancario).';

  @override
  String get pix_disclaimer_outside_rules =>
      'Las transferencias fuera de las reglas se devuelven al pagador.';

  @override
  String get pix_disclaimer_analyzed =>
      'El 100% de los PIX son analizados por infraestructura conjunta — reembolso automático si se sospecha automatización.';

  @override
  String get pix_disclaimer_avg_time =>
      'Tiempo medio: 5 a 25 min. PIX con señales de riesgo bancario: 3–7 días hábiles (reembolsable).';

  @override
  String get pix_deposit_title => 'Detalles del Depósito PIX';

  @override
  String get pix_deposit_label => 'Depósito PIX';

  @override
  String get pix_deposit_date => 'Fecha';

  @override
  String get pix_deposit_target_asset => 'Activo de destino';

  @override
  String get pix_deposit_value => 'Monto';

  @override
  String get pix_deposit_pix_key => 'Clave PIX';

  @override
  String get pix_deposit_id => 'ID del Depósito';

  @override
  String get pix_deposit_received_value => 'Monto recibido';

  @override
  String get pix_deposit_tx_id => 'TX ID';

  @override
  String get pix_deposit_expired => 'Plazo vencido';

  @override
  String get pix_deposit_time_remaining => 'Tiempo restante para pagar';

  @override
  String get pix_deposit_invalid => 'Este PIX ya no es válido';

  @override
  String get pix_deposit_info => 'Información';

  @override
  String get pix_deposit_view_explorer => 'Ver en el Explorer';

  @override
  String get pix_deposit_view_chain => 'Ver en la blockchain';

  @override
  String get human_verif_title => 'Verificación de Humanidad';

  @override
  String get human_verif_intro_title => 'Verifica que eres humano';

  @override
  String get human_verif_intro_body =>
      'Para garantizar la seguridad de la plataforma, debemos verificar que eres una persona real.';

  @override
  String get human_verif_step1_title => 'Pago simbólico';

  @override
  String get human_verif_step1_desc =>
      'Realizarás un PIX de R\$ 1,00 a nuestra clave. El monto se devolverá inmediatamente después del pago.';

  @override
  String get human_verif_step2_title => 'Recibe el código';

  @override
  String get human_verif_step2_desc =>
      'Recibirás el monto de vuelta junto con un código único en el mensaje.';

  @override
  String get human_verif_step3_title => 'Valida tu identidad';

  @override
  String get human_verif_step3_desc =>
      'Ingresa el código recibido para confirmar que eres humano.';

  @override
  String get human_verif_payment_title => 'Pago de Verificación';

  @override
  String get human_verif_time_remaining_prefix => 'Tienes ';

  @override
  String get human_verif_minutes_and => 'minutos y ';

  @override
  String get human_verif_seconds => 'segundos ';

  @override
  String get human_verif_to_pay => 'para completar el pago.';

  @override
  String get human_verif_pix_key => 'Clave PIX';

  @override
  String get human_verif_time_expired_title => 'Tiempo Agotado';

  @override
  String get human_verif_time_expired_body =>
      'El plazo para realizar el pago ha expirado. Inténtalo de nuevo.';

  @override
  String get human_verif_after_payment =>
      'Después del pago, recibirás un código en el mensaje del PIX de retorno.';

  @override
  String get human_verif_already_paid => 'Ya hice el pago';

  @override
  String get human_verif_code_title => 'Validar Código';

  @override
  String get human_verif_code_prompt_prefix => 'Ingresa el ';

  @override
  String get human_verif_code_word => 'código';

  @override
  String get human_verif_code_body =>
      'Ingresa el código de 6 dígitos que recibiste en el mensaje del PIX de retorno.';

  @override
  String get human_verif_code_invalid => 'Código inválido. Inténtalo de nuevo.';

  @override
  String get human_verif_code_help =>
      'Verifica el campo de mensaje del PIX que recibiste de vuelta.';

  @override
  String get human_verif_back_to_payment => 'Volver al pago';

  @override
  String get phone_verif_title => 'Verificación';

  @override
  String get phone_verif_humanity_title => 'Verificación de Humanidad';

  @override
  String get phone_verif_humanity_body =>
      'Para garantizar la seguridad, debemos confirmar que eres una persona real. El número de teléfono solo se usará para enviar un código de verificación. Ningún dato será almacenado ni vinculado a tu billetera.';

  @override
  String get phone_verif_method_title => 'Elegir Método';

  @override
  String get phone_verif_inform_prefix => 'Indica tu ';

  @override
  String get phone_verif_phone_number => 'número de teléfono';

  @override
  String get phone_verif_method_subtitle =>
      'Elige cómo deseas recibir el código de verificación';

  @override
  String get phone_verif_number_label => 'Número';

  @override
  String get phone_verif_number_hint => 'Ingresa tu número';

  @override
  String get phone_verif_send_code => 'Enviar código';

  @override
  String get phone_verif_code_title => 'Confirmar Código';

  @override
  String get phone_verif_code_prompt_prefix => 'Ingresa el ';

  @override
  String get phone_verif_code_word => 'código recibido';

  @override
  String phone_verif_code_body(String phone) {
    return 'Enviamos un código de 6 dígitos al $phone vía Telegram.';
  }

  @override
  String get phone_verif_verify => 'Verificar';

  @override
  String phone_verif_resend_in(String seconds) {
    return 'Reenviar en 00:$seconds';
  }

  @override
  String get phone_verif_resend_code => 'Reenviar código';

  @override
  String get refund_screen_title => 'Reembolso de Transacción';

  @override
  String get refund_available_title => 'Reembolsos Disponibles';

  @override
  String refund_retry_progress(int current, int max) {
    return 'Intento $current de $max';
  }

  @override
  String get refund_loading_long => 'Espera, esto puede demorar un poco...';

  @override
  String get refund_empty_title => 'Sin Reembolsos Disponibles';

  @override
  String get refund_empty_body =>
      'No tienes transacciones pendientes de reembolso.';

  @override
  String get refund_pull_to_refresh => 'Desliza hacia abajo para actualizar';

  @override
  String get refund_speed_title => 'Velocidad de la Transacción';

  @override
  String get refund_insufficient_for_fee =>
      'Fondos insuficientes para cubrir la tarifa de transacción';

  @override
  String refund_fee_load_error(String error) {
    return 'Error al obtener tarifas: $error';
  }

  @override
  String get refund_calculating_fees => 'Calculando tarifas...';

  @override
  String get refund_amount_too_small =>
      'Monto demasiado pequeño para cubrir las tarifas de transacción';

  @override
  String get refund_confirm_button => 'Confirmar Reembolso';

  @override
  String refund_process_error(String error) {
    return 'Error al procesar el reembolso: $error';
  }

  @override
  String get refund_none_found => 'No se encontraron swaps reembolsables';

  @override
  String get refund_details_title => 'Detalles del Reembolso';

  @override
  String get refund_auto_send_info =>
      'No te preocupes, el reembolso en Bitcoin se enviará automáticamente a la dirección de tu billetera.';

  @override
  String get refund_info_title => 'Información del Reembolso';

  @override
  String get refund_label_amount => 'Valor';

  @override
  String get refund_label_transaction => 'Transacción';

  @override
  String get refund_label_date => 'Fecha';

  @override
  String get refund_label_refund_amount => 'Valor del Reembolso';

  @override
  String get refund_address_label => 'Dirección Bitcoin';

  @override
  String get refund_address_hint => 'Ingresa la dirección Bitcoin';

  @override
  String get refund_address_required =>
      'Por favor, ingresa una dirección Bitcoin';

  @override
  String get refund_address_invalid => 'Dirección Bitcoin inválida';

  @override
  String get refund_address_invalid_long =>
      'Dirección Bitcoin inválida. Usa una dirección válida (ej: 1..., 3..., bc1...)';

  @override
  String get refund_status_pending => 'Pendiente';

  @override
  String get refund_status_available => 'Disponible';

  @override
  String get refund_action_retransmit => 'Retransmitir';

  @override
  String get refund_speed_select_title =>
      'Selecciona la velocidad de la transacción';

  @override
  String get refund_amount_too_small_short =>
      'Monto demasiado pequeño para cubrir las tarifas';

  @override
  String get refund_fee_label_economy => 'Economía';

  @override
  String get refund_fee_label_standard => 'Estándar';

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
    return 'Tarifa: $rate sat/vB';
  }

  @override
  String refund_fee_total(String amount) {
    return 'Total: $amount sats';
  }

  @override
  String get refund_success_title => '¡Reembolso Iniciado!';

  @override
  String get refund_success_body =>
      'Tu reembolso ha sido procesado con éxito. Pronto los fondos estarán disponibles en la dirección informada.';

  @override
  String get refund_success_amount_label => 'Valor Reembolsado';

  @override
  String get refund_success_txid_label => 'Transaction ID';

  @override
  String get refund_success_back_dashboard => 'Volver al Dashboard';

  @override
  String get refund_test_title => '🧪 Prueba de Refund';

  @override
  String get refund_test_heading => 'Modo de Prueba - Refund';

  @override
  String get refund_test_description =>
      'Usa esta pantalla para probar el flujo completo de refund con datos simulados, sin necesidad de transacciones reales.';

  @override
  String get refund_test_button_mock => 'Probar con Datos Mock';

  @override
  String get refund_test_button_real_sdk => 'Probar con SDK Real';

  @override
  String get refund_test_mock_data_title => 'Datos Mock Incluidos';

  @override
  String get refund_test_mock_item_swaps => '• 3 swaps reembolsables';

  @override
  String get refund_test_mock_item_amounts =>
      '• Valores: 0.001, 0.0025, 0.0005 BTC';

  @override
  String get refund_test_mock_item_fees => '• 4 opciones de tarifa diferentes';

  @override
  String get refund_test_mock_item_address => '• Dirección Bitcoin pre-llenada';

  @override
  String get refund_test_mock_item_success =>
      '• Simula éxito en el 90% de los casos';

  @override
  String get refund_test_advanced_title => '🧪 Prueba de Refund Avanzada';

  @override
  String get refund_test_clear_tooltip => 'Limpiar transacciones mock';

  @override
  String get refund_test_cleared_snack => 'Transacciones mockeadas eliminadas';

  @override
  String get refund_test_advanced_heading =>
      'Prueba de Refund con\nTransacciones Reales';

  @override
  String get refund_test_advanced_description =>
      'Simula transacciones Peg In refundables basadas en\ndatos reales para probar el flujo completo de reembolso.';

  @override
  String get refund_test_load_mock_button => 'Cargar Transacciones Mock';

  @override
  String refund_test_loaded_snack(int count) {
    return '$count transacciones mockeadas cargadas';
  }

  @override
  String refund_test_mock_list_title(int count) {
    return 'Transacciones Mockeadas ($count)';
  }

  @override
  String get refund_test_flow_button => 'Probar Flujo de Refund (Mock SDK)';

  @override
  String get refund_test_real_tx_title => 'Sobre la Transacción Real';

  @override
  String get refund_test_real_tx_type => '🔹 Tipo: Peg In (BTC → LBTC)';

  @override
  String get refund_test_real_tx_id => '🔹 TX ID: 5e2159e9b5fbf7023b2800...';

  @override
  String get refund_test_real_tx_sent =>
      '🔹 Valor enviado: 52574 sats (402 sats de tarifa)';

  @override
  String get refund_test_real_tx_expected =>
      '🔹 Valor esperado: 52172 sats (LBTC)';

  @override
  String get refund_test_real_tx_date => '🔹 Fecha: 04/02/2026 a las 00:17:10';

  @override
  String get refund_test_real_tx_lockup =>
      '🔹 Lockup TX: 2622dd4f5a1c69f7cea5...';

  @override
  String get refund_test_real_tx_address =>
      '🔹 Dirección: bc1p62e2r4jnr3v985uqk...';

  @override
  String get refund_test_real_tx_warning =>
      'Status: REFUNDABLE\nEsta transacción falló y los fondos pueden ser reembolsados a la dirección Bitcoin original.';

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
  String get qr_scanner_searching => 'Buscando QR Code...';

  @override
  String get qr_scanner_found => '¡QR Code encontrado!';

  @override
  String get qr_scanner_position_hint =>
      'Coloca el QR dentro del área destacada';

  @override
  String get qr_scanner_supported_networks => 'Bitcoin • Lightning • Liquid';

  @override
  String get qr_scanner_flash_label => 'Flash';

  @override
  String get qr_scanner_camera_label => 'Cámara';

  @override
  String get qr_validation_empty => 'QR code vacío';

  @override
  String get qr_validation_unrecognized => 'Formato de QR code no reconocido';

  @override
  String get qr_validation_lightning_unsupported_symbols =>
      'Lightning con símbolos especiales (₿, #, \$) no es compatible';

  @override
  String get qr_validation_lnurl_bip353_unsupported =>
      'Formato LNURL BIP 353 no es compatible por ahora. Usa una dirección Lightning válida o LNURL de walletofsatoshi.com';

  @override
  String get qr_validation_boltz_invalid => 'Invoice BOLTZ inválido';

  @override
  String get qr_validation_boltz_no_amount =>
      'Invoice BOLTZ sin valor no es compatible. Por favor, genera un invoice con valor definido';

  @override
  String get qr_validation_liquid_invalid =>
      'Dirección Liquid inválida en el QR code';

  @override
  String get qr_validation_liquid_format_error =>
      'Error al procesar QR Liquid: formato inválido';

  @override
  String get qr_validation_bitcoin_invalid =>
      'Dirección Bitcoin inválida en el QR code';

  @override
  String get qr_validation_bitcoin_format_error =>
      'Error al procesar QR Bitcoin: formato inválido';

  @override
  String get qr_validation_lightning_too_short =>
      'Lightning invoice demasiado corto';

  @override
  String get qr_validation_lnurl_unsupported =>
      'LNURL no compatible. Usa walletofsatoshi.com u otro proveedor compatible';

  @override
  String get qr_validation_invalid_default => 'QR code inválido';

  @override
  String get tx_sent_title => '¡Transacción Enviada!';

  @override
  String tx_sent_subtitle(String ticker) {
    return 'Tu $ticker fue enviado con éxito';
  }

  @override
  String get tx_sent_status_label => 'Enviado';

  @override
  String get tx_sent_track_history =>
      'Puedes seguir el estado en la sección de historial.';

  @override
  String get setup_first_access_title => '¿Cómo quieres comenzar?';

  @override
  String get setup_first_access_subtitle =>
      'Puedes crear una nueva billetera protegida por ti, o importar una existente con tu clave.';

  @override
  String get setup_create_wallet_appbar => 'Crear billetera';

  @override
  String get setup_seed_length_title => 'Selecciona el tamaño de la ';

  @override
  String get setup_seed_length_highlight => 'frase semilla';

  @override
  String get setup_seed_length_subtitle =>
      'Puedes crear tu billetera con 12 o 24 palabras. Ambas son seguras, pero cada opción tiene su nivel de practicidad y protección.';

  @override
  String get setup_seed_12_title => '12 Palabras';

  @override
  String get setup_seed_12_desc =>
      'Más práctica y rápida de configurar. Recomendada\npara principiantes o quienes prefieren simplicidad sin\nrenunciar a la seguridad.';

  @override
  String get setup_seed_24_title => '24 Palabras (recomendado)';

  @override
  String get setup_seed_24_desc =>
      'Brinda más seguridad. Recomendada para\nquienes desean proteger valores mayores o buscan\nla máxima seguridad.';

  @override
  String get setup_generate_seed_button => 'Generar frase de recuperación';

  @override
  String get setup_confirm_seed_appbar => 'Confirma tu frase';

  @override
  String get setup_confirm_seed_title => 'Confirmación de ';

  @override
  String get setup_confirm_seed_highlight => 'Seguridad';

  @override
  String get setup_confirm_seed_subtitle =>
      'Selecciona las palabras en el orden correcto para confirmar tu frase de recuperación.';

  @override
  String get setup_confirm_seed_error =>
      'Una o más palabras son incorrectas. Intenta de nuevo.';

  @override
  String setup_seed_word_label(int position) {
    return 'Palabra #$position: ';
  }

  @override
  String get setup_import_appbar => 'Importar Billetera';

  @override
  String get setup_import_restart_tooltip => 'Reiniciar';

  @override
  String get setup_import_instruction_title =>
      'Ingresa tu frase de recuperación';

  @override
  String get setup_import_instruction_body =>
      'Ingresa cada palabra de tu seed phrase (12 o 24 palabras). El sistema ofrecerá sugerencias BIP39 mientras escribes. Presiona espacio o toca para confirmar cada palabra.';

  @override
  String get setup_import_seed_valid =>
      '¡Seed phrase válida! Lista para importar.';

  @override
  String get setup_import_checksum_invalid =>
      'Checksum inválido. Verifica las palabras.';

  @override
  String get setup_import_tip =>
      'Tip: Presiona espacio para confirmar la primera sugerencia rápidamente';

  @override
  String get setup_import_button => 'Importar Billetera';

  @override
  String get setup_import_cleanup_warning =>
      'Aviso: Algunos archivos antiguos no se pudieron eliminar. La app puede necesitar reiniciarse.';

  @override
  String get setup_clipboard_detected_title => 'Frase semilla detectada';

  @override
  String get setup_clipboard_detected_body =>
      'Detectamos una frase en el portapapeles';

  @override
  String get setup_clipboard_paste_button => 'Pegar';

  @override
  String get setup_clipboard_ignore_button => 'Ignorar';

  @override
  String setup_input_hint_press_space(String word) {
    return 'Presiona espacio para confirmar \"$word\"';
  }

  @override
  String get setup_input_hint_default => 'Escribe una palabra BIP39...';

  @override
  String get setup_progress_label => 'Progreso';

  @override
  String setup_progress_count(int count, int target) {
    return '$count/$target palabras';
  }

  @override
  String setup_seed_invalid_word(String word) {
    return 'Palabra inválida: $word';
  }

  @override
  String setup_seed_wrong_count(int count) {
    return 'La frase debe tener 12, 15, 18, 21 o 24 palabras. Encontradas: $count';
  }

  @override
  String setup_seed_invalid_words_list(String list) {
    return 'Palabras inválidas: $list';
  }

  @override
  String get setup_seed_invalid_checksum =>
      'Frase inválida. Verifica el checksum.';

  @override
  String get wallet_import_msg_processing => 'Procesando...';

  @override
  String get wallet_import_msg_verifying => 'Verificando datos...';

  @override
  String get wallet_import_msg_initializing => 'Inicializando billetera...';

  @override
  String get wallet_import_phase_platform => 'Inicializando plataforma...';

  @override
  String get wallet_import_phase_database => 'Preparando base de datos...';

  @override
  String get wallet_import_phase_credentials => 'Cargando credenciales...';

  @override
  String get wallet_import_phase_connecting => 'Conectando a las redes...';

  @override
  String get wallet_import_phase_authenticating => 'Autenticando sesión...';

  @override
  String get wallet_import_phase_finalizing => 'Finalizando billetera...';

  @override
  String get wallet_import_msg_loading_balances => 'Cargando saldos...';

  @override
  String get wallet_import_msg_loading_transactions =>
      'Cargando transacciones...';

  @override
  String get wallet_import_msg_completed => 'Importación completada ✓';

  @override
  String wallet_import_msg_synced(String name) {
    return '$name sincronizado ✓';
  }

  @override
  String wallet_import_msg_resynced(String name) {
    return '$name - resincronizando...';
  }

  @override
  String get wallet_import_datasource_liquid => 'Liquid Network';

  @override
  String get wallet_import_datasource_bitcoin => 'Bitcoin';

  @override
  String get wallet_import_datasource_lightning => 'Lightning';

  @override
  String get wallet_import_error_reconnecting => 'Intentando reconectar...';

  @override
  String get wallet_import_error_load_data => 'Error al cargar datos';

  @override
  String get wallet_import_error_connection => 'Error de conexión';

  @override
  String get wallet_import_error_servers =>
      'Error al conectar con los servidores';

  @override
  String get wallet_import_error_servers_unavailable =>
      'Servidores no disponibles';

  @override
  String get wallet_import_error_generic => 'Error en la importación';

  @override
  String get wallet_import_error_occurred => 'Ocurrió un error';

  @override
  String wallet_import_error_reconnecting_count(String current, String max) {
    return 'Reconectando ($current/$max)';
  }

  @override
  String get wallet_import_error_reconnecting_servers =>
      'Intentando reconectar a los servidores...';

  @override
  String get wallet_import_error_no_connection =>
      'No se pudo conectar con los servidores.\nVerifica tu conexión e intenta de nuevo.';

  @override
  String get wallet_import_error_servers_long =>
      'Error al conectar con los servidores.\nIntenta de nuevo.';

  @override
  String get wallet_import_error_internet =>
      'Error de conexión.\nVerifica tu internet.';

  @override
  String get wallet_import_error_wallet_data =>
      'Error al cargar datos de la billetera.';

  @override
  String get wallet_import_error_unknown => 'Error desconocido';

  @override
  String get send_pix_appbar => 'Enviar PIX';

  @override
  String get send_pix_qr_title => 'Escanear QR Code PIX';

  @override
  String get send_pix_empty_key_error => 'Escribe o escanea una clave PIX';

  @override
  String get send_pix_insert_key => 'Ingresa la clave PIX';

  @override
  String get send_pix_paste_or_scan => 'Pega la clave o escanea el QR Code';

  @override
  String get send_pix_key_label => 'Clave PIX';

  @override
  String get send_pix_key_hint => 'ejemplo@email.com o clave aleatoria';

  @override
  String get send_pix_accepted_types => 'Tipos de clave aceptados:';

  @override
  String get send_pix_type_email => 'Correo';

  @override
  String get send_pix_type_phone => 'Teléfono';

  @override
  String get send_pix_type_cpf_cnpj => 'CPF/CNPJ';

  @override
  String get send_pix_type_random => 'Clave aleatoria';

  @override
  String get send_pix_lightning_info =>
      'Pago instantáneo usando Lightning Network';

  @override
  String get swap_success_title => '¡Swap Realizado!';

  @override
  String get swap_success_body =>
      'Tu transacción fue procesada con éxito, en instantes el saldo estará disponible en tu billetera.';

  @override
  String get swap_success_dialog_txid_copied => '¡TX ID copiado!';

  @override
  String get send_pix_success_title => '¡PIX Enviado!';

  @override
  String get send_pix_success_body => '¡Tu pago PIX fue realizado con éxito!';

  @override
  String get send_pix_success_value_sent => 'Valor enviado';

  @override
  String get send_pix_success_recipient_info =>
      'El destinatario ya puede verificar la recepción del PIX.';

  @override
  String get pix_deposit_status_pending_label => 'Pago Pendiente';

  @override
  String get pix_deposit_status_under_review_label => 'Revisión bancaria';

  @override
  String get pix_deposit_status_processing_1_2_label => 'Procesando 1/2';

  @override
  String get pix_deposit_status_under_analysis_label => 'En análisis';

  @override
  String get pix_deposit_status_processing_2_2_label => 'Procesando 2/2';

  @override
  String get pix_deposit_status_finished_label => 'Enviado';

  @override
  String get pix_deposit_status_expired_label => 'Expirado';

  @override
  String get pix_deposit_status_refunded_label => 'Pago reembolsado';

  @override
  String get pix_deposit_status_med_label => 'Disputado - MED';

  @override
  String get pix_deposit_status_processing_refund_1_2_label =>
      'Reembolsando 1/2';

  @override
  String get pix_deposit_status_processing_refund_2_2_label =>
      'Reembolsando 2/2';

  @override
  String get pix_deposit_status_completed_label => 'Completado';

  @override
  String get pix_deposit_status_unknown_label => 'Revisión manual';

  @override
  String get pix_deposit_status_pending_plural => 'Pagos Pendientes';

  @override
  String get pix_deposit_status_under_review_plural => 'En Análisis';

  @override
  String get pix_deposit_status_processing_plural => 'Procesando';

  @override
  String get pix_deposit_status_in_transit_plural => 'En camino';

  @override
  String get pix_deposit_status_under_analysis_plural => 'En análisis';

  @override
  String get pix_deposit_status_finished_plural => 'Enviados';

  @override
  String get pix_deposit_status_expired_plural => 'Expirados';

  @override
  String get pix_deposit_status_refunded_plural => 'Pagos reembolsados';

  @override
  String get pix_deposit_status_processing_refunds_plural =>
      'Procesando reembolsos';

  @override
  String get pix_deposit_status_completed_plural => 'Completados';

  @override
  String get swap_error_processing =>
      'Espera unos instantes antes de hacer otro swap. Tu transacción anterior aún se está procesando.';

  @override
  String swap_error_insufficient_balance_detailed(int available, int required) {
    return 'Saldo insuficiente para este swap. Disponible: $available sats. Necesario (enviado + tarifas): $required sats.';
  }

  @override
  String get swap_error_no_active_quote => 'Ninguna cotización activa';

  @override
  String get swap_error_timeout =>
      'Timeout: La operación tardó demasiado. Intenta de nuevo.';

  @override
  String swap_error_unexpected(String error) {
    return 'Error inesperado: $error';
  }

  @override
  String get tx_refund_failed_title => 'Transacción Fallida';

  @override
  String get tx_refund_failed_body =>
      'Tu transacción de peg-in no pudo completarse. Al hacer clic en OK, tus bitcoins serán devueltos a tu billetera onchain.';

  @override
  String get tx_refund_status_label => 'Estado';

  @override
  String get tx_refund_status_failed => 'Fallida';

  @override
  String get tx_refund_address_label => 'Dirección Bitcoin para Reembolso';

  @override
  String get tx_refund_address_hint => 'Ingresa la dirección Bitcoin';

  @override
  String get tx_refund_address_auto =>
      'Dirección generada automáticamente desde tu billetera';

  @override
  String get tx_refund_fees_fallback_warning =>
      'Usando tarifas estimadas (API temporalmente no disponible)';

  @override
  String get tx_refund_screen_deprecated =>
      'Esta pantalla está obsoleta. Por favor, usa el nuevo flujo de reembolso.';

  @override
  String get tx_refund_dialog_title => 'Reembolso Iniciado';

  @override
  String get tx_refund_dialog_body => '¡Tu reembolso fue procesado con éxito!';

  @override
  String get tx_refund_dialog_txid_label => 'TX ID:';

  @override
  String get human_verif_success_title => '¡Humanidad Confirmada!';

  @override
  String get human_verif_success_body =>
      'Tu identidad fue verificada con éxito. Ahora puedes usar todos los recursos de la plataforma.';

  @override
  String get human_verif_success_card_title => 'Verificación completa';

  @override
  String get human_verif_success_card_body => 'Eres una persona real';

  @override
  String get human_verif_success_refund_info =>
      'Tu PIX de R\$ 1,00 fue devuelto con éxito.';

  @override
  String get pix_received_title => '¡PIX Recibido!';

  @override
  String get pix_received_body => 'Tu depósito está siendo procesado';

  @override
  String get pix_deposit_id_label => 'ID del Depósito';

  @override
  String get pix_main_tab_receive => 'Recibir';

  @override
  String get pix_main_tab_send => 'Enviar';

  @override
  String get pix_info_title => 'Información sobre PIX';

  @override
  String get pix_info_processing_title => 'Plazo de procesamiento';

  @override
  String get pix_info_processing_body =>
      'Los pagos vía PIX pueden ser procesados en hasta 72 horas hábiles después de la confirmación.';

  @override
  String get pix_info_lbtc_variation_title => 'Variación de cambio (LBTC)';

  @override
  String get pix_info_lbtc_variation_body =>
      'Al elegir recibir en LBTC, el valor final puede variar debido a la cotización al momento de la conversión. Puedes recibir más o menos de lo calculado.';

  @override
  String get pix_info_fees_title => 'Sobre las tarifas';

  @override
  String get pix_info_fees_body =>
      'Las tarifas varían según el valor de la transacción. Valores menores tienen tarifas fijas, valores mayores tienen tarifas porcentuales decrecientes.';

  @override
  String get pix_info_fees_button => 'Ver detalles de tarifas';

  @override
  String get pix_limits_title => 'Límites de Pago';

  @override
  String get pix_limits_intro => 'Entiende cómo funcionan los pagos PIX:';

  @override
  String get pix_limits_initial_label => 'Límite Inicial';

  @override
  String get pix_limits_initial_value => 'R\$ 20,00';

  @override
  String get pix_limits_max_label => 'Límite Máximo';

  @override
  String get pix_limits_max_value => 'R\$ 3.000,00';

  @override
  String get pix_limits_explanation =>
      'A lo largo de los pagos efectuados, tus límites de transacción pueden evolucionar hasta el límite máximo de R\$ 3.000,00 por transacción, según tu puntuación de confianza en el aplicativo Mooze.';

  @override
  String get pix_limits_trust_info =>
      'Consulta tus niveles de confianza en el menú, opción \"Nivel de la billetera\".';

  @override
  String get pix_limits_increase_info =>
      'Para aumentar tus límites, el uso frecuente de pagos los elevará gradualmente.';

  @override
  String pix_limits_button_understood_countdown(int seconds) {
    return 'Entendido ($seconds)';
  }

  @override
  String get swap_pending_dialog_title => 'Transacción Pendiente';

  @override
  String get refund_mock_simulation_error =>
      'Error simulado: Falla en la transmisión de la transacción';

  @override
  String get merchant_welcome_title => '¡Bienvenido al Modo Comerciante!';

  @override
  String get merchant_welcome_body =>
      'Aquí tienes un mini punto de venta: registra ítems, suma valores y cobra a tus clientes rápidamente.';

  @override
  String get merchant_step_enter_value_title => 'Ingresa el monto deseado';

  @override
  String get merchant_step_enter_value_body =>
      'Empecemos ingresando un valor de R\$ 20,00 con el teclado de abajo.';

  @override
  String get merchant_step_add_value_title => 'Agregar monto';

  @override
  String get merchant_step_add_value_body =>
      'Ahora toca el botón verde \'+\' para agregar el monto a la lista de ítems.';

  @override
  String get merchant_step_items_tab_title => 'Pestaña de Ítems';

  @override
  String get merchant_step_items_tab_body =>
      'Toca aquí para ver tus productos registrados y crear nuevos.';

  @override
  String get merchant_step_create_product_title => 'Crear producto';

  @override
  String get merchant_step_create_product_body =>
      'Toca el botón \'+\' para crear automáticamente el producto \'Producto 01\' con precio de R\$ 21,00.';

  @override
  String get merchant_step_edit_delete_title => 'Editar y Eliminar productos';

  @override
  String get merchant_step_edit_delete_body =>
      'Desliza este producto de derecha a izquierda para ver las opciones de editar y eliminar.';

  @override
  String get merchant_step_finalize_title => 'Finalizar venta';

  @override
  String get merchant_step_finalize_body =>
      'Cuando tengas ítems en el carrito (mínimo R\$ 20,00), toca aquí para finalizar la venta.';

  @override
  String get merchant_step_clear_cart_title => 'Vaciar carrito';

  @override
  String get merchant_step_clear_cart_body =>
      'Si quieres empezar de cero, toca aquí para eliminar todos los ítems del carrito.';

  @override
  String get merchant_tutorial_done_title => '¡Tutorial Completado!';

  @override
  String get merchant_tutorial_done_body =>
      'Ya sabes usar todas las funciones del Modo Comerciante. ¿Listo para empezar?';

  @override
  String get merchant_default_product_name => 'Producto 01';

  @override
  String get merchant_loose_value => 'Monto Suelto';

  @override
  String get merchant_add_item_first =>
      'Agrega ítems al carrito antes de finalizar la venta';

  @override
  String get merchant_min_sale_value =>
      'El monto mínimo para finalizar la venta es R\$ 20,00';

  @override
  String merchant_add_product_error(String error) {
    return 'Error al agregar el producto: $error';
  }

  @override
  String merchant_update_product_error(String error) {
    return 'Error al actualizar el producto: $error';
  }

  @override
  String merchant_remove_product_error(String error) {
    return 'Error al eliminar el producto: $error';
  }

  @override
  String get merchant_tab_keypad => 'Teclado';

  @override
  String get merchant_tab_items => 'Ítems';

  @override
  String get merchant_load_products_error => 'Error al cargar los productos';

  @override
  String get merchant_mode_header => 'Modo Comerciante';

  @override
  String get merchant_clear_cart => 'Vaciar';

  @override
  String get merchant_no_products_title => 'Sin productos registrados';

  @override
  String get merchant_no_products_body =>
      'Empieza agregando tu primer producto\ntocando el botón + de abajo';

  @override
  String get merchant_delete_item_title => 'Eliminar ítem';

  @override
  String merchant_delete_item_confirm(String name) {
    return '¿Eliminar \"$name\"?';
  }

  @override
  String get merchant_delete_action => 'Eliminar';

  @override
  String get merchant_add_product_title => 'Agregar Producto';

  @override
  String get merchant_edit_product_title => 'Editar Producto';

  @override
  String get merchant_product_name_label => 'Nombre del producto';

  @override
  String get merchant_product_name_hint => 'Ingresa el nombre del producto';

  @override
  String get merchant_price_label => 'Precio';

  @override
  String get merchant_add_action => 'Agregar';

  @override
  String get merchant_min_sale_short => 'Mín. R\$ 20,00';

  @override
  String get merchant_finalize_sale_button => 'Finalizar Venta';

  @override
  String get merchant_charge_receive_title => 'Recibir';

  @override
  String get merchant_charge_instruction_prefix =>
      'Elige el activo que deseas recibir en ';

  @override
  String get merchant_limit_daily => 'Límite diario';

  @override
  String get merchant_limit_per_transaction => 'Por transacción';

  @override
  String get merchant_limit_min => 'Monto mínimo';

  @override
  String get merchant_limits_load_error => 'Error al cargar los límites';

  @override
  String get merchant_generate_qr => 'Generar código QR';

  @override
  String merchant_validation_min_amount(String amount) {
    return 'Monto mínimo: R\$ $amount';
  }

  @override
  String merchant_validation_max_per_tx(String amount) {
    return 'Límite por transacción: R\$ $amount';
  }

  @override
  String get merchant_exit_ready => '¿Listo para vender?';

  @override
  String get merchant_exit_new_payment => 'Recibir nuevo pago';

  @override
  String get merchant_exit_back_to_wallet => '¿Quieres acceder a la billetera?';

  @override
  String get merchant_items_section => 'Ítems';

  @override
  String merchant_qty_prefix(int qty) {
    return 'x$qty';
  }

  @override
  String get common_error => 'Error';

  @override
  String get error_open_browser_link_copied =>
      'No se pudo abrir el navegador. Enlace copiado al portapapeles.';

  @override
  String get pix_you_will_receive => 'Recibirás';

  @override
  String pix_of_amount(String amount) {
    return 'de R\$ $amount';
  }

  @override
  String get pix_fees_applied => 'Tarifas aplicadas';

  @override
  String get pix_fee_fixed_label => 'Tarifa fija';

  @override
  String get pix_fee_fixed_mooze => 'Tarifa fija (Mooze)';

  @override
  String get pix_fee_fixed_for_small_subtitle => 'Para montos hasta R\$ 55';

  @override
  String get pix_fee_mooze => 'Tarifa Mooze';

  @override
  String get pix_fee_processor => 'Tarifa de la procesadora';

  @override
  String get pix_fee_referral_discount => 'Ya con 15% de descuento aplicado';

  @override
  String pix_fee_savings(String amount) {
    return '¡Ahorraste R\$ $amount con el código de referido!';
  }

  @override
  String get pix_waiting_amount_title => 'Esperando monto';

  @override
  String get pix_waiting_amount_body =>
      'Ingresa un monto válido para ver\nel resumen de la transacción';

  @override
  String get pix_payment_screen_title => 'Pago PIX';

  @override
  String pix_qr_generation_error(String error) {
    return 'Error al generar el código QR: $error';
  }

  @override
  String get pix_payment_expired_body =>
      'El plazo para realizar el pago ha expirado. Por favor, genera un nuevo PIX.';

  @override
  String get pix_fees_screen_header_title => 'Tarifas Transparentes';

  @override
  String get pix_fees_screen_header_subtitle =>
      'Conoce nuestras tarifas de depósito vía PIX';

  @override
  String get pix_fees_screen_fixed_fee_title => 'Tarifa Fija';

  @override
  String get pix_fees_screen_fixed_fee_subtitle =>
      'Para depósitos hasta R\$ 55,00';

  @override
  String get pix_fees_screen_fixed_fee_breakdown =>
      'R\$ 1,00 Mooze + R\$ 1,00 Procesadora';

  @override
  String get pix_fees_screen_percentage_title => 'Tarifas Porcentuales';

  @override
  String get pix_fees_screen_percentage_subtitle =>
      'Para depósitos superiores a R\$ 55,00';

  @override
  String get pix_fees_screen_tab_no_discount => 'Sin Descuento';

  @override
  String get pix_fees_screen_tab_with_discount => 'Con Descuento';

  @override
  String pix_fees_screen_fee_range_before(String percentage) {
    return 'antes $percentage%';
  }

  @override
  String pix_fees_screen_fee_range_label(String min, String max) {
    return 'R\$ $min hasta R\$ $max';
  }

  @override
  String get pix_fees_screen_referral_title => 'Bono de Referido';

  @override
  String get pix_fees_screen_referral_subtitle => 'Usa un código de referido';

  @override
  String get pix_fees_screen_referral_discount => '15% de descuento';

  @override
  String get pix_fees_screen_referral_disclaimer =>
      'Todas las tarifas porcentuales se multiplican por 0,85';

  @override
  String get pix_fees_screen_examples_title => 'Ejemplos Prácticos';

  @override
  String get pix_fees_screen_example_deposit => 'Depósito';

  @override
  String get pix_fees_screen_example_receive => 'Recibes';

  @override
  String get pix_fees_screen_example_with_referral => 'Con referido';

  @override
  String get pix_fees_screen_example_fee_label => 'Tarifa';

  @override
  String pix_fees_screen_fee_calculation_of(String percentage, String amount) {
    return '$percentage% de R\$ $amount';
  }

  @override
  String get pix_fees_screen_footer_title => 'Información Importante';

  @override
  String get pix_fees_screen_footer_info_1 =>
      'La tarifa fija de R\$ 2,00 aplica solo para depósitos hasta R\$ 55,00';

  @override
  String get pix_fees_screen_footer_info_2 =>
      'Para montos superiores a R\$ 55,00, se aplican las tarifas porcentuales';

  @override
  String get pix_fees_screen_footer_info_3 =>
      'El descuento del 15% con referido aplica solo a las tarifas porcentuales';

  @override
  String get pix_fees_screen_footer_info_4 =>
      'Las tarifas se deducen automáticamente del monto depositado';

  @override
  String get tx_detail_blockchain => 'Blockchain';

  @override
  String get tx_detail_swap_label => 'Intercambio de activos';

  @override
  String get tx_detail_sent => 'Enviado';

  @override
  String get tx_detail_expected => 'Esperado';

  @override
  String get tx_type_redeposit => 'Auto-redepósito';

  @override
  String get tx_type_unknown => 'Desconocido';

  @override
  String get tx_status_failed_processed => 'Reembolso Procesado';

  @override
  String get tx_status_refundable_pending => 'Esperando Reembolso';

  @override
  String get tx_status_confirmed_fem => 'Confirmada';

  @override
  String get tx_detail_confirmations => 'Confirmaciones';

  @override
  String get tx_detail_confirmations_full => '6+ confirmaciones';

  @override
  String tx_detail_confirmations_progress(int count) {
    return '$count/6 confirmaciones';
  }

  @override
  String get tx_detail_preimage_label => 'Preimagen';

  @override
  String get tx_detail_preimage_pending =>
      'Preimagen pendiente: cuando tu transacción se confirme, la preimagen aparecerá aquí';

  @override
  String tx_detail_submarine_btc_to_lbtc(String from, String to) {
    return 'Swap de red: Enviaste $from y recibirás $to. Cuando la transacción on-chain se confirme, los fondos aparecerán automáticamente en Liquid Network.';
  }

  @override
  String tx_detail_submarine_lbtc_to_btc(String from, String to) {
    return 'Swap de red: Enviaste $from y recibirás $to. Una vez procesado, la transacción se enviará a la blockchain de Bitcoin.';
  }

  @override
  String get tx_detail_submarine_generic =>
      'Swap de red: transacción entre redes diferentes. Espera la confirmación.';

  @override
  String get tx_detail_submarine_default =>
      'Esta transacción representa un swap de red. Una vez confirmada, recibirás los fondos en la red de destino.';

  @override
  String get tx_detail_request_refund => 'Solicitar Reembolso';

  @override
  String get tx_detail_request_refund_subtitle => 'Recupera tus fondos ahora';

  @override
  String get tx_detail_view_send => 'Ver Envío';

  @override
  String get tx_detail_view_receive => 'Ver Recepción';

  @override
  String get tx_detail_validate_payment => 'Validar Pago';

  @override
  String get tx_detail_verify_preimage => 'Verificar preimagen';

  @override
  String tx_detail_send_id_label(String chain) {
    return 'ID de Envío ($chain)';
  }

  @override
  String tx_detail_receive_id_label(String chain) {
    return 'ID de Recepción ($chain)';
  }

  @override
  String get main_settings_title => 'Menú';

  @override
  String get main_settings_section_merchant => 'COMERCIANTE';

  @override
  String get main_settings_section_transactions => 'TRANSACCIONES';

  @override
  String get main_settings_section_settings => 'CONFIGURACIÓN';

  @override
  String get main_settings_section_wallet => 'BILLETERA';

  @override
  String get main_settings_section_external_links => 'ENLACES EXTERNOS';

  @override
  String get main_settings_section_fees => 'TARIFAS';

  @override
  String get main_settings_section_version => 'VERSIÓN';

  @override
  String get main_settings_settings_label => 'Configuración';

  @override
  String get main_settings_wallet_level => 'Nivel de la billetera';

  @override
  String get main_settings_pix_fees => 'Tarifas de PIX';

  @override
  String get main_settings_btc_services => 'Servicios vía Bitcoin';

  @override
  String get main_settings_support => 'Soporte';

  @override
  String get onboarding_1_title => 'Tu dinero, bajo tu control';

  @override
  String get onboarding_1_body =>
      'Recibe, envía y administra Bitcoin con privacidad real. Una billetera hecha para quienes valoran la libertad.';

  @override
  String get onboarding_2_title => 'Seguridad ante todo';

  @override
  String get onboarding_2_body =>
      'Tu llave, tu responsabilidad. Protege tu patrimonio con cifrado fuerte y respaldos locales.';

  @override
  String get onboarding_3_title => '¿Listo para empezar?';

  @override
  String get onboarding_3_body =>
      'Crea o importa tu billetera en segundos y toma el control de tu Bitcoin.';

  @override
  String get first_access_create_wallet => 'Crear Billetera';

  @override
  String get first_access_import_wallet => 'Importar billetera';

  @override
  String get first_access_terms_prefix => 'He leído y acepto los ';

  @override
  String get first_access_terms_link => 'Términos y Condiciones';

  @override
  String get level_my_levels => 'Mis Niveles';

  @override
  String level_label(int n) {
    return 'Nivel $n';
  }

  @override
  String get level_current => 'Nivel actual: ';

  @override
  String level_progress(int percent) {
    return 'Progreso: $percent%';
  }

  @override
  String level_next(String name) {
    return 'Siguiente: $name';
  }

  @override
  String get level_load_error => 'Error al cargar el nivel';

  @override
  String get level_load_retry => 'Inténtalo más tarde.';

  @override
  String get level_user_label => 'Nivel de usuario';

  @override
  String get level_desc_bronze =>
      'Empieza moviendo pequeños montos y desbloquea los primeros beneficios.';

  @override
  String get level_desc_silver =>
      'Cuanto más gastes, más subes de nivel. Alcanza el nivel Plata.';

  @override
  String get level_desc_gold =>
      'Nivel Gold con límites mayores para movimientos más grandes.';

  @override
  String get level_desc_max =>
      'Nivel máximo con los límites más altos y beneficios exclusivos.';

  @override
  String get wallet_levels_title => 'Niveles de la Billetera';

  @override
  String get wallet_levels_api_down_title => 'API No Disponible';

  @override
  String get wallet_levels_api_down_body =>
      'Los datos pueden estar desactualizados. Algunas funciones están temporalmente no disponibles.';

  @override
  String get wallet_levels_load_error_title => 'Error al cargar los niveles';

  @override
  String get wallet_levels_load_error_body =>
      'Verifica tu conexión a internet e inténtalo de nuevo';

  @override
  String get wallet_levels_header_title => 'Crece con Mooze';

  @override
  String get wallet_levels_header_subtitle =>
      'Cuanto más mueves, más beneficios y límites desbloqueas.';

  @override
  String get wallet_levels_quick_unlock_title => 'Desbloquea';

  @override
  String get wallet_levels_quick_unlock_subtitle => 'Aumenta límites';

  @override
  String get wallet_levels_quick_earn_title => 'Gana';

  @override
  String get wallet_levels_quick_earn_subtitle => 'Beneficios extras';

  @override
  String get wallet_levels_quick_status_title => 'Estado';

  @override
  String get wallet_levels_quick_status_subtitle => 'Reconocimiento VIP';

  @override
  String get wallet_levels_current_limits_title => 'Tus Límites Actuales';

  @override
  String wallet_levels_current_level(String levelName) {
    return 'Nivel: $levelName';
  }

  @override
  String get wallet_levels_limit_per_transaction => 'Por transacción';

  @override
  String get wallet_levels_limit_daily => 'Límite diario';

  @override
  String get wallet_levels_limit_minimum => 'Mínimo';

  @override
  String get wallet_levels_next_level_hint =>
      '¡Sigue usando para desbloquear el siguiente nivel!';

  @override
  String wallet_levels_next_level_hint_named(String nextLevelName) {
    return '¡Sigue usando para desbloquear el siguiente nivel $nextLevelName!';
  }

  @override
  String get wallet_levels_load_limits_error_title =>
      'Error al cargar los límites';

  @override
  String get wallet_levels_load_limits_error_body =>
      'Inténtalo más tarde o contacta soporte.';

  @override
  String get update_available_short => 'Nueva actualización disponible';

  @override
  String get update_available_body =>
      'Actualiza para obtener mejoras y correcciones';

  @override
  String get update_available_button => 'ACTUALIZAR';

  @override
  String get update_dialog_title => 'Actualización Disponible';

  @override
  String get update_dialog_body => 'Hay una nueva versión de la aplicación.';

  @override
  String get update_current_version => 'Versión actual:';

  @override
  String get update_new_version => 'Nueva versión:';

  @override
  String get update_dialog_recommend =>
      'Recomendamos actualizar para obtener las mejoras más recientes y correcciones de errores.';

  @override
  String get update_later => 'MÁS TARDE';

  @override
  String get info_overlay_dismiss_hint => 'Toca fuera de esta área para cerrar';

  @override
  String get auth_syncing => 'Sincronizando...';

  @override
  String get api_down_dialog_title => 'API No Disponible';

  @override
  String get api_down_dialog_body =>
      'La API de Mooze no está disponible temporalmente.';

  @override
  String get api_down_maintenance_title =>
      'El servidor puede estar en mantenimiento';

  @override
  String get api_down_warning_list =>
      '• PIX no disponible\n• Sincronización en pausa\n• Datos en caché en uso';

  @override
  String get api_down_dialog_footer => 'Inténtalo de nuevo en unos minutos.';

  @override
  String get api_down_indicator => 'API No Disponible';

  @override
  String get sync_error_indicator => 'Error de Sync';

  @override
  String get sync_error_dialog_title => 'Error de Sincronización';

  @override
  String get sync_error_dialog_body =>
      'No se pueden sincronizar los servicios Mooze.';

  @override
  String get sync_error_warning => 'Operación no autorizada';

  @override
  String get pin_create_title => 'Crear PIN';

  @override
  String get pin_create_min_length => 'El PIN debe tener al menos 6 caracteres';

  @override
  String get pin_create_yours => 'Crea tu ';

  @override
  String get pin_create_intro_prefix => 'El ';

  @override
  String get pin_create_intro_suffix =>
      'se utilizará para autorizar transacciones y acceder a tu billetera.';

  @override
  String get currency_select_title => 'Seleccionar Moneda';

  @override
  String get currency_display_label => 'Moneda de visualización';

  @override
  String get currency_display_description =>
      'Elige la moneda utilizada para mostrar precios y valores en toda la aplicación.';

  @override
  String get currency_brl_name => 'Brasil (Real Brasileño)';

  @override
  String get currency_usd_name => 'Estados Unidos (Dólar)';

  @override
  String get referral_save_title => '¡Ahorra con referidos!';

  @override
  String get referral_discount_badge => 'HASTA 15% DE DESCUENTO';

  @override
  String get referral_save_description =>
      'Ingresa tu código de referido y disfruta descuentos exclusivos en todas las tarifas de la plataforma.';

  @override
  String get referral_active_title => 'Descuento Activo';

  @override
  String referral_code_with_value(String code) {
    return 'Código: $code';
  }

  @override
  String get referral_savings_message =>
      '¡Estás ahorrando en todas las transacciones!';

  @override
  String get referral_apply_code => 'Aplicar Código';

  @override
  String get referral_validating => 'Validando...';

  @override
  String get referral_api_down_warning =>
      'La API no está disponible. No es posible aplicar códigos de referido en este momento.';

  @override
  String get referral_input_unavailable => 'No disponible';

  @override
  String get referral_input_hint => 'Ej: MOOZE123';

  @override
  String get referral_input_label => 'Código de Referido';

  @override
  String get pix_fee_conversion_title => 'Tarifas de conversión';

  @override
  String get pix_fee_discount_active_short => 'Descuento activo';

  @override
  String get pix_fee_tier1_range => 'R\$ 20 a R\$ 55';

  @override
  String get pix_fee_tier1_value => 'R\$ 2,00 fijo *';

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
      '* 15% de descuento para usuarios con código de referido.';

  @override
  String get pix_fee_footnote_network =>
      '* Tarifas de red/spread variable por cuenta del usuario.';

  @override
  String get pix_fee_discount_chip_15 => '−15%';

  @override
  String get support_user_code_load_error_inline => 'Error al cargar el código';

  @override
  String get support_user_code_unique => 'Código único';

  @override
  String get wallet_send_appbar_title => 'Enviar activos';

  @override
  String get wallet_send_instruction_prefix =>
      'Elige el activo que quieres enviar en ';

  @override
  String get wallet_send_address_label => 'Dirección de destino';

  @override
  String get wallet_send_address_hint => 'Escribe o pega la dirección';

  @override
  String get wallet_send_address_scan_qr => 'Escanear código QR';

  @override
  String get wallet_send_select_asset => 'Selecciona un activo';

  @override
  String get wallet_send_available_balance => 'Saldo disponible';

  @override
  String get wallet_send_balance_unavailable => 'No disponible';

  @override
  String get wallet_send_balance_load_error => 'Error al cargar';

  @override
  String get wallet_send_amount_label => 'Monto';

  @override
  String get wallet_send_amount_hint => 'Ingresa el monto';

  @override
  String get wallet_send_amount_in_sats => 'Monto en Satoshis:';

  @override
  String get wallet_send_amount_valid => '¡Monto válido!';

  @override
  String get wallet_send_conversion_asset => 'Activo';

  @override
  String get wallet_send_conversion_sats => 'Satoshis';

  @override
  String get wallet_send_conversion_fiat => 'Fiat';

  @override
  String get wallet_send_drain_title => 'Envío Total de Fondos';

  @override
  String wallet_send_drain_body(String asset) {
    return 'Seleccionaste enviar todos los fondos del activo $asset.';
  }

  @override
  String get wallet_send_drain_ready =>
      'Listo para revisar - las tarifas se descontarán del monto total';

  @override
  String get wallet_send_fee_estimated => 'Tarifa estimada';

  @override
  String get wallet_send_fee_calculating => 'Calculando tarifa...';

  @override
  String get wallet_send_fee_calc_error => 'Error al calcular la tarifa';

  @override
  String get wallet_send_fee_free => 'Gratis';

  @override
  String get wallet_send_lbtc_disclaimer_title =>
      'Cómo funciona el envío de activos';

  @override
  String get wallet_send_lbtc_disclaimer_body =>
      'Para enviar activos (Bitcoin L2, DePIX o USDT), necesitas mantener un saldo de Bitcoin L2 en tu billetera.';

  @override
  String get wallet_send_lbtc_network_fees_title => 'Tarifas de red';

  @override
  String get wallet_send_lbtc_network_fees_desc =>
      'El saldo de Bitcoin L2 se utiliza para pagar las tarifas de los mineros de la red Liquid.';

  @override
  String get wallet_send_lbtc_obtain_title => 'Cómo obtener Bitcoin L2';

  @override
  String get wallet_send_lbtc_obtain_desc_disclaimer =>
      'Usa la función SWAP o recibe Bitcoin por Lightning o Liquid.';

  @override
  String get wallet_send_lbtc_obtain_desc_info =>
      'Usa la función SWAP para convertir Bitcoin (Lightning u on-chain) en Bitcoin L2 directamente en la app.';

  @override
  String get wallet_send_lbtc_disclaimer_tip =>
      'Mantén un pequeño saldo de Bitcoin L2 para asegurar que tus transacciones se procesen.';

  @override
  String wallet_send_lbtc_disclaimer_understood_countdown(int seconds) {
    return 'Entendido ($seconds)';
  }

  @override
  String get wallet_send_lbtc_info_title => 'Información sobre tarifas';

  @override
  String get wallet_send_lbtc_info_step1_title =>
      'Bitcoin L2 para tarifas de red';

  @override
  String get wallet_send_lbtc_info_step1_desc =>
      'Para enviar DePIX, USDT o cualquier activo de la red Liquid, necesitas tener Bitcoin L2 (Liquid Bitcoin) en la billetera. Se utiliza para pagar a los mineros de la red.';

  @override
  String get wallet_send_lbtc_info_step3_title =>
      'Recibe por Lightning o Liquid';

  @override
  String get wallet_send_lbtc_info_step3_desc =>
      'Recibe Bitcoin por Lightning Network o Liquid para obtener Bitcoin L2 en tu billetera sin usar SWAP.';

  @override
  String get wallet_send_lbtc_go_swap => 'Ir a SWAP';

  @override
  String get wallet_send_lbtc_insufficient_title => 'Bitcoin L2 insuficiente';

  @override
  String wallet_send_lbtc_insufficient_body(String asset) {
    return 'Necesitas Bitcoin L2 para pagar las tarifas de los mineros al enviar $asset:';
  }

  @override
  String get wallet_send_lbtc_insufficient_swap_prefix => 'Usa la función ';

  @override
  String get wallet_send_lbtc_insufficient_swap_suffix =>
      ' para obtener Bitcoin L2';

  @override
  String get wallet_send_lbtc_insufficient_lightning =>
      'Recibe Bitcoin por Lightning o Liquid para obtener Bitcoin L2';

  @override
  String get wallet_send_lbtc_banner_title =>
      'Bitcoin L2 necesario para tarifas';

  @override
  String get wallet_send_lbtc_banner_body =>
      'Para enviar DePIX o USDT, necesitas tener Bitcoin L2 en la billetera para pagar las tarifas de la red.';

  @override
  String get wallet_send_lbtc_banner_action => 'Obtener vía SWAP';

  @override
  String get wallet_send_network_unidentified => 'Red no identificada';

  @override
  String get wallet_send_network_bitcoin => 'Bitcoin On-chain';

  @override
  String get wallet_send_network_lightning => 'Lightning Network';

  @override
  String get wallet_send_network_liquid => 'Liquid Network';

  @override
  String get wallet_send_network_unknown => 'Red desconocida';

  @override
  String get wallet_send_predefined_label => 'Monto predefinido';

  @override
  String get wallet_send_predefined_body =>
      'Esta factura/dirección tiene un monto predefinido. El campo de cantidad se completó automáticamente.';

  @override
  String wallet_send_predefined_label_value(String label) {
    return 'Etiqueta: $label';
  }

  @override
  String wallet_send_predefined_message_value(String message) {
    return 'Mensaje: $message';
  }

  @override
  String get wallet_send_review_preparing => 'Preparando...';

  @override
  String get wallet_send_review_drain => 'Revisar Envío Total';

  @override
  String get wallet_send_review_transaction => 'Revisar Transacción';

  @override
  String wallet_send_review_lbtc_insufficient_error(String asset) {
    return 'Saldo de Bitcoin L2 insuficiente para tarifas.\n\nPara enviar $asset, necesitas Bitcoin L2 para pagar a los mineros de la red. Usa la función SWAP o recibe Bitcoin por Lightning o Liquid.';
  }

  @override
  String get wallet_send_review_insufficient_error =>
      'Saldo insuficiente para realizar el envío.\n\nVerifica que tengas saldo suficiente en el activo seleccionado y Bitcoin L2 para pagar las tarifas de la red.';

  @override
  String get wallet_send_review_prepare_error =>
      'No se pudo preparar la transacción. Inténtalo de nuevo.';

  @override
  String get wallet_send_loading_conversions => 'Cargando conversiones...';

  @override
  String get wallet_send_equivalent_conversions => 'Conversiones equivalentes:';

  @override
  String get wallet_send_satoshis_label => 'Satoshis:';

  @override
  String get wallet_send_validation_attention => 'Atención';

  @override
  String get wallet_send_validation_help =>
      'Las validaciones se verifican automáticamente mientras escribes.';

  @override
  String get wallet_send_error_address_required =>
      'La dirección es obligatoria';

  @override
  String get wallet_send_error_address_invalid =>
      'Dirección inválida o no admitida';

  @override
  String wallet_send_error_asset_liquid_only(String asset) {
    return '$asset solo puede enviarse por la red Liquid o Lightning';
  }

  @override
  String get wallet_send_error_liquid_only =>
      'Para enviar activos Liquid usa Bitcoin L2, Depix o USDT';

  @override
  String get wallet_send_error_amount_positive =>
      'El monto debe ser mayor a cero';

  @override
  String get wallet_send_error_balance_check =>
      'Error al verificar el saldo disponible';

  @override
  String get wallet_send_error_insufficient_balance => 'Saldo insuficiente';

  @override
  String get wallet_send_error_address_unrecognized =>
      'Dirección inválida o no reconocida';

  @override
  String get wallet_send_error_pending_payments =>
      'No es posible enviar el saldo total mientras haya pagos pendientes. Espera a que se completen los pagos e inténtalo de nuevo.';

  @override
  String wallet_send_error_validation_failed(String error) {
    return 'No se pudo validar la transacción: $error';
  }

  @override
  String get wallet_send_error_amount_exceeds_balance =>
      'El monto ingresado es mayor que el saldo disponible';

  @override
  String wallet_send_error_insufficient_with_fees(
    String total,
    String amount,
    String fee,
    String satText,
    String balance,
  ) {
    return 'Saldo insuficiente. Necesitas $total sats ($amount + $fee $satText de tarifa), pero solo tienes $balance sats disponibles';
  }

  @override
  String wallet_send_error_fee_calc_failed(String error) {
    return 'No se pudieron calcular las tarifas: $error';
  }

  @override
  String wallet_send_error_validate_balance_fees(String error) {
    return 'Error al validar saldo y tarifas: $error';
  }

  @override
  String wallet_send_error_min_lightning(int amount) {
    return 'Monto mínimo para Lightning es $amount sats';
  }

  @override
  String wallet_send_error_max_lightning(int amount) {
    return 'Monto máximo para Lightning es $amount sats';
  }

  @override
  String get wallet_send_error_min_usdt => 'Monto mínimo para USDT es 0.5 USDT';

  @override
  String get wallet_send_error_min_depix =>
      'Monto mínimo para Depix es 1.0 Depix';

  @override
  String wallet_send_error_validate_limits(String error) {
    return 'Error al validar límites de envío: $error';
  }

  @override
  String get wallet_action_receive => 'RECIBIR';

  @override
  String get wallet_action_send => 'ENVIAR';

  @override
  String get wallet_assets_section_title => 'Activos';

  @override
  String get wallet_transactions_section_title => 'Transacciones';

  @override
  String get wallet_section_see_more => 'Ver más';

  @override
  String wallet_tx_sent(String ticker) {
    return 'Enviaste $ticker';
  }

  @override
  String wallet_tx_received(String ticker) {
    return 'Recibiste $ticker';
  }

  @override
  String wallet_tx_swap_pair(String from, String to) {
    return 'Swap: $from a $to';
  }

  @override
  String wallet_tx_redeposit(String ticker) {
    return 'Autodepositaste $ticker';
  }

  @override
  String get wallet_tx_unknown => 'Tipo de transacción desconocido';

  @override
  String get wallet_tx_load_error_title =>
      'No se pudieron cargar las transacciones';

  @override
  String get wallet_tx_load_error_retry => 'Inténtalo de nuevo más tarde';

  @override
  String get wallet_tx_empty_title => 'No se encontraron transacciones';

  @override
  String get wallet_tx_empty_body =>
      'Tu historial de transacciones aparecerá aquí en cuanto realices algún movimiento.';

  @override
  String get wallet_all_assets_title => 'Todos los Activos';

  @override
  String get wallet_all_assets_subtitle =>
      'Consulta las cotizaciones de todos los activos disponibles';

  @override
  String get wallet_all_assets_favorite_hint =>
      'Toca el ícono para marcar como favorito — ';

  @override
  String wallet_all_assets_favorite_count(int count) {
    return '$count/2 seleccionados';
  }

  @override
  String wallet_asset_chart_title(String period) {
    return 'Gráfico - $period';
  }

  @override
  String get wallet_asset_chart_unavailable => 'Gráfico no disponible';

  @override
  String get wallet_asset_chart_load_error => 'No se pudo cargar el gráfico';

  @override
  String get wallet_holding_appbar_title => 'Activos';

  @override
  String get wallet_holding_action_send => 'Enviar';

  @override
  String get wallet_holding_action_receive => 'Recibir';

  @override
  String get wallet_holding_action_swap => 'Swap';

  @override
  String wallet_holding_unexpected_error(String error) {
    return 'Error inesperado: $error';
  }

  @override
  String get wallet_holding_empty => 'No se encontraron activos';

  @override
  String get wallet_holding_no_balance => 'Sin saldo';

  @override
  String get wallet_holding_load_error_title => 'Error al cargar activos';

  @override
  String get wallet_holding_pending_payments_title => 'Pagos en análisis';

  @override
  String wallet_holding_pending_payments_total(String currency, String value) {
    return 'Total: $currency $value';
  }

  @override
  String get wallet_holding_calculating => 'Calculando...';

  @override
  String get pix_receive_appbar_title => 'Recibir PIX';

  @override
  String get pix_receive_api_unavailable =>
      'No es posible procesar transacciones PIX en este momento. Por favor, inténtalo de nuevo más tarde.';

  @override
  String get pix_receive_info_title => 'Información sobre PIX';

  @override
  String get pix_receive_info_step1_title => 'Plazo de procesamiento';

  @override
  String get pix_receive_info_step1_desc =>
      'Los pagos vía PIX pueden procesarse en hasta 72 horas hábiles después de la confirmación.';

  @override
  String get pix_receive_info_step2_title => 'Variación de cambio (LBTC)';

  @override
  String get pix_receive_info_step2_desc =>
      'Al elegir recibir en LBTC, el valor final puede variar debido a la cotización del momento de la conversión. Puedes recibir más o menos que lo calculado.';

  @override
  String get pix_receive_info_step3_title => 'Sobre las tarifas';

  @override
  String get pix_receive_info_step3_desc =>
      'Las tarifas varían según el valor de la transacción. Los valores menores tienen tarifas fijas, los mayores tienen tarifas porcentuales decrecientes.';

  @override
  String get pix_receive_info_see_fees => 'Ver detalles de las tarifas';

  @override
  String get pix_receive_instruction_prefix =>
      'Elige el activo que deseas recibir en ';

  @override
  String get pix_receive_tip_more_payments =>
      'Haz más pagos para desbloquear nuevos límites';

  @override
  String get pix_receive_advance => 'Continuar';

  @override
  String get pix_receive_my_level => 'Mi Nivel';

  @override
  String get pix_receive_you_add => 'Añades';

  @override
  String get pix_receive_my_limits => 'Mis límites';

  @override
  String get pix_receive_see_levels => 'Ver niveles';

  @override
  String get pix_receive_daily_limit => 'Límite diario';

  @override
  String get pix_receive_per_transaction => 'Por transacción';

  @override
  String get pix_receive_min => 'Mín.';

  @override
  String get pix_receive_limits_error => 'Error al cargar los límites';

  @override
  String pix_receive_details(String detail) {
    return 'Detalles: $detail';
  }

  @override
  String get pix_receive_validation_invalid_amount => 'Ingresa un monto válido';

  @override
  String pix_receive_validation_below_min(String amount) {
    return 'Monto mínimo: R\$ $amount';
  }

  @override
  String pix_receive_validation_above_transaction(String amount) {
    return 'Límite por transacción: R\$ $amount';
  }

  @override
  String get pix_tip_consecutive_daily =>
      'Máx. 3 PIX seguidos del mismo titular en 30 min · Límite de R\$ 5.000/día por titular.';

  @override
  String get pix_tip_outside_rules_returned =>
      'Los pagos fuera de las reglas son devueltos automáticamente al remitente.';

  @override
  String get pix_tip_processing_avg_time =>
      'Procesamiento en 5–25 min. PIX con señales de riesgo bancario puede tardar 3–7 días (reembolsable).';

  @override
  String get pix_payment_appbar_title => 'Pago PIX';

  @override
  String pix_payment_qr_error(String error) {
    return 'Error al generar el código QR: $error';
  }

  @override
  String get pix_payment_time_expired_body =>
      'El plazo para realizar el pago ha expirado. Por favor, genera un nuevo PIX.';

  @override
  String get tx_filter_pix_title => 'Filtros PIX';

  @override
  String get tx_filter_deposit_status => 'Estado del depósito';

  @override
  String get tx_filter_most_recent => 'Más Reciente';

  @override
  String get tx_filter_oldest => 'Más Antiguo';

  @override
  String get tx_filter_select_period => 'Seleccionar Período';

  @override
  String get tx_filter_select => 'Selecciona';

  @override
  String get tx_filter_to => 'a';

  @override
  String get tx_filter_start_after_end_error =>
      'La fecha de inicio no puede ser posterior a la fecha de fin.';

  @override
  String get tx_history_refresh_debug => 'Actualizar (Debug)';

  @override
  String tx_history_filters_active(String description) {
    return 'Filtros activos - $description';
  }

  @override
  String get tx_history_clear => 'Limpiar';

  @override
  String tx_history_filter_count(int filtered, int total, String description) {
    return '$filtered de $total transacciones - $description';
  }

  @override
  String get tx_history_filter_refunds => 'Reembolsos';

  @override
  String tx_history_filter_from(String date) {
    return 'Desde $date';
  }

  @override
  String tx_history_filter_until(String date) {
    return 'Hasta $date';
  }

  @override
  String get tx_history_filter_oldest_first => 'Más antiguos primero';

  @override
  String get tx_history_filter_default => 'Todos';

  @override
  String get pix_filter_status_pending => 'Pago Pendiente';

  @override
  String get pix_filter_status_processing => 'Procesando 1/2';

  @override
  String get pix_filter_status_finished => 'Enviado';

  @override
  String get pix_filter_status_expired => 'Expirado';

  @override
  String get address_explorer_title => 'Direcciones y UTXOs';

  @override
  String get address_explorer_search_hint => 'Buscar dirección…';

  @override
  String get address_explorer_search_match_onchain =>
      'Dirección encontrada en On-chain.';

  @override
  String get address_explorer_search_match_liquid =>
      'Dirección encontrada en Liquid.';

  @override
  String address_explorer_search_match_at_index(String chain, int index) {
    return '$chain · índice $index';
  }

  @override
  String get address_explorer_search_no_match =>
      'La dirección no pertenece a su billetera.';

  @override
  String get address_explorer_tab_onchain => 'On-chain';

  @override
  String get address_explorer_tab_liquid => 'Liquid';

  @override
  String address_explorer_load_more(int count) {
    return 'Cargar $count direcciones más';
  }

  @override
  String get address_explorer_loading_more => 'Cargando…';

  @override
  String get address_explorer_loading => 'Cargando direcciones…';

  @override
  String get address_explorer_empty => 'No se encontraron direcciones.';

  @override
  String address_explorer_load_error(String error) {
    return 'Error al cargar direcciones: $error';
  }

  @override
  String get address_explorer_address_copied => 'Dirección copiada';

  @override
  String get address_explorer_status_used => 'USADA';

  @override
  String get address_explorer_status_unused => 'NO USADA';

  @override
  String address_explorer_utxo_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count UTXOs',
      one: '1 UTXO',
      zero: 'sin UTXOs',
    );
    return '$_temp0';
  }

  @override
  String get address_explorer_utxos_section => 'UTXOs';

  @override
  String get address_explorer_utxos_tap_to_expand => 'tocar para expandir';

  @override
  String get address_explorer_utxos_tap_to_collapse => 'tocar para contraer';

  @override
  String address_explorer_summary(int total, int used, int utxos) {
    return '$total direcciones · $used usadas · $utxos UTXOs';
  }

  @override
  String address_explorer_summary_addresses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count direcciones',
      one: '1 dirección',
    );
    return '$_temp0';
  }

  @override
  String address_explorer_summary_status(int used, int unused) {
    return '$used usadas • $unused no usadas';
  }

  @override
  String address_explorer_summary_utxos_total(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count UTXOs',
      one: '1 UTXO',
      zero: 'sin UTXOs',
    );
    return '$_temp0';
  }

  @override
  String address_explorer_total_received(String amount) {
    return 'Recibido: $amount';
  }

  @override
  String get address_explorer_filter_all => 'Todas';

  @override
  String get address_explorer_filter_used => 'Usadas';

  @override
  String get address_explorer_filter_unused => 'No usadas';

  @override
  String get address_explorer_filter_with_utxos => 'Con UTXOs';

  @override
  String get address_explorer_filter_empty =>
      'Ninguna dirección coincide con el filtro actual.';

  @override
  String get address_explorer_full_address_title => 'Dirección';

  @override
  String get address_explorer_full_address_copy => 'Copiar dirección';

  @override
  String get address_explorer_close => 'Cerrar';

  @override
  String get address_ownership_title => 'Verificar dirección';

  @override
  String get address_ownership_description =>
      'Pegue una dirección para verificar la propiedad';

  @override
  String get address_ownership_subtitle => 'Compatible con Bitcoin y Liquid';

  @override
  String get address_ownership_input_hint => 'bc1q… / lq1… / 1A1z…';

  @override
  String get address_ownership_paste_tooltip => 'Pegar';

  @override
  String get address_ownership_clear_tooltip => 'Limpiar';

  @override
  String get address_ownership_verify => 'Verificar';

  @override
  String get address_ownership_verifying => 'Verificando…';

  @override
  String get address_ownership_clear => 'Limpiar';

  @override
  String get address_ownership_paste_feedback => 'Pegado desde el portapapeles';

  @override
  String get address_ownership_clear_feedback => 'Limpiado';

  @override
  String address_ownership_detected(String chain) {
    return 'Detectado: $chain';
  }

  @override
  String get address_ownership_invalid_format =>
      'Formato de dirección no válido';

  @override
  String get address_ownership_owned_title => 'Tu dirección';

  @override
  String get address_ownership_not_owned_title => 'No es tu dirección';

  @override
  String get address_ownership_field_type => 'Tipo';

  @override
  String get address_ownership_field_utxos => 'UTXOs';

  @override
  String get address_ownership_field_used => 'Usada';

  @override
  String get address_ownership_yes => 'Sí';

  @override
  String get address_ownership_no => 'No';

  @override
  String get address_ownership_chain_bitcoin => 'Bitcoin';

  @override
  String get address_ownership_chain_liquid => 'Liquid';

  @override
  String address_ownership_index_label(int index) {
    return 'índice $index';
  }

  @override
  String get address_ownership_status_used => 'usada';

  @override
  String get address_ownership_status_unused => 'no usada';

  @override
  String get settings_section_addresses => 'DIRECCIONES';

  @override
  String get settings_verify_address => 'Verificar dirección';

  @override
  String get settings_address_explorer => 'Direcciones y UTXOs';
}
