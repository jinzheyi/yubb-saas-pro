import $U from '@/common/free-lib/util.js';
import $H from '@/common/free-lib/request.js';
import $C from '@/common/free-lib/config.js';
import Chat from '@/common/free-lib/chat.js';
export default {
	state:{
		user:false,
		
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
		updateUser(state,{ k,v }){
			if(state.user){
				state.user[k] = v
				$U.setStorage('user',JSON.stringify(state.user))
			}
		}
	},
	actions:{
		// 登录后处理
		login({ state,dispatch },user){
			// 存到状态中
			state.user = user
			// 存储到本地存储中
			$U.setStorage('token',user.token)
			$U.setStorage('user',JSON.stringify(user))
			$U.setStorage('user_id',user.id)
			// 获取好友申请列表
			dispatch('getApply')
			// 连接socket
			state.chat = new Chat({
				url:$C.socketUrl
			})
			// 获取会话列表
			dispatch('getChatList')
			// 初始化总未读数角标
			dispatch('updateBadge')
			// 获取朋友圈动态通知
			dispatch('getNotice');
		},
		// 退出登录处理
		logout({ state }){
			// 清除登录状态
			state.user = false
			// 清除本地存储数据
			$U.removeStorage('token');
			$U.removeStorage('user');
			$U.removeStorage('user_id');
			// 关闭socket连接
			if(state.chat){
				state.chat.close()
				state.chat = null
			}
			// 跳转到登录页
			uni.reLaunch({
				url:"/pages/common/login/login"
			})
			// 注销监听事件
			uni.$off('onUpdateChatList')
			uni.$off('momentNotice')
			uni.$off('totalNoreadnum')
		},
		// 初始化登录状态
		initLogin({ state,dispatch }){
			// 拿到存储
			let user = $U.getStorage('user')
			if(user){
				// 初始化登录状态
				state.user = JSON.parse(user)
				// 连接socket
				state.chat = new Chat({
					url:$C.socketUrl,
					// 心跳单位毫秒
					ping:10000
				})
				// 获取会话列表
				dispatch('getChatList')
				// 获取离线信息
				// 获取好友申请列表
				dispatch('getApply')
				// 初始化总未读数角标
				dispatch('updateBadge')
				// 获取朋友圈动态通知
				dispatch('getNotice');
			}
		},
		// 获取好友申请列表
		getApply({state,dispatch},page = 1){
			$H.get('/apply/'+page).then(res=>{
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
			$H.get('/friend/list').then(res=>{
				state.mailList = res.rows.newList ? res.rows.newList : [],
				console.log(state.mailList);
			})
		},
		// 获取会话列表
		getChatList({ state }){
			state.chatList = state.chat.getChatList()
			// 监听会话列表变化
			uni.$on('onUpdateChatList',(list)=>{
				state.chatList = list
			})
		},
		// 获取朋友圈动态通知
		getNotice({ state }){
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
		},
		// 初始化总未读数角标
		updateBadge({state}){
			// 开启监听总未读数变化
			uni.$on('totalNoreadnum',(num)=>{
				state.totalNoreadnum = num
			})
			state.chat.updateBadge()
		},
		// 断线自动重连
		reconnect({state}){
			if(state.user && state.chat){
				state.chat.reconnect()
			}
		}
	}
}