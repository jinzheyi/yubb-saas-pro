<template>
	<view class="page">
		<!-- 导航栏 -->
		<free-nav-bar showBack :showRight="detail.friend" bgColor="bg-white">
			<view slot="right">
				<free-icon-button 
				:icon="'\ue6fd'" v-if="detail.friend"
				@click="openAction"></free-icon-button>
			</view>
		</free-nav-bar>
		<view class="px-3 py-4 flex align-center bg-white border-bottom">
			<free-avater :src="detail.avatar" size="120"></free-avater>
			<view class="flex flex-column ml-3 flex-1">
				<view class="flex align-center justify-between">
					<text class="font-lg font-weight-bold mb-1">{{detail.nickname}}</text>
					<image v-if="detail.star" src="/static/images/star.png"
					style="width: 40rpx;height: 40rpx;"></image>
				</view>
				<text class="font-md text-light-muted">账号：{{detail.username}}</text>
			</view>
		</view>
		<free-list-item v-if="detail.friend" showRight :showLeftIcon="false" 
		@click="navigate(tagPath)">
			<view class="flex align-center">
				<text class="font-md text-dark mr-3">标签</text>
				<text class="font-md text-light-muted mr-2"
				v-for="(item,index) in detail.tags" :key="index">{{item}}</text>
				<text class="font-md text-light-muted" v-if="detail.tags.length < 1">未设置</text>
			</view>
		</free-list-item>
		<free-divider></free-divider>
		<free-list-item v-if="detail.friend" showRight :showLeftIcon="false" @click="openMoments">
			<view class="flex align-center">
				<text class="font-md text-dark mr-3">朋友圈</text>
				<template v-if="detail.moments[0]">
					<text v-if="detail.moments[0].content && !detail.moments[0].image.length" class="font text-secondary">{{detail.moments[0].content}}</text>
					<image v-for="(item,index) in detail.moments[0].image" :key="index" :src="item" style="width: 90rpx;height: 90rpx;"
					class="mr-2"></image>
				</template>
			</view>
		</free-list-item>
		<free-list-item title="更多信息" showRight :showLeftIcon="false"></free-list-item>
		<free-divider></free-divider>
		<view class="py-3 flex align-center justify-center bg-white"
		hover-class="bg-light" v-if="detail.friend" @click="doEvent">
			<text class="iconfont text-primary mr-1" 
			v-if="!detail.isblack">&#xe64e;</text>
			<text class="font-md text-primary">{{detail.isblack ? '移出黑名单' : '发信息'}}</text>
		</view>
		
		<view class="py-3 flex align-center justify-center bg-white"
		hover-class="bg-light" v-else 
		@click="navigate(addFriend)">
			<text class="font-md text-primary">添加好友</text>
		</view>
		<!-- 操作菜单 -->
		<free-popup ref="action" bottom transformOrigin="center bottom" maskColor>
			<scroll-view scroll-y="true" style="height: 580rpx;" 
			class="bg-white" :show-scrollbar="false">
				<free-list-item v-for="(item,index) in actions" :key="index" :title="item.title" :showRight="false" :border="false" @click="popupEvent(item)">
					<text slot="icon" class="iconfont font-lg py-1">{{item.icon}}</text>
				</free-list-item>
			</scroll-view>
		</free-popup>
		
		
	</view>
</template>

<script>
	import freeNavBar from "@/components/free-ui/free-nav-bar.vue"
	import freeAvater from '@/components/free-ui/free-avater.vue';
	import freeDivider from "@/components/free-ui/free-divider.vue"
	import freeListItem from "@/components/free-ui/free-list-item.vue"
	import freeIconButton from '@/components/free-ui/free-icon-button.vue';
	import freePopup from '@/components/free-ui/free-popup.vue';
	import auth from '@/common/mixin/auth.js';
	import $H from '@/common/free-lib/request.js';
	
	export default {
		mixins:[auth],
		components: {
			freeNavBar,
			freeAvater,
			freeDivider,
			freeListItem,
			freeIconButton,
			freePopup
		},
		data() {
			return {
				detail:{
					id: 0,
					username: "",
					nickname: "",
					avatar: "",
					sex: "",
					sign: "",
					area: "",
					friend: false,
					lookme: 1,
					lookhim: 1,
					star: 0,
					isblack: 0,
					tags: []
				},
			}
		},
		onLoad(e) {
			if(!e.user_id){
				return this.backToast()
			}
			this.detail.id = e.user_id
			
			uni.$on('saveRemarkTag',(e)=>{
				this.nickname = e.nickname
				this.tagList = e.tagList
			})
		},
		onShow() {
			// 获取当前用户资料
			this.getData()
		},
		computed: {
			addFriend() {
				let obj = {
					friend_id:this.detail.id,
					nickname:this.detail.nickname,
					lookme:typeof this.detail.lookme === 'number' ? this.detail.lookme : 1,
					lookhim:typeof this.detail.lookhim === 'number' ? this.detail.lookhim : 1
				}
				return 'mail/add-friend/add-friend?params='+JSON.stringify(obj)
			},
			tagPath(){
				return "mail/user-remark-tag/user-remark-tag?params="+JSON.stringify({
						user_id:this.detail.id,
						nickname:this.detail.nickname,
						tags:this.detail.tags ? this.detail.tags.join(',') : ''
					})
			},
			actions(){
				return [{
					icon:"\ue6b3",
					title:"设置备注和标签",
					type:"navigate",
					path:this.tagPath
				},{
					icon:"\ue613",
					title:"把他推荐给朋友",
					type:"navigate",
					path:"chat/chat-list/chat-list?params="+encodeURIComponent(JSON.stringify({
						type: "card",
						data: this.detail.nickname || this.detail.username,
						options: {
							avatar: this.detail.avatar,
							id: this.detail.id
						}
					}))
				},{
					icon:"\ue6b0",
					title:this.detail.star ? '取消星标好友' : "设为星标朋友",
					type:"event",
					event:"setStar"
				},{
					icon:"\ue667",
					title:"设置朋友圈和动态权限",
					type:"navigate",
					path:"mail/user-moments-auth/user-moments-auth?user_id="+this.detail.id +"&params="+JSON.stringify({
						lookme:this.detail.lookme,
						lookhim:this.detail.lookhim,
					})
				},{
					icon:"\ue638",
					title:this.detail.isblack ? '移出黑名单' : "加入黑名单",
					type:"event",
					event:"setBlack"
				},{
					icon:"\ue61c",
					title:"投诉",
					type:"navigate",
					path:"mail/user-report/user-report?params="+JSON.stringify({
						user_id:this.detail.id,
						type:"user"
					})
				},{
					icon:"\ue638",
					title:"删除",
					type:"event",
					event:"deleteItem"
				}]
			}
		},
		beforeDestroy() {
			uni.$off('saveRemarkTag')
		},
		methods: {
			getData(){
				$H.get('/friend/read/'+this.detail.id).then(res=>{
					if(!res){
						return this.backToast('该用户不存在')
					}
					if(res.moments && res.moments[0]){
						res.moments[0].image = res.moments[0].image.split(',')
					}
					this.detail = res
				})
			},
			// 打开操作菜单
			openAction(){
				this.$refs.action.show()
			},
			// 跳转
			navigate(path){
				uni.navigateTo({
					url: '/pages/'+path,
				});
			},
			// 操作菜单事件 
			popupEvent(e){
				if(!e.type){
					return
				}
				switch (e.type){
					case 'navigate':
					uni.navigateTo({
						url: '/pages/'+e.path
					});
						break;
					case 'event':
					this[e.event](e)
						break;
				}
				setTimeout(()=>{
					// 关闭弹出层
					this.$refs.action.hide()
				},300)
			},
			// 删除好友
			deleteItem(){
				uni.showModal({
					content: '是否要删除该好友？',
					success: (res)=> {
						if (res.confirm) {
							$H.post('/friend/destroy',{
								friend_id:this.detail.id
							}).then(res=>{
								uni.showToast({
									title: '删除好友成功',
									icon: 'none'
								});
								uni.reLaunch({
									url:"/pages/tabbar/index/index"
								})
							})
						}
					}
				});
			},
			// 设为星标
			setStar(e){
				let star = this.detail.star == 0 ? 1 : 0
				$H.post('/friend/setstar/'+this.detail.id,{
					star
				}).then(res=>{
					this.detail.star = star
					e.title = this.detail.star ? '取消星标好友' : "设为星标朋友"
				})
			},
			// 加入黑名单
			setBlack(e){
				let msg = this.detail.isblack ? '移出黑名单' : '加入黑名单'
				uni.showModal({
					content: '是否要'+msg+'？',
					success: (res)=> {
						if (res.confirm) {
							let isblack = this.detail.isblack == 0 ? 1 : 0
							$H.post('/friend/setblack/'+this.detail.id,{
								isblack
							}).then(res=>{
								this.detail.isblack = isblack
							})
							uni.showToast({
								title: msg+'成功',
								icon: 'none'
							});
						} 
					}
				});
			},
			doEvent(){
				if(this.detail.isblack){
					return this.setBlack()
				}
				uni.navigateTo({
					url: '../../chat/chat/chat?params='+encodeURIComponent(JSON.stringify({
						id:this.detail.id,
						name:this.detail.nickname ? this.detail.nickname : this.detail.username,
						avatar:this.detail.avatar,
						chat_type:"user"
					})),
				});
			}
		}
	}
</script>

<style>

</style>
