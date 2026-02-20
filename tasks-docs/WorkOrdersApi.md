# Work Orders API

## Endpoint
- **Method:** `POST`
- **Route:** `/WorkOrdersApi/Search`

## Authentication
This endpoint uses **Basic Auth** with the **same credentials and config keys as the existing Vacancy API** (`VacancyApiAccountId` / `VacancyApiPassword` in `Web.config`).

Header format:

```http
Authorization: Basic base64(accountId:password)
```

If unauthorized, the API returns `401` and includes:

```http
WWW-Authenticate: Basic realm="VacancyAPI"
```

## Request Body

```json
{
  "Categories": ["APH-Plumbing"],
  "CompletionDateIsBlank": true,
  "WONumbers": [490659],
  "BuildingNums": ["4114"],
  "JobStatus": "Open",
  "IncludeWOItems": true
}
```

### Example 1: filter by `BuildingNums` + `JobStatus`

```json
{
  "BuildingNums": ["4114", "0029"],
  "JobStatus": "Open"
}
```

### Example 2: filter by `Categories` + `CompletionDateIsBlank=true` + `IncludeWOItems=true`

```json
{
  "Categories": ["APH-Plumbing", "APH-Electrical"],
  "CompletionDateIsBlank": true,
  "IncludeWOItems": true
}
```

## Guardrail Rule
At least one filter is required. Valid filters are:
- `Categories`
- `CompletionDateIsBlank`
- `WONumbers`
- `BuildingNums`
- `JobStatus`

`IncludeWOItems` **does not** count as a filter by itself.

If no filter is provided, API returns `400` with:

```json
{
  "message": "At least one filter is required (Categories, CompletionDateIsBlank, WONumbers, BuildingNums, or JobStatus). Returning all work orders is not allowed."
}
```

## Sample Response

> Returns an array of work orders with all columns from `tblWorkOrders`.

```json
[
  {
    "MLID": 123,
    "WONumber": 490659,
    "CallDate": "2026-02-01T00:00:00",
    "BuildingNum": "4114",
    "AptNum": "5K",
    "JobStatus": "Open",
    "ScheduledCompletedDate": null,
    "BatchID": null,
    "BatchDate": null,
    "TransBatchDate": null,
    "InvoiceDate": null,
    "PostedMonth": "2026-02",
    "BriefDesc": "...",
    "Category": "APH-Plumbing",
    "ExpenseType": "...",
    "InitialEstPrice": 0.00,
    "SellingPricing": 0.00,
    "MaterialPricingMarkupDesc": "...",
    "JobAssigned_Outside": "...",
    "PONumbers": "...",
    "POVendors": "...",
    "VendorInvoiceAmt": 0.00,
    "MaterialFromInventCost": 0.00,
    "PurchasedMaterialCost": 0.00,
    "TotalMaterialCost": 0.00,
    "TotalMaterialPricing": 0.00,
    "LaborCost_Outside": 0.00,
    "CompletedDate": null,
    "DateOfSale": null,
    "SchedDate": null,
    "LaborPricing_Outside": 0.00,
    "LaborAdj_OT": 0.00,
    "Labor_Total": 0.00,
    "Labor_MarkUp": 0.00,
    "TotalMaterialsLaborAndOL": 0.00,
    "FinalSalePrice": 0.00,
    "SalesTax": 0.00,
    "InvoicePrice": 0.00,
    "GrossProfit": 0.00,
    "CostPlusOH": 0.00,
    "NetProfit": 0.00,
    "GrossProfitMargin_Pct": 0.00,
    "NetProfitMargin_Pct": 0.00,
    "rowCreateDate": "2026-02-01T00:00:00",
    "rowUpdateDate": "2026-02-02T00:00:00",
    "yardiCreateDate": "2026-02-01T00:00:00",
    "yardiUpdateDate": "2026-02-02T00:00:00",
    "WorkOrderItems": [
      {
        "WOItemRowID": 1,
        "YardiWODetailRowID": 10001,
        "WONumber": 490659,
        "ItemCode": "12-123",
        "Quantity": 2,
        "PayAmount": 19.95,
        "FullDescription": "Supply line"
      }
    ]
  }
]
```

## Public API Organization Note
Public API controllers are now organized under `Controllers/PublicAPI/`:
- Vacancy API controller
- Properties API controller file (renamed from `APIController.cs`)
- Work Orders API controller

This is an internal organization change only. Existing external route usage remains compatible.
