#!/bin/bash

USER_DIR="users"
USER_FILE="$USER_DIR/users_list.txt"

mkdir -p "$USER_DIR"
touch "$USER_FILE"

authenticate() {
    while true; do
        echo "==== Welcome to Finance User Management System ===="
        echo "1. LOGIN"
        echo "2. REGISTER"
        echo "3. EXIT"
        read choice

        case $choice in
            1) login ;;
            2) register ;;
            3) exit 0 ;;
            *) echo "Invalid choice! Try again." ;;
        esac
    done
}

register() {
    echo "Enter New Username:"
    read new_username

    if grep -q "^$new_username:" "$USER_FILE"; then
        echo "User already exists!"
    
        echo "Enter New Password:"
        read  new_password
        echo "Assign Role (admin/user):"
        read role

  
        echo "$new_username:$new_password:$role" >> "$USER_FILE"

      
        echo "Date,Amount,Description" > "$USER_DIR/${new_username}_income.csv"
        echo "Date,Amount,Category,Description" > "$USER_DIR/${new_username}_expenses.csv"
        echo "0" > "$USER_DIR/${new_username}_budget.txt"

        echo "User $new_username registered successfully!"
    fi
}

login() {
    echo "Enter Username:"
    read username
    echo "Enter Password:"
    read password

    if grep -q "^$username:" "$USER_FILE"; then
        stored_pass=$(grep "^$username:" "$USER_FILE" | cut -d ":" -f2)

        if [ "$password" == "$stored_pass" ]; then
            echo "Login successful!"
            main_menu "$username"
        else
            echo "Incorrect password!"
        fi
    else
        echo "User not found!"
    fi
}

main_menu() {
    logged_in_user="$1"
    while true; do
        echo "==== Main Menu ($logged_in_user) ===="
        echo "1. USER MANAGEMENT"
        echo "2. PERSONAL FINANCE"
        echo "3. LOGOUT"
        read main_choice

        case $main_choice in
            1) user_management "$logged_in_user" ;;
            2) finance_manager "$logged_in_user" ;;
            3) authenticate ;;
            *) echo "Invalid choice! Try again." ;;
        esac
    done
}

user_management() {
    current_user="$1"
    user_role=$(grep "^$current_user:" "$USER_FILE" | cut -d ":" -f3)

    if [ "$user_role" != "admin" ]; then
        echo "Access Denied! Only admins can manage users."
        return
    fi

    while true; do
        echo "==== User Management ===="
        echo "1. ADD USER"
        echo "2. DELETE USER"
        echo "3. MODITY ROLES"
        echo "4. VIEW ALL USERS"
        echo "5. BACK TO MENU"
        read um_choice

        case $um_choice in
            1) register ;;
            2) delete_user ;;
            3) modify_user ;;
            4) view_users ;;
            5) return ;;
            *) echo "Invalid choice! Try again." ;;
        esac
    done
}

delete_user() {
    echo "Enter Username to Delete:"
    read del_username

    if grep -q "^$del_username:" "$USER_FILE"; then
        sed -i "/^$del_username:/d" "$USER_FILE"

       
        rm -f "$USER_DIR/${del_username}_income.csv"
        rm -f "$USER_DIR/${del_username}_expenses.csv"
        rm -f "$USER_DIR/${del_username}_budget.txt"

        echo "User $del_username deleted successfully!"
    else
        echo " User not found!"
    fi
}

modify_user() {
    echo "Enter Username to Modify Role:"
    read mod_username

    if grep -q "^$mod_username:" "$USER_FILE"; then
        echo "Enter New Role (admin/user):"
        read new_role

        sed -i "s/^$mod_username:\([^:]\):./$mod_username:\1:$new_role/" "$USER_FILE"

        echo "Role updated successfully!"
    else
        echo "User not found!"
    fi
}


view_users() {
    echo "==== Registered Users ===="
    cut -d ":" -f1,3 "$USER_FILE" | awk -F ":" '{print "User: "$1", Role: "$2}'
}

#!/bin/bash

finance_manager() {
    username="$1"
    income_file="$USER_DIR/${username}_income.csv"
    expenses_file="$USER_DIR/${username}_expenses.csv"
    budget_file="$USER_DIR/${username}_budget.txt"

    while true; do
        echo "==== Personal Finance Manager ($username) ===="
        echo "⿡ Add Income"
        echo "⿢ Add Expense"
        echo "⿣ View Reports"
        echo "⿤ Manage Budget"
        echo "⿥ Back to Main Menu"
        read choice

        case $choice in
            1) add_income "$income_file" ;;
            2) add_expense "$expenses_file" ;;
            3) view_reports "$income_file" "$expenses_file" "$budget_file" ;;
            4) manage_budget "$budget_file" ;;
            5) return ;;
            *) echo "Invalid choice! Try again." ;;
        esac
    done
}


add_income() {
    file="$1"
    echo "💰 Enter Income Amount:"
    read income
    echo "📝 Enter Description (e.g., Salary, Bonus, Gift):"
    read desc
    echo "$(date +"%Y-%m-%d %H:%M:%S"),$income,$desc" >> "$file"
    echo "✅ Income of ₹$income recorded under '$desc' successfully!"
}

add_expense() {
    file="$1"
    echo "💸 Enter Expense Amount:"
    read expense
    echo "🏷 Enter Category (e.g., Food, Rent, Travel):"
    read category
    echo "📝 Enter Description:"
    read desc
    echo "$(date +"%Y-%m-%d %H:%M:%S"),$expense,$category,$desc" >> "$file"
    echo "❌ Expense of ₹$expense recorded under '$category' ($desc) successfully!"
}

view_reports() {
    income_file="$1"
    expenses_file="$2"
    budget_file="$3"

    echo "📊 ==== Financial Report ==== 📊"
    
    echo "💰 📌 Income Entries:"
    column -t -s ',' "$income_file"
    echo ""
    
    echo "💸 📌 Expense Entries:"
    column -t -s ',' "$expenses_file"
    echo ""

    # Calculate total income & expenses
    total_income=$(awk -F',' '{sum+=$2} END {print sum}' "$income_file")
    total_expenses=$(awk -F',' '{sum+=$2} END {print sum}' "$expenses_file")
    balance=$((total_income - total_expenses))
    
    # Read budget
    if [[ -f "$budget_file" ]]; then
        budget=$(cat "$budget_file")
    else
        budget=0
    fi

    echo "💰 Total Income: ₹$total_income"
    echo "❌ Total Expenses: ₹$total_expenses"
    echo "🟢 Net Balance: ₹$balance"
    echo "🎯 Budget Limit: ₹$budget"

    if (( total_expenses > budget )); then
        echo "⚠ Warning: You have *exceeded* your budget limit! Reduce spending."
    elif (( total_expenses == budget )); then
        echo "🟡 Alert: You have reached your budget limit!"
    else
        remaining=$((budget - total_expenses))
        echo "✅ You are within budget. Remaining budget: ₹$remaining"
    fi
}

# 🎯 Function to set or update budget
manage_budget() {
    file="$1"
    echo "🎯 Enter New Budget Amount:"
    read budget
    echo "$budget" > "$file"
    echo "✅ Budget set to ₹$budget successfully!"
}

authenticate
