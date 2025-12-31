# VacancyAPI Usage

The **VacancyAPI** provides a lightweight HTTP GET endpoint to generate and download the Vacancy Cover Sheet Excel file using the existing report helper logic.

## Endpoint
`GET /VacancyApi/VacancyCoverSheet`

## Required query parameters
- `selectedBuildingCode` — property/building code to include in the report.
- `selectedAptNumber` — apartment/unit number to include in the report.

## Required header
- `Authorization: Basic <base64(accountId:password)>` using the configured values in `Web.config` (`VacancyApiAccountId` and `VacancyApiPassword`).

## Example request
```
GET https://<your-domain>/VacancyApi/VacancyCoverSheet?selectedBuildingCode=ABC123&selectedAptNumber=1A
Authorization: Basic MjAyNTEyMzA0NTQ6cUY5IW1aMkBMNyNSa0E4JFZ4
```

## Behavior
- Returns HTTP 401 (with `WWW-Authenticate: Basic realm="VacancyAPI"`) when the Basic authorization header is missing or does not match the configured values.
- Returns HTTP 400 when either `selectedBuildingCode` or `selectedAptNumber` is missing.
- On success, returns the generated Excel file (`application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`) for download.
- Returns HTTP 500 if the report helper cannot create the Excel file.

## Configuration
Credential values are stored in `Web.config` as `VacancyApiAccountId` and `VacancyApiPassword`. Update them there to rotate credentials or add additional sets in the future.
