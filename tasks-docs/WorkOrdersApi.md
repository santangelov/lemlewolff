# Work Orders API Usage

The **Work Orders API** provides a secured endpoint to return filtered work orders, with optional nested work-order item details.

## Endpoint
`POST /api/work-orders/query`

> Note: The legacy `/api/work-orders/search` alias was removed. Use `query` only.

## Authentication
This endpoint uses **Basic Authorization** with the same configured credentials as the Vacancy API.

### Required header
- `Authorization: Basic <credentials>`
- Credentials are validated against `VacancyApiAccountId` and `VacancyApiPassword` in `Web.config`.

Header format:

```http
Authorization: Basic base64(accountId:password)
```

If authorization fails, the API returns:
- HTTP `401 Unauthorized`
- `WWW-Authenticate: Basic realm="VacancyAPI"`

## Request Body
Send JSON in the POST body.

```json
{
  "Categories": ["APH-Plumbing"],
  "CompletionDateIsBlank": true,
  "WONumber": 490659,
  "BuildingNums": ["4114"],
  "JobStatus": "Open",
  "ItemCodes": ["12-123", "22-500"],
  "FilterItemCategories": ["Plumbing", "Electrical"],
  "IncludeWOItems": true
}
```

## Filter behavior
At least one **work-order-level** filter is required:
- `Categories`
- `CompletionDateIsBlank`
- `WONumber` (single value)
- `BuildingNums`
- `JobStatus`

`IncludeWOItems`, `ItemCodes`, and `FilterItemCategories` do **not** count toward the top-level required-filter rule.

If no work-order-level filter is provided, API returns `400`:

```json
{
  "message": "At least one filter is required (Categories, CompletionDateIsBlank, WONumber, BuildingNums, or JobStatus). Returning all work orders is not allowed."
}
```

## Item-level options
Use these when `IncludeWOItems` is `true`:
- `ItemCodes`: one or more item codes to limit returned item rows.
- `FilterItemCategories`: one or more item category names.

Item category names are sourced via join to `tblSortlyInventory` on `ItemCode` and returned as:
- `ItemCategoryName`

## Response shape
- Returns an array of work orders (all columns from `tblWorkOrders`).
- If `IncludeWOItems=true`, each work-order object includes `WorkOrderItems` (array).
- Each item row includes work-order item fields (`tblWorkOrderItems`) plus `ItemCategoryName` when available.

## Error behavior
- `401 Unauthorized`: invalid/missing Basic Authorization header.
- `400 Bad Request`: no valid top-level work-order filter provided.
- `403 Forbidden`: DB login cannot read work-order items table/procedure path when items are requested.
- `500 Internal Server Error`: unexpected processing failure.

## Database implementation notes
Filtering is implemented through stored procedures:
- `dbo.spWorkOrders`
- `dbo.spWorkOrderItems`

Both procedures are defined in:
- `LW_Data2/SQL scripts/spWorkOrders.sql`

Before using the API in a target environment, deploy that SQL script and ensure execute rights for the read-only app login (currently granted to `[lemwolffRO]` in the script).
