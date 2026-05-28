# Automated User Provisioner

## Project Overview
This project is a Bash-based automation tool designed to streamline the onboarding process for new employees in a Linux environment. It automates the creation of user accounts, group assignments, and secure password generation, mimicking real-world IAM (Identity and Access Management) workflows in the cloud.

## Key Features
* **Batch Processing:** Reads a formatted text file to create multiple users at once.
* **Automatic Group Management:** Creates department groups if they don't already exist.
* **Security-First Approach:** - Generates random, secure passwords for every user.
  - Forces users to change their password upon their first login.
  - Stores passwords in a secure, restricted-access file (`/var/secure/user_passwords.csv`).
* **System Logging:** Records all actions, successes, and warnings to `/var/log/user_management.log` for auditing purposes.

## Tools & Concepts Learned
* **Language:** Bash Scripting (Loops, conditionals, input handling, string manipulation)
* **OS:** Linux (Ubuntu system administration)
* **Linux Commands:** `useradd`, `groupadd`, `chage`, `openssl`, `chmod`
* **Version Control:** Git & GitHub

---

## File Structure
```text
automated-user-provisioner/
├── create_users.sh      # The core automation Bash script
├── users.txt            # Input file containing user data (comma/semicolon-separated)
└── README.md            # Project documentation
