# What to Eat (WTE)

解决外卖选择困难症的移动端 APP。

## 项目简介

每天都在纠结"今天吃什么"？WTE 帮你快速做出决定！

- 记录外卖历史
- 转盘随机推荐
- 统计消费偏好
- 预算管理

## 技术栈

| 技术 | 用途 |
|------|------|
| Flutter 3.x | 跨平台 UI 框架 |
| Dart 3.x | 编程语言 |
| Riverpod 2.x | 状态管理 |
| drift | 本地数据库 (SQLite ORM) |
| fl_chart | 图表组件 |
| go_router | 路由管理 |
| shared_preferences | KV 存储 |

## 功能清单

### P0 - 核心功能（已实现）

- [x] 外卖记录（店铺/菜品/价格/标签）
- [x] 美食标签体系（口味/类型/菜系）
- [x] 转盘随机推荐（点击 GO，动画旋转）
- [x] 偏好分析与推荐引擎
- [x] 历史统计图表（饼图/折线图）
- [x] 收藏夹

### P1 - 扩展功能（已实现）

- [x] 预算管理（月度预算/消费进度条）
- [x] 排除机制（今天不想吃...）

### v1.1 版本规划

> 定位「稳定补全版」：修复 MVP 遗留缺口，补齐记录效率。详见 [Agent.md](./Agent.md) 第 4.1 节。

**遗留缺口修复**

- [x] 收藏夹闭环（记录时勾选收藏 → 收藏页聚合展示 → 快速带出店铺名）
- [x] 点餐频次柱状图 + 图表下钻（饼图/折线图/柱状图点击 → 底部弹层明细）
- [x] 推荐理由展示（久未食用 / 均衡尝新 / 偏好命中）
- [x] 数据备份与恢复（导出/导入 JSON，保存在应用私有 `backups/` 目录）
- [x] 数据库迁移策略（逐级 `applyMigrationStep` + 单元测试）

**新增功能**

- [ ] 自然语言快速记录（"中午麦当劳巨无霸35块"）
- [ ] 上餐一键复用

### 版本路线图

| 版本 | 定位 | 核心内容 |
|------|------|----------|
| v1.1 | 稳定补全 | 遗留修复 + 记录效率 |
| v1.2 | 价值深化 | 统计增强 + 健康/天气智能推荐 |
| v1.3 | 多端基础 | 账号体系 + 云端同步 |
| v2.0 | 场景扩展 | 多人协作 / 社交 |

## 项目结构

```
wte/
├── lib/
│   ├── main.dart              # 入口
│   ├── router.dart            # 路由配置
│   ├── constants/             # 常量（主题配置）
│   ├── database/              # 数据库（drift）
│   │   ├── tables.dart        # 表定义
│   │   ├── app_database.dart  # 数据库主类
│   │   ├── daos/              # 数据访问对象
│   │   └── seed_data.dart     # 预设数据
│   ├── models/                # 数据模型
│   ├── screens/               # 页面
│   │   ├── home_screen.dart   # 首页（转盘）
│   │   ├── record_*.dart      # 记录相关
│   │   ├── stats_screen.dart  # 统计
│   │   ├── favorites_screen.dart # 收藏
│   │   ├── budget_screen.dart # 预算
│   │   ├── backup_screen.dart # 数据备份
│   │   └── settings_screen.dart # 设置
│   ├── services/              # 业务逻辑
│   │   ├── preference_service.dart # 偏好分析
│   │   ├── recommendation_service.dart # 推荐引擎
│   │   ├── stats_service.dart # 统计服务
│   │   └── backup_service.dart # 备份与恢复
│   ├── widgets/               # 通用组件
│   │   ├── fortune_wheel.dart # 转盘组件
│   │   └── scaffold_with_nav_bar.dart # 导航栏
│   └── utils/                 # 工具函数
├── assets/
│   └── data/                  # 静态数据
├── test/
│   └── migration_test.dart    # 数据库 schema 与迁移测试
├── android/                   # Android 平台
├── ios/                       # iOS 平台
├── web/                       # Web 平台
├── windows/                   # Windows 平台
├── linux/                     # Linux 平台
└── macos/                     # macOS 平台
```

## 开发日志

### 2026-09-17

#### M0 - 项目初始化
- 创建 Git 仓库
- 配置 GitHub 和 Gitee 远程仓库
- 创建 Agent.md 开发需求文档

#### M1 - 项目骨架搭建
- 确定技术栈：Flutter + Riverpod + drift + fl_chart + go_router
- 初始化 Flutter 项目
- 配置核心依赖
- 搭建目录结构

#### M2 - 核心数据层
- 定义数据模型（Tag, Record, Shop, Budget）
- 实现 drift 数据库表和 DAO
- 创建预设标签数据
- 运行代码生成

#### M3 - 外卖记录 + 标签体系
- 实现底部导航栏（5 个 Tab）
- 实现外卖记录列表和表单
- 实现标签管理（按维度分组/增删改）
- 实现收藏夹页面
- 配置 go_router 路由

#### M4 - 偏好分析 + 推荐引擎 + 转盘
- 实现偏好分析服务（标签频率统计）
- 实现推荐引擎（加权随机算法）
- 实现转盘组件（CustomPainter + AnimationController）
- 更新首页集成转盘推荐

#### M5 - 统计图表 + 收藏夹
- 实现统计服务（消费统计、标签分布）
- 实现统计页面（摘要卡片、饼图、折线图）
- 完善收藏夹搜索功能

#### M6 - 预算管理 + 排除机制
- 实现预算管理页面（设置/进度条/提醒）
- 实现排除机制（推荐前排除标签）
- 更新设置页面集成预算管理

#### M7 - UI 打磨 + 测试
- 创建统一主题配置
- 修复代码分析问题
- 更新 .gitignore

#### Bug 修复与优化
- 修复转盘显示与推荐结果不一致问题
- 修复价格符号不统一问题
- 添加转盘编辑功能
- 实现转盘数据持久化
- 修复转盘箭头颜色问题

### 2026-09-19

#### M8 - Android 构建链路打通
- 配置 Android SDK 与国内镜像（阿里云 Maven、腾讯云 Gradle）
- 升级构建链：Gradle 8.7 / AGP 8.6.1 / Kotlin 1.9.24 / Java 17
- 配置 `compileSdk = 35`、`buildToolsVersion = 34.0.0`
- APK 构建成功（24.9MB）

#### v1.1 规划
- 梳理 MVP 遗留缺口 D-01~D-06
- 新增 v1.1 需求 F-09~F-15，更新里程碑 M9~M13
- 确定版本路线图（v1.1 稳定补全 / v1.2 价值深化 / v1.3 多端基础 / v2.0 场景扩展）

#### M9 - 收藏夹闭环 + 推荐理由
- 打通「记录时收藏 → 收藏页聚合 → 快速带出店铺名」
- 收藏列表显示消费单数与最近消费时间
- 编辑转盘支持「导入收藏店铺」作为推荐候选
- 转盘结果弹窗展示推荐理由（久未食用 / 均衡尝新 / 偏好命中）
- 「去记录」自动带出推荐菜名

#### M10 - 统计补全
- 新增点餐频次柱状图（7天按日 / 30天按自然周）
- 饼图、折线图、柱状图均支持点击下钻，底部弹层展示记录明细
- 修正折线图时间轴倒序缺陷

#### M11 - 数据安全加固
- 备份服务：导出 JSON、列举备份、恢复、清空（含格式版本校验）
- 新增「数据备份」页面（设置入口）
- 数据库逐级迁移策略 `applyMigrationStep`，未登记版本显式报错
- 新增单元测试：`test/migration_test.dart`、`test/backup_test.dart`（7 个用例）
- 登记质量门禁：`flutter analyze` + `flutter test`

#### 记录删除能力补全
- 记录列表卡片新增「⋯」菜单（编辑 / 删除）
- 删除二次确认，确认框回显店铺、菜品、价格
- 统计图表改为随记录变更自动刷新（`statsRevisionProvider`）

## 运行指南

### 环境要求

- Flutter 3.x
- Dart 3.x

### 安装依赖

```bash
flutter pub get
```

### 运行应用

```bash
# Windows 桌面
flutter run -d windows

# Chrome 浏览器
flutter run -d chrome

# Android 真机（需要连接手机）
flutter run -d <设备ID>

# 构建 APK
flutter build apk --release
```

### 代码分析

```bash
dart analyze lib/
```

### 单元测试

```bash
flutter test
```

## 贡献指南

1. Fork 本仓库
2. 创建功能分支：`git checkout -b feature/xxx`
3. 提交更改：`git commit -m 'feat: add xxx'`
4. 推送分支：`git push origin feature/xxx`
5. 创建 Pull Request

## 许可证

MIT License

## 联系方式

- GitHub: https://github.com/YuKlmi/what_to_eat
- Gitee: https://gitee.com/yklm/what_to_eat.git