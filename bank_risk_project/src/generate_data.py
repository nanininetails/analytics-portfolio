import numpy as np
import pandas as pd
from numpy.random import default_rng

rng  = default_rng(1)

N_CUSTOMERS = 2000

customers = pd.DataFrame({
    "customer_id": range(1, N_CUSTOMERS + 1),
    "segment": rng.choice(
        ["Retail", "SME-lite"],
        size=N_CUSTOMERS,
        p=[0.7,0.3]
    ),
    "region": rng.choice(
        ["North", "South", "East", "West"],
        size=N_CUSTOMERS
    )
})

ACCOUNT_BEHAVIOUR_PROBS = {
    "Stable" : 0.45,
    "Growing" : 0.20,
    "Volatile" : 0.15,
    "Deteriorating" : 0.15,
    "Shock" : 0.05
}

behaviour_types = list(ACCOUNT_BEHAVIOUR_PROBS.keys())
behaviour_probs = list(ACCOUNT_BEHAVIOUR_PROBS.values())

accounts = []
account_id = 1

for _, cust in customers.iterrows():
    segment = cust["segment"]

    if segment == "Retail":
        n_account = rng.choice([1,2],p=[0.7,0.3])
        account_type = "Credit Card"
        limit_low, Limit_high = 50_000, 300_000
    else:
        n_account = rng.choice([1,2],p=[0.6,0.4])
        account_type = "Loan"
        limit_low, Limit_high = 300_000, 2_000_000
    
    for _ in range(n_account):
        accounts.append({
            "account_id": account_id,
            "customer_id": cust["customer_id"],
            "account_type": account_type,
            "credit_limit": rng.integers(limit_low,Limit_high),
            "behaviour_type": rng.choice(behaviour_types,p=behaviour_probs)
        })
        account_id += 1

accounts = pd.DataFrame(accounts)

MONTHS = pd.date_range(
    start="2023-01-01",
    periods=24,
    freq="MS"
)

def generate_utilization_series(behaviour, n_months, rng):
    util = []

    if behaviour == "Stable":
        base = rng.uniform(0.25,0.45)
        for _ in range(n_months):
            util.append(np.clip(base+rng.normal(0,0.03),0.15,0.6))

    elif behaviour == "Growing":
        base = rng.uniform(0.3,0.4)
        slope = rng.uniform(0.01,0.02)
        for i in range(n_months):
            util.append(np.clip(base + i*slope,0.15,0.9))
    
    elif behaviour == "Volatile":
        base = rng.uniform(0.2,0.8)
        for _ in range(n_months):
            util.append(np.clip(base,0.15,0.9))

    elif behaviour == "Deteriorating":
        base = rng.uniform(0.35,0.45)
        slope = rng.uniform(0.015,0.025)
        for i in range(n_months):
            util.append(np.clip(base + i*slope,0.2,0.95))

    elif behaviour == "Shock":
        shock_month = rng.integers(6, n_months - 3)
        for i in range(n_months):
            if i == shock_month:
                util.append(rng.uniform(0.9, 0.98))
            else:
                util.append(rng.uniform(0.25, 0.45))

    return util

monthly_rows = []

for _, acc in accounts.iterrows():
    util_series = generate_utilization_series(
        acc["behaviour_type"],
        len(MONTHS),
        rng
    )

    for month, util in zip(MONTHS,util_series):
        balance = util * acc["credit_limit"]

        # Transactions proxy
        if acc["account_type"] == "Credit Card":
            txns = int(rng.normal(30, 10))
        else:
            txns = int(rng.normal(5, 2))

        txns = max(txns, 0)

        # Missed payments
        missed = 0
        if acc["behaviour_type"] in ["Volatile", "Deteriorating"]:
            if rng.random() < 0.1:
                missed = 1

        if acc["behaviour_type"] == "Shock" and util > 0.9:
            missed = rng.choice([1, 2])

        monthly_rows.append({
            "account_id": acc["account_id"],
            "month": month,
            "outstanding_balance": round(balance, 2),
            "utilization_pct": round(util * 100, 2),
            "total_transactions": txns,
            "missed_payments": missed
        })

monthly_activity = pd.DataFrame(monthly_rows)
