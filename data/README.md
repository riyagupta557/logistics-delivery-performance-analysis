# Data Inspection & Cleaning Summary

## 📂 Dataset

- [Brazilian E-Commerce Public Dataset by Olist – Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)


| Table | Rows | Columns |
|---|---|---|
| orders | 99,441 | 8 |
| order_items | 112,650 | 7 |
| products | 32,951 | 9 |
| product_category_translation | 71 | 2 |
| sellers | 3,095 | 4 |
| customers | 99,441 | 5 |
| order_payments | 103,886 | 5 |
| order_reviews | 99,224 | 7 |

**Not used:** the Olist geolocation table was used only as a lookup reference while correcting city names. It is not part of the analysis model.


## 2. Table-by-table summary

### 2.1 Orders

**Inspection findings**

- 99,441 rows, 8 columns.
- Missing values: `order_approved_at` (160), `order_delivered_carrier_date` (1,783), `order_delivered_customer_date` (2,965).
- 8 orders had `order_status = Delivered` but no customer delivery date.
- 1,359 orders had a carrier handover timestamp earlier than the approval timestamp.
- 23 delivered orders (2016-2017) had a carrier handover timestamp later than the customer delivery timestamp.

**Cleaning actions**

| Issue | Action | Reason |
|---|---|---|
| Extra spaces and non-printable characters in text columns | Applied Trim and Clean | Hidden characters cause joins and filters to silently miss matches. |
| Inconsistent `order_status` values | Standardised the values | Gives consistent grouping and filtering. |
| 8 orders marked "Delivered" with no delivery date | **Removed** (8 of 99,441, under 0.01%), along with their related rows in order_items, order_payments and order_reviews | Delivery days and late/on-time status cannot be calculated without the delivery date. Keeping them would make "total delivered orders" and "average delivery days" use different sets of orders. Filling the dates with guesses would invent data. |
| Nulls in the three date columns for other orders | **Kept as null** | These are mostly canceled or undelivered orders, so a missing delivery date is expected. No reliable information exists to fill them. |
| Carrier handover earlier than approval (1,359 rows) | **Flagged** with `Carrier_Before_Approval_Flag`; original timestamps preserved | The cause is unclear (possible system timing or logging), so changing dates would be guessing. A flag keeps the data and lets the analysis filter these rows if needed. |
| 23 delivered orders with handover after delivery (2016-2017) | **Kept** for delivery-time and review analysis; **excluded** from the handover-deadline analysis | Their delivery date and review are valid, but the handover timestamp is unreliable, so it should not be used to judge missed seller deadlines. |

**Definition used in analysis:** a delivered order is one with `order_status = Delivered` and a valid `order_delivered_customer_date`. Canceled or undelivered orders are excluded from delivery KPIs.


### 2.2 Order items

| Check | Finding | Decision | Reason |
|---|---|---|---|
| Rows and columns | 112,650 rows, 7 columns | Verified | – |
| Missing values | None | No action | – |
| Data types | Correct | No conversion | – |
| Negative or zero prices | None | No action | – |
| Duplicate order-item keys | None | Passed | – |
| Zero freight values | 383 | **Kept** and documented | Free shipping is a valid business case, so these are real values, not errors. |


### 2.3 Products

**Inspection findings**

- 610 rows with missing category name, name length, description length and photo count.
- 2 rows missing weight and all dimensions (the same rows).
- 4 rows with `product_weight_g = 0`.
- 74 distinct values in the products table (73 named categories plus blank).

**Cleaning actions**

| Issue | Action | Reason |
|---|---|---|
| Extra spaces and hidden characters in `product_id` and `product_category_name` | Applied Trim and Clean | Prevents join mismatches. |
| 610 blank category names | Replaced with `unknown` | Keeps these products in category analysis as their own group instead of dropping them or hiding them as nulls. |
| 2 products with missing weight and dimensions | **Kept as null** | The real values are unknowable, and products are still needed for order-level analysis. |
| 4 products with weight 0 | **Kept** and documented as a data-quality risk | A zero weight is implausible, but weight is not a metric in this project, so deleting would lose valid orders. |
| `product_name_lenght`, `product_description_lenght`, `product_photos_qty` | **Removed** | Do not contribute to the analysis meaningfully.



### 2.4 Product category translation

| Issue | Action | Reason |
|---|---|---|
| 71 categories, no missing or duplicate values | Verified | – |
| 2 categories in products had no translation: `pc_gamer` (3 products) and `portateis_cozinha_e_preparadores_de_alimentos` (10 products) | Added mappings: `PC Gaming` and `Portable Kitchens and Food Processors` (table now 73 rows) | Without them, 13 products would show a blank English category in reports. |

**Final merge:** Products were joined to the translation table with a **Left Outer Join** on `product_category_name`, and the English category was added as a new column. A left join keeps every product, including those with an `unknown` category. The Portuguese column is retained alongside the English one.


### 2.5 Sellers

**Inspection findings:** 3,095 rows, 4 columns, no missing values, `seller_id` unique. `seller_city` contained typos, misspellings, state or country text inside the city, and invalid entries.

**Cleaning actions (68 rows changed, 611 → 554 unique cities)**

| Issue | Example (before → after) | Reason |
|---|---|---|
| Typos | `sao pauo` → `sao paulo`; `cascavael` → `cascavel` | One city spelled several ways would split the city's late-delivery rate across groups. |
| State or country text in the city | `lages - sc` → `lages`; `novo hamburgo, rio grande do sul, brasil` → `novo hamburgo` | The state is already in its own column. |
| Extra spaces | `ferraz de  vasconcelos` → `ferraz de vasconcelos` | Double spaces make identical cities group separately. |
| Accents and special characters | `são paulo` → `sao paulo`; `d´oeste` → `d'oeste` | Matches the plain-text spelling used in the rest of the data. |
| Abbreviations | `sbc` → `sao bernardo do campo` | Expanded to the full name for consistent grouping. |
| Invalid values (state names, numbers, email address) | `sp`, `parana`, `04482255`, an email address → a real city | Not cities, so they would appear as false locations in seller-location results. |

**Method:** city names were checked against real city names. For invalid entries such as `sp` or `parana`, the correct city was found by looking up the zip code prefix in the Olist geolocation table.



### 2.6 Customers

**Inspection findings:** 99,441 rows, 5 columns, no missing values, `customer_id` unique. `customer_unique_id` repeats for returning customers, which is expected. `customer_city` had formatting and spelling inconsistencies.

**Cleaning actions (289 rows changed across 32 distinct city names, 4,119 → 4,107 unique cities)**

| Issue | Example (before → after) | Rows | Reason |
|---|---|---|---|
| Hyphens inside names | `mogi-guacu` → `mogi guacu` | about 215 | Brings hyphenated names in line with one consistent spelling style. |
| Missing apostrophes | `santa barbara d oeste` → `santa barbara d'oeste` | about 10 | Matches the same cities already spelled correctly elsewhere in the data. |
| Typos | `piumhii` → `piumhi`; `itapage` → `itapaje` | about 42 | Prevents one city from being counted as two. |
| Non-official names | `parati` → `paraty`; `embu` → `embu das artes` | 24 | Uses the official name so it matches maps and the sellers table. |



### 2.7 Order payments

**Inspection findings:** 103,886 rows, 5 columns, no missing values. `order_id` repeats by design (one row per payment), and `order_id + payment_sequential` is unique. 9 rows had `payment_value = 0`, and one order had 29 voucher payment records.

**Cleaning actions**

| Issue | Action | Reason |
|---|---|---|
| 3 rows with `payment_type = not_defined` (value 0) | **Removed** | A placeholder, not a real payment method. No revenue was lost, and payment-type counts stay accurate. |
| 2 credit card rows with `payment_installments = 0` | Set to **null** | Zero installments is impossible and the real number cannot be known. Payment amounts were kept, so revenue is unaffected. |
| 6 voucher rows with `payment_value = 0` | **Kept** | Valid zero-value voucher payments. |
| One order with 29 voucher payments | **Kept** | Consistent with how split voucher payments are recorded; not an error. |
| 80 orders where `payment_sequential` does not start at 1 | **Kept**, documented | The missing payment rows cannot be recovered, and the impact is tiny. |


### 2.8 Order reviews

**Inspection findings**

- 99,224 rows, 7 columns. `review_score` is always 1 to 5 with no blanks, and no answer comes before its creation date.
- `review_comment_title` is 88% blank and `review_comment_message` is 59% blank.
- 547 orders have 2 or 3 reviews (551 extra rows). 202 of these have different scores for the same order.
- 789 `review_id` values repeat across different orders.

**Cleaning actions (99,224 → 98,673 rows, 7 → 2 columns, one row per order)**

| Issue | Action | Reason |
|---|---|---|
| Orders with multiple reviews | Sorted by `review_answer_timestamp` (newest first), buffered the sort, and removed duplicates on `order_id`, keeping the **latest review** | Joining as is would duplicate orders and distort late-delivery rates and review averages. The latest review is the customer's final opinion. |
| `review_comment_title`, `review_comment_message` | **Removed** | Mostly blank, free Portuguese text with line breaks and commas, and not used by any question. |
| `review_id` | **Removed** | Not a reliable key (789 IDs repeat across orders) and not needed. |
| `review_creation_date`, `review_answer_timestamp` | **Removed** | The time trend uses order dates, and the answer timestamp was only needed to pick the latest review. |


### After Cleaning

| Table | Rows | Columns |
|---|---|---|
| orders | 99,433 | 9 |
| order_items | 112,650 | 7 |
| products | 32,951 | 7 |
| product_category_translation | 73 | 2 |
| sellers | 3,095 | 4 |
| customers | 99,441 | 5 |
| order_payments | 103,883 | 5 |
| order_reviews | 98,673 | 2 |


## 3. Assumptions and limitations

- **Removed orders:** 8 orders (under 0.01%) were removed from delivery KPIs because their delivery date is unknown.
- **Timestamp inconsistencies:** 1,359 carrier-before-approval rows are flagged, not corrected, and 23 delivered orders have unreliable handover timestamps, so they are excluded from the handover-deadline analysis only.
- **Latest-review rule:** keeping only the newest review is a judgment call that affects about 0.2% of orders.
- **City cleaning:** corrected city names came from online checks and zip prefix lookups. `seller_state` and `customer_state` were not re-validated against zip prefixes.
- **Zero values:** 383 zero-freight rows and 4 zero-weight products were kept and not corrected.

