## feature/parent-D 工作说明

1. 本分支完成了什么  
- **家长端主页（Parent Home）**：新增 `ParentHomePage`，展示当前 mock 绑定状态、待审批数量，并提供“活动审批”“安全功能”两个入口。  
- **活动审批流程闭环（仅基于 mock）**：  
  - 儿童端在 `ActivityPage` 点击“加入活动”会创建一条活动加入审批请求（pending），并在活动卡片上展示审批状态文案。  
  - 家长在 `ApprovalListPage` 中可以对待审批请求进行“同意/拒绝”操作，更新内存中的审批状态。  
  - 返回活动页后，根据同一活动 ID 读取审批状态，展示“已同意/已拒绝”等状态。  
- **安全功能演示页**：新增 `SafetyPage`，包含“定位共享”开关（仅演示，不做真实定位/权限）、紧急联系人信息展示和若干安全提示卡片。  
- **路由与导航接入**：在 `main.dart` 中增加 `/parent`、`/approval-list`、`/safety` 路由；在已有底部导航页面中增加“家长”入口，形成：首页 / 聊天 / 活动 / 家长 / 我的 的五栏导航结构。  

2. 新增了哪些文件  
- `lib/models/approval_request.dart`：审批请求模型，含 `ApprovalRequestType`、`ApprovalStatus` 枚举和 `ApprovalRequest` 实体。  
- `lib/models/mock_parent_data.dart`：家长端 mock 仓库，仅在内存中维护：  
  - `isBound`（当前是否 mock 绑定家长，默认 true）  
  - `locationSharingEnabled`（定位共享开关，仅演示）  
  - `approvalRequests`（活动加入审批请求列表）  
  - 方法：`createActivityRequest` / `approveRequest` / `rejectRequest` / `getStatusByActivityId` / `pendingCount`。  
- `lib/pages/parent_home_page.dart`：家长主页，展示绑定状态、待审批数量以及“活动审批”“安全功能”入口。  
- `lib/pages/approval_list_page.dart`：活动审批列表页，区分“待审批”和“已处理”两段列表，支持同步更新 mock 数据。  
- `lib/pages/safety_page.dart`：安全功能 demo 页，包含定位共享开关、紧急联系人展示和安全提示卡片。  

3. 修改了哪些已有文件  
- `lib/main.dart`  
  - 新增导入：`ParentHomePage` / `ApprovalListPage` / `SafetyPage`。  
  - 在 `routes` 中增加：`/parent`、`/approval-list`、`/safety` 三个路由，保留原有路由不变。  
- `lib/pages/home_page.dart`  
  - 保持原有好友推荐及列表逻辑不变，仅调整底部导航：  
    - 从 3 个 Tab 扩展为 5 个 Tab：`首页 / 聊天 / 活动 / 家长 / 我的`。  
    - `currentIndex` 设为 0。  
    - `onTap` 中新增 `/chat` 和 `/parent` 的跳转。  
- `lib/pages/activity_page.dart`  
  - 将 `ActivityPage` 由 `StatelessWidget` 改为 `StatefulWidget`，但仍然使用本地假活动列表 `_activities`，未引入后端数据。  
  - 新增引入 `mock_parent_data.dart` 与 `approval_request.dart`，将“加入活动”按钮接入 mock 审批流：  
    - 首次点击某活动的“加入活动”时，通过 `MockParentData.createActivityRequest` 创建 pending 请求，并弹出 SnackBar：“已发送家长确认”。  
    - 使用 `MockParentData.getStatusByActivityId` 读取当前活动的审批状态，在活动标题下方展示状态文案（待审批 / 已同意 / 已拒绝 / 尚未发起审批），颜色分别为橙/绿/红/灰。  
    - 按钮文案与可用状态随审批状态变化：  
      - 未申请且有名额：按钮为“加入活动”，可点击。  
      - pending：按钮为“等待审批”，禁用。  
      - approved：按钮为“已同意”，禁用。  
      - rejected：按钮为“已拒绝”，禁用（不做重新申请逻辑）。  
      - 无名额时统一显示“名额已满”，禁用。  
  - 调整底部导航为 5 个 Tab，并设置 `currentIndex = 2`，点击“家长”跳转 `/parent`。  
- `lib/pages/profile_page.dart`  
  - 将“家长设置”项的 `onTap` 改为 `Navigator.pushNamed(context, '/parent')`，实现最小接入。  
  - 对当前用户场景的 `BottomNavigationBar`：  
    - 从 3 个 Tab 扩展为 5 个 Tab（首页 / 聊天 / 活动 / 家长 / 我的），`currentIndex = 4`。  
    - 在 `onTap` 中新增 `/chat`、`/parent` 的跳转。  
  - 其它 UI 与交互保持不变，避免影响现有流程。  

4. 目前哪些仍然是 mock / demo  
- **所有家长相关数据均为内存 mock**：  
  - `MockParentData.isBound` 仅用于在家长主页展示“当前 mock 状态：已绑定”，没有真实绑定逻辑。  
  - `MockParentData.locationSharingEnabled` 仅驱动安全页上的开关文案，不做真实定位、不做权限请求。  
  - `MockParentData.approvalRequests` 仅在运行期内存存在，不做持久化，不与后端交互。  
- **活动数据仍为前端假数据**：`ActivityPage` 中 `_activities` 未改为仓库/后端数据，只是在 UI 层引用 `MockParentData` 获取审批状态。  
- **审批范围仅限活动**：  
  - `ApprovalRequestType` 目前只在结构上支持扩展；本分支实际只创建 `type == activity` 的请求。  
  - 未实现聊天/好友相关的审批逻辑。  
- **未实现完整绑定流程**：  
  - 未新增配对码、扫码等主绑定流程页面。  
  - 仅通过 `isBound = true` 的 mock 状态模拟“已经完成绑定”的前置条件，方便演示审批闭环。  

5. 后续和 feature/parent-H 合并时，建议如何对接  
- **绑定流程接入建议**  
  - 由 parent-H 分支实现真实的家长绑定流程与状态管理（含配对码 / 账号体系 / 登录鉴权等）。  
  - 可以将 `MockParentData.isBound` 替换为真实的绑定状态读取接口，家长主页的“当前绑定状态（Mock）”文案可根据真实数据调整为“已绑定 XXX 家长账号”等。  
  - 如需持久化定位开关和安全配置，可在 parent-H 中将 `MockParentData.locationSharingEnabled` 的角色升级为真实设置的默认值或临时占位，在后端/本地存储接入完成前保留该静态字段作为 fallback。  
- **审批数据模型与真实后端的映射**  
  - `ApprovalRequest` 已包含：`id` / `type` / `targetId` / `targetTitle` / `childName` / `status` / `createdAt`，基本可以映射到后端的审批实体。  
  - parent-H 可以：  
    - 复用 `ApprovalStatus` 与 `ApprovalRequestType` 的定义，保持前后端状态枚举一致。  
    - 用真实接口替换 `MockParentData` 中的内存列表操作（创建请求、状态更新、按 activityId 查询状态），在接口层维持同名方法，以减少对 UI 页面的改动。  
    - 考虑将 `MockParentData` 重构为接口 + 实现的形式：本分支当前实现可作为“本地 demo 实现”，parent-H 提供“远程实现”。  
- **页面与路由衔接**  
  - `/parent`、`/approval-list`、`/safety` 三个路由已在 `main.dart` 注册，且底部导航和“家长设置”入口都指向 `/parent`。  
  - 若 parent-H 需要拆分“家长登录/绑定向导页”和“家长首页”，建议：  
    - 保留 `/parent` 作为家长端主入口路由。  
    - 在 `/parent` 内部根据绑定/登录状态决定展示哪一套 UI：  
      - 未绑定：展示 H 分支实现的绑定流程页。  
      - 已绑定：展示本分支的家长主页（或其演进版本）。  
  - `ApprovalListPage` 与 `SafetyPage` 均为轻 UI 页，后续如需接真实数据，可直接在页面中调用新的仓库/接口层，无需改路由。  
- **合并策略与冲突控制**  
  - 本分支尽量只改动与 parent-D 强相关的文件，未触碰登录 / 兴趣选择 / 聊天逻辑，有利于降低与 parent-H 的冲突面。  
  - 建议在合并前：  
    - 以 `ApprovalRequest` 与 `MockParentData` 为基础，与 H 分支约定统一的“家长审批领域模型”。  
    - 由 H 分支在完成真实实现后，再统一替换 `MockParentData` 的内部逻辑，保持对 UI 层方法签名不变。  
    - 合并测试时重点回归以下路径：  
      - 儿童端：活动页“加入活动” → 生成审批请求。  
      - 家长端：查看审批列表 → 同意/拒绝 → 返回活动页查看状态。  
      - 家长端：安全页开关与提示展示是否正常。  


##habitime-D工作说明

兴趣页升级、屏幕使用时间功能、导航与返回逻辑修复。
## 一、兴趣页升级
### 1.1 功能目标

- 将兴趣选择页从“少量兴趣 + 简单 pill 按钮”升级为**分类 + 图片卡片式网格**，更贴近社交 App 的兴趣标签页体验。
- 保持与现有用户兴趣存储、首页推荐、个人资料展示的兼容。

### 1.2 数据与结构

- **分类**：共 12 个分类——推荐、爱好、旅行、生活、性格、音乐、运动、美食、宠物、自然、艺术、游戏。
- **兴趣项**：扩展至 **40+ 个**兴趣标签（带 emoji），按分类组织；每个兴趣项包含：分类 ID、展示文案、分类名称。
- **选中与存储**：仍使用 `Set<String> _selectedInterests` 存储选中的兴趣文案；完成时调用 `CurrentUser.setInterests(_selectedInterests.toList())`，与 HomePage / ProfilePage / FriendCard 的现有逻辑完全兼容。

### 1.3 页面结构

- **顶部**：保留原有橙色提示卡片和“选择你的兴趣爱好”标题，风格不变。
- **横向分类导航**：新增水平滚动的分类 Tab（ListView 横向），当前选中分类高亮（紫色背景 + 白字），未选中为白底紫边。
- **下方内容**：按当前选中的分类过滤兴趣项，以**两列卡片网格**展示：
  - 每张卡片为圆角矩形，带渐变背景（紫/橙暖色）、轻阴影，底部显示分类名和勾选图标。
  - 选中态：渐变加深、勾选图标明显，与未选中区分清晰。
- **底部**：保留“完成”按钮；校验至少选一个兴趣后，写入 `CurrentUser.setInterests` 并 `pushReplacementNamed('/home')`。

### 1.4 涉及文件

- **修改**：`lib/pages/interest_selection_page.dart`  
  - 新增内部数据结构（`_InterestCategory`、`_InterestItem`）、分类列表与 40+ 兴趣项配置；  
  - 新增横向分类导航与 `_InterestCard` 卡片组件；  
  - 完成逻辑与 `CurrentUser.setInterests` 调用未改。

---

## 二、屏幕使用时间功能（Demo）

### 2.1 功能目标

- 在儿童端核心页面顶部展示“健康使用手机”相关的**今日已用时长、剩余时长、每日上限**。
- 达到上限时，进入一个**应用内限制页**（护眼/休息提示），不做系统级锁屏。
- 全部为**前端 Demo**：计时可压缩（如每 5 秒视为 1 分钟），便于演示。

### 2.2 状态管理

- **新增**：`lib/utils/screen_time_manager.dart`
  - `ScreenTimeState`：`used`（已用时长）、`limit`（每日上限）、`limitReached`（是否到上限）。
  - `ScreenTimeManager`（单例）：
    - 使用 `Timer.periodic` 做 Demo 计时（例如每 5 秒累加 1 分钟，代码内已注释说明为 Demo）。
    - 通过 `StreamController<ScreenTimeState>` 广播状态。
    - 提供 `start()`（幂等启动）、`reset()`、以及“限制页是否已展示”的标记，避免重复弹窗。

### 2.3 展示与限制页

- **Banner 组件**：`lib/widgets/screen_time_banner.dart`
  - 展示标题“健康使用手机”，以及“今日已用 X 分钟 · 剩余 Y 分钟（每日上限 Z 分钟）”或到达上限时的提示文案。
  - 订阅 `ScreenTimeManager.stream`，在达到上限且未展示过限制页时，`pushNamed('/screen-time-limit')` 并标记已展示。
- **限制页**：`lib/pages/screen_time_limit_page.dart`
  - 路由：`/screen-time-limit`（在 `main.dart` 中注册）。
  - 内容：图标 + “今天的使用时间差不多啦～”等提示 + “我知道了”按钮，点击后 `Navigator.pop(context)` 返回。

### 2.4 接入位置

- **儿童端四个核心页面顶部**均接入 `ScreenTimeBanner`：
  - `HomePage`（好友首页）
  - `ActivityPage`（活动广场，列表第一项为 Banner）
  - `ChatPage`（聊天页）
  - `ProfilePage`（我的/他人资料）
- 家长端页面未接入 Banner，符合“仅儿童端展示”的设定。

### 2.5 涉及文件

- **新增**：`lib/utils/screen_time_manager.dart`、`lib/widgets/screen_time_banner.dart`、`lib/pages/screen_time_limit_page.dart`
- **修改**：`lib/main.dart`（注册 `/screen-time-limit`）、`lib/pages/home_page.dart`、`lib/pages/activity_page.dart`、`lib/pages/chat_page.dart`、`lib/pages/profile_page.dart`（在页面顶部插入 `ScreenTimeBanner`）

---

## 三、导航与返回逻辑修复

### 3.1 问题与目标

- 一级 Tab 页面之间切换时，避免栈过深或返回行为不一致。
- 二级页面（如创建活动、绑定码、审批列表、安全页）返回时，优先 `pop`，无法 pop 时应有安全 fallback，避免白屏。
- 从“卡片/按钮”进入一级页（如从 Profile 的“我的活动”“家长设置”进入）时，与底部 Tab 切换使用同一套逻辑，避免栈混乱。

### 3.2 统一 Tab 切换

- **NavigationHelper 扩展**：`lib/utils/navigation_helper.dart`
  - 新增 `goToTab(BuildContext context, int index)`：
    - 内部维护路由数组：`['/home', '/chat', '/activity', '/parent', '/profile']`。
    - 使用 `Navigator.pushReplacementNamed(context, routes[index])` 切换一级页。
- **使用处**：所有带底部导航的页面的 `onTap` 均改为 `NavigationHelper.goToTab(context, index)`：
  - `HomePage`、`ActivityPage`、`ChatPage`、`ProfilePage`（当前用户）、`ParentHomePage`。

### 3.3 pushNamed / pushReplacementNamed 补全与统一

- **一级页之间的跳转**：不再在各处手写 `pushReplacementNamed('/home')` 等，统一为：
  - 底部导航：`goToTab(context, index)`。
  - Home 右上角“个人”图标：`goToTab(context, 4)`。
  - Profile 内“我的活动”“我的好友”“家长设置”：`goToTab(context, 2/0/3)`。
- **二级页进入**：保持 `Navigator.pushNamed`，用于从一级页或卡片进入详情/子页：
  - 活动页 → 创建活动：`pushNamed(context, '/create-activity')`。
  - 好友/Profile → 聊天、他人资料：`pushNamed(context, '/chat'|'/profile', arguments: user)`。
  - Profile → 绑定码、家长端 → 审批列表/安全页/绑定码：`pushNamed(context, '/binding-code'|'/approval-list'|'/safety', arguments: ...)`。
- **返回逻辑**：`ChatPage`、他人 `ProfilePage` 继续使用 `NavigationHelper.smartPop`；`safePop` / `smartPop` 在无法 pop 时使用 `pushReplacementNamed(defaultRoute ?? '/home')`，避免白屏。

### 3.4 涉及文件

- **修改**：`lib/utils/navigation_helper.dart`（新增 `goToTab`）、`lib/pages/home_page.dart`、`lib/pages/activity_page.dart`、`lib/pages/chat_page.dart`、`lib/pages/profile_page.dart`、`lib/pages/parent_home_page.dart`（底部导航及部分入口改为 `goToTab`）。

---

## 四、提交与文件清单

### 4.1 提交记录（habitime-D 分支）

1. **feat: enhance interest selection with categorized cards**  
   - 仅包含：`lib/pages/interest_selection_page.dart`。

2. **feat: add screen time demo and unify tab navigation**  
   - 包含：  
     - 新增：`screen_time_manager.dart`、`screen_time_banner.dart`、`screen_time_limit_page.dart`；  
     - 修改：`main.dart`，以及 Home/Activity/Chat/Profile/ParentHome 的 Banner 接入与导航统一，`navigation_helper.dart` 的 `goToTab`。

### 4.2 新增文件

| 文件 | 说明 |
|------|------|
| `lib/utils/screen_time_manager.dart` | 屏幕时间状态与 Demo 计时器 |
| `lib/widgets/screen_time_banner.dart` | 屏幕时间 Banner 组件 |
| `lib/pages/screen_time_limit_page.dart` | 达到使用上限时的限制提示页 |

### 4.3 修改文件

| 文件 | 主要改动 |
|------|----------|
| `lib/main.dart` | 注册路由 `/screen-time-limit` |
| `lib/pages/interest_selection_page.dart` | 分类 + 40+ 兴趣项 + 横向导航 + 卡片网格 |
| `lib/pages/home_page.dart` | 顶部接入 ScreenTimeBanner；底部导航及个人入口改为 goToTab |
| `lib/pages/activity_page.dart` | 列表顶部接入 ScreenTimeBanner；底部导航改为 goToTab |
| `lib/pages/chat_page.dart` | 顶部接入 ScreenTimeBanner；底部导航改为 goToTab |
| `lib/pages/profile_page.dart` | 顶部接入 ScreenTimeBanner；底部导航及“我的活动/好友/家长设置”改为 goToTab |
| `lib/pages/parent_home_page.dart` | 底部导航改为 goToTab |
| `lib/utils/navigation_helper.dart` | 新增 goToTab，统一一级页切换 |

---

## 五、约束与说明

- **未引入新依赖**：未修改 `pubspec.yaml`，未新增第三方 package。
- **未接后端**：兴趣数据、屏幕时间、导航均为前端/内存或静态配置，无网络请求与持久化。
- **UI 风格**：与现有项目保持一致（紫/橙暖色、圆角卡片、Material 组件），未更换整套设计语言。
- **Demo 假设**：屏幕时间“1 分钟”在代码中压缩为若干秒（如 5 秒），仅用于演示；限制页只做一次引导，不实现系统级锁屏。



