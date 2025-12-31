# VacancyAPI Usage

The **VacancyAPI** provides a lightweight HTTP GET endpoint to generate and download the Vacancy Cover Sheet Excel file using the existing report helper logic.

## Endpoint
`GET /VacancyApi/VacancyCoverSheet`

## Required query parameters
- `selectedBuildingCode` — property/building code to include in the report.
- `selectedAptNumber` — apartment/unit number to include in the report.

## Required header
- `Authorization: Basic <credentials>` where `<credentials>` can be either Base64-encoded `accountId:password` **or** the plain text `accountId:password` pair. Values come from `Web.config` (`VacancyApiAccountId` and `VacancyApiPassword`).

## Example request
```
GET https://<your-domain>/VacancyApi/VacancyCoverSheet?selectedBuildingCode=ABC123&selectedAptNumber=1A
Authorization: Basic MjAyNTEyMzA0NTQ6cUY5IW1aMkBMNyNSa0E4JFZ4
```

Plain-text credentials can also be supplied (they are still sent under the `Basic` scheme):

```
GET https://<your-domain>/VacancyApi/VacancyCoverSheet?selectedBuildingCode=ABC123&selectedAptNumber=1A
Authorization: Basic 20251230454:qF9!mZ2@L7#RkA8$Vx
```

## Behavior
- Returns HTTP 401 (with `WWW-Authenticate: Basic realm="VacancyAPI"`) when the Basic authorization header is missing or does not match the configured values.
- Returns HTTP 400 when either `selectedBuildingCode` or `selectedAptNumber` is missing.
- On success, returns the generated Excel file (`application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`) for download.
- Returns HTTP 500 if the report helper cannot create the Excel file.

**Note:** Basic auth is not encrypted by itself; use HTTPS so credentials (encoded or plain text) are protected in transit.

## Configuration
Credential values are stored in `Web.config` as `VacancyApiAccountId` and `VacancyApiPassword`. Update them there to rotate credentials or add additional sets in the future.
