# Assignment 1 · Linux shell scripting and Git

Run the commands in Ubuntu or another Linux distribution with Bash, Git, and GNU/Linux utilities. On Windows, use the Ubuntu terminal in WSL. Start in the folder containing this README.

## 1. Make both scripts executable

```bash
chmod +x sysinfo.sh log_report.sh
bash -n sysinfo.sh && bash -n log_report.sh && echo "Syntax OK"
ls -l sysinfo.sh log_report.sh
```

**Checkpoint:** The syntax check prints `Syntax OK`. Both files have `x` in their permission bits.

## 2. Run the system report

Start the cron service first. See the setup commands in step 4.

```bash
./sysinfo.sh
```

`hostname`, `date` and `whoami` report the machine name, local time and current user. `df -h /` reports the filesystem mounted at `/`, and `free -h` reports RAM and swap. `ps` sorts by resident memory size (RSS), and `awk` displays the header and first five process rows.

Illustrative output. Your machine supplies the actual values.

```text
Hostname: ubuntu-lab
Date and time: 2026-11-10 15:30:00 IST
Logged-in user: student

Disk usage for /:
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda2        40G   11G   27G  29% /

Memory usage:
               total        used        free      shared  buff/cache   available
Mem:           7.7Gi       2.1Gi       3.4Gi       160Mi       2.2Gi       5.3Gi
Swap:          2.0Gi          0B       2.0Gi

Top 5 processes by memory (RSS in KiB):
    PID USER     COMMAND         %MEM   RSS
   1802 student  firefox          7.4 593920
   1415 student  gnome-shell      3.7 294912
   2151 student  code             2.5 204800
    781 root     dockerd          1.2 98304
   2035 student  gnome-terminal   0.9 73728
```

**Checkpoint:** All six requested items appear. The process table has five rows when at least five processes are running, with RSS largest first.

## 3. Run the access-log report

```bash
./log_report.sh sample_access.log
```

The handout refers to a sample log. This repository supplies an eight-line practice file. If your instructor supplies a separate log, pass that file as the argument and check its own totals.

The parser expects a Common or Combined access log with the client IP in the first field and the three-digit HTTP status after the quoted request. It counts rows with those fields, counts only status `404` as a 404 error, and ranks addresses by request count. Equal counts are ordered by IP as text. [Apache access-log format](https://httpd.apache.org/docs/2.4/logs.html#accesslog)

**Checkpoint:** The practice file produces this exact result.

```text
Total requests: 8
404 errors: 2
Top 3 IP addresses (IP, requests):
  192.0.2.10 3
  198.51.100.8 2
  203.0.113.7 2
```

There are four unique addresses. The fourth made one request, so it falls outside the top three. The request for `/lookup/404` returned `200`.

## 4. Optional bonus checks

```bash
bash log_report.sh
echo "Exit status: $?"
```

**Checkpoint:** With no argument, the log script prints `Usage: log_report.sh <access-log-file>` and exits with status `2`.

### Set up cron and run the system report

In Ubuntu, install and start cron once. Run `sysinfo.sh` as your regular Linux user to register the job in your own crontab.

```bash
sudo apt update
sudo apt install -y cron
sudo service cron start
bash sysinfo.sh
crontab -l
stat -c '%y %n' "sysinfo-$(date +%F).txt"
```

A manual run prints the report, saves `sysinfo-YYYY-MM-DD.txt` in the project folder, and installs or replaces the hourly job. The `--save` flag is still accepted and does the same thing. The script replaces entries it previously marked with `# assignment-1-sysinfo` and the original README's exact example entry. Other jobs stay in the crontab.

**Checkpoint:** Run `bash sysinfo.sh` twice. `crontab -l` should still show one entry for this assignment, starting with `0 * * * *` and ending with `# assignment-1-sysinfo`. At the next hour, while Ubuntu and cron are running, `stat` should show a newer timestamp. The scheduled command uses `--cron-run` to save the report without editing the crontab. At midnight it writes a file for the new date. Check `cron.log` if the scheduled command fails.

## 5. Publish the GitHub repository

Create an empty **public** repository on GitHub named `assignment-1-shell-git`. Leave the initial README, license, and gitignore options off because the files are already local. Authenticate your Git CLI before pushing. [GitHub's guide to pushing an existing project](https://docs.github.com/en/migrations/importing-source-code/using-the-command-line-to-import-source-code/adding-locally-hosted-code-to-github)

```bash
git init -b main
git add .
git update-index --chmod=+x sysinfo.sh log_report.sh
git ls-files --stage -- sysinfo.sh log_report.sh
git commit -m "Add system and access-log reporting scripts"
git remote add origin https://github.com/YOUR-USERNAME/assignment-1-shell-git.git
git push -u origin main
```

**Checkpoint:** Both scripts show mode `100755` before the commit. After the push, open the repository on GitHub and check that it is public and displays this README, both scripts, and the practice log.
