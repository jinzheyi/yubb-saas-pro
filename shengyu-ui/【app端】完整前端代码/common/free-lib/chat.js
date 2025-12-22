import $U from './util.js';
import $H from './request.js';
import $store from '@/store/index.js';
import { getAccessToken, getRefreshToken, getTenantId } from './auth.js';
class chat {
	constructor(arg) {
		this.url = arg.url
		this.isOnline = false
		this.socket = null
		this.reconnectTime = 0
		this.isOpenReconnect = true
		this.heartbeatTimer = null
		this.heartbeatInterval = 30000 // 30秒发送一次心跳
		// 获取当前用户相关信息
		let user = $U.getStorage('user')
		this.user = user ? JSON.parse(user) : {}
		// 初始化聊天对象
		this.TO = false;
		this.platform = uni.getSystemInfoSync().platform;
		// 创建背景音频管理器
		this.bgAudioMannager = uni.getBackgroundAudioManager();
		// 连接和监听
		if(this.user && getAccessToken()){
			this.connectSocket()
		}
	}
	// 断线重连
    reconnect(){
        if(this.isOnline){
            return
        }
        if(this.reconnectTime >= 20){
            return this.reconnectConfirm()
        }
        this.reconnectTime += 1
        this.connectSocket()
    }
	// 连接socket
	connectSocket(){
		// 检查用户是否有有效的token
		if (!this.user || !getAccessToken()) {
			console.error('websocket连接失败：用户未登录或token无效')
			return
		}
		// 确保url格式正确
		let wsUrl = this.url
		if (!wsUrl.endsWith('/')) {
			wsUrl += '/'
		}
		// 移除可能存在的ws://或wss://前缀，确保统一格式
		if (wsUrl.startsWith('http://')) {
			wsUrl = wsUrl.replace('http://', 'ws://')
		} else if (wsUrl.startsWith('https://')) {
			wsUrl = wsUrl.replace('https://', 'wss://')
		}

		this.socket = uni.connectSocket({
		    // #ifdef H5
				url: wsUrl + "?token=" + getAccessToken() + "&refreshToken=" + getRefreshToken() + "&tenantId=" + getTenantId(),
				// #endif
				// #ifndef H5
				url: wsUrl + "?token=" + getAccessToken() + "&refreshToken=" + getRefreshToken(),
				header: {
						'content-type': 'application/json',
						'Authorization': 'Bearer ' + getAccessToken(),
						'tenant-id': getTenantId()
				},
				// #endif
				complete: ()=> {}
		})
		// 监听连接成功
		this.socket.onOpen(()=>this.onOpen())
		// 监听接收信息
		this.socket.onMessage((res)=>this.onMessage(res))
		// 监听断开
		this.socket.onClose(()=>this.onClose())
		// 监听错误
		this.socket.onError(()=>this.onError())
	}
	// 监听打开
	onOpen(){
		// 用户上线
		this.isOnline = true
		this.reconnectTime = 0 // 重置重连次数
		this.isOpenReconnect = true
		// 启动心跳
		this.startHeartbeat()
		// 获取用户离线消息
		this.getMessage()
	}
	// 获取离线消息
	getMessage(){
		$H.post('/im/chat/getmessage')
	}
	// 启动心跳
	startHeartbeat(){
		// 清除之前的心跳定时器
		if (this.heartbeatTimer) {
			clearInterval(this.heartbeatTimer)
		}
		// 定时发送心跳
		this.heartbeatTimer = setInterval(()=>{
			if (this.isOnline && this.socket) {
				// 发送心跳消息
				this.socket.send({
					data: JSON.stringify({type: 'heartbeat'}),
					fail: (err)=>{
						console.error('心跳发送失败:', err)
						this.onError()
					}
				})
			}
		}, this.heartbeatInterval)
	}
	// 停止心跳
	stopHeartbeat(){
		if (this.heartbeatTimer) {
			clearInterval(this.heartbeatTimer)
			this.heartbeatTimer = null
		}
	}
	// 监听关闭
	onClose(){
		// 用户下线
		this.isOnline = false
		this.stopHeartbeat()
		this.socket = null
		if(this.isOpenReconnect){
			// 延迟重连，避免频繁连接
			setTimeout(()=>{
				this.reconnect()
			}, 3000)
		}
	}
	// 监听连接错误
	onError(){
		// 用户下线
		this.isOnline = false
		this.stopHeartbeat()
		this.socket = null
		if(this.isOpenReconnect){
			// 延迟重连，避免频繁连接
			setTimeout(()=>{
				this.reconnect()
			}, 3000)
		}
	}
	// 监听接收消息
	onMessage(data){
		let res = JSON.parse(data.data)
		console.log('监听接收消息',res)
		if(res.msg == 'undefined' || !res.msg){
			return
		}
		// 错误
		switch (res.msg){
			case 'fail':
				return uni.showToast({
					title: res.data,
					icon: 'none'
				});
				break;
			case 'recall': // 撤回消息
				this.handleOnRecall(res.data)
				break;
			case 'updateApplyList': // 新的好友申请
				$store.dispatch('getApply');
				break;
			case 'moment': // 朋友圈更新
				this.handleMoment(res.data)
				break;
			default:
				// 处理消息
				this.handleOnMessage(res.data)
				break;
		}
	}
	// 获取本地存储中的朋友圈动态通知
	getNotice(){
		let notice = $U.getStorage('moment_'+this.user.id)
		return notice ? JSON.parse(notice) : {
			avatar:"",
			user_id:0,
			num:0
		}
	}
	// 处理朋友圈通知
	async handleMoment(message){
		let notice = this.getNotice()
		switch (message.type){
			case 'new':
			if(message.user_id !== this.user.id){
				notice.avatar = message.avatar
				notice.user_id = message.user_id
				uni.showTabBarRedDot({
					index:2
				})
			}
				break;
			default:
			if(message.user_id !== this.user.id){
				notice.avatar = message.avatar
				notice.user_id = message.user_id
				notice.num += 1
			}
			if(notice.num > 0){
				uni.setTabBarBadge({
					index:2,
					text:notice.num > 99 ? '99+' : notice.num.toString()
				})
			} else {
				uni.removeTabBarBadge({
					index:2
				})
			}
				break;
		}
		uni.$emit('momentNotice',notice)
		$U.setStorage('moment_'+this.user.id,JSON.stringify(notice))
	}
	// 读取朋友圈动态
	async readMoments(){
		let notice = {
			avatar:"",
			user_id:0,
			num:0
		}
		$U.setStorage('moment_'+this.user.id,JSON.stringify(notice))
		uni.hideTabBarRedDot({
			index:2
		})
		uni.removeTabBarBadge({
			index:2
		})
		uni.$emit('momentNotice',notice)
	}
	// 监听撤回消息处理
	async handleOnRecall(message){
		// 通知聊天页撤回消息
		uni.$emit('onMessage',{
			...message,
			isremove:1
		})
		// 修改聊天记录
		let id = message.chat_type === 'group' ? message.to_id : message.from_id
		// key值：chatDetail_当前用户id_会话类型_接收人/群id
		let key = `chatDetail_${this.user.id}_${message.chat_type}_${id}`
		// 获取原来的聊天记录
		let list = this.getChatDetail(key)
		// 根据k查找对应聊天记录
		let index = list.findIndex(item=>item.id === message.id)
		if(index === -1) return;
		list[index].isremove = 1
		// 存储
		this.setStorage(key,list)
		// 当前会话最后一条消息的显示
		this.updateChatItem({
			id,
			chat_type:message.chat_type
		},(item)=>{
			item.data = '对方撤回了一条消息'
			item.update_time = (new Date()).getTime()
			return item
		})
	}
	// 处理消息
	async handleOnMessage(message){
		// 添加消息记录到本地存储中
		let { data } = this.addChatDetail(message,false)
		// 更新会话列表
		this.updateChatList(data,false)
		// 全局通知
		uni.$emit('onMessage',data)
		// 消息提示
		this.messageNotice()
	}
	// 消息提示
	messageNotice(){
		if(this.platform === 'android'){
			uni.vibrateShort();
		} else {
			uni.vibrateLong()
		}
		// 提示音
		if(this.bgAudioMannager.src){
			this.bgAudioMannager.play()
		} else {
			this.bgAudioMannager.src = '/static/notice.mp3';
		}
	}
	// 关闭连接
	close(){
		if(this.socket){
			this.socket.close()
		}
		this.isOpenReconnect = false
	}
	// 创建聊天对象
	createChatObject(detail){
		this.TO = detail
		// console.log('创建聊天对象',this.TO);
	}
	// 销毁聊天对象
	destoryChatObject(){
		this.TO = false
		// console.log('销毁聊天对象');
	}
	// 断线重连提示
	reconnectConfirm(){
		this.reconnectTime = 0
		uni.showModal({
			content: '你已经断线，是否重新连接？',
			confirmText:"重新连接",
			success:(res)=> {
				if (res.confirm) {
					this.connectSocket()
				}
			}
		});
	}
	// 验证是否上线
	checkOnline(){
		if(!this.isOnline){
			// 断线重连提示
			this.reconnectConfirm()
			return false
		}
		return true
	}
	// 组织发送信息格式
	formatSendData(params){
		return {
			id:0, // 唯一id，后端生成，用于撤回指定消息
			from_avatar:this.user.avatar,// 发送者头像
			from_name:this.user.nickname || this.user.username, // 发送者昵称
			from_id:this.user.id, // 发送者id
			to_id:params.to_id || this.TO.id, // 接收人/群 id
			to_name:params.to_name || this.TO.name, // 接收人/群 名称
			to_avatar:params.to_avatar || this.TO.avatar, // 接收人/群 头像
			chat_type:params.chat_type || this.TO.chat_type, // 接收类型
			type:params.type,// 消息类型
			data:params.data, // 消息内容
			options:params.options ? params.options : {}, // 其他参数
			create_time:(new Date()).getTime(), // 创建时间
			isremove:0, // 是否撤回
			sendStatus:params.sendStatus ? params.sendStatus : "pending" // 发送状态，success发送成功,fail发送失败,pending发送中
		}
	}
	// 撤回消息
	recall(message){
		return new Promise((result,reject)=>{
			$H.post('/im/chat/recall',{
				to_id:message.to_id,
				chat_type:message.chat_type,
				id:message.id,
			}).then(res=>{
				// key值：chatDetail_当前用户id_会话类型_接收人/群id
				let key = `chatDetail_${this.user.id}_${message.chat_type}_${message.to_id}`
				// 获取原来的聊天记录
				let list = this.getChatDetail(key)
				// 根据k查找对应聊天记录
				let index = list.findIndex(item=>item.id === message.id)
				if(index === -1) return;
				list[index].isremove = 1
				// 存储
				this.setStorage(key,list)
				result(res)
				// 更新会话最后一条消息显示
				this.updateChatItem({
					id:message.to_id,
					chat_type:message.chat_type
				},(item)=>{
					item.data = '你撤回了一条消息'
					item.update_time = (new Date()).getTime()
					return item
				})
			}).catch(err=>{
				reject(err)
			})
		})
	}
	// 发送消息
	send(message,onProgress = false){
		return new Promise(async (result,reject)=>{
			// 添加消息历史记录
			let { k } = this.addChatDetail(message)
			// 更新会话列表
			this.updateChatList(message)
			// 验证是否上线
			if(!this.checkOnline()) return reject('未上线')
			// 上传文件
			let isUpload = (message.type !== 'text' && message.type !== 'emoticon' && message.type !== 'card' && !message.data.startsWith('http://tangzhe123-com'))

			let uploadResult = ''
			if(isUpload){ uploadResult = await $H.upload('/upload',{
					filePath:message.data
				},onProgress)

				if(!uploadResult){
					// 发送失败
					message.sendStatus = 'fail'
					// 更新指定历史记录
					this.updateChatDetail(message,k)
					// 断线重连提示
					return reject('上传失败')
				}
			}

			// 提交到后端
			let data = isUpload ? uploadResult : message.data
			$H.post('/im/chat/send',{
				to_id:message.to_id || this.TO.id,
				chat_type:message.chat_type || this.TO.chat_type,
				type:message.type,
				data,
				options:JSON.stringify(message.options)
			}).then(res=>{
				// 发送成功
				message.id = res.id
				message.sendStatus = 'success'

				if(message.type === 'video'){
					message.options = res.options
				}

				// 更新指定历史记录
				// console.log('更新指定历史记录',message);
				this.updateChatDetail(message,k)
				result(res)
			}).catch(err=>{
				// 发送失败
				message.sendStatus = 'fail'
				// 更新指定历史记录
				this.updateChatDetail(message,k)
				// 断线重连提示
				reject(err)
			})
		})
	}
	// 添加聊天记录
	addChatDetail(message,isSend = true){
		// console.log('添加聊天记录');
		// 获取对方id
		let id = message.chat_type === 'user' ? (isSend ? message.to_id : message.from_id) : message.to_id
		// key值：chatDetail_当前用户id_会话类型_接收人/群id
		let key = `chatDetail_${this.user.id}_${message.chat_type}_${id}`
		// 获取原来的聊天记录
		let list = this.getChatDetail(key)
		// console.log('获取原来的聊天记录',list)
		// 标识
		message.k = 'k'+list.length
		list.push(message)
		// 加入缓存
		// console.log('加入缓存',key)
		this.setStorage(key,list)
		// 返回
		return {
			data:message,
			k:message.k
		}
	}
	// 删除指定聊天记录
	async deleteChatDetailItem(message,isSend = true){
		// 获取对方id
		let id = message.chat_type === 'user' ? (isSend ? message.to_id : message.from_id) : message.to_id
		// key值：chatDetail_当前用户id_会话类型_接收人/群id
		let key = `chatDetail_${this.user.id}_${message.chat_type}_${id}`
		// 获取原来的聊天记录
		let list = this.getChatDetail(key)
		// 根据k查找对应聊天记录
		let index = list.findIndex(item=>item.k === message.k || item.id === message.id)
		if(index === -1) return;
		list.splice(index,1)
		// 存储
		this.setStorage(key,list)
	}
	// 更新指定历史记录
	async updateChatDetail(message,k,isSend = true){
		// 获取对方id
		let id = message.chat_type === 'user' ? (isSend ? message.to_id : message.from_id) : message.to_id
		// key值：chatDetail_当前用户id_会话类型_接收人/群id
		let key = `chatDetail_${this.user.id}_${message.chat_type}_${id}`
		// console.log('key值',key)
		// 获取原来的聊天记录
		let list = this.getChatDetail(key)
		// console.log('获取原来的聊天记录',list)
		// 根据k查找对应聊天记录
		let index = list.findIndex(item=>item.k === k)
		// console.log('根据k查找对应聊天记录',index)
		if(index === -1) return;
		list[index] = message
		// 存储
		this.setStorage(key,list)
	}
	// 获取聊天记录
	getChatDetail(key = false){
		key = key ? key : `chatDetail_${this.user.id}_${this.TO.chat_type}_${this.TO.id}`
		return this.getStorage(key)
	}

	// 格式化会话最后一条消息显示
	formatChatItemData(message,isSend){
		let data = message.data
		switch (message.type){
			case 'emoticon':
			data = '[表情]'
				break;
			case 'image':
			data = '[图片]'
				break;
			case 'audio':
			data = '[语音]'
				break;
			case 'video':
			data = '[视频]'
				break;
			case 'card':
			data = '[名片]'
				break;
		}
		data = isSend ? data : `${message.from_name}: ${data}`
		return data
	}

	/**
	 {
	 	id:1, // 接收人/群 id
	 	chat_type:'user', // 接收类型 user单聊 group群聊
	 	avatar:'', // 接收人/群 头像
	 	name:'昵称', // 接收人/群 昵称
	 	update_time:(new Date()).getTime(), // 最后一条消息的时间戳
	 	data:"最后一条消息内容", // 最后一条消息内容
	 	type:'text', 		   // 最后一条消息类型
	 	noreadnum:0, // 未读数
	 	istop:false, // 是否置顶
	 	shownickname:0, // 是否显示昵称
	 	nowarn:0, // 消息免打扰
	 	strongwarn:0, // 是否开启强提醒

		user_id:0, // 群管理员id
		remark:"公告", // 群公告
		invite_confirm:0, // 邀请确认
	 }
	 * **/
	// 初始化会话
	initChatListItem(message){
		 // 获取本地存储会话列表
		 let list = this.getChatList()
		 // 会话是否存在
		 let index = list.findIndex(item=>{
		 	return item.chat_type === message.chat_type && item.id === message.to_id
		 })
		 // 最后一条消息展现形式
		 let data = this.formatChatItemData(message,true)
		 // 会话不存在，创建会话
		 if(index === -1){
		 	let chatItem = {
		 		id:message.to_id, // 接收人/群 id
		 		chat_type:message.chat_type, // 接收类型 user单聊 group群聊
		 		avatar:message.to_avatar,// 接收人/群 头像
		 		name:message.to_name,// 接收人/群 昵称
		 		update_time:(new Date()).getTime(), // 最后一条消息的时间戳
		 		data:message.data, // 最后一条消息内容
		 		type:'system', 		   // 最后一条消息类型
		 		noreadnum:0, // 未读数
		 		istop:false, // 是否置顶
		 		shownickname:false, // 是否显示昵称
		 		nowarn:false, // 消息免打扰
		 		strongwarn:false, // 是否开启强提醒
		 	}
		 	// 群聊
		 	if(message.chat_type === 'group' && message.group){
		 		chatItem = {
		 			...chatItem,
		 			user_id:message.group.user_id, // 群管理员id
		 			remark:'', // 群公告
		 			invite_confirm:message.group.invite_confirm, // 邀请确认
		 		}
		 	}
		 	list.unshift(chatItem)
		 	// 存储
		 	let key = `chatlist_${this.user.id}`
		 	this.setStorage(key,list)
		 	// 通知更新vuex中的聊天会话列表
		 	uni.$emit('onUpdateChatList',list)
		 }
	}
	// 更新会话列表
	updateChatList(message,isSend = true){
		// 获取本地存储会话列表
		let list = this.getChatList()
		// 是否处于当前聊天中
		let isCurrentChat = false
		// 接收人/群 id/头像/昵称
		let id = 0
		let avatar = ''
		let name = ''

		// 判断私聊还是群聊
		if(message.chat_type === 'user'){ // 私聊
			// 聊天对象是否存在
			isCurrentChat = this.TO ? (isSend ? this.TO.id === message.to_id : this.TO.id === message.from_id) : false

			id = isSend ? message.to_id : message.from_id
			avatar = isSend ? message.to_avatar : message.from_avatar
			name = isSend ? message.to_name : message.from_name
		} else { // 群聊
			isCurrentChat = this.TO && (this.TO.id === message.to_id)
			id = message.to_id
			avatar = message.to_avatar
			name = message.to_name
		}

		// 会话是否存在
		let index = list.findIndex(item=>{
			return item.chat_type === message.chat_type && item.id === id
		})
		// 最后一条消息展现形式
		// let data = isSend ? message.data : `${message.from_name}: ${message.data}`
		let data = this.formatChatItemData(message,isSend)
		// 会话不存在，创建会话
		// 未读数是否 + 1
		let noreadnum = (isSend || isCurrentChat) ? 0 : 1
		if(index === -1){
			let chatItem = {
				id, // 接收人/群 id
				chat_type:message.chat_type, // 接收类型 user单聊 group群聊
				avatar, // 接收人/群 头像
				name, // 接收人/群 昵称
				update_time:(new Date()).getTime(), // 最后一条消息的时间戳
				data, // 最后一条消息内容
				type:message.type, 		   // 最后一条消息类型
				noreadnum, // 未读数
				istop:false, // 是否置顶
				shownickname:false, // 是否显示昵称
				nowarn:false, // 消息免打扰
				strongwarn:false, // 是否开启强提醒
			}
			// 群聊
			if(message.chat_type === 'group' && message.group){
				chatItem.shownickname = true
				chatItem.name = name
				chatItem = {
					...chatItem,
					user_id:message.group.user_id, // 群管理员id
					remark:"", // 群公告
					invite_confirm:1, // 邀请确认
				}
			}
			list.unshift(chatItem)
		} else { // 存在，更新会话
			// 拿到当前会话
			let item = list[index]
			// 更新该会话最后一条消息时间，内容，类型
			item.update_time = (new Date()).getTime()
			item.name = name
			item.data = data
			item.type = message.type
			// 未读数更新
			item.noreadnum += noreadnum
			// 置顶会话
			list = this.listToFirst(list,index)
		}
		// 存储
		let key = `chatlist_${this.user.id}`
		this.setStorage(key,list)
		// 更新未读数
		this.updateBadge(list)
		// 通知更新vuex中的聊天会话列表
		uni.$emit('onUpdateChatList',list)
		return list
	}
	// 更新未读数
	async updateBadge(list = false){
		// 获取所有会话列表
		list = list ? list : this.getChatList()
		// 统计所有未读数
		let total = 0
		list.forEach(item=>{
			total += item.noreadnum
		})
		// 设置底部导航栏角标
		if(total > 0){
			uni.setTabBarBadge({
				index:0,
				text:total <= 99 ? total.toString() : '99+'
			})
		} else {
			uni.removeTabBarBadge({
				index:0
			})
		}
		uni.$emit('totalNoreadnum',total)
	}
	// 更新指定会话
	async updateChatItem(where,data){
		// 获取所有会话列表
		let list = this.getChatList()
		// 找到当前会话
		let index = list.findIndex(item=>item.id === where.id && item.chat_type === where.chat_type)
		if(index === -1) return;
		// 更新数据
		if(typeof data === 'function'){
			list[index] = data(list[index])
		} else {
			list[index] = data
		}

		let key = `chatlist_${this.user.id}`
		this.setStorage(key,list)

		// 更新会话列表状态
		uni.$emit('onUpdateChatList',list)
	}
	// 读取会话
	async readChatItem(id,chat_type){
		// 获取所有会话列表
		let list = this.getChatList()
		// 找到当前会话
		let index = list.findIndex(item=>item.id === id && item.chat_type === chat_type)
		if(index !== -1){
			list[index].noreadnum = 0
			let key = `chatlist_${this.user.id}`
			this.setStorage(key,list)
			// 重新获取总未读数
			this.updateBadge()
			// 更新会话列表状态
			uni.$emit('onUpdateChatList',list)
		}
	}
	// 删除指定会话
	async removeChatItem(id,chat_type){
		// 获取所有会话列表
		let list = this.getChatList()
		// 找到当前会话
		let index = list.findIndex(item=>item.id === id && item.chat_type === chat_type)
		if(index !== -1){
			list.splice(index,1)

			let key = `chatlist_${this.user.id}`
			this.setStorage(key,list)
			// 重新获取总未读数
			this.updateBadge()
			// 更新会话列表状态
			uni.$emit('onUpdateChatList',list)
		}
	}
	// 清空聊天记录
	async clearChatDetail(id,chat_type){
		let key = `chatDetail_${this.user.id}_${chat_type}_${id}`
		$U.removeStorage(key)

		// 获取所有会话列表
		let list = this.getChatList()
		// 找到当前会话
		let index = list.findIndex(item=>item.id === id && item.chat_type === chat_type)
		if(index !== -1){
			list[index].data = ''

			let key = `chatlist_${this.user.id}`
			this.setStorage(key,list)
			// 更新会话列表状态
			uni.$emit('onUpdateChatList',list)
		}
	}
	// 获取本地存储会话列表
	getChatList(){
		let key = `chatlist_${this.user.id}`
		return this.getStorage(key)
	}
	// 获取指定会话
	getChatListItem(id,chat_type){
		// 获取所有会话列表
		let list = this.getChatList()
		// 找到当前会话
		let index = list.findIndex(item=>item.id === id && item.chat_type === chat_type)
		if(index !== -1){
			return list[index]
		}
		return false
	}
	// 获取存储
	getStorage(key){
		let list = $U.getStorage(key)
		return list ? JSON.parse(list) : []
	}
	// 设置存储
	setStorage(key,value){
		return $U.setStorage(key,JSON.stringify(value))
	}
	// 数组置顶
	listToFirst(arr,index){
		if (index != 0) {
			arr.unshift(arr.splice(index,1)[0]);
		}
		return arr;
	}
}
export default chat
