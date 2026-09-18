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

### 后续规划

- [ ] 云端同步
- [ ] 用户登录
- [ ] 拍照识别菜品
- [ ] 多人拼单

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
│   │   └── settings_screen.dart # 设置
│   ├── services/              # 业务逻辑
│   │   ├── preference_service.dart # 偏好分析
│   │   ├── recommendation_service.dart # 推荐引擎
│   │   └── stats_service.dart # 统计服务
│   ├── widgets/               # 通用组件
│   │   ├── fortune_wheel.dart # 转盘组件
│   │   └── scaffold_with_nav_bar.dart # 导航栏
│   └── utils/                 # 工具函数
├── assets/
│   └── data/                  # 静态数据
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