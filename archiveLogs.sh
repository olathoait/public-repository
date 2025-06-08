#!/bin/bash

# Kiểm tra số lượng đối số
if [ -z "$1" ]; then
  echo "Usage: $0 <log-directory> [output-directory]"
  exit 1
fi

LOG_DIR=$1
# Nếu người dùng không nhập output-directory, đặt mặc định là /var/log/archive
OUTPUT_DIR=${2:-/var/log/archive}

# Kiểm tra sự tồn tại của thư mục chứa logs
if [ ! -d "$LOG_DIR" ]; then
  echo "Thư mục '$LOG_DIR' không tồn tại."
  exit 1
fi

# Tạo thư mục output nếu chưa tồn tại
if [ ! -d "$OUTPUT_DIR" ]; then
  mkdir -p "$OUTPUT_DIR"
fi

# Tạo tên file archive với ngày giờ hiện tại
TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
ARCHIVE_NAME="logs_archive_${TIMESTAMP}.tar.gz"
ARCHIVE_PATH="${OUTPUT_DIR}/${ARCHIVE_NAME}"

# Nén nội dung thư mục log vào file archive
tar -czf "$ARCHIVE_PATH" -C "$LOG_DIR" .

# Kiểm tra lại kết quả
if [ $? -eq 0 ]; then
  echo "Logs đã được nén thành công: $ARCHIVE_PATH"
  # Bạn có thể thêm ghi log vào một file theo kiểu:
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] Archive created: $ARCHIVE_NAME" >> "$OUTPUT_DIR/archive.log"
else
  echo "Có lỗi xảy ra trong quá trình nén logs."
  exit 1
fi
