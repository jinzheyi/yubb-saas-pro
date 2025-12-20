<template>
	<view>
		<!-- 导航栏 -->
		<free-nav-bar title="聊天记录" showBack :showRight="false">
		</free-nav-bar>
		<!-- 搜索框 -->
		<view class="p-3 bg-light position-fixed left-0 right-0"
		:style="'top:'+top+'px;'">
			<input type="text" v-model="keyword" placeholder="搜索" class="bg-white rounded" placeholder-class="text-center" style="height: 80rpx;"/>
		</view>
		<view style="height: 140rpx;"></view>
		<!-- 联系人列表 -->
		<view class="px-2 py-1 bg-light">
			<text class="font-sm text-muted">{{keyword ? '搜索结果' :'最近联系人'}}</text>
		</view>
		
		<view v-for="(item,index) in allList" :key="index"
		:id="'chatItem_'+index">
			<free-chat-item :item="item" :index="index" ref="chatItem"
			:pretime=" index > 0 ? list[index-1].create_time : 0"
			:shownickname="true"
			></free-chat-item>
		</view>
		
		<view v-if="keyword !== '' && searchList.length === 0" 
		class="flex align-center justify-center" 
		style="height: 100rpx;">
			<text class="font text-light-muted">暂无搜索结果</text>
		</view>
		
		
	</view>
</template>

<script>
	import freeNavBar from '@/components/free-ui/free-nav-bar.vue';
	import freeMainButton from '@/components/free-ui/free-main-button.vue';
	import freeChatItem from '@/components/free-ui/free-chat-item.vue';
	import freeAvater from '@/components/free-ui/free-avater.vue';
	import {mapState} from 'vuex';
	export default {
		components: {
			freeNavBar,
			freeMainButton,
			freeChatItem,
			freeAvater
		},
		data() {
			return {
				keyword:"",
				top:0,
				list:[]
			}
		},
		onLoad(e) {
			let res = uni.getSystemInfoSync()
			let statusBarHeight = 0
			// #ifndef MP
			statusBarHeight = res.statusBarHeight
			// #endif
			this.top = statusBarHeight + uni.upx2px(90)
			
			this.list = this.chat.getChatDetail()
		},
		computed: {
			...mapState({
				user:state=>state.user.user,
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
					return item.data.indexOf(this.keyword) !== -1
				})
			},
		},
		methods: {
			
		}
	}
</script>

<style>

</style>
