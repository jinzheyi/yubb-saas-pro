import $H from '@/common/free-lib/request.js';
import $C from '@/common/free-lib/config.js';
import { setToken, removeToken } from '@/common/free-lib/auth.js';
import $U from '@/common/free-lib/util.js';
import Chat from '@/common/free-lib/chat.js';

// 登录方法
export function login(username, password, captchaVerification) {
	const data = {
		username,
		password,
		captchaVerification
	}
	return $H.request({
		url: '/system/auth/login',
		headers: {
			isToken: false
		},
		method: 'POST',
		data: data
	})
}

// 获取用户详细信息
export function getInfo() {
	return $H.request({
		url: '/system/auth/get-permission-info',
		method: 'GET'
	})
}

// 退出方法
export function logout() {
	return $H.request({
		url: '/system/auth/logout',
		method: 'POST'
	})
}

export default {
	state:{
		id: 0, // 用户编号
		name: $U.getStorage('name') || '',
		avatar: $U.getStorage('avatar') || '',
		roles: $U.getStorage('roles') || [],
		permissions: $U.getStorage('permissions') || [],
		user: false,

		apply:{
			rows: [],
			count: 0
		},

		mailList:[],

		chat:null,

		// 会话列表
		chatList:[],

		// 总未读数
		totalNoreadnum:0,

		notice:{
			avatar:"",
			user_id:0,
			num:0
		}
	},
	mutations:{
		SET_ID: (state, id) => {
			state.id = id
		},
		SET_NAME: (state, name) => {
			state.name = name
			$U.setStorage('name', name)
		},
		SET_AVATAR: (state, avatar) => {
			state.avatar = avatar
			$U.setStorage('avatar', avatar)
		},
		SET_ROLES: (state, roles) => {
			state.roles = roles
			$U.setStorage('roles', roles)
		},
		SET_PERMISSIONS: (state, permissions) => {
			state.permissions = permissions
			$U.setStorage('permissions', permissions)
		},
		updateUser(state,{ k,v }){
			if(state.user){
				state.user[k] = v
				$U.setStorage('user',JSON.stringify(state.user))
			}
		}
	},
	actions:{
		// 登录
		Login({ commit, state, dispatch }, userInfo) {
			const username = userInfo.username.trim()
			const password = userInfo.password
			const captchaVerification = userInfo.captchaVerification
			return new Promise((resolve, reject) => {
				login(username, password, captchaVerification).then(res => {
					res = res.data; // 读取 data 数据
					// 设置 token
					setToken(res)

					// 获取用户信息
					return dispatch('GetInfo').then(() => {
						// 初始化聊天功能
						dispatch('initChat')
						resolve()
					})
				}).catch(error => {
					reject(error)
				})
			})
		},

		// 获取用户信息
		GetInfo({ commit, state }) {
			return new Promise((resolve, reject) => {
				getInfo().then(res => {
					res = res.data; // 读取 data 数据
					const user = res.user
					const avatar = (user == null || user.avatar === "" || user.avatar == null) ? "/static/images/profile.jpg" : user.avatar
					const nickname = (user == null || user.nickname === "" || user.nickname == null) ? "" : user.nickname
					if (res.roles && res.roles.length > 0) {
						commit('SET_ROLES', res.roles)
						commit('SET_PERMISSIONS', res.permissions)
					} else {
						commit('SET_ROLES', ['ROLE_DEFAULT'])
					}
					commit('SET_ID', user.id)
					commit('SET_NAME', nickname)
					commit('SET_AVATAR', avatar)

					// 保存用户信息到本地
					state.user = user
					$U.setStorage('user', JSON.stringify(user))
					$U.setStorage('user_id', user.id)

					resolve(res)
				}).catch(error => {
					reject(error)
				})
			})
		},

		// 退出系统
		LogOut({ commit, state }) {
			return new Promise((resolve, reject) => {
				logout().then(() => {
					commit('SET_ROLES', [])
					commit('SET_PERMISSIONS', [])
					removeToken()

					// 清除本地存储数据
					$U.removeStorage('user');
					$U.removeStorage('user_id');
					$U.removeStorage('name');
					$U.removeStorage('avatar');
					$U.removeStorage('roles');
					$U.removeStorage('permissions');

					// 清除用户状态
					state.user = false

					// 关闭socket连接
					if(state.chat){
						state.chat.close()
						state.chat = null
					}

					// 跳转到登录页
					uni.reLaunch({
						url: "/pages/common/login/login"
					})

					// 注销监听事件
					uni.$off('onUpdateChatList')
					uni.$off('momentNotice')
					uni.$off('totalNoreadnum')

					resolve()
				}).catch(error => {
					reject(error)
				})
			})
		},

		// 初始化聊天功能
		initChat({ state, dispatch }) {
			// 获取好友申请列表
			dispatch('getApply')
			// 连接socket
			state.chat = new Chat({
				url: $C.socketUrl
			})
			// 获取会话列表
			dispatch('getChatList')
			// 初始化总未读数角标
			dispatch('updateBadge')
			// 获取朋友圈动态通知
			dispatch('getNotice')
		},

		// 初始化登录状态
		initLogin({ state, dispatch }) {
			// 获取用户信息
			dispatch('GetInfo').then(() => {
				// 初始化聊天功能
				dispatch('initChat')
			}).catch(() => {
				// 跳转到登录页
				uni.reLaunch({
					url: "/pages/common/login/login"
				})
			})
		},

		// 获取好友申请列表
		getApply({state,dispatch},page = 1){
			$H.get('/im/apply/'+page).then(res=>{
				console.log(res);
				if(page === 1){
					state.apply = res
				} else {
					state.apply.rows = [ ...state.apply.rows, ...res.rows ]
					state.apply.count = res.count
				}
				// 更新通讯录角标提示
				dispatch('updateMailBadge')
			})
		},

		// 更新通讯录角标提示
		updateMailBadge({ state }){
			let count = state.apply.count > 99 ? '99+' : state.apply.count.toString()
			if(state.apply.count > 0){
				return uni.setTabBarBadge({
					index:1,
					text:count
				})
			}
			uni.removeTabBarBadge({
				index:1
			})
		},

		// 获取通讯录列表
		getMailList({ state }){
			$H.get('/im/mail/list').then(res=>{
				state.mailList = res.rows.newList ? res.rows.newList : [],
				console.log(state.mailList);
			})
		},

		// 获取会话列表
		getChatList({ state }){
			if (state.chat) {
				state.chatList = state.chat.getChatList()
				// 监听会话列表变化
				uni.$on('onUpdateChatList',(list)=>{
					state.chatList = list
				})
			}
		},

		// 获取朋友圈动态通知
		getNotice({ state }){
			if (state.chat) {
				state.notice = state.chat.getNotice()
				if(state.notice.num > 0){
					uni.setTabBarBadge({
						index:2,
						text:state.notice.num > 99 ? '99+' : state.notice.num.toString()
					})
				} else {
					uni.removeTabBarBadge({
						index:2
					})
				}
				uni.$on('momentNotice',(notice)=>{
					state.notice = notice
				})
			}
		},

		// 初始化总未读数角标
		updateBadge({state}){
			if (state.chat) {
				// 开启监听总未读数变化
				uni.$on('totalNoreadnum',(num)=>{
					state.totalNoreadnum = num
				})
				state.chat.updateBadge()
			}
		},

		// 断线自动重连
		reconnect({state}){
			if(state.user && state.chat){
				state.chat.reconnect()
			}
		}
	}
}
