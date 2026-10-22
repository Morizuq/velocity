/// Defines whether a recurring cashflow is an incoming or outgoing commitment.
enum CashflowDirection {
  /// Monthly outgoings: Internet, Spotify, Rent, Utilities, Cloud SaaS.
  outflowPayable('Monthly Payable'),

  /// Monthly incomings: Salary, Fixed Monthly Retainers, Recurring Gigs, Stipends.
  inflowReceivable('Monthly Inflow');

  final String displayName;
  const CashflowDirection(this.displayName);
}
