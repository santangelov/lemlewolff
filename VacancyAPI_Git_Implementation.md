# Implementing the VacancyAPI changes in Git

Use these steps to bring the VacancyAPI work into your own clone of the repo and push it through a standard Git/GitHub flow.

## 1) Clone and set up your workspace
1. Clone the repository (replace `<origin>` with your Git remote URL):
   ```bash
   git clone <origin>
   cd lemlewolff
   ```
2. Confirm you are on the correct base branch (e.g., `work`):
   ```bash
   git status -sb
   git switch work
   git pull
   ```

## 2) Create a feature branch
Create a branch for the VacancyAPI work so you can open a pull request later:
```bash
git switch -c feature/vacancy-api-download
```

## 3) Bring in the VacancyAPI changes
1. If you are applying the changes from a patch or a different clone, copy the changed files into place (for example, `LW_Web/Controllers/VacancyApiController.cs`, `LW_Web/Web.config`, `LW_Web/LW_Web.csproj`, and `LW_Web/VacancyAPI.md`).
2. Review the diff locally:
   ```bash
   git status -sb
   git diff
   ```

## 4) Build or spot-check locally (optional)
If you have the tooling available, run a build to confirm things compile:
```bash
msbuild lemlewolff.sln /t:Build /p:Configuration=Release
```

## 5) Commit the work
Stage and commit the changes with a descriptive message:
```bash
git add LW_Web/Controllers/VacancyApiController.cs LW_Web/Web.config LW_Web/LW_Web.csproj LW_Web/VacancyAPI.md
git commit -m "Add VacancyAPI download endpoint"
```

## 6) Push and open a pull request
Push your branch to the origin and open a PR:
```bash
git push -u origin feature/vacancy-api-download
```
Then create a pull request in your Git hosting provider with a summary similar to:
- Add a VacancyAPI controller endpoint to generate and download vacancy cover sheets using existing report helper logic
- Secure the endpoint with configurable account ID and password stored in `web.config`
- Include the new controller in the web project build
- Add documentation on how to call the VacancyAPI endpoint

## 7) Merge
After review and checks pass, merge the PR and delete the feature branch if desired:
```bash
git switch work
git pull
git merge --ff-only origin/feature/vacancy-api-download
git push
```

---
These steps mirror the workflow used to land the VacancyAPI work contained in the latest commit on the `work` branch.
