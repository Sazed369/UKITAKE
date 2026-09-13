#!/bin/bash

# -----------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'


# -----------------------------

handle_interrupt() {
    echo
    echo -e "${YELLOW}[!] Interrupted.${NC}"
    echo -e "${CYAN}    ======================================================================.${NC}"
    exit 130
}

trap handle_interrupt INT


# -----------------------------

banner() {
    echo
    echo -e "${CYAN}======================================================================${NC}"
    echo -e "${WHITE}                              UKITAKE${NC}"
    echo -e "${WHITE}    This man knows a lot of secrets, no wonder Ginjo wanted him dead!${NC}"
    echo -e "${CYAN}======================================================================${NC}"
    echo
}

section() {
    echo
    echo -e "${CYAN}----------------------------------------------------------------------${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${CYAN}----------------------------------------------------------------------${NC}"
}

success() {
    echo -e "${BLUE}[+] $1${NC}"
}

error_msg() {
    echo -e "${RED}[!] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

info() {
    echo -e "${CYAN}[*] $1${NC}"
}

pause() {
    echo
    read -r -p "Press Enter to return to the main menu..."
}


# -----------------------------

check_directory() {
    local directory="$1"

    if [ ! -e "$directory" ]; then
        error_msg "Directory does not exist: $directory"
        return 1
    fi

    if [ ! -d "$directory" ]; then
        error_msg "Not a directory: $directory"
        return 1
    fi

    if [ ! -r "$directory" ]; then
        error_msg "Directory is not readable: $directory"
        return 1
    fi

    return 0
}


check_file() {
    local file="$1"

    if [ ! -e "$file" ]; then
        error_msg "File does not exist: $file"
        return 1
    fi

    if [ ! -f "$file" ]; then
        error_msg "Not a regular file: $file"
        return 1
    fi

    if [ ! -r "$file" ]; then
        error_msg "File is not readable: $file"
        return 1
    fi

    return 0
}


# -----------------------------

get_format_filter() {

    local format

    read -r -p "File format/extension (optional, e.g. txt, pdf): " format

    # Remove a leading dot if the user enters ".txt"
    format="${format#.}"

    echo "$format"
}

show_file_type() {
    local file="$1"

    echo -e "${WHITE}Type:${NC}"
    file -b "$file" 2>/dev/null
}


show_file_size() {
    local file="$1"

    local size
    size=$(stat -c "%s" "$file" 2>/dev/null)

    if [ -n "$size" ]; then
        echo -e "${WHITE}Size:${NC} $size bytes"
    else
        echo -e "${WHITE}Size:${NC} Unknown"
    fi
}


show_file_owner() {
    local file="$1"

    local owner
    local uid

    owner=$(stat -c "%U" "$file" 2>/dev/null)
    uid=$(stat -c "%u" "$file" 2>/dev/null)

    echo -e "${WHITE}Owner:${NC} $owner (UID: $uid)"
}


show_file_group() {
    local file="$1"

    local group
    local gid

    group=$(stat -c "%G" "$file" 2>/dev/null)
    gid=$(stat -c "%g" "$file" 2>/dev/null)

    echo -e "${WHITE}Group:${NC} $group (GID: $gid)"
}


show_file_permissions() {
    local file="$1"

    local permissions
    local numeric

    permissions=$(stat -c "%A" "$file" 2>/dev/null)
    numeric=$(stat -c "%a" "$file" 2>/dev/null)

    echo -e "${WHITE}Permissions:${NC} $permissions ($numeric)"
}


show_file_modified() {
    local file="$1"

    local modified
    modified=$(stat -c "%y" "$file" 2>/dev/null)

    echo -e "${WHITE}Last Modified:${NC} $modified"
}


show_file_sha1() {
    local file="$1"

    local hash
    hash=$(sha1sum "$file" 2>/dev/null | awk '{print $1}')

    if [ -n "$hash" ]; then
        echo -e "${WHITE}SHA1:${NC} $hash"
    else
        echo -e "${WHITE}SHA1:${NC} Unable to calculate"
    fi
}


show_file_lines() {
    local file="$1"

    local lines
    lines=$(wc -l < "$file" 2>/dev/null)

    if [ -n "$lines" ]; then
        echo -e "${WHITE}Lines:${NC} $lines"
    else
        echo -e "${WHITE}Lines:${NC} Unable to count"
    fi
}


show_file_ips() {
    local file="$1"

    local ips

    ips=$(grep -Eo \
        '([0-9]{1,3}\.){3}[0-9]{1,3}' \
        "$file" 2>/dev/null | sort -u)

    if [ -n "$ips" ]; then
        echo -e "${WHITE}IP Addresses:${NC}"
        echo "$ips"
    else
        echo -e "${WHITE}IP Addresses:${NC} None found"
    fi
}


show_file_executable_status() {
    local file="$1"

    local permissions
    permissions=$(stat -c "%a" "$file" 2>/dev/null)

    if [ -z "$permissions" ]; then
        echo -e "${WHITE}Executable by everyone:${NC} Unknown"
        return
    fi

    local mode=$((8#$permissions))

    if (( (mode & 0111) == 0111 )); then
        echo -e "${WHITE}Executable by everyone:${NC} YES"
    else
        echo -e "${WHITE}Executable by everyone:${NC} NO"
    fi
}


# ============================================================
 
find_files() {

    section "FIND FILES BY NAME"

    echo
    echo "Enter one or more filenames separated by spaces."
    echo "Example: file1 file2 file3"
    echo

    read -r -a filenames -p "Filename(s): "

    if [ "${#filenames[@]}" -eq 0 ]; then
        error_msg "No filenames entered."
        pause
        return
    fi

    echo
    local format
    format=$(get_format_filter)

    echo
    read -r -p "Search directory [/]: " search_dir

    if [ -z "$search_dir" ]; then
        search_dir="/"
    fi

    if ! check_directory "$search_dir"; then
        pause
        return
    fi

    echo
    info "Searching for files..."
    echo

    local find_expression=()
    local name

    for name in "${filenames[@]}"; do

        if [ "${#find_expression[@]}" -gt 0 ]; then
            find_expression+=( -o )
        fi

        find_expression+=( -name "$name" )

    done

    local results

    if [ -n "$format" ]; then

        results=$(find "$search_dir" \
            -type f \
            \( "${find_expression[@]}" \) \
            -iname "*.$format" \
            -print \
            2>/dev/null)

    else

        results=$(find "$search_dir" \
            -type f \
            \( "${find_expression[@]}" \) \
            -print \
            2>/dev/null)

    fi

    if [ -n "$results" ]; then

        success "Matching files found:"
        echo
        echo "$results"

    else

        warning "No matching files found."

    fi

    pause
}


# ============================================================
 
file_information() {

    section "FILE INFORMATION"

    echo
    read -r -p "Enter full file path: " file

    if ! check_file "$file"; then
        pause
        return
    fi

    echo
    echo -e "${CYAN}File:${NC} $file"
    echo

    show_file_type "$file"
    show_file_size "$file"
    show_file_owner "$file"
    show_file_group "$file"
    show_file_permissions "$file"
    show_file_modified "$file"
    show_file_sha1 "$file"
    show_file_lines "$file"
    show_file_ips "$file"
    show_file_executable_status "$file"

    pause
}


# ============================================================
 
search_content() {

    section "SEARCH FILE CONTENT"

    echo
    read -r -p "Enter text/pattern to search for: " pattern

    if [ -z "$pattern" ]; then
        error_msg "Search pattern cannot be empty."
        pause
        return
    fi

    echo
    local format
    format=$(get_format_filter)

    echo
    read -r -p "Search directory [/]: " search_dir

    if [ -z "$search_dir" ]; then
        search_dir="/"
    fi

    if ! check_directory "$search_dir"; then
        pause
        return
    fi

    echo
    info "Searching..."
    echo

    local results

    if [ -n "$format" ]; then

        results=$(grep -RInI \
            --include="*.$format" \
            -- "$pattern" \
            "$search_dir" \
            2>/dev/null)

    else

        results=$(grep -RInI \
            -- "$pattern" \
            "$search_dir" \
            2>/dev/null)

    fi

    if [ -n "$results" ]; then

        success "Matches found:"
        echo
        echo "$results"

    else

        warning "No matches found."

    fi

    pause
}


# ============================================================
 
find_by_hash() {

    section "FIND FILE BY SHA1 HASH"

    echo
    read -r -p "Enter SHA1 hash: " target_hash

    target_hash="${target_hash,,}"

    if [[ ! "$target_hash" =~ ^[a-f0-9]{40}$ ]]; then
        error_msg "Invalid SHA1 hash."
        pause
        return
    fi

    echo
    local format
    format=$(get_format_filter)

    echo
    read -r -p "Search directory [/]: " search_dir

    if [ -z "$search_dir" ]; then
        search_dir="/"
    fi

    if ! check_directory "$search_dir"; then
        pause
        return
    fi

    echo
    info "Calculating SHA1 hashes. This may take some time..."
    echo

    local found=0
    local file
    local hash

    while IFS= read -r file; do

        hash=$(sha1sum "$file" 2>/dev/null | awk '{print $1}')

        if [ "$hash" = "$target_hash" ]; then

            echo "$file"
            found=1

        fi

    done < <(

        if [ -n "$format" ]; then

            find "$search_dir" \
                -type f \
                -readable \
                -iname "*.$format" \
                -print \
                2>/dev/null

        else

            find "$search_dir" \
                -type f \
                -readable \
                -print \
                2>/dev/null

        fi

    )

    echo

    if [ "$found" -eq 1 ]; then
        success "Matching file(s) found."
    else
        warning "No file with that SHA1 hash was found."
    fi

    pause
}


# ============================================================
 
find_by_lines() {

    section "FIND FILE BY LINE COUNT"

    echo
    read -r -p "Enter exact number of lines: " target_lines

    if [[ ! "$target_lines" =~ ^[0-9]+$ ]]; then
        error_msg "Line count must be a non-negative integer."
        pause
        return
    fi

    echo
    local format
    format=$(get_format_filter)

    echo
    read -r -p "Search directory [/]: " search_dir

    if [ -z "$search_dir" ]; then
        search_dir="/"
    fi

    if ! check_directory "$search_dir"; then
        pause
        return
    fi

    echo
    info "Searching for files containing exactly $target_lines lines..."
    echo

    local found=0
    local file
    local line_count

    while IFS= read -r file; do

        line_count=$(wc -l < "$file" 2>/dev/null)

        if [ "$line_count" = "$target_lines" ]; then

            echo "$file"
            found=1

        fi

    done < <(

        if [ -n "$format" ]; then

            find "$search_dir" \
                -type f \
                -readable \
                -iname "*.$format" \
                -print \
                2>/dev/null

        else

            find "$search_dir" \
                -type f \
                -readable \
                -print \
                2>/dev/null

        fi

    )

    echo

    if [ "$found" -eq 1 ]; then
        success "Matching files found."
    else
        warning "No files with exactly $target_lines lines were found."
    fi

    pause
}


# ============================================================
 
find_by_uid() {

    section "FIND FILE BY OWNER UID"

    echo
    read -r -p "Enter UID: " target_uid

    if [[ ! "$target_uid" =~ ^[0-9]+$ ]]; then
        error_msg "UID must be numeric."
        pause
        return
    fi

    echo
    local format
    format=$(get_format_filter)

    echo
    read -r -p "Search directory [/]: " search_dir

    if [ -z "$search_dir" ]; then
        search_dir="/"
    fi

    if ! check_directory "$search_dir"; then
        pause
        return
    fi

    echo
    info "Searching for files owned by UID $target_uid..."
    echo

    local results

    if [ -n "$format" ]; then

        results=$(find "$search_dir" \
            -type f \
            -uid "$target_uid" \
            -iname "*.$format" \
            -print \
            2>/dev/null)

    else

        results=$(find "$search_dir" \
            -type f \
            -uid "$target_uid" \
            -print \
            2>/dev/null)

    fi

    if [ -n "$results" ]; then

        success "Matching files found:"
        echo
        echo "$results"

    else

        warning "No files owned by UID $target_uid were found."

    fi

    pause
}


# ============================================================
 
find_by_group() {

    section "FIND FILE BY GROUP"

    echo
    read -r -p "Enter group name: " target_group

    if [ -z "$target_group" ]; then
        error_msg "Group name cannot be empty."
        pause
        return
    fi

    if ! getent group "$target_group" >/dev/null 2>&1; then
        warning "Group '$target_group' does not appear in the local group database."
        echo
        read -r -p "Search anyway? [y/N]: " continue_search

        if [[ ! "$continue_search" =~ ^[Yy]$ ]]; then
            pause
            return
        fi
    fi

    echo
    local format
    format=$(get_format_filter)

    echo
    read -r -p "Search directory [/]: " search_dir

    if [ -z "$search_dir" ]; then
        search_dir="/"
    fi

    if ! check_directory "$search_dir"; then
        pause
        return
    fi

    echo
    info "Searching for files belonging to group '$target_group'..."
    echo

    local results

    if [ -n "$format" ]; then

        results=$(find "$search_dir" \
            -type f \
            -group "$target_group" \
            -iname "*.$format" \
            -print \
            2>/dev/null)

    else

        results=$(find "$search_dir" \
            -type f \
            -group "$target_group" \
            -print \
            2>/dev/null)

    fi

    if [ -n "$results" ]; then

        success "Matching files found:"
        echo
        echo "$results"

    else

        warning "No files belonging to group '$target_group' were found."

    fi

    pause
}


# ============================================================
 
find_executable() {

    section "FIND FILES EXECUTABLE BY EVERYONE"

    echo
    echo "This searches for files where:"
    echo "  Owner  = execute"
    echo "  Group  = execute"
    echo "  Others = execute"
    echo
    echo "Equivalent permission requirement:"
    echo "  ---x--x--x"
    echo

    local format
    format=$(get_format_filter)

    echo
    read -r -p "Search directory [/]: " search_dir

    if [ -z "$search_dir" ]; then
        search_dir="/"
    fi

    if ! check_directory "$search_dir"; then
        pause
        return
    fi

    echo
    info "Searching..."
    echo

    local results

    if [ -n "$format" ]; then

        results=$(find "$search_dir" \
            -type f \
            -perm -111 \
            -iname "*.$format" \
            -print \
            2>/dev/null)

    else

        results=$(find "$search_dir" \
            -type f \
            -perm -111 \
            -print \
            2>/dev/null)

    fi

    if [ -n "$results" ]; then

        success "Files executable by everyone:"
        echo
        echo "$results"

    else

        warning "No files executable by everyone were found."

    fi

    pause
}


# ============================================================
 
full_investigation() {

    section "FULL FILE INVESTIGATION"

    echo
    read -r -p "Enter full file path: " file

    if ! check_file "$file"; then
        pause
        return
    fi

    echo
    echo -e "${CYAN}======================================================================${NC}"
    echo -e "${BLUE}FILE:${NC} $file"
    echo -e "${CYAN}======================================================================${NC}"
    echo

    show_file_type "$file"

    echo
    show_file_size "$file"

    echo
    show_file_owner "$file"

    echo
    show_file_group "$file"

    echo
    show_file_permissions "$file"

    echo
    show_file_modified "$file"

    echo
    show_file_sha1 "$file"

    echo
    show_file_lines "$file"

    echo
    show_file_executable_status "$file"

    echo
    echo -e "${CYAN}======================================================================${NC}"

    pause
}


# ============================================================
 
main_menu() {

    while true; do

        banner

        echo -e "${BLUE}FILE SEARCH${NC}"
        echo
        echo -e "  ${GREEN}1.${NC} Find files by filename ---  Search for one or multiple filenames."

        echo
        echo -e "  ${GREEN}2.${NC} File information --- Inspect type, size, owner, group, permissions, hash, etc."
 
        echo
        echo -e "  ${GREEN}3.${NC} Search file contents ---  Search recursively for text or patterns."

        echo
        echo -e "${BLUE}REVERSE INVESTIGATION${NC}"
        echo
        echo -e "  ${GREEN}4.${NC} Find file by SHA1 hash --- Hash → file"

        echo
        echo -e "  ${GREEN}5.${NC} Find file by line count --- Number of lines → file"

        echo
        echo -e "  ${GREEN}6.${NC} Find file by owner UID --- UID → file"

        echo
        echo -e "  ${GREEN}7.${NC} Find file by group --- Group → file"
 
        echo
        echo -e "  ${GREEN}8.${NC} Find files executable by everyone"

        echo
        echo -e "${BLUE}INVESTIGATION${NC}"
        echo
        echo -e "  ${GREEN}9.${NC} Full file investigation --- Perform a complete information check on one file."

        echo
        echo -e "  ${RED}0.${NC} Exit"

        echo
        echo -e "${CYAN}----------------------------------------------------------------------${NC}"

        read -r -p "Select an option: " choice

        case "$choice" in

            1)
                find_files
                ;;

            2)
                file_information
                ;;

            3)
                search_content
                ;;

            4)
                find_by_hash
                ;;

            5)
                find_by_lines
                ;;

            6)
                find_by_uid
                ;;

            7)
                find_by_group
                ;;

            8)
                find_executable
                ;;

            9)
                full_investigation
                ;;

            0)
                echo
                success "...shutting down..."
                echo -e "${CYAN}========================================================================================================================.${NC}"
                echo
                exit 0
                ;;

            *)
                error_msg "Invalid option. Please select a number from 0-9."
                sleep 2
                ;;

        esac

    done
}

 
main_menu
