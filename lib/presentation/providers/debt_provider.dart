// lib/presentation/providers/debt_provider.dart

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/debt_model.dart';

// ── Persons provider ─────────────────────────────────────────
class DebtPersonNotifier extends StateNotifier<List<DebtPerson>> {
  DebtPersonNotifier() : super([]) { _load(); }

  static const _key = 'debt_persons';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      state = list.map((e) => DebtPerson.fromJson(e as Map<String, dynamic>)).toList();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.map((p) => p.toJson()).toList()));
  }

  Future<void> addPerson(DebtPerson person) async {
    state = [...state, person];
    await _save();
  }

  Future<void> updatePerson(DebtPerson person) async {
    state = state.map((p) => p.id == person.id ? person : p).toList();
    await _save();
  }

  Future<void> deletePerson(String id) async {
    state = state.where((p) => p.id != id).toList();
    await _save();
  }
}

final debtPersonsProvider =
    StateNotifierProvider<DebtPersonNotifier, List<DebtPerson>>(
        (ref) => DebtPersonNotifier());

// ── Debt transactions provider ───────────────────────────────
class DebtTransactionNotifier extends StateNotifier<List<DebtTransaction>> {
  DebtTransactionNotifier() : super([]) { _load(); }

  static const _key = 'debt_transactions';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      state = list.map((e) => DebtTransaction.fromJson(e as Map<String, dynamic>)).toList();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.map((t) => t.toJson()).toList()));
  }

  Future<void> add(DebtTransaction tx) async {
    state = [...state, tx];
    await _save();
  }

  Future<void> delete(String id) async {
    state = state.where((t) => t.id != id).toList();
    await _save();
  }

  List<DebtTransaction> forPerson(String personId) =>
      state.where((t) => t.personId == personId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  // Positive = person owes me, Negative = I owe person
  double netForPerson(String personId) {
    return forPerson(personId).fold(0.0, (sum, t) {
      return t.type == DebtType.gave ? sum + t.amount : sum - t.amount;
    });
  }
}

final debtTransactionsProvider =
    StateNotifierProvider<DebtTransactionNotifier, List<DebtTransaction>>(
        (ref) => DebtTransactionNotifier());

// ── Helper: net balance per person ───────────────────────────
final personNetProvider = Provider.family<double, String>((ref, personId) {
  final txs = ref.watch(debtTransactionsProvider);
  return txs
      .where((t) => t.personId == personId)
      .fold(0.0, (sum, t) => t.type == DebtType.gave ? sum + t.amount : sum - t.amount);
});

// ── Total I am owed (across all persons) ─────────────────────
final totalOwedToMeProvider = Provider<double>((ref) {
  final txs = ref.watch(debtTransactionsProvider);
  return txs.fold(0.0, (sum, t) => t.type == DebtType.gave ? sum + t.amount : sum - t.amount);
});
