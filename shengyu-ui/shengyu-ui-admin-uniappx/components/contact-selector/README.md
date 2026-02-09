# ContactSelector 联系人选择组件

可复用的联系人选择组件，支持字母索引、分组显示、多选功能。

## 功能特性

- ✅ 字母分组显示
- ✅ 右侧字母索引快速定位
- ✅ 可选的快捷分类入口
- ✅ 支持单选/多选模式
- ✅ 自动生成假名数据（用于演示）
- ✅ 支持自定义联系人数据
- ✅ 响应式设计，适配各种屏幕

## 使用方法

### 1. 基础用法（仅展示）

```vue
<template>
  <contact-selector 
    @select="handleSelect"
  />
</template>

<script setup lang="uts">
import ContactSelector from '../../components/contact-selector/contact-selector.uvue'

function handleSelect(item : any) {
  console.log('点击联系人:', item.name)
}
</script>
```

### 2. 多选模式（带复选框）

```vue
<template>
  <contact-selector 
    :selectable="true"
    :contacts="contactList"
    @select="handleSelect"
  />
</template>

<script setup lang="uts">
import ContactSelector from '../../components/contact-selector/contact-selector.uvue'

const contactList = ref([
  {
    id: 1,
    name: '张伟',
    role: '高级经理',
    avatarText: '张伟',
    avatarBg: '#0ea5e9',
    pinyin: 'Z',
    selected: false
  }
  // ... 更多联系人
])

function handleSelect(item : any) {
  console.log('选择联系人:', item.name, '选中状态:', item.selected)
}
</script>
```

### 3. 完整功能（带分类入口）

```vue
<template>
  <contact-selector 
    :show-categories="true"
    :selectable="true"
    :contacts="contactList"
    @select="handleSelect"
    @category-click="handleCategory"
  />
</template>

<script setup lang="uts">
import ContactSelector from '../../components/contact-selector/contact-selector.uvue'

const contactList = ref([])

function handleSelect(item : any) {
  console.log('选择联系人:', item)
}

function handleCategory(item : any) {
  console.log('点击分类:', item.nameKey)
  uni.showToast({
    title: '功能开发中',
    icon: 'none'
  })
}
</script>
```

## Props

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| showCategories | Boolean | false | 是否显示快捷分类入口 |
| selectable | Boolean | false | 是否显示复选框（多选模式） |
| contacts | Array | [] | 联系人数据数组，为空时使用默认假名数据 |

## Events

| 事件名 | 参数 | 说明 |
|--------|------|------|
| select | item: any | 点击联系人时触发，返回联系人对象 |
| category-click | item: any | 点击分类时触发，返回分类对象 |

## 联系人数据结构

```typescript
{
  id: number,           // 联系人 ID
  name: string,         // 姓名
  role: string,         // 职位
  avatarText: string,   // 头像文字（通常是姓名前2个字）
  avatarBg: string,     // 头像背景色（十六进制颜色）
  pinyin: string,       // 拼音首字母（用于分组，A-Z）
  selected: boolean,    // 是否选中（仅在 selectable=true 时使用）
  isCurrentUser?: boolean  // 是否是当前登录用户（可选，用于防止取消选中）
}
```

**特殊说明**:
- 当 `isCurrentUser: true` 且 `selected: true` 时，用户无法取消选中该联系人
- 适用于发起群聊等场景，确保创建者始终在群成员中

## 分类数据结构

组件内置4个快捷分类：

```typescript
[
  { icon: '\ue616', bg: '#fb923c', nameKey: 'contacts.groups' },      // 群组
  { icon: '\uea90', bg: '#facc15', nameKey: 'contacts.following' },   // 关注
  { icon: '\ue62b', bg: '#84cc16', nameKey: 'contacts.org' },         // 组织
  { icon: '\ue686', bg: '#06b6d4', nameKey: 'contacts.dept' }         // 部门
]
```

## 默认假名数据

当不传入 `contacts` 参数时，组件会自动生成50条假名数据：

- **姓氏**: 张、李、王、刘、陈、杨、赵、黄、周、吴等20个常见姓氏
- **名字**: 伟、芳、娜、秀英、敏、静、丽、强、磊、军等20个常见名字
- **职位**: 高级经理、部门经理、项目经理、开发工程师等10种职位
- **拼音**: 按 A-Z 循环分配

## 样式定制

组件使用标准的 UniAppX 样式，主要颜色：

- 主题色: `#1677FF`
- 背景色: `#FFFFFF`
- 分割线: `#EFF0F1`
- 文字颜色: `#333333` / `#999999`
- 激活状态: `#F2F3F5`

## 使用场景

### 1. 发起群聊

```vue
<!-- pages/contacts/initiate-group.uvue -->
<contact-selector 
  :show-categories="true"
  :selectable="true"
  :contacts="contactList"
  @select="handleSelect"
  @category-click="handleCategory"
/>
```

### 2. 转发消息

```vue
<!-- pages/message/forward.uvue -->
<contact-selector 
  :selectable="true"
  :contacts="contactList"
  @select="handleSelect"
/>
```

### 3. 通讯录展示

```vue
<!-- pages/contacts/contacts.uvue -->
<contact-selector 
  :contacts="contactList"
  @select="handleContact"
/>
```

### 4. 添加成员

```vue
<!-- pages/group/add-member.uvue -->
<contact-selector 
  :selectable="true"
  :contacts="availableContacts"
  @select="handleSelect"
/>
```

## 注意事项

1. **数据响应式**: 传入的 `contacts` 数组需要使用 `ref()` 包裹，以保证选中状态的响应式更新
2. **拼音字段**: 每个联系人必须包含 `pinyin` 字段（A-Z），用于字母分组
3. **选中状态**: 在多选模式下，组件会直接修改传入对象的 `selected` 属性
4. **国际化**: 组件使用 `useI18n` hook，确保项目已配置国际化
5. **当前用户保护**: 如果联系人标记为 `isCurrentUser: true` 且已选中，则无法取消选中

## 完整示例

参考文件：
- `pages/contacts/initiate-group.uvue` - 发起群聊页面
- `pages/contacts/contacts.uvue` - 通讯录页面

## 更新日志

### v1.0.0 (2026-02-09)
- ✅ 初始版本
- ✅ 支持字母分组和索引
- ✅ 支持多选模式
- ✅ 支持快捷分类
- ✅ 自动生成假名数据
