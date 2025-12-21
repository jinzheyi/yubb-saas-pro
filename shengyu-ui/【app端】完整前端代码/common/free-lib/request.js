import $C from './config.js';
import $U from './util.js';
import $store from '@/store/index.js';
import { getAccessToken, getRefreshToken, setToken, formatToken, getTenantId } from './auth.js';

let timeout = 10000
const baseUrl = $C.baseUrl + $C.baseApi;

export default {
    // 全局配置
    common:{
        baseUrl: baseUrl,
        header:{
            'Content-Type':'application/json;charset=UTF-8',
        },
        data:{},
        method:'GET',
        dataType:'json',
        token:true
    },
    // 是否正在刷新token
    refreshingToken: false,
    // 等待刷新token的请求队列
    tokenRequestQueue: [],
    
    // 请求 返回promise
    request(options = {}){
        // 是否需要设置 token
        const isToken = (options.header || {}).isToken === false
        options.header = options.header || this.common.header
        if (getAccessToken() && !isToken) {
            options.header['Authorization'] = 'Bearer ' + getAccessToken()
        }
        // 设置租户
        const tenantId = getTenantId()
        if (tenantId) options.header['tenant-id'] = tenantId;
        // get请求映射params参数
        if (options.params) {
            let url = options.url + '?' + this.tansParams(options.params)
            url = url.slice(0, -1)
            options.url = url
        }
        
        // 组织参数
        options.url = options.url
        options.data = options.data || this.common.data
        options.method = options.method || this.common.method
        options.dataType = options.dataType || this.common.dataType
        
        // 请求
        return new Promise((resolve, reject) => {
            // 请求中...
            uni.request({
                method: options.method || 'get',
                timeout: options.timeout ||  timeout,
                url: options.baseUrl || this.common.baseUrl + options.url,
                data: options.data,
                header: options.header,
                dataType: 'json'
            }).then(response => {
                let [error, res] = response
                if (error) {
                    const errMsg = '后端接口连接异常'
                    uni.showToast({ title: errMsg, icon: 'none' });
                    reject({ code: 500, msg: errMsg })
                    return
                }
                const code = res.data.code || 200
                const msg = res.data.msg || '请求失败'
                if (code === 401) {
                    // token过期，尝试刷新token
                    this.handleTokenExpired(options, resolve, reject)
                } else if (code === 500) {
                    uni.showToast({ title: msg, icon: 'none' });
                    reject({ code: 500, msg: msg })
                } else if (code !== 200) {
                    reject({ code: code, msg: msg })
                } else {
                    resolve(res.data)
                }
            })
            .catch(error => {
                let message = error.message || '请求失败'
                if (message === 'Network Error') {
                    message = '后端接口连接异常'
                } else if (message.includes('timeout')) {
                    message = '系统接口请求超时'
                } else if (message.includes('Request failed with status code')) {
                    message = '系统接口' + message.substr(message.length - 3) + '异常'
                }
                uni.showToast({ title: message, icon: 'none' });
                reject({ code: 500, msg: message })
            })
        })
    },
    
    // 处理token过期
    handleTokenExpired(options, resolve, reject) {
        if (!this.refreshingToken) {
            // 开始刷新token
            this.refreshingToken = true
            
            // 使用refreshToken获取新的token
            uni.request({
                url: this.common.baseUrl + '/system/auth/refresh-token',
                method: 'POST',
                data: {
                    refreshToken: getRefreshToken()
                },
                header: {
                    'Content-Type': 'application/json;charset=UTF-8'
                }
            }).then(response => {
                let [error, res] = response
                if (error) {
                    this.handleRefreshTokenError()
                    reject({ code: 401, msg: '无效的会话，或者会话已过期，请重新登录。' })
                    return
                }
                
                const code = res.data.code || 200
                if (code === 200) {
                    // 刷新成功，更新token
                    setToken(res.data.data)
                    
                    // 重新发送所有等待的请求
                    this.tokenRequestQueue.forEach(cb => cb())
                    this.tokenRequestQueue = []
                    
                    // 重新发送当前请求
                    this.request(options).then(resolve).catch(reject)
                } else {
                    // 刷新失败，跳转到登录页
                    this.handleRefreshTokenError()
                    reject({ code: 401, msg: '无效的会话，或者会话已过期，请重新登录。' })
                }
            }).catch(() => {
                this.handleRefreshTokenError()
                reject({ code: 401, msg: '无效的会话，或者会话已过期，请重新登录。' })
            }).finally(() => {
                this.refreshingToken = false
            })
        } else {
            // 正在刷新token，将请求加入队列
            this.tokenRequestQueue.push(() => {
                this.request(options).then(resolve).catch(reject)
            })
        }
    },
    
    // 处理刷新token失败
    handleRefreshTokenError() {
        uni.showModal({
            title: '提示',
            content: '登录状态已过期，您可以继续留在该页面，或者重新登录?',
            success: (modalRes) => {
                if (modalRes.confirm) {
                    $store.dispatch('logout').then(res => {
                        uni.reLaunch({ url: '/pages/common/login/login' })
                    })
                }
            }
        })
    },
    // get请求
    get(url,data = {},options = {}){
        options.url = url
        options.data = data
        options.method = 'GET'
        return this.request(options)
    },
    // post请求
    post(url,data = {},options = {}){
        options.url = url
        options.data = data
        options.method = 'POST'
        return this.request(options)
    },
    // delete请求
    del(url,data = {},options = {}){
        options.url = url
        options.data = data
        options.method = 'DELETE'
        return this.request(options)
    },
    // 上传文件
    upload(url,data,onProgress = false){
        return new Promise((resolve,reject)=>{
            // 上传
            let token = getAccessToken()
            if (!token) {
                uni.showToast({ title: '请先登录', icon: 'none' });
                // token不存在时跳转
                return uni.reLaunch({
                    url: '/pages/common/login/login',
                });
            }
            
            const uploadTask = uni.uploadFile({
                url: this.common.baseUrl + url,
                filePath: data.filePath,
                name: data.name || "files",
                header: { 
                    'Authorization': 'Bearer ' + token,
                    'tenant-id': uni.getStorageSync('TENANT_ID') || '1'
                },
                success: (res) => {
                    if(res.statusCode !== 200){
                        const errMsg = '上传失败'
                        uni.showToast({
                            title: errMsg,
                            icon: 'none'
                        });
                        reject({ code: res.statusCode, msg: errMsg })
                        return;
                    }
                    let message = JSON.parse(res.data)
                    if (message.code === 200) {
                        resolve(message.data);
                    } else {
                        const errMsg = message.msg || '上传失败'
                        uni.showToast({
                            title: errMsg,
                            icon: 'none'
                        });
                        reject({ code: message.code, msg: errMsg })
                    }
                },
                fail: (err) => {
                    console.log(err);
                    const errMsg = '上传失败'
                    uni.showToast({
                        title: errMsg,
                        icon: 'none'
                    });
                    reject({ code: 500, msg: errMsg })
                }
            })
            
            uploadTask.onProgressUpdate((res) => {
                if(typeof onProgress === 'function'){
                    onProgress(res.progress)
                }
            });
            
        })
    },
    // 参数处理
    tansParams(params) {
        let result = ''
        for (const propName of Object.keys(params)) {
            const value = params[propName];
            let part = encodeURIComponent(propName) + "=";
            if (value !== null && value !== undefined && typeof (value) !== "object") {
                part += encodeURIComponent(value) + "&";
            } else if (value instanceof Array) {
                for (const key of value) {
                    const params = propName + "[]";
                    const subPart = encodeURIComponent(params) + "=";
                    part += encodeURIComponent(key) + "&";
                }
            }
            result += part;
        }
        return result
    }
}