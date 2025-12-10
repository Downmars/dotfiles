#!/usr/bin/env bash
# ftask.sh - Enhanced Taskwarrior management using fzf with batch operations and Create Task option

set -euo pipefail

# Log file path
LOGFILE="$HOME/.ftask.log"

# Function to display help
display_help() {
  echo "Usage: ftask.sh"
  echo "Enhanced Taskwarrior management using fzf with batch operations and Create Task option."
  echo ""
  echo "Options:"
  echo "  -h, --help    Show this help message and exit"
}

# Function to log actions
log_action() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >>"$LOGFILE"
}

# Function to check dependencies
check_dependencies() {
  for cmd in task fzf awk sed head tail tr grep notify-send; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      notify-send "ftask.sh - Error" "$cmd is not installed. Please install $cmd first." -u critical -i dialog-error
      log_action "Missing dependency: $cmd"
      exit 1
    fi
  done
}

# Function to fetch tasks
fetch_tasks() {
  task list | sed '1,2d; $d; $d' | awk '{print $1, $2, substr($0, index($0,$3))}'
}

# Function to select tasks
select_tasks() {
  echo -e "$tasks_with_create" | fzf --height=90% --reverse \
    --preview "if [[ {} == Create* ]]; then echo 'Create a new task'; else task info {1}; fi" \
    --delimiter=" " --multi
}

# Function to select operation
select_operation() {
  printf "%s\n" "${operations[@]}" | fzf --height=40% --reverse --prompt="Choose an operation: " --header="Task IDs: $task_ids"
}

# Function to confirm deletion
confirm_deletion() {
  echo -e "yes\nno" | fzf --prompt="Are you sure you want to delete tasks $task_ids? (yes/no): " --height=40% --reverse --select-1
}

# Function to add a new task
add_new_task() {
  echo "Enter the description for the new task:"
  read -r new_task_description

  # Ensure description is not empty
  if [ -z "$new_task_description" ]; then
    notify-send "ftask.sh - Error" "Task description cannot be empty. Task creation canceled." -u critical -i dialog-error
    log_action "Task creation canceled: Empty description"
    return
  fi

  echo "Enter project (optional, press Enter to skip):"
  read -r new_task_project

  echo "Enter priority (H/M/L, press Enter to skip):"
  read -r new_task_priority

  echo "Enter due date (YYYY-MM-DD, optional, press Enter to skip):"
  read -r new_task_due

  echo "Enter tags separated by spaces (optional, press Enter to skip):"
  read -r new_task_tags

  # Build the task add command with provided fields using an array
  task_add_cmd=("task" "add" "$new_task_description")

  # Append optional fields if provided
  if [ -n "$new_task_project" ]; then
    task_add_cmd+=("project:$new_task_project")
  fi

  if [ -n "$new_task_priority" ]; then
    case "$new_task_priority" in
    H | M | L)
      task_add_cmd+=("priority:$new_task_priority")
      ;;
    *)
      notify-send "ftask.sh - Warning" "Invalid priority '$new_task_priority'. Skipping priority." -u normal -i dialog-warning
      log_action "Invalid priority entered: $new_task_priority"
      ;;
    esac
  fi

  if [ -n "$new_task_due" ]; then
    # Simple validation for date format YYYY-MM-DD
    if [[ "$new_task_due" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
      task_add_cmd+=("due:$new_task_due")
    else
      notify-send "ftask.sh - Warning" "Invalid due date format '$new_task_due'. Skipping due date." -u normal -i dialog-warning
      log_action "Invalid due date entered: $new_task_due"
    fi
  fi

  if [ -n "$new_task_tags" ]; then
    # Prepend '+' to each tag
    tags_with_plus=$(echo "$new_task_tags" | sed 's/\(\w\+\)/+\1/g')
    task_add_cmd+=($tags_with_plus)
  fi

  # Execute the task add command
  if "${task_add_cmd[@]}"; then
    notify-send "ftask.sh - Success" "New task added: $new_task_description" -u normal -i dialog-ok
    log_action "Added task: $new_task_description"
  else
    notify-send "ftask.sh - Error" "Failed to add new task." -u critical -i dialog-error
    log_action "Failed to add task: $new_task_description"
  fi
}

# Handle help option
if [[ "${1-}" == "-h" || "${1-}" == "--help" ]]; then
  display_help
  exit 0
fi

# Initialize dependencies
check_dependencies

# Define operations
operations=(
  "Mark as Done"
  "Delete Task"
  "Edit Task"
  "Set Priority"
  "View Details"
  "Cancel"
)

# Fetch tasks
tasks=$(fetch_tasks)

# Prepend a "Create Task" option
tasks_with_create=$(echo -e "Create Task\n$tasks")

# Initialize create_task_selected to false
create_task_selected=false

# Select tasks or create a new task
selected_items=$(select_tasks)

# Check if any items were selected
if [ -z "$selected_items" ]; then
  notify-send "ftask.sh - Info" "No items selected." -u normal -i dialog-information
  log_action "No items selected"
  exit 0
fi

# Check if "Create Task" was selected
if echo "$selected_items" | grep -q "^Create Task"; then
  create_task_selected=true
  # Remove "Create Task" from selected items
  selected_items=$(echo "$selected_items" | grep -v "^Create Task" || true)
fi

# If "Create Task" was selected, add a new task
if [[ "$create_task_selected" == true ]]; then
  add_new_task
fi

# If there are other selected tasks, proceed with operations
if [ -n "$selected_items" ]; then
  # Extract Task IDs
  task_ids=$(echo "$selected_items" | awk '{print $1}' | tr '\n' ' ')

  # Select operation
  selected_operation=$(select_operation)

  # Execute operation
  case "$selected_operation" in
  "Mark as Done")
    if task $task_ids done; then
      notify-send "ftask.sh - Success" "Tasks $task_ids have been marked as done." -u normal -i dialog-ok
      log_action "Marked tasks as done: $task_ids"
    else
      notify-send "ftask.sh - Error" "Failed to mark tasks $task_ids as done." -u critical -i dialog-error
      log_action "Failed to mark tasks as done: $task_ids"
    fi
    ;;

  "Delete Task")
    # Confirm deletion
    confirmation=$(confirm_deletion)
    if echo "$confirmation" | grep -iq "^yes"; then
      if task $task_ids delete; then
        notify-send "ftask.sh - Success" "Tasks $task_ids have been deleted." -u normal -i dialog-ok
        log_action "Deleted tasks: $task_ids"
      else
        notify-send "ftask.sh - Error" "Failed to delete tasks $task_ids." -u critical -i dialog-error
        log_action "Failed to delete tasks: $task_ids"
      fi
    else
      notify-send "ftask.sh - Info" "Task deletion canceled." -u normal -i dialog-information
      log_action "Task deletion canceled for: $task_ids"
    fi
    ;;

  "Edit Task")
    # Edit each selected task
    for id in $task_ids; do
      task "$id" edit
      log_action "Edited task: $id"
    done
    notify-send "ftask.sh - Info" "Selected tasks have been edited." -u normal -i dialog-information
    ;;

  "Set Priority")
    # Select priority
    priority=$(printf "H\nM\nL\nNone" | fzf --height=40% --reverse --prompt="Select Priority (H/M/L/None): ")
    if [[ -n "$priority" ]]; then
      if [[ "$priority" != "None" ]]; then
        task $task_ids priority:"$priority"
        log_action "Set priority to $priority for tasks: $task_ids"
      else
        # Remove priority if "None" is selected
        task $task_ids priority:_
        log_action "Removed priority for tasks: $task_ids"
      fi
      notify-send "ftask.sh - Success" "Priority of tasks $task_ids set to $priority." -u normal -i dialog-ok
    else
      notify-send "ftask.sh - Info" "Priority setting canceled." -u normal -i dialog-information
      log_action "Priority setting canceled for tasks: $task_ids"
    fi
    ;;

  "View Details")
    for id in $task_ids; do
      task "$id" info
      echo "-----------------------------"
      log_action "Viewed details for task: $id"
    done
    notify-send "ftask.sh - Info" "Displayed details for tasks $task_ids." -u normal -i dialog-information
    ;;

  "Cancel")
    notify-send "ftask.sh - Info" "Operation canceled." -u normal -i dialog-information
    log_action "Operation canceled by user"
    ;;

  *)
    notify-send "ftask.sh - Error" "Invalid operation selected." -u critical -i dialog-error
    log_action "Invalid operation selected"
    ;;
  esac
fi
