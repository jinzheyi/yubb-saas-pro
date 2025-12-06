// 直接使用项目现有的请求配置，不依赖外部config模块
export const myRequest = (option = {}) => {
	return new Promise((reslove, reject) => {
		uni.request({
			// 使用完整URL，添加基础路径
			url: 'http://localhost:48080' + option.url,
			data: option.data,
			method: option.method || "GET",
			header: {
				'Content-Type': 'application/json'
			},
			success: (result) => {
				try {
					// 尝试解析响应数据，如果失败则直接返回原始数据
					if (result.data && typeof result.data === 'string') {
						result.data = JSON.parse(result.data)
					}
				} catch (e) {
					// 解析失败时，不影响后续处理
					console.warn('JSON parse failed:', e)
				}
				reslove(result)
			},
			fail: (error) => {
				reject(error)
			}
		})
	})
}
