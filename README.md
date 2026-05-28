# PhotoSync - 手机相册同步备份应用

## 项目结构

```
photosync/
├── server/                 # Go API Server
│   ├── main.go
│   ├── config/
│   ├── handlers/
│   ├── middleware/
│   ├── models/
│   └── utils/
├── mobile/                 # Flutter App
│   ├── lib/
│   │   ├── config/
│   │   ├── models/
│   │   ├── services/
│   │   ├── screens/
│   │   └── main.dart
│   └── pubspec.yaml
├── scripts/                # 工具脚本
└── .github/workflows/      # CI/CD
```

## 技术栈

- **前端**: Flutter (跨平台)
- **后端**: Go + Gin 框架
- **数据库**: SQLite (纯 Go 实现)
- **认证**: JWT Token
- **存储**: NAS 本地文件系统

## 域名和端口

- **API 域名**: `photo.threel.site`
- **API 端口**: `18080`
- **API 地址**: `https://photo.threel.site:18080/api`

## 存储路径

- **数据库**: `/vol1/1000/相册/photosync.db`
- **照片文件**: `/vol1/1000/相册/photos/{user_id}/{year}/{month}/`

## 快速开始

### 1. 启动 API Server

```bash
cd server
go build -o photosync-server .
./photosync-server
```

### 2. 配置 SSL 证书

将证书文件放置到服务器，配置 Nginx 反向代理：

```nginx
server {
    listen 443 ssl;
    server_name photo.threel.site;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:18080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 3. 编译 Flutter App

```bash
cd mobile
flutter pub get
flutter build apk --release
```

## API 接口

### 认证

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/auth/register` | 用户注册 |
| POST | `/api/auth/login` | 用户登录 |

### 照片

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/photos` | 获取照片列表 |
| POST | `/api/photos/upload` | 上传照片 |
| GET | `/api/photos/:id/file` | 下载照片 |
| DELETE | `/api/photos/:id` | 删除照片 |
| POST | `/api/photos/check-sync` | 批量检查同步状态 |

### 相册

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/albums` | 获取相册列表 |
| POST | `/api/albums` | 创建相册 |
| GET | `/api/albums/:id` | 获取相册详情 |
| PUT | `/api/albums/:id` | 更新相册 |
| DELETE | `/api/albums/:id` | 删除相册 |

## GitHub Actions 自动构建

### 配置 Secrets

在 GitHub 仓库设置以下 Secrets：

1. `KEYSTORE_BASE64`: Keystore 文件的 Base64 编码
2. `KEYSTORE_PASSWORD`: Keystore 密码
3. `KEY_PASSWORD`: 密钥密码
4. `KEY_ALIAS`: 密钥别名

### 生成 Keystore

```bash
chmod +x scripts/generate_keystore.sh
./scripts/generate_keystore.sh
```

### 发布新版本

```bash
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions 会自动构建 APK 并创建 Release。

## 包名

- **Android**: `com.threel.photosync`
- **iOS**: `com.threel.photosync`

## 版本号规范

采用语义化版本：`主版本.次版本.修订号`

- **主版本**: 重大功能变更
- **次版本**: 新增功能
- **修订号**: Bug 修复

## 开发流程

1. 在 `main` 分支开发
2. 功能完成后创建 PR
3. 合并后打 tag 触发自动构建
4. 下载 APK 安装测试
