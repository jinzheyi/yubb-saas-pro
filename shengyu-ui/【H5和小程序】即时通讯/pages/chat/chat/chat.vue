<template>
	<view>

		<!-- 导航栏 -->
		<free-nav-bar :title="detail.name" :noreadnum="totalNoreadnum" showBack>
			<free-icon-button slot="right" :icon="'\ue6fd'" @click="openChatSet"></free-icon-button>
		</free-nav-bar>

		<!-- 聊天内容区域 -->
		<scroll-view scroll-y class="bg-light position-fixed left-0 right-0 px-3"
			style="bottom: 105rpx;box-sizing: border-box;" :style="chatBodyBottom" :show-scrollbar="false"
			:scroll-into-view="scrollIntoView" :scroll-with-animation="true" @click="clickPage">

			<!-- 聊天信息列表组件 -->
			<view v-for="(item, index) in list" :key="index" :id="'chatItem_' + index">
				<free-chat-item :item="item" :index="index" ref="chatItem"
					:pretime="index > 0 ? list[index - 1].create_time : 0" @long="long" @preview="previewImage"
					:shownickname="currentChatItem.shownickname"></free-chat-item>
			</view>

		</scroll-view>

		<!-- #ifdef APP-PLUS-NVUE -->
		<div v-if="mode === 'action' || mode === 'emoticon'" class="position-fixed top-0 right-0 left-0"
			:style="'bottom:' + maskBottom + 'px;'" @click="clickPage"></div>
		<!-- #endif -->

		<!-- 底部输入框 -->
		<view class="position-fixed left-0 right-0 border-top flex align-center"
			style="background-color: #F7F7F6;height: 105rpx;" :style="'bottom:' + KeyboardHeight + 'px;'">
			<!-- #ifndef H5 -->
			<free-icon-button v-if="mode === 'audio'" :icon="'\ue607'" @click="changeVoiceOrText"></free-icon-button>
			<free-icon-button v-else :icon="'\ue606'" @click="changeVoiceOrText"></free-icon-button>
			<!-- #endif -->
			<view class="flex-1">
				<view v-if="mode === 'audio'" class="rounded flex align-center justify-center" style="height: 80rpx;"
					:class="isRecording ? 'bg-hover-light' : 'bg-white'" @touchstart="voiceTouchStart"
					@touchend="voiceTouchEnd" @touchcancel="voiceTouchCancel" @touchmove="voiceTouchMove">
					<text class="font">{{ isRecording ? '松开 结束' : '按住 说话' }}</text>
				</view>

				<textarea v-else fixed class="bg-white rounded p-2 py-1 font-md ml-2"
					style="height: 80rpx;max-width: 450rpx;box-sizing: border-box;" :show-confirm-bar="true"
					:adjust-position="false" v-model="text" @focus="mode = 'text'" />
			</view>
			<!-- 表情 -->
			<free-icon-button :icon="'\ue605'" @click="openActionOrEmoticon('emoticon')"></free-icon-button>
			<template v-if="text.length === 0">
				<!-- 扩展菜单 -->
				<free-icon-button :icon="'\ue603'" @click="openActionOrEmoticon('action')"></free-icon-button>
			</template>
			<view v-else class="flex-shrink">
				<!-- 发送按钮 -->
				<free-main-button name="发送" @click="send('text')"></free-main-button>
			</view>

		</view>

		<!-- 扩展菜单 -->
		<free-popup ref="action" bottom transformOrigin="center bottom" @hide="KeyboardHeight = 0" :mask="false">
			<view style="height: 580rpx;" class="border-top border-light-secondary bg-light">
				<swiper :indicator-dots="emoticonOrActionList.length > 1" style="height: 510rpx;">
					<swiper-item class="row" v-for="(item, index) in emoticonOrActionList" :key="index">
						<view class="col-3 flex flex-column align-center justify-center"
							style="height: 255rpx;box-sizing: border-box;" v-for="(item2, index2) in item" :key="index2"
							@click="actionEvent(item2)">
							<image :src="item2.icon" mode="widthFix" style="width: 100rpx;height: 100rpx;"></image>
							<text class="font-sm text-muted mt-2">{{ item2.name }}</text>
						</view>
					</swiper-item>
				</swiper>
			</view>
		</free-popup>


		<!-- 弹出层 -->
		<free-popup ref="extend" :bodyWidth="240" :bodyHeight="450" :tabbarHeight="105">
			<view class="flex flex-column" style="width: 240rpx;" :style="getMenusStyle">
				<view class="flex-1 flex align-center" hover-class="bg-light" v-for="(item, index) in menusList"
					:key="index" @click="clickEvent(item.event)">
					<text class="font-md pl-3">{{ item.name }}</text>
				</view>
			</view>
		</free-popup>


		<!-- 录音提示 -->
		<view v-if="isRecording" class="position-fixed top-0 left-0 right-0 flex align-center justify-center"
			style="bottom: 105rpx;">
			<view style="width: 360rpx;height: 360rpx;background-color: rgba(0,0,0,0.5);"
				class="rounded flex flex-column align-center justify-center">
				<image src="/static/audio/recording.gif" style="width: 150rpx;height: 150rpx;"></image>
				<text class="font text-white mt-3">{{ unRecord ? '松开手指，取消发送' : '手指上滑，取消发送' }}</text>
			</view>
		</view>

	</view>
</template>

<script>
// #ifdef APP-PLUS-NVUE
const dom = weex.requireModule('dom')
// #endif

import freeNavBar from "@/components/free-ui/free-nav-bar.vue"
import freeIconButton from "@/components/free-ui/free-icon-button.vue"
import freeChatItem from '@/components/free-ui/free-chat-item.vue';
import freePopup from "@/components/free-ui/free-popup.vue"
import freeMainButton from '@/components/free-ui/free-main-button.vue';


import { mapState, mapMutations } from 'vuex'

import auth from '@/common/mixin/auth.js';
import $H from '@/common/free-lib/request.js';
import $C from '@/common/free-lib/config.js';
export default {
	mixins: [auth],
	components: {
		freeNavBar,
		freeIconButton,
		freeChatItem,
		freePopup,
		freeMainButton
	},
	data() {
		return {
			scrollIntoView: "",
			// 模式 text输入文字，emoticon表情，action操作，audio音频
			mode: "text",
			// 扩展菜单列表
			actionList: [
				[{
					name: "相册",
					icon: "/static/images/extends/pic.png",
					event: "uploadImage"
				}, {
					name: "拍摄",
					icon: "/static/images/extends/video.png",
					event: "uploadVideo"
				}, {
					name: "收藏",
					icon: "/static/images/extends/shoucan.png",
					event: "openFava"
				}, {
					name: "名片",
					icon: "/static/images/extends/man.png",
					event: "sendCard"
				}, {
					name: "语音通话",
					icon: "/static/images/extends/phone.png",
					event: "test"
				}, {
					name: "位置",
					icon: "/static/images/extends/path.png",
					event: "test"
				}]
			],
			emoticonList: [],
			// 键盘高度
			KeyboardHeight: 0,
			menusList: [],
			navBarHeight: 0,
			list: [],
			// 当前操作的气泡索引
			propIndex: -1,
			// 输入文字
			text: "",

			// 音频录制状态
			isRecording: false,
			RecordingStartY: 0,
			// 取消录音
			unRecord: false,

			detail: {
				id: 0,
				name: "",
				avatar: "",
				chat_type: "user"
			}
		}
	},
	mounted() {
		var statusBarHeight = 0
		// #ifdef APP-PLUS-NVUE
		statusBarHeight = plus.navigator.getStatusbarHeight()
		// #endif
		this.navBarHeight = statusBarHeight + uni.upx2px(90)

		// 监听键盘高度变化
		uni.onKeyboardHeightChange(res => {
			if (this.mode !== 'action' && this.mode !== 'emoticon') {
				this.KeyboardHeight = res.height
			}
			if (this.KeyboardHeight > 0) {
				this.pageToBottom()
			}
		})


		// 注册发送音频事件
		this.regSendVoiceEvent((url) => {
			if (!this.unRecord) {
				this.send('audio', url, {
					time: this.RecordTime
				})
			}
		})

		this.pageToBottom()
	},
	computed: {
		...mapState({
			chatList: state => state.user.chatList,
			RECORD: state => state.audio.RECORD,
			RecordTime: state => state.audio.RecordTime,
			chat: state => state.user.chat,
			totalNoreadnum: state => state.user.totalNoreadnum,
			user: state => state.user.user
		}),
		// 当前会话配置信息
		currentChatItem() {
			let index = this.chatList.findIndex(item => item.id === this.detail.id && item.chat_type === this.detail.chat_type)
			if (index !== -1) {
				return this.chatList[index]
			}
			return {}
		},
		// 获取蒙版的位置
		maskBottom() {
			return this.KeyboardHeight + uni.upx2px(105)
		},
		// 动态获取菜单高度
		getMenusHeight() {
			let H = 100
			return this.menusList.length * H
		},
		// 获取菜单的样式
		getMenusStyle() {
			return `height: ${this.getMenusHeight}rpx;`
		},
		// 判断是否操作本人信息
		isdoSelf() {
			// 获取本人id（假设拿到了）
			let id = 1
			let user_id = this.propIndex > -1 ? this.list[this.propIndex].user_id : 0
			return user_id === id
		},
		// 聊天区域bottom
		chatBodyBottom() {
			return `bottom:${uni.upx2px(105) + this.KeyboardHeight}px;top:${this.navBarHeight}px;`
		},
		// 获取操作或者表情列表
		emoticonOrActionList() {
			return (this.mode === 'emoticon' || this.mode === 'action') ? this[this.mode + 'List'] : []
		},
		// 所有信息的图片地址
		imageList() {
			let arr = []
			this.list.forEach((item) => {
				if (item.type === 'emoticon' || item.type === 'image') {
					arr.push(item.data)
				}
			})
			return arr
		}
	},
	watch: {
		mode(newValue, oldValue) {
			if (newValue !== 'action' && newValue !== 'emoticon') {
				this.$refs.action.hide()
			}
			if (newValue !== 'text') {
				// uni.hideKeyboard()
			}
		}
	},
	onLoad(e) {
		if (!e.params) {
			return this.backToast()
		}
		this.detail = JSON.parse(decodeURIComponent(e.params))
		console.log(this.detail);
		// 初始化
		this.__init()
		// 创建聊天对象
		this.chat.createChatObject(this.detail)
		// 获取历史记录
		this.list = this.chat.getChatDetail()
		// 监听接收聊天信息
		uni.$on('onMessage', this.onMessage)

		uni.$on('updateHistory', this.updateHistory)

		// 监听发送收藏和名片
		uni.$on('sendItem', this.onSendItem)
	},
	destroyed() {
		// 销毁聊天对象
		this.chat.destoryChatObject()
		// 销毁监听接收聊天消息
		uni.$off('onMessage', this.onMessage)

		uni.$off('updateHistory', this.updateHistory)

		uni.$off('sendItem', this.onSendItem)
	},
	methods: {
		test() {
			uni.showToast({
				title: '不在课程范围内，自己扩展',
				icon: 'none'
			});
		},
		...mapMutations(['regSendVoiceEvent']),
		onSendItem(e) {
			if (e.sendType === 'fava' || e.sendType === 'card') {
				this.send(e.type, e.data, e.options)
			}
		},
		updateHistory(isclear = true) {
			if (isclear) {
				this.list = []
			} else {
				this.list = this.chat.getChatDetail()
			}
		},
		onMessage(message) {
			console.log('[聊天页] 监听接收聊天信息', message);
			if ((message.from_id === this.detail.id && message.chat_type === 'user') || (message.chat_type === 'group' && message.to_id === this.detail.id)) {
				if (message.isremove !== 1) {
					this.list.push(message)
					// 置于底部
					return this.pageToBottom()
				}
				// 撤回消息
				let index = this.list.findIndex(item => item.id === message.id)
				if (index !== -1) {
					this.list[index].isremove = 1
				}
			}
		},
		__init() {
			var total = 20
			var page = Math.ceil(total / 8)
			var arr = []
			for (var i = 0; i < page; i++) {
				var start = i * 8
				arr[i] = []
				for (var j = 0; j < 8; j++) {
					var no = start + j
					if ((no + 1) > total) {
						continue;
					}
					arr[i].push({
						name: "表情" + no,
						icon: $C.emoticonUrl + no + '.gif',
						event: "sendEmoticon"
					})
				}
			}
			this.emoticonList = arr
			// 初始化会话列表
			this.chat.initChatListItem({
				chat_type: this.detail.chat_type,
				to_id: this.detail.id,
				to_name: this.detail.name,
				to_avatar: this.detail.avatar,
				data: this.detail.chat_type === 'user' ? '你们已经是好友，可以开始聊天了' : '你已经加入群聊，可以开始聊天了'
			})
		},
		// 打开扩展菜单或者表情包
		openActionOrEmoticon(mode = 'action') {
			this.mode = mode
			this.$refs.action.show()

			uni.hideKeyboard()
			this.KeyboardHeight = uni.upx2px(580)
		},
		// 发送
		send(type, data = '', options = {}) {
			// 组织数据格式
			switch (type) {
				case 'text':
					data = data || this.text
					break;
			}

			const isVideo = type === 'video'
			let message = this.chat.formatSendData({
				type,
				data: isVideo ? data.filePath : data,
				options
			})

			if (isVideo) {
				message.file = data.file
			}

			// 渲染到页面
			let index = this.list.length
			this.list.push(message)
			// 监听上传进度
			let onProgress = false
			if (message.type !== 'text' && message.type !== 'emoticon' && message.type !== 'card' && !message.data.startsWith('http')) {
				onProgress = (progress) => {
					console.log('上传进度：', progress);
				}
			}
			// 发送到服务端
			this.chat.send(message, onProgress).then(res => {
				console.log(res);
				// 发送成功
				this.list[index].id = res.id
				this.list[index].sendStatus = 'success'
			}).catch(err => {
				// 发送失败
				this.list[index].sendStatus = 'fail'
				console.log(err);
			})
			// 发送文字成功，清空输入框
			if (type === 'text') {
				this.text = ''
			}
			// 置于底部
			this.pageToBottom()
		},
		// 回到底部
		pageToBottom() {
			// #ifdef APP-PLUS-NVUE
			let chatItem = this.$refs.chatItem
			let lastIndex = chatItem.length > 0 ? chatItem.length - 1 : 0
			if (chatItem[lastIndex]) {
				dom.scrollToElement(chatItem[lastIndex], {})
			}
			// #endif
			// #ifndef APP-NVUE
			setTimeout(() => {
				let lastIndex = this.list.length - 1
				this.scrollIntoView = 'chatItem_' + lastIndex
			}, 300)
			// #endif
		},
		// 长按消息气泡
		long({ x, y, index }) {
			// 初始化 索引
			this.propIndex = index
			// 组装菜单
			let menus = [{
				name: "发送给朋友",
				event: 'sendToChatItem'
			}, {
				name: "收藏",
				event: 'fava'
			}, {
				name: "删除",
				event: 'delete'
			}]
			let item = this.list[this.propIndex]
			let isSelf = this.user.id === item.from_id
			if (isSelf) {
				menus.push({
					name: "撤回",
					event: 'removeChatItem'
				})
			}
			// #ifndef H5
			if (item.type === 'text') {
				menus.unshift({
					name: "复制",
					event: 'copy',
				})
			}
			// #endif
			this.menusList = menus
			// 显示扩展菜单
			this.$refs.extend.show(x, y)
		},
		// 操作菜单方法分发
		clickEvent(event) {
			let item = this.list[this.propIndex]
			let isSelf = this.user.id === item.from_id
			switch (event) {
				case 'removeChatItem': // 撤回消息
					// 拿到当前被操作的信息
					this.chat.recall(item).then(res => {
						item.isremove = 1
					})
					break;
				case 'sendToChatItem':
					uni.navigateTo({
						url: '../chat-list/chat-list?params=' + encodeURIComponent(JSON.stringify(item)),
					});
					break;
				case 'copy': // 复制
					uni.setClipboardData({
						data: item.data,
						success: () => {
							uni.showToast({
								title: '复制成功',
								icon: 'none'
							});
						}
					});
					break;
				case 'delete':
					uni.showModal({
						content: '是否要删除该记录？',
						success: (res) => {
							if (!res.confirm) return;
							this.chat.deleteChatDetailItem(item, isSelf)
							this.list.splice(this.propIndex, 1)
							// 删除最后一条消息
							if (this.list.length === this.propIndex) {
								this.chat.updateChatItem({
									id: this.detail.id,
									chat_type: this.detail.chat_type
								}, (v) => {
									let o = this.list[this.propIndex - 1]
									let data = ''
									if (o) {
										data = this.chat.formatChatItemData(o, isSelf)
									}
									v.data = data
									return v
								})
							}
						}
					});
					break;
				case 'fava': // 加入收藏
					uni.showModal({
						content: '是否要加入收藏？',
						success: (res) => {
							if (res.confirm) {
								$H.post('/fava/create', {
									type: item.type,
									data: item.data,
									options: JSON.stringify(item.options)
								}).then(res => {
									uni.showToast({
										title: '加入收藏成功',
										icon: 'none'
									});
								})
							}
						}
					});
					break;
			}
			// 关闭菜单
			this.$refs.extend.hide()
		},
		// 扩展菜单
		actionEvent(e) {
			switch (e.event) {
				case 'uploadImage': // 选择相册
					uni.chooseImage({
						count: 9,
						success: (res) => {
							// 发送到服务器
							// 渲染到页面
							res.tempFilePaths.forEach((item) => {
								this.send('image', item)
							})
						}
					})
					break;
				case 'uploadVideo': // 发送短视频
					uni.chooseVideo({
						maxDuration: 10,
						success: (res) => {
							this.send('video', {
								file: res.tempFile,
								filePath: res.tempFilePath
							})
							// 渲染页面
							// 发送到服务端（获取视频封面，返回url）
							// 修改本地的发送状态
						}
					})
					break;
				case 'sendEmoticon': // 发送表情包
					this.send('emoticon', e.icon)
					break;
				case 'openFava': // 发送收藏
					uni.navigateTo({
						url: '../../my/fava/fava?type=send',
					});
					break;
				case 'sendCard': // 发送名片
					uni.navigateTo({
						url: '../../mail/mail/mail?type=sendCard&limit=1',
					});
					break;
				case 'test':
					this.test()
					break;
			}
		},
		// 点击页面
		clickPage() {
			this.mode = ''
		},
		// 预览图片
		previewImage(url) {
			uni.previewImage({
				current: url,
				urls: this.imageList,
				indicator: "default"
			})
		},
		// 切换音频录制和文本输入
		changeVoiceOrText() {
			this.mode = this.mode !== 'audio' ? 'audio' : 'text'
		},
		// 录音相关
		// 录音开始
		voiceTouchStart(e) {
			// 初始化
			this.isRecording = true
			this.RecordingStartY = e.changedTouches[0].screenY
			this.unRecord = false
			// 开始录音
			this.RECORD.start({
				format: "mp3"
			})
		},
		// 录音结束
		voiceTouchEnd() {
			this.isRecording = false
			// 停止录音
			this.RECORD.stop()
		},
		// 录音被打断
		voiceTouchCancel() {
			this.isRecording = false
			this.unRecord = true
			// 停止录音
			this.RECORD.stop()
		},
		voiceTouchMove(e) {
			let Y = Math.abs(e.changedTouches[0].screenY - this.RecordingStartY)
			this.unRecord = (Y >= 50)
		},
		// 打开聊天信息设置
		openChatSet() {
			uni.navigateTo({
				url: '../chat-set/chat-set?params=' + JSON.stringify({
					id: this.detail.id,
					chat_type: this.detail.chat_type
				}),
			});
		}
	}
}
</script>

<style></style>
