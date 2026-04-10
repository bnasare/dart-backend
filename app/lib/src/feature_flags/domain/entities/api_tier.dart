enum ApiTier {
  sandbox('Sandbox'),
  standard('Standard'),
  enhanced('Enhanced'),
  enterprise('Enterprise');

  const ApiTier(this.label);

  final String label;
}
