/// Who pays a Pix charge of the deposit flow.
///
/// The provider requires the CPF or CNPJ of the payer, so the flow must know
/// whose document to use.
enum PixChargePayer {
  /// The user, from their own bank account: a deposit into their wallet.
  self,

  /// Another person: a charge that the user shows to someone else.
  someoneElse;

  /// Value of the `payer` query parameter of the deposit routes.
  static const String queryKey = 'payer';

  /// Reads the `payer` query parameter. Any value other than `other` is the
  /// user's own deposit, as before the parameter existed.
  static PixChargePayer fromQuery(Map<String, String> query) =>
      query[queryKey] == 'other' ? someoneElse : self;

  /// The query string that carries this payer to the next route.
  String get query => this == someoneElse ? '?$queryKey=other' : '';
}
