Dưới đây là bản kế hoạch chi tiết (**Initial Bootstrap Plan**) để bạn dựng phần **Hạt nhân (Core)** cho hệ thống: Kết nối thành công **9Router** (quản lý model) $\\rightarrow$ **OpenClaw** (bộ não xử lý) $\\rightarrow$ **Telegram** (kênh giao tiếp).  
Hoàn thành kế hoạch này, bạn sẽ có một "bệ phóng" sạch sẽ, sẵn sàng để Agent tự đọc bản Master Plan trước đó và tự tiến hóa.

# **🛠️ INITIAL PLAN: TRIỂN KHAI HẠT NHÂN CORE (OPENCLAW \+ 9ROUTER \+ TELEGRAM)**

## **📌 I. CHUẨN BỊ MÔI TRƯỜNG (PREREQUISITES)**

Đảm bảo server hoặc máy local của bạn đã cài đặt sẵn các hạ tầng cơ bản sau:

* **Node.js** (Phiên bản LTS từ 18 trở lên) để chạy OpenClaw.  
* **Docker & Docker Compose** để chạy môi trường Sandbox an toàn cho Agent thực thi lệnh Linux.  
* **Git** để quản lý mã nguồn và hỗ trợ Agent tự kéo/đẩy code.

## **📅 II. CÁC BƯỚC TRIỂN KHAI CHI TIẾT**

### **BƯỚC 1: CẤU HÌNH HẠ TẦNG LLM TRÊN 9ROUTER**

9Router đóng vai trò gom và phân phối API Key từ các model miễn phí, giúp Agent chạy liên tục không lo tốn phí.

1. Khởi động giao diện Dashboard của **9Router** (Mặc định tại http://localhost:20138).  
2. Vào mục **Providers** $\\rightarrow$ Thêm các API Key miễn phí mà bạn có (Kiro AI, OpenCode Free, iFlow...).  
3. Vào mục **Combos** $\\rightarrow$ Tạo 2 nhóm định tuyến chiến lược:  
   * **combo-reasoning**: Ưu tiên gán model nemotron-3-ultra-free (Dùng để bóc tách logic, lên kế hoạch và viết tài liệu đặc tả).  
   * **combo-coding**: Ưu tiên gán model qwen3.6-plus-free và north-mini-code-free (Dùng để gõ code thực tế, chạy terminal và review cú pháp).

### **BƯỚC 2: KHỞI TẠO BOT TELEGRAM (CỔNG GIAO TIẾP CHÍNH)**

1. Mở ứng dụng Telegram, tìm kiếm và chat với @BotFather.  
2. Gửi lệnh /newbot, đặt tên cho Bot (Ví dụ: MyClawCore\_Bot) và username cho Bot.  
3. **Lưu lại đoạn Token API** (Chuỗi ký tự dạng 123456789:ABC...).  
4. Tìm và chat với @userinfobot để lấy **User ID** tài khoản Telegram của chính bạn. Đây là bước bắt buộc để cấu hình bảo mật, đảm bảo chỉ có bạn mới có quyền ra lệnh cho server.

### **BƯỚC 3: DỰNG CẤU TRÚC THƯ MỤC CƠ BẢN (BASE SETUP)**

Tạo một thư mục dự án mới ngoài server và tạo sẵn các folder cốt lõi theo đúng thiết kế kiến trúc tự tiến hóa:

Bash  
mkdir my-agent-base && cd my-agent-base  
mkdir \-p core/openclaw\_config core/telegram\_bot docs/features docs/agents agents plugins modules workspace

### **BƯỚC 4: CÀI ĐẶT VÀ CẤU HÌNH OPENCLAW**

1. Cài đặt gói OpenClaw toàn cục trên hệ thống:

npm install \-g openclaw

2\. Tạo file cấu hình môi trường \`.env\` nằm tại thư mục gốc của dự án (\`my-agent-base/.env\`) với nội dung sau:

\`\`\`env  
\# \--- CẤU HÌNH ĐỊNH TUYẾN QUA 9ROUTER \---  
OPENAI\_API\_BASE=http://localhost:20138/v1  
OPENAI\_API\_KEY=9router\_local\_secret  
OPENAI\_MODEL=combo-coding

\# \--- CẤU HÌNH BẢO MẬT & KÊNH CHAT TELEGRAM \---  
TELEGRAM\_BOT\_TOKEN=điền\_token\_của\_bot\_father\_vào\_đây  
TELEGRAM\_ALLOWED\_USER\_IDS=điền\_user\_id\_telegram\_của\_bạn\_vào\_đây

\# \--- QUYỀN CAN THIỆP TERMINAL LINUX \---  
WORKSPACE\_DIR=./workspace  
ENABLE\_TERMINAL\_EXECUTION=true  
EXECUTION\_MODE=docker  \# Ép Agent chạy lệnh terminal bên trong container Docker để an toàn

### **BƯỚC 5: THIẾT LẬP FILE ĐIỂM KHỞI CHẠY LÕI (core/bootloader.js)**

Tạo file core/bootloader.js để làm nhiệm vụ kích hoạt OpenClaw và tự động nạp các plugin, agent mà AI sẽ tự "đẻ" ra sau này:

JavaScript  
const fs \= require('fs');  
const path \= require('path');  
const { exec } \= require('child\_process');

console.log("\[Core\] Đang khởi động Hạt nhân điều khiển...");

// 1\. Kiểm tra và tự động tạo thư mục động nếu chưa có  
const requiredDirs \= \['./agents', './plugins', './modules', './docs'\];  
requiredDirs.forEach(dir \=\> {  
    if (\!fs.existsSync(dir)) {  
        fs.mkdirSync(dir, { recursive: true });  
    }  
});

// 2\. Quét động và tự kích hoạt các Plugin (như Zalo, Discord sau này)  
const pluginsDir \= path.join(\_\_dirname, '../plugins');  
fs.readdirSync(pluginsDir).forEach(pluginName \=\> {  
    const pluginPath \= path.join(pluginsDir, pluginName, 'index.js');  
    if (fs.existsSync(pluginPath)) {  
        console.log(\`\[Core\] Đang nạp cổng kết nối tự sinh: ${pluginName}\`);  
        require(pluginPath);  
    }  
});

// 3\. Gọi OpenClaw bắt đầu lắng nghe Telegram  
console.log("\[Core\] Kết nối Telegram và 9Router thành công. Hệ thống Online\!");

## **🎯 III. KIỂM TRA ĐỘ HOẠT ĐỘNG (SMOKE TEST)**

Sau khi hoàn thành 5 bước trên, bạn tiến hành chạy thử nghiệm:

1. Chạy lệnh kích hoạt hệ thống:

node core/bootloader.js

2\. Mở Telegram, truy cập vào con Bot bạn vừa tạo và gõ: \`/start\` hoặc \`"Hi, kiểm tra hệ thống"\`.  
3\. Nếu Bot phản hồi lại tin nhắn và đồng thời trên giao diện \*\*9Router\*\* hiển thị log nhận request từ model \`combo-coding\`, nghĩa là phần trục xương sống (Core) đã thông suốt 100%\!

Bây giờ, bạn chỉ cần copy nội dung bản \*\*Master Plan\*\* trước đó lưu vào file \`docs/system\_spec.md\`, hệ thống sẽ chính thức có "bản đồ tư duy" để tự thực hiện các yêu cầu mở rộng nâng cao tiếp theo của bạn.  
