#!/bin/bash

# =============================================
#           COLOR AND STYLE DEFINITIONS
# =============================================
# More compatible color definitions
BOLD="\033[1m"
RESET="\033[0m"
RED="\033[31m"          
GREEN="\033[32m"        
YELLOW="\033[33m"       
BLUE="\033[34m"        
PURPLE="\033[35m"       
CYAN="\033[36m"         
ORANGE="\033[38;5;208m" 
# Icons
CHECK="${GREEN}✓${RESET}"
CROSS="${RED}✗${RESET}"
WARN="⚠ "
MONEY="💰"
LOCK="🔒"
USER="👤"
GEAR="⚙ "
GRAPH="📊"
PIGGY="🐷"
CARD="💳"
CALENDAR="📅"
RECEIPT="🧾"

# =============================================
#               SYSTEM SETUP
# =============================================
USER_DIR="users"
USER_FILE="$USER_DIR/users_list.txt"

mkdir -p "$USER_DIR"
touch "$USER_FILE"

# =============================================
#               HELPER FUNCTIONS
# =============================================
function divider() {
    echo -e "${BLUE}------------------------------------------------${RESET}"
}

function header() {
    clear
    echo -e "${PURPLE}${BOLD}$1${RESET}"
    divider
}

function press_any_key() {
    echo -e "\n${BLUE}${BOLD}Press any key to continue...${RESET}"
    read -n 1 -s
}

# =============================================
#               AUTHENTICATION
# =============================================
function authenticate() {
    while true; do
        header "FINANCE MANAGEMENT SYSTEM"
        echo -e "${BOLD}1. ${LOCK} Login${RESET}"
        echo -e "${BOLD}2. ${USER} Register${RESET}"
        echo -e "${BOLD}3. ${CROSS} Exit${RESET}"
        divider
        read -p "➤ Select option [1-3]: " choice

        case $choice in
            1) login ;;
            2) register ;;
            3) exit 0 ;;
            *) echo -e "${RED}Invalid choice! Please select 1-3.${RESET}"
               sleep 1 ;;
        esac
    done
}

function register() {
    header "USER REGISTRATION"
    read -p "➤ ${USER} Enter username: " new_username

    if grep -q "^$new_username:" "$USER_FILE"; then
        echo -e "${CROSS} ${RED}Username already exists!${RESET}"
    else
        read -sp "➤ ${LOCK} Enter password: " new_password
        echo
        read -p "➤ ${GEAR} Assign role (admin/user): " role

        echo "$new_username:$new_password:$role" >> "$USER_FILE"
        
        # Create user files
        echo "Date,Amount,Description" > "$USER_DIR/${new_username}_income.csv"
        echo "Date,Amount,Category,Description" > "$USER_DIR/${new_username}_expenses.csv"
        echo "0" > "$USER_DIR/${new_username}_budget.txt"

        echo -e "\n${CHECK} ${GREEN}Registration successful!${RESET}"
    fi
    
    press_any_key
}

function login() {
    header "USER LOGIN"
    read -p "➤ ${USER} Username: " username
    read -sp "➤ ${LOCK} Password: " password
    echo

    if grep -q "^$username:" "$USER_FILE"; then
        stored_pass=$(grep "^$username:" "$USER_FILE" | cut -d ":" -f2)
        
        if [ "$password" == "$stored_pass" ]; then
            echo -e "\n${CHECK} ${GREEN}Login successful!${RESET}"
            sleep 1
            main_menu "$username"
        else
            echo -e "\n${CROSS} ${RED}Incorrect password!${RESET}"
            sleep 1
        fi
    else
        echo -e "\n${CROSS} ${RED}User not found!${RESET}"
        sleep 1
    fi
}

# =============================================
#               MAIN MENU
# =============================================
function main_menu() {
    local username="$1"
    while true; do
        header "MAIN MENU (${CYAN}${username}${RESET})"
        echo -e "${BOLD}1. ${GEAR} User Management${RESET}"
        echo -e "${BOLD}2. ${MONEY} Personal Finance${RESET}"
        echo -e "${BOLD}3. ${CROSS} Logout${RESET}"
        divider
        read -p "➤ Select option [1-3]: " choice

        case $choice in
            1) user_management "$username" ;;
            2) finance_manager "$username" ;;
            3) return ;;
            *) echo -e "${RED}Invalid choice!${RESET}"
               sleep 1 ;;
        esac
    done
}

# =============================================
#               USER MANAGEMENT
# =============================================
function user_management() {
    local current_user="$1"
    local user_role=$(grep "^$current_user:" "$USER_FILE" | cut -d ":" -f3)

    if [ "$user_role" != "admin" ]; then
        echo -e "${CROSS} ${RED}Access denied! Admin privileges required.${RESET}"
        sleep 1
        return
    fi

    while true; do
        header "USER MANAGEMENT"
        echo -e "${BOLD}1. ${USER} Add User${RESET}"
        echo -e "${BOLD}2. ${CROSS} Delete User${RESET}"
        echo -e "${BOLD}3. ${GEAR} Modify Roles${RESET}"
        echo -e "${BOLD}4. ${RECEIPT} View Users${RESET}"
        echo -e "${BOLD}5. ${CHECK} Back to Menu${RESET}"
        divider
        read -p "➤ Select option [1-5]: " choice

        case $choice in
            1) register ;;
            2) delete_user ;;
            3) modify_user ;;
            4) view_users ;;
            5) return ;;
            *) echo -e "${RED}Invalid choice!${RESET}"
               sleep 1 ;;
        esac
    done
}

function delete_user() {
    header "DELETE USER"
    read -p "➤ Enter username to delete: " del_username

    if grep -q "^$del_username:" "$USER_FILE"; then
        sed -i "/^$del_username:/d" "$USER_FILE"
        rm -f "$USER_DIR/${del_username}_income.csv"
        rm -f "$USER_DIR/${del_username}_expenses.csv"
        rm -f "$USER_DIR/${del_username}_budget.txt"
        echo -e "${CHECK} ${GREEN}User deleted successfully!${RESET}"
    else
        echo -e "${CROSS} ${RED}User not found!${RESET}"
    fi
    press_any_key
}

function modify_user() {
    header "MODIFY USER ROLE"
    read -p "➤ Enter username: " mod_username

    if grep -q "^$mod_username:" "$USER_FILE"; then
        read -p "➤ Enter new role (admin/user): " new_role
        sed -i "s/^$mod_username:\([^:]*\):[^:]*/$mod_username:\1:$new_role/" "$USER_FILE"
        echo -e "${CHECK} ${GREEN}Role updated successfully!${RESET}"
    else
        echo -e "${CROSS} ${RED}User not found!${RESET}"
    fi
    press_any_key
}

function view_users() {
    header "REGISTERED USERS"
    echo -e "${BOLD}${CYAN}Username            Role${RESET}"
    divider
    cut -d ":" -f1,3 "$USER_FILE" | awk -F ":" '{printf "%-20s %-10s\n", $1, $2}'
    press_any_key
}

# =============================================
#               FINANCE MANAGER
# =============================================
function finance_manager() {
    local username="$1"
    local income_file="$USER_DIR/${username}_income.csv"
    local expenses_file="$USER_DIR/${username}_expenses.csv"
    local budget_file="$USER_DIR/${username}_budget.txt"

    while true; do
        header "FINANCE MANAGER (${CYAN}${username}${RESET})"
        echo -e "${BOLD}1. ${MONEY} Add Income${RESET}"
        echo -e "${BOLD}2. ${CARD} Add Expense${RESET}"
        echo -e "${BOLD}3. ${GRAPH} View Reports${RESET}"
        echo -e "${BOLD}4. ${PIGGY} Manage Budget${RESET}"
        echo -e "${BOLD}5. ${CHECK} Back to Menu${RESET}"
        divider
        read -p "➤ Select option [1-5]: " choice

        case $choice in
            1) add_income "$income_file" ;;
            2) add_expense "$expenses_file" ;;
            3) view_reports "$income_file" "$expenses_file" "$budget_file" ;;
            4) manage_budget "$budget_file" ;;
            5) return ;;
            *) echo -e "${RED}Invalid choice!${RESET}"
               sleep 1 ;;
        esac
    done
}

function add_income() {
    local file="$1"
    header "ADD INCOME"
    read -p "➤ ${MONEY} Amount: " amount
    read -p "➤ Description: " desc
    
    echo "$(date +"%Y-%m-%d %H:%M:%S"),$amount,$desc" >> "$file"
    echo -e "\n${CHECK} ${GREEN}Income recorded: ${YELLOW}₹$amount${RESET}"
    press_any_key
}

function add_expense() {
    local file="$1"
    header "ADD EXPENSE"
    read -p "➤ ${CARD} Amount: " amount
    read -p "➤ Category: " category
    read -p "➤ Description: " desc
    
    echo "$(date +"%Y-%m-%d %H:%M:%S"),$amount,$category,$desc" >> "$file"
    echo -e "\n${CHECK} ${GREEN}Expense recorded: ${RED}₹$amount${RESET}"
    press_any_key
}

function view_reports() {
    local income_file="$1"
    local expenses_file="$2"
    local budget_file="$3"

    header "FINANCIAL REPORT"
    
    # Calculate totals
    local total_income=$(awk -F',' 'NR>1 {sum+=$2} END {print sum}' "$income_file" 2>/dev/null || echo "0")
    local total_expenses=$(awk -F',' 'NR>1 {sum+=$2} END {print sum}' "$expenses_file" 2>/dev/null || echo "0")
    local balance=$((total_income - total_expenses))
    local budget=$(cat "$budget_file" 2>/dev/null || echo "0")

    # Display summary
    echo -e "${BOLD}${CYAN}Summary:${RESET}"
    divider
    echo -e "${MONEY} ${GREEN}Total Income:  ${YELLOW}₹$total_income${RESET}"
    echo -e "${CARD} ${RED}Total Expenses: ${RED}₹$total_expenses${RESET}"
    
    if (( balance >= 0 )); then
        echo -e "${CHECK} ${GREEN}Net Balance:   ${GREEN}₹$balance${RESET}"
    else
        echo -e "${CROSS} ${RED}Net Balance:   ${RED}₹$balance${RESET}"
    fi
    
    echo -e "${PIGGY} ${BLUE}Budget Limit:  ${BLUE}₹$budget${RESET}"
    
    # Budget analysis
    if (( budget > 0 )); then
        divider
        if (( total_expenses > budget )); then
            local over=$((total_expenses - budget))
            echo -e "${WARN} ${RED}You exceeded budget by ${RED}₹$over${RESET}"
        elif (( total_expenses == budget )); then
            echo -e "${WARN} ${YELLOW}You've reached your budget limit${RESET}"
        else
            local remaining=$((budget - total_expenses))
            echo -e "${CHECK} ${GREEN}Remaining budget: ${GREEN}₹$remaining${RESET}"
        fi
    fi
    
    press_any_key
}

function manage_budget() {
    local file="$1"
    header "MANAGE BUDGET"
    read -p "➤ ${PIGGY} Enter new budget amount: " budget
    
    echo "$budget" > "$file"
    echo -e "\n${CHECK} ${GREEN}Budget set to ${BLUE}₹$budget${GREEN} successfully!${RESET}"
    press_any_key
}

# =============================================
#               START APPLICATION
# =============================================
authenticate
