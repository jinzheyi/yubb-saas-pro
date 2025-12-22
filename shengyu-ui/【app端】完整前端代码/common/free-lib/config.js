// 应用全局配置
export default {
  // baseUrl: 'http://api-dashboard.yudao.iocoder.cn',
  baseUrl: 'http://localhost:48080',
  baseApi: '/admin-api',
  // websocket配置
  socketUrl: 'ws://localhost:8090/sy',
  env:"dev",
  codeUrl:"http://localhost:48080",
  // 表情包线上路径
  emoticonUrl:"http://wechath5.dishait.cn/static/images/emoticon/5497/",
  // 应用信息
  appInfo: {
    // 应用名称
    name: "钰言",
    // 应用版本
    version: "1.0.0",
    // 应用logo
    logo: "/static/logo.png",
    // 官方网站
    site_url: "http://shengyukj.top/",
    // 政策协议
    agreements: [{
        title: "隐私政策",
        url: "http://shengyukj.top/"
      },
      {
        title: "用户服务协议",
        url: "http://shengyukj.top/"
      }
    ]
  }
}
