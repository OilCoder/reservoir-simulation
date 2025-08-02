#!/bin/bash
DATE=$(date +%Y-%m-%d)
TODO_FILE_PATH="/workspace/todo_list/${DATE}.md" npx -y @danjdewhurst/todo-md-mcp "$@"