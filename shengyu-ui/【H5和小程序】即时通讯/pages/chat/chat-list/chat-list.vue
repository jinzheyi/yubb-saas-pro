<template>
	<view>
		<!-- 导航栏 -->
		<free-nav-bar title="选择" showBack :showRight="true">
			<free-main-button :name="muliSelect ? '发送 ('+selectCount+')' : '多选'" slot="right" @click="handleNavBarBtn"></free-main-button>
		</free-nav-bar>
		<!-- 搜索框 -->
		<view class="p-3 bg-light position-fixed left-0 right-0"
		:style="'top:'+top+'px;'" style="z-index: 2;">
			<input type="text" v-model="keyword" placeholder="搜索" class="bg-white rounded" placeholder-class="text-center" style="height: 80rpx;"/>
		</view>
		<view style="height: 140rpx;"></view>
		
		<free-list-item :title="item.name" 
		v-for="(item,index) in allList"
		:key="index" :cover="item.avatar || '/static/images/userpic.png'" showRight 
		:showRightIcon="false" @click="selectItem(item)">
			<view v-if="muliSelect" slot="right" 
			style="width: 40rpx;height: 40rpx;"
			class="border rounded-circle flex align-center justify-center">
				<view v-if="item.checked" style="width: 30rpx;height: 30rpx;"
				class="main-bg-color rounded-circle"></view>
			</view>
		</free-list-item>
		
		<view v-if="keyword !== '' && searchList.length === 0" 
		class="flex align-center justify-center" 
		style="height: 100rpx;">
			<text class="font text-light-muted">暂无搜索结果</text>
		</view>
		
		<free-confirm ref="confirm" title="发送给：">
			<scroll-view v-if="selectCount > 0" scroll-x="true" :show-scrollbar="false">
				<view class="flex">
					<view class="mr-1" v-for="(item,index) in selectList" :key="index">
						<free-avater :src="item.avatar" size="60"></free-avater>
					</view>
				</view>
			</scroll-view>
			<view class="flex" v-else>
				<free-avater :src="sendItem.avatar" size="60"></free-avater>
				<text class="font text-muted ml-2">{{sendItem.name}}</text>
			</view>
			<view class="my-3 bg-light rounded p-2">
				<text class="font text-light-muted">{{message}}</text>
			</view>
			<input type="text" class="border-bottom font-md" style="height: 60rpx;" placeholder="给朋友留言" v-model="content"/>
		</free-confirm>
		
	</view>
</template>

<script>
	import freeNavBar from '@/components/free-ui/free-nav-bar.vue';
	import freeMainButton from '@/components/free-ui/free-main-button.vue';
	import freeListItem from '@/components/free-ui/free-list-item.vue';
	import freeConfirm from '@/components/free-ui/free-confirm.vue';
	import freeAvater from '@/components/free-ui/free-avater.vue';
	import { mapState } from 'vuex'
	export default {
		components: {
			freeNavBar,
			freeMainButton,
			freeListItem,
			freeConfirm,
			freeAvater
		},
		data() {
			return {
				keyword:"",
				muliSelect:false,
				top:0,
				list:[],
				detail:{},
				sendItem:{},
				content:""
			}
		},
		onLoad(e) {
			let res = uni.getSystemInfoSync()
			this.top = res.statusBarHeight + uni.upx2px(90)
			
			this.list = this.chatList.map(item=>{
				return {
					...item,
					checked:false
				}
			})
			
			if(e.params){
				this.detail = JSON.parse(decodeURIComponent(e.params))
				console.log(this.detail);
			}
		},
		computed: {
			...mapState({
				chatList:state=>state.user.chatList,
				chat:state=>state.user.chat
			}),
			// 最终列表
			allList(){
				return this.keyword==='' ? this.list : this.searchList
			},
			// 搜索结果列表
			searchList(){
				if(this.keyword === ''){
					return []
				}
				return this.list.filter(item=>{
					return item.name.indexOf(this.keyword) !== -1
				})
			},
			// 选中列表
			selectList() {
				return this.list.filter(item=>item.checked) 
			},
			// 选中数量
			selectCount(){
				return this.selectList.length
			},
			message(){
				let obj = {
					image:"[图片]",
					video:"[视频]",
					audio:"[语音]",
					card:"[名片]",
					emoticon:"[表情]"
				}
				return this.detail.type === 'text' ? this.detail.data : obj[this.detail.type]
			}
		},
		methods: {
			// 点击导航栏按钮事件（群发）
			handleNavBarBtn(){
				// 切换成多选状态
				if(!this.muliSelect){
					return this.muliSelect = true
				}
				// 发送
				if(this.selectCount === 0){
					return uni.showToast({
						title: '请先选择',
						icon: 'none'
					});
				}
				this.$refs.confirm.show((close)=>{
					this.selectList.forEach(item=>{
						this.send(item)
						if(this.content){
							this.send(item,this.content,'text')
						}
					})
					close()
					uni.reLaunch({
						url:"../../tabbar/index/index"
					})
				})
			},
			// 选中/取消选中 | 发送
			selectItem(item){
				// 选中/取消选中
				if(this.muliSelect){
					if(!item.checked && this.selectCount === 9){ 
						// 选中|限制选中数量
						return uni.showToast({
							title: '最多选中 9 个',
							icon: 'none'
						});
					}
					return item.checked = !item.checked
				}
				// 发送
				this.sendItem = item
				this.$refs.confirm.show((close)=>{
					this.send(item)
					if(this.content){
						this.send(item,this.content,'text')
					}
					close()
					uni.reLaunch({
						url:"../../tabbar/index/index"
					})
				})
			},
			send(item,data = false,type = false){
				let message = this.chat.formatSendData({
					to_id:item.id,
					to_name:item.name,
					to_avatar:item.avatar,
					chat_type:item.chat_type,
					data:data || this.detail.data,
					type:type || this.detail.type,
					options:this.detail.options
				})
				this.chat.send(message)
			},
			// 更多联系人
			openMail(){
				uni.navigateTo({
					url: '../mail/mail'
				});
			}
		}
	}
</script>

<style>

</style>
