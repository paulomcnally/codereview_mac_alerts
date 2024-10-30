# Codereview Alerts on Mac OS

./codereview.sh

Envs

```
export GITHUB_CODEREVIEW_TOKEN="ghp_xxxxxx"
export GITHUB_CODEREVIEW_USER="paulomcnally"
```

Crontab

```
$ crontab -e
```

```
GITHUB_CODEREVIEW_TOKEN="ghp_xxxxxx"
GITHUB_CODEREVIEW_USER="paulomcnally"
0 7-16 * * * /Users/paulomcnally/github/paulomcnally/codereview_mac_alerts/codereview.sh
```