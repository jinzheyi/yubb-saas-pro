# UniApp X 工具类使用指南

本目录包含了从 Web 端迁移并适配三端（Android、iOS、Web）的工具类。

## 文件列表

### 1. dict.uts - 字典工具类

用于管理和使用数据字典。

**主要功能**：
- 获取字典选项
- 获取字典标签
- 支持整数、字符串、布尔类型字典
- 字典数据本地缓存

**使用示例**：

```typescript
import { getDictOptions, getDictLabel, DICT_TYPE } from '@/utils/dict.uts'

// 获取字典选项
const statusOptions = getDictOptions(DICT_TYPE.COMMON_STATUS)

// 获取字典标签
const statusLabel = getDictLabel(DICT_TYPE.COMMON_STATUS, 1)

// 获取整数类型字典
const intOptions = getIntDictOptions(DICT_TYPE.SYSTEM_USER_SEX)

// 设置字典数据（从后端加载）
setDictData(DICT_TYPE.COMMON_STATUS, [
	{ dictType: 'common_status', label: '启用', value: '1', colorType: 'success', cssClass: '' },
	{ dictType: 'common_status', label: '禁用', value: '0', colorType: 'danger', cssClass: '' }
])
```

### 2. file.uts - 文件工具类

用于文件相关的操作和判断。

**主要功能**：
- 文件名提取
- 文件类型判断（图片、视频、音频、文档）
- 文件大小格式化
- 文件扩展名获取
- MIME 类型获取
- 文件验证

**使用示例**：

```typescript
import { 
	getFileNameFromUrl, 
	isImage, 
	formatFileSize,
	getFileIcon,
	validateFileSize
} from '@/utils/file.uts'

// 从 URL 提取文件名
const fileName = getFileNameFromUrl('https://example.com/files/image.jpg')

// 判断是否为图片
if (isImage('photo.jpg')) {
	console.log('这是一张图片')
}

// 格式化文件大小
const sizeStr = formatFileSize(1024000) // "1000.00 KB"

// 获取文件图标
const icon = getFileIcon('document.pdf') // "pdf"

// 验证文件大小（最大 10MB）
if (validateFileSize(fileSize, 10)) {
	console.log('文件大小符合要求')
}

// 验证文件类型
if (validateFileType('image.jpg', ['jpg', 'png', 'gif'])) {
	console.log('文件类型符合要求')
}
```

### 3. request.uts - 请求工具类

用于网络请求，已包含 Token 刷新机制。

**主要功能**：
- GET/POST 请求封装
- 自动添加 Token 和租户 ID
- Token 过期自动刷新
- 请求/响应拦截
- 错误处理

**使用示例**：

```typescript
import { get, post, setToken, removeToken } from '@/utils/request.uts'

// GET 请求
const data = await get('/system/user/profile')

// POST 请求
const result = await post('/system/user/update', {
	nickname: '张三',
	email: 'zhangsan@example.com'
})

// 设置 Token（登录后）
setToken({
	accessToken: 'xxx',
	refreshToken: 'yyy'
})

// 移除 Token（登出）
removeToken()
```

### 4. upload.uts - 文件上传工具类

用于文件上传，支持图片、视频、文件上传。

**主要功能**：
- 文件上传
- 图片选择并上传
- 视频选择并上传
- 文件选择并上传（H5）
- 上传进度监听

**使用示例**：

```typescript
import { 
	uploadFile, 
	chooseAndUploadImage,
	chooseAndUploadVideo,
	getUploadUrl,
	getUploadHeader
} from '@/utils/upload.uts'

// 上传文件
const result = await uploadFile(
	'/path/to/file.jpg',
	'avatar', // 目录
	(progress) => {
		console.log('上传进度:', progress + '%')
	}
)

// 选择并上传图片
const images = await chooseAndUploadImage(
	3, // 最多选择 3 张
	'product', // 目录
	(progress) => {
		console.log('上传进度:', progress + '%')
	}
)

// 选择并上传视频
const video = await chooseAndUploadVideo(
	'video', // 目录
	(progress) => {
		console.log('上传进度:', progress + '%')
	}
)

// 获取上传 URL（用于自定义上传组件）
const uploadUrl = getUploadUrl()

// 获取上传请求头（用于自定义上传组件）
const uploadHeader = getUploadHeader()
```

## 平台兼容性

所有工具类都经过三端适配：

| 工具类 | Android | iOS | Web |
|--------|---------|-----|-----|
| dict.uts | ✅ | ✅ | ✅ |
| file.uts | ✅ | ✅ | ✅ |
| request.uts | ✅ | ✅ | ✅ |
| upload.uts | ✅ | ✅ | ✅ |

## 注意事项

### 1. 字典数据初始化

字典数据需要在应用启动时从后端加载：

```typescript
// 在 App.uvue 的 onLaunch 中
import { setDictData } from '@/utils/dict.uts'
import { getDictDataApi } from '@/api/system/dict.uts'

onLaunch(async () => {
	// 加载字典数据
	const dictData = await getDictDataApi()
	for (const dictType in dictData) {
		setDictData(dictType, dictData[dictType])
	}
})
```

### 2. Token 管理

Token 会自动添加到请求头中，无需手动处理。Token 过期时会自动刷新。

### 3. 文件上传

- Android/iOS：使用 `uni.chooseImage`、`uni.chooseVideo`
- Web：使用 `uni.chooseFile`（需要条件编译）

### 4. 条件编译

部分功能使用了条件编译来适配不同平台：

```typescript
// #ifdef H5
// Web 端特有代码
// #endif

// #ifdef APP-ANDROID
// Android 端特有代码
// #endif

// #ifdef APP-IOS
// iOS 端特有代码
// #endif
```

## 完整示例

### 用户列表页面

```vue
<template>
	<view class="user-list">
		<view v-for="user in userList" :key="user.id" class="user-item">
			<image :src="user.avatar" class="avatar"></image>
			<view class="info">
				<text class="name">{{ user.nickname }}</text>
				<text class="status">{{ getUserStatusLabel(user.status) }}</text>
			</view>
		</view>
	</view>
</template>

<script setup lang="uts">
	import { get } from '@/utils/request.uts'
	import { getDictLabel, DICT_TYPE } from '@/utils/dict.uts'
	
	const userList = ref<any[]>([])
	
	// 获取用户状态标签
	function getUserStatusLabel(status: number): string {
		return getDictLabel(DICT_TYPE.COMMON_STATUS, status)
	}
	
	// 加载用户列表
	async function loadUserList() {
		try {
			const data = await get('/system/user/list')
			userList.value = data.list
		} catch (e) {
			console.error('加载用户列表失败:', e)
		}
	}
	
	onMounted(() => {
		loadUserList()
	})
</script>
```

### 文件上传页面

```vue
<template>
	<view class="upload-page">
		<button @click="handleUploadImage">上传图片</button>
		<button @click="handleUploadVideo">上传视频</button>
		
		<view v-if="uploadProgress > 0" class="progress">
			<text>上传进度: {{ uploadProgress }}%</text>
		</view>
		
		<view v-if="uploadedFiles.length > 0" class="file-list">
			<view v-for="file in uploadedFiles" :key="file.url" class="file-item">
				<image v-if="isImage(file.name)" :src="file.url" class="preview"></image>
				<text class="file-name">{{ file.name }}</text>
				<text class="file-size">{{ formatFileSize(file.size) }}</text>
			</view>
		</view>
	</view>
</template>

<script setup lang="uts">
	import { chooseAndUploadImage, chooseAndUploadVideo } from '@/utils/upload.uts'
	import { isImage, formatFileSize } from '@/utils/file.uts'
	
	const uploadProgress = ref<number>(0)
	const uploadedFiles = ref<any[]>([])
	
	// 上传图片
	async function handleUploadImage() {
		try {
			uploadProgress.value = 0
			
			const results = await chooseAndUploadImage(
				3, // 最多 3 张
				'product',
				(progress) => {
					uploadProgress.value = progress
				}
			)
			
			uploadedFiles.value.push(...results.map(r => r.data))
			
			uni.showToast({
				title: '上传成功',
				icon: 'success'
			})
		} catch (e) {
			console.error('上传失败:', e)
		} finally {
			uploadProgress.value = 0
		}
	}
	
	// 上传视频
	async function handleUploadVideo() {
		try {
			uploadProgress.value = 0
			
			const result = await chooseAndUploadVideo(
				'video',
				(progress) => {
					uploadProgress.value = progress
				}
			)
			
			uploadedFiles.value.push(result.data)
			
			uni.showToast({
				title: '上传成功',
				icon: 'success'
			})
		} catch (e) {
			console.error('上传失败:', e)
		} finally {
			uploadProgress.value = 0
		}
	}
</script>
```

## 总结

这些工具类提供了完整的业务支持：

1. **dict.uts** - 字典管理
2. **file.uts** - 文件处理
3. **request.uts** - 网络请求
4. **upload.uts** - 文件上传

所有工具类都经过三端适配，可以直接在项目中使用。
