import 'package:flutter/material.dart';
import 'package:uni_swap/controller/api_client.dart';
import 'package:uni_swap/controller/app_controllers.dart';
import 'package:uni_swap/model/admin_transactions.dart';
import 'package:uni_swap/model/format.dart';
import 'package:uni_swap/model/order.dart';

const _cBg = Color(0xFFFAF9F6);
const _cCard = Color(0xFFFFFFFF);
const _cInk = Color(0xFF2B2B26);
const _cMuted = Color(0xFF8A8A82);
const _cBorder = Color(0xFFE6E4DE);
const _cAmberBg = Color(0xFFFBEBC2);
const _cAmberFg = Color(0xFF8A6410);
const _cGreenBg = Color(0xFFE1EEE5);
const _cGreenFg = Color(0xFF3F6B52);
const _cRedBg = Color(0xFFF8DADA);
const _cRedFg = Color(0xFFB3402F);

class AdminTransactionsPage extends StatefulWidget {
  const AdminTransactionsPage({super.key});

  @override
  State<AdminTransactionsPage> createState() => _AdminTransactionsPageState();
}

class _AdminTransactionsPageState extends State<AdminTransactionsPage> {
  AdminTransactionSummary _summary = const AdminTransactionSummary();
  final List<Order> _transactions = [];
  String _payoutFilter = 'all';
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _page = 1;
  String? _error;
  int? _busyOrderId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool loadMore = false}) async {
    if (loadMore && (_loadingMore || !_hasMore)) return;
    setState(() {
      if (loadMore) {
        _loadingMore = true;
      } else {
        _loading = true;
        _error = null;
      }
    });
    final requestedPage = loadMore ? _page + 1 : 1;
    try {
      final response = await adminController.completedTransactions(
        payoutStatus: _payoutFilter,
        page: requestedPage,
        limit: 20,
      );
      if (response['success'] == false) {
        throw ApiException(
          response['message']?.toString() ?? 'Could not load sales history.',
        );
      }
      final report = AdminTransactionsReport.fromJson(response);
      if (!mounted) return;
      setState(() {
        _summary = report.summary;
        if (loadMore) {
          _transactions.addAll(report.transactions);
        } else {
          _transactions
            ..clear()
            ..addAll(report.transactions);
        }
        _page = report.page;
        _hasMore = report.hasMore;
        _error = null;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load sales history.');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _setFilter(String filter) async {
    if (filter == _payoutFilter) return;
    setState(() {
      _payoutFilter = filter;
      _transactions.clear();
      _page = 1;
      _hasMore = false;
    });
    await _load();
  }

  Future<void> _recordPayout(Order order) async {
    final transferRef = await showDialog<String>(
      context: context,
      builder: (_) => _RecordSellerPayoutDialog(
        sellerName: order.sellerName ?? 'the seller',
        amount: order.sellerPayout,
      ),
    );
    if (transferRef == null || !mounted) return;

    setState(() => _busyOrderId = order.id);
    try {
      await adminController.recordSellerPayout(
        order.id,
        transferRef: transferRef.isEmpty ? null : transferRef,
      );
      await _load();
      if (mounted) {
        _snack(context, 'Payout recorded.');
      }
    } on ApiException catch (error) {
      if (mounted) {
        _snack(context, error.message);
      }
    } finally {
      if (mounted) setState(() => _busyOrderId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cBg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: 'Sales & payouts',
              subtitle: '${_summary.completedSales} completed sales',
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _load(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    const _DemoNotice(),
                    const SizedBox(height: 16),
                    _Summary(summary: _summary),
                    const SizedBox(height: 24),
                    const Text(
                      'All sales',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _cInk,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        _filterChip('All', 'all'),
                        _filterChip('To pay', 'pending'),
                        _filterChip('Paid', 'paid'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_loading && _transactions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null && _transactions.isEmpty)
                      _EmptyMessage(message: _error!, onRetry: _load)
                    else if (_transactions.isEmpty)
                      const _EmptyMessage(message: 'No completed sales yet.')
                    else ...[
                      for (final order in _transactions)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _TransactionCard(
                            order: order,
                            busy: _busyOrderId == order.id,
                            onRecordPayout: () => _recordPayout(order),
                          ),
                        ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      if (_hasMore)
                        OutlinedButton(
                          onPressed: _loadingMore
                              ? null
                              : () => _load(loadMore: true),
                          child: _loadingMore
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Load more'),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _payoutFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: _cInk,
      backgroundColor: _cCard,
      side: const BorderSide(color: _cBorder),
      labelStyle: TextStyle(
        color: selected ? Colors.white : _cInk,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (_) => _setFilter(value),
    );
  }
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cAmberBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: _cAmberFg),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Demo records: buyer payment is simulated. Mark a seller as paid '
              'only after you have transferred the money outside the app.',
              style: TextStyle(color: _cAmberFg, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordSellerPayoutDialog extends StatefulWidget {
  const _RecordSellerPayoutDialog({
    required this.sellerName,
    required this.amount,
  });

  final String sellerName;
  final double amount;

  @override
  State<_RecordSellerPayoutDialog> createState() =>
      _RecordSellerPayoutDialogState();
}

class _RecordSellerPayoutDialogState extends State<_RecordSellerPayoutDialog> {
  final _referenceController = TextEditingController();

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _cBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Confirm payout',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: _cInk,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirm that you have transferred ${formatPriceTHB(widget.amount)} '
            'to ${widget.sellerName} outside the app. '
            'This only records the payout; it does not transfer money.',
            style: const TextStyle(fontSize: 13, color: _cInk),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _referenceController,
            maxLength: 150,
            decoration: InputDecoration(
              labelText: 'Transfer reference (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _cBorder),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: _cMuted),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, _referenceController.text.trim()),
          style: FilledButton.styleFrom(
            backgroundColor: _cInk,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Confirm paid'),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.summary});

  final AdminTransactionSummary summary;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _SummaryCard(
          title: 'Completed sales',
          value: '${summary.completedSales}',
        ),
        _SummaryCard(
          title: 'Total sales',
          value: formatPriceTHB(summary.grossSales),
        ),
        _SummaryCard(
          title: 'UniSwap fees',
          value: formatPriceTHB(summary.commissionIncome),
        ),
        _SummaryCard(
          title: 'To pay sellers',
          value: formatPriceTHB(summary.pendingSellerPayouts),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.sizeOf(context).width - 50) / 2,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cCard,
        border: Border.all(color: _cBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: _cMuted)),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _cInk,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.order,
    required this.busy,
    required this.onRecordPayout,
  });

  final Order order;
  final bool busy;
  final VoidCallback onRecordPayout;

  @override
  Widget build(BuildContext context) {
    final transferStatus = order.sellerTransferStatus ?? 'not_ready';
    final payoutPending =
        transferStatus == 'pending' || transferStatus == 'processing';
    final payoutLabel = switch (transferStatus) {
      'pending' || 'processing' => 'Awaiting payout',
      'paid' => 'Paid out',
      'failed' => 'Payout failed',
      _ => transferStatus.replaceAll('_', ' '),
    };
    final completedAt = order.receivedAt ?? order.createdAt;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cCard,
        border: Border.all(color: _cBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.productTitle ?? 'Item',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _cInk,
                  ),
                ),
              ),
              _StatusLabel(text: payoutLabel, status: transferStatus),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${orderLabel(order.id)} · ${completedAt == null ? 'Date unavailable' : formatWhen(completedAt.toLocal())}',
            style: const TextStyle(fontSize: 11, color: _cMuted),
          ),
          const SizedBox(height: 10),
          Text(
            '${order.buyerName ?? 'Buyer'} → ${order.sellerName ?? 'Seller'}',
            style: const TextStyle(fontSize: 12, color: _cInk),
          ),
          const Divider(height: 20, color: _cBorder),
          _MoneyLine(label: 'Sale price', amount: order.totalAmount),
          _MoneyLine(label: 'UniSwap fee', amount: order.commissionAmount),
          _MoneyLine(label: 'Seller receives', amount: order.sellerPayout),
          if (order.sellerTransferRef?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Reference: ${order.sellerTransferRef}',
                style: const TextStyle(fontSize: 11, color: _cMuted),
              ),
            ),
          if (order.sellerPaidAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Paid on: ${formatWhen(order.sellerPaidAt!.toLocal())}',
                style: const TextStyle(fontSize: 11, color: _cMuted),
              ),
            ),
          if (payoutPending) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _cInk,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: busy ? null : onRecordPayout,
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Mark as paid'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MoneyLine extends StatelessWidget {
  const _MoneyLine({required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: _cMuted),
            ),
          ),
          Text(
            formatPriceTHB(amount),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _cInk,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.text, required this.status});

  final String text;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: switch (status) {
          'paid' => _cGreenBg,
          'failed' => _cRedBg,
          _ => _cAmberBg,
        },
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: switch (status) {
            'paid' => _cGreenFg,
            'failed' => _cRedFg,
            _ => _cAmberFg,
          },
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _cInk,
      ),
    );
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _cInk,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: _cMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
