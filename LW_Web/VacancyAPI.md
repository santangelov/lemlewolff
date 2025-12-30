# VacancyAPI Usage

The **VacancyAPI** provides a lightweight HTTP GET endpoint to generate and download the Vacancy Cover Sheet Excel file using the existing report helper logic.

## Endpoint
`GET /VacancyApi/VacancyCoverSheet`

## Required query parameters
- `accountId` — credential identifier. Use the configured value in `Web.config` (`VacancyApiAccountId`).
- `password` — credential secret. Use the configured value in `Web.config` (`VacancyApiPassword`).
- `selectedBuildingCode` — property/building code to include in the report.
- `selectedAptNumber` — apartment/unit number to include in the report.

## Example request
```
GET https://<your-domain>/VacancyApi/VacancyCoverSheet?accountId=20251230454&password=qF9!mZ2@L7#RkA8$Vx&selectedBuildingCode=ABC123&selectedAptNumber=1A
```

## Behavior
- Returns HTTP 401 when `accountId` or `password` do not match the configured values.
- Returns HTTP 400 when either `selectedBuildingCode` or `selectedAptNumber` is missing.
- On success, returns the generated Excel file (`application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`) for download.
- Returns HTTP 500 if the report helper cannot create the Excel file.

## Configuration
Credential values are stored in `Web.config` as `VacancyApiAccountId` and `VacancyApiPassword`. Update them there to rotate credentials or add additional sets in the future.
