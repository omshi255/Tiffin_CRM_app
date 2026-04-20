import mongoose from "mongoose";

function asObjectId(id) {
  if (!id) return null;
  if (id instanceof mongoose.Types.ObjectId) return id;
  if (!mongoose.Types.ObjectId.isValid(id)) return null;
  return new mongoose.Types.ObjectId(id);
}

function money(n) {
  const v = Number(n || 0);
  return Number.isFinite(v) ? v : 0;
}

/**
 * Build a reusable finance summary aggregation pipeline for Transaction.
 *
 * Rules:
 *  revenue  = processed + completed + credit
 *  incomes  = income    + completed + credit
 *  deposits = deposit   + completed + credit
 *  expenses = expense   + completed + debit
 *  refunds  = refund    + completed + debit
 *
 * Returns: { revenue, incomes, deposits, expenses, refunds, gross_income, net_profit, pending_cash }
 */
export function getFinanceSummary(ownerId, matchQuery = {}) {
  const ownerOid = asObjectId(ownerId);
  if (!ownerOid) {
    throw new Error("Invalid ownerId");
  }

  const baseMatch = {
    ownerId: ownerOid,
    status: "completed",
    ...matchQuery,
  };

  const sumFacet = (financeType, type) => [
    { $match: { financeType, type } },
    { $group: { _id: null, total: { $sum: { $ifNull: ["$amount", 0] } } } },
    { $project: { _id: 0, total: 1 } },
  ];

  return [
    { $match: baseMatch },
    {
      $facet: {
        revenue: sumFacet("processed", "credit"),
        incomes: sumFacet("income", "credit"),
        deposits: sumFacet("deposit", "credit"),
        expenses: sumFacet("expense", "debit"),
        refunds: sumFacet("refund", "debit"),
      },
    },
    {
      $project: {
        revenue: { $ifNull: [{ $first: "$revenue.total" }, 0] },
        incomes: { $ifNull: [{ $first: "$incomes.total" }, 0] },
        deposits: { $ifNull: [{ $first: "$deposits.total" }, 0] },
        expenses: { $ifNull: [{ $first: "$expenses.total" }, 0] },
        refunds: { $ifNull: [{ $first: "$refunds.total" }, 0] },
      },
    },
    {
      $addFields: {
        gross_income: { $add: ["$revenue", "$incomes"] },
      },
    },
    {
      $addFields: {
        net_profit: { $subtract: [{ $subtract: ["$gross_income", "$refunds"] }, "$expenses"] },
        pending_cash: { $subtract: ["$gross_income", "$deposits"] },
      },
    },
    {
      $project: {
        revenue: 1,
        incomes: 1,
        deposits: 1,
        expenses: 1,
        refunds: 1,
        gross_income: 1,
        net_profit: 1,
        pending_cash: 1,
      },
    },
  ];
}

export function normalizeFinanceSummary(doc) {
  const o = doc || {};
  const revenue = money(o.revenue);
  const incomes = money(o.incomes);
  const deposits = money(o.deposits);
  const expenses = money(o.expenses);
  const refunds = money(o.refunds);
  const gross_income = money(o.gross_income ?? revenue + incomes);
  const net_profit = money(o.net_profit ?? gross_income - refunds - expenses);
  const pending_cash = money(o.pending_cash ?? gross_income - deposits);

  return {
    revenue,
    incomes,
    deposits,
    expenses,
    refunds,
    gross_income,
    net_profit,
    pending_cash,
  };
}

