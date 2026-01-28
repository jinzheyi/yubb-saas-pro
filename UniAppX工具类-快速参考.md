# UniApp X 工具类快速参考

## 📦 工具类列表

| 工具类 | 文件路径 | 主要功能 |
|--------|---------|---------|
| 字典工具 | `utils/dict.uts` | 字典数据管理 |
| 文件工具 | `utils/file.uts` | 文件类型判断、大小格式化 |
| 请求工具 | `utils/request.uts` | 网络请求、Token 管理 |
| 上传工具 | `utils/upload.uts` | 文件上传、进度监听 |

---

## 🔧 常用 API

### 字典工具（dict.uts）

```typescript
import { getDictOptions, getDictLabel, DICT_TYPE } from '@/utils/dict.uts'

// 获取字典选项
getDictOptions(DICT_TYPE.COMMON_STATUS)

// 获取字典标签
getDictLabel(DICT_TYPE.COMMON_STATUS, 1)

// 设置字典数据
setDictData(dictType, dictData)
```

### 文件工具（file.uts）

```typescript
import { isImage, formatFileSize, getFileIcon } from '@/utils/file.uts'

// 判断文件类型
isImage('photo.jpg')        // 是否为图片
isVideo('video.mp4')        // 是否为视频
isAudio('music.mp3')        // 是否为音频
isDocument('file.pdf')      // 是否为文档

// 格式化文件大小
formatFileSize(1024000)     // "1000.00 KB"

// 获取文件图标
getFileIcon('document.pdf') // "pdf"

// 验证文件
validateFileSize(fileSize, 10)              // 验证大小（最大 10MB）
validateFileType('image.jpg', ['jpg', 'png']) // 验证类型
```

### 请求工具（request.uts）

```typescript
import { get, post, setToken, removeToken } from '@/utils/request.uts'

// GET 请求
await get('/system/user/profile')

// POST 请求
await post('/system/user/update', { nickname: '张三' })

// Token 管理
setToken({ accessToken: 'xxx', refreshToken: 'yyy' })
removeToken()
```

### 上传工具（upload.uts）

```typescript
import { 
	uploadFile, 
	chooseAndUploadImage,
	chooseAndUploadVideo 
} from '@/utils/upload.uts'

// 上传文件
await uploadFile(filePath, 'avatar', (progress) => {
	console.log('进度:', progress + '%')
})

// 选择并上传图片（最多 3 张）
await chooseAndUploadImage(3, 'product', (progress) => {
	console.log('进度:', progress + '%')
})

// 选择并上传视频
await chooseAndUploadVideo('video', (progress) => {
	console.log('进度:', progress + '%')
})
```

---

## 📱 平台兼容性

| 功能 | Android | iOS | Web |
|------|---------|-----|-----|
| 字典管理 | ✅ | ✅ | ✅ |
| 文件判断 | ✅ | ✅ | ✅ |
| 网络请求 | ✅ | ✅ | ✅ |
| 图片上传 | ✅ | ✅ | ✅ |
| 视频上传 | ✅ | ✅ | ✅ |
| 文件上传 | ❌ | ❌ | ✅ |

---

## 💡 使用技巧

### 1. 字典数据初始化

在 `App.uvue` 的 `onLaunch` 中加载字典：

```typescript
import { setDictData } from '@/utils/dict.uts'

onLaunch(async () => {
	const dictData = await getDictDataApi()
	for (const dictType in dictData) {
		setDictData(dictType, dictData[dictType])
	}
})
```

### 2. 文件上传进度显示

```typescript
const uploadProgress = ref<number>(0)

await chooseAndUploadImage(1, 'avatar', (progress) => {
	uploadProgress.value = progress
})
```

### 3. 文件类型验证

```typescript
// 上传前验证
if (!validateFileType(fileName, ['jpg', 'png', 'gif'])) {
	uni.showToast({ title: '只能上传图片', icon: 'none' })
	return
}

if (!validateFileSize(fileSize, 10)) {
	uni.showToast({ title: '文件不能超过 10MB', icon: 'none' })
	return
}
```

### 4. 请求错误处理

```typescript
try {
	const data = await get('/api/xxx')
	// 处理数据
} catch (e) {
	console.error('请求失败:', e)
	// 错误已在 request.uts 中统一处理（显示 Toast）
}
```

---

## ⚠️ 注意事项

1. **字典数据**：需要在应用启动时从后端加载
2. **Token 管理**：Token 会自动添加到请求头，无需手动处理
3. **文件上传**：建议文件大小不超过 10MB
4. **条件编译**：部分功能使用了条件编译（如 H5 的文件选择）

---

## 📚 完整文档

详细使用说明请查看：`utils/README.md`

---

**更新日期**：2026-01-28  
**版本**：v1.0.0
