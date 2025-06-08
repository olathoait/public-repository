#!/bin/bash
# server-stats.sh: Script để thu thập thống kê hiệu suất máy chủ
#
# Các tính năng chính:
#   - Tính tổng CPU usage theo cách lấy mẫu qua /proc/stat
#   - In ra thông tin bộ nhớ (total, used, free và phần trăm sử dụng)
#   - In ra thông tin ổ đĩa (dành cho phân vùng root "/")
#   - Hiển thị top 5 tiến trình tiêu thụ CPU nhiều nhất
#   - Hiển thị top 5 tiến trình tiêu thụ bộ nhớ nhiều nhất
#
# Stretch goal:
#   - In ra OS version, uptime, load average, số người đang đăng nhập và số lần đăng nhập thất bại.
# Requirements
# You are required to write a script server-stats.sh that can analyse basic server performance stats. You should be able to run the script on any Linux server and it should give you the following stats:

# Total CPU usage
# Total memory usage (Free vs Used including percentage)
# Total disk usage (Free vs Used including percentage)
# Top 5 processes by CPU usage
# Top 5 processes by memory usage
# Stretch goal: Feel free to optionally add more stats such as os version, uptime, load average, logged in users, failed login attempts etc.
########################################
# Hàm tính CPU usage bằng cách lấy mẫu trước/sau 1 giây
########################################
get_cpu_usage() {
  # Lấy mẫu ban đầu từ /proc/stat (dòng bắt đầu bằng 'cpu ')
  PREV=($(grep '^cpu ' /proc/stat))
  # Tính idle time (idle + iowait) và tổng thời gian
  PREV_IDLE=$(( ${PREV[4]} + ${PREV[5]} ))
  PREV_TOTAL=$(( ${PREV[1]} + ${PREV[2]} + ${PREV[3]} + ${PREV[4]} + ${PREV[5]} + ${PREV[6]} + ${PREV[7]} ))
  
  sleep 1
  
  # Lấy mẫu mới sau 1 giây
  CUR=($(grep '^cpu ' /proc/stat))
  CUR_IDLE=$(( ${CUR[4]} + ${CUR[5]} ))
  CUR_TOTAL=$(( ${CUR[1]} + ${CUR[2]} + ${CUR[3]} + ${CUR[4]} + ${CUR[5]} + ${CUR[6]} + ${CUR[7]} ))
  
  # Tính sự biến đổi
  DIFF_TOTAL=$(( CUR_TOTAL - PREV_TOTAL ))
  DIFF_IDLE=$(( CUR_IDLE - PREV_IDLE ))
  
  # Tính CPU usage theo công thức: (total_delta - idle_delta) / total_delta * 100
  cpu_usage=$(echo "scale=2; (100*($DIFF_TOTAL - $DIFF_IDLE))/$DIFF_TOTAL" | bc)
  echo "$cpu_usage"
}

########################################
# In ra thống kê CPU usage
########################################
cpu_usage=$(get_cpu_usage)
echo "=== Thống kê server ==="
echo "Total CPU Usage: ${cpu_usage}%"
echo "------------------------------"

########################################
# Thống kê bộ nhớ: sử dụng lệnh free
########################################
# Lấy thông tin dòng "Mem:" từ lệnh free
mem_info=$(free | grep -i "^Mem:")
read _ mem_total mem_used mem_free _ <<< "$mem_info"
# Tính phần trăm sử dụng bộ nhớ
mem_usage_percent=$(echo "scale=2; $mem_used * 100 / $mem_total" | bc)
echo "Memory Usage:"
echo "  Total: ${mem_total} KB"
echo "  Used:  ${mem_used} KB"
echo "  Free:  ${mem_free} KB"
echo "  Usage: ${mem_usage_percent}%"
echo "------------------------------"

########################################
# Thống kê ổ đĩa: sử dụng df cho phân vùng "/"
########################################
disk_info=$(df -h / | awk 'NR==2 {print "Total: "$2", Used: "$3", Available: "$4", Usage: "$5}')
echo "Disk Usage (/):"
echo "  $disk_info"
echo "------------------------------"

########################################
# Top 5 tiến trình sử dụng CPU nhiều nhất
########################################
echo "Top 5 processes by CPU usage:"
ps -eo pid,comm,%cpu --sort=-%cpu | head -n 6
echo "------------------------------"

########################################
# Top 5 tiến trình sử dụng bộ nhớ nhiều nhất
########################################
echo "Top 5 processes by Memory usage:"
ps -eo pid,comm,%mem --sort=-%mem | head -n 6
echo "------------------------------"

########################################
# Stretch goal: Thông tin bổ sung cho server
########################################

# OS version (nếu file /etc/os-release tồn tại)
if [ -f /etc/os-release ]; then
    os_version=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
    echo "OS Version: $os_version"
fi

# Uptime (thời gian chạy của server)
echo "Uptime: $(uptime -p)"

# Load average (1, 5, 15 phút)
read l1 l5 l15 _ < /proc/loadavg
echo "Load Average (1, 5, 15 minutes): $l1, $l5, $l15"

# Số người đang đăng nhập
logged_users=$(who | wc -l)
echo "Logged in users: $logged_users"

# Số lần đăng nhập thất bại (dựa theo log /var/log/auth.log, nếu tồn tại)
if [ -f /var/log/auth.log ]; then
    failed_logins=$(grep -i "failed password" /var/log/auth.log | wc -l)
    echo "Failed login attempts: $failed_logins"
fi

echo "=== Kết thúc thống kê ==="
