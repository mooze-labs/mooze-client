/// Source of logs to display
enum LogSource {
  memory('Memória'),
  database('Banco de Dados'),
  all('Todos');

  final String label;
  const LogSource(this.label);
}