/// Classe de dados para representar uma página do onboarding
class OnboardingPageData {
  final String title;
  final String subtitle;

  const OnboardingPageData({required this.title, required this.subtitle});
  // Data
  static const List<OnboardingPageData> pages = [
    OnboardingPageData(
      title: 'Seu dinheiro, sob seu controle',
      subtitle:
          'Receba, envie e gerencie Bitcoin com privacidade real. Nada de KYC. Nada de rastreamento. Uma carteira feita pra quem valoriza liberdade.',
    ),
    OnboardingPageData(
      title: 'Segurança em primeiro lugar',
      subtitle:
          'Sua chave, sua responsabilidade. Proteja seu patrimônio com criptografia e backups locais.',
    ),
    OnboardingPageData(
      title: 'Pronto para começar?',
      subtitle:
          'Crie ou importe sua carteira em segundos e assuma o controle do seu Bitcoin.',
    ),
  ];
}
