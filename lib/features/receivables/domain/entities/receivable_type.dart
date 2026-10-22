
/// Categorizes the origin of a receivable claim.
enum ReceivableType {
  /// Formal freelance or contractor invoice.
  freelanceInvoice('Freelance Invoice'),

  /// Personal loan or informal IOU extended to an individual.
  personalLoan('Personal Loan'),

  /// Corporate expense, medical claim, or peer reimbursement pending return.
  reimbursement('Reimbursement');

  final String displayName;
  const ReceivableType(this.displayName);
}
